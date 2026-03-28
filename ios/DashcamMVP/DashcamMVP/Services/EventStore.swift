import Foundation

final class EventStore: ObservableObject {
    @Published private(set) var events: [DetectedEvent] = []

    let clipsDirectoryURL: URL
    private let metadataURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appURL = baseURL.appendingPathComponent("DashcamMVP", isDirectory: true)
        self.clipsDirectoryURL = appURL.appendingPathComponent("SavedClips", isDirectory: true)
        self.metadataURL = appURL.appendingPathComponent("events.json")

        try? fileManager.createDirectory(at: clipsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        load()
    }

    func add(_ event: DetectedEvent) {
        events.insert(event, at: 0)
        persist()
    }

    func update(_ event: DetectedEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        persist()
    }

    func delete(_ event: DetectedEvent) {
        events.removeAll { $0.id == event.id }
        try? fileManager.removeItem(at: url(for: event))
        persist()
    }

    func url(for event: DetectedEvent) -> URL {
        clipsDirectoryURL.appendingPathComponent(event.clipRelativePath)
    }

    func totalClipBytes() -> Int64 {
        events.reduce(into: Int64(0)) { partialResult, event in
            let values = try? url(for: event).resourceValues(forKeys: [.fileSizeKey])
            partialResult += Int64(values?.fileSize ?? 0)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL) else { return }
        if let decoded = try? JSONDecoder().decode([DetectedEvent].self, from: data) {
            events = decoded.sorted(by: { $0.timestamp > $1.timestamp })
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }
}

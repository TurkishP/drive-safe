import AVKit
import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let eventID: UUID

    var body: some View {
        Group {
            if let event = event {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VideoPlayer(player: AVPlayer(url: environment.eventStore.url(for: event)))
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        InfoCard(title: event.eventType.title, systemImage: "exclamationmark.triangle") {
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                            Text("Confidence: \(Int(event.confidence * 100))%")
                            Text("Duration: \(Int(event.duration)) seconds")
                        }

                        InfoCard(title: "Detector Notes", systemImage: "brain.head.profile") {
                            Text(event.detectorSummary)
                            Text("TODO: Show model-specific overlays, lane masks, and tracked vehicle annotations here when real CV is integrated.")
                                .foregroundStyle(.secondary)
                        }

                        actionButtons(for: event)
                    }
                    .padding()
                }
                .navigationTitle("Review Event")
            } else {
                ContentUnavailableView("Event Missing", systemImage: "xmark.bin", description: Text("The selected clip is no longer available."))
            }
        }
    }

    private var event: DetectedEvent? {
        environment.eventStore.events.first(where: { $0.id == eventID })
    }

    private func actionButtons(for event: DetectedEvent) -> some View {
        VStack(spacing: 12) {
            Button("Keep Clip") {
                update(event: event, reviewState: .kept)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("Mark For Report") {
                update(event: event, reviewState: .markedForReport)
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            Button("Delete Clip", role: .destructive) {
                environment.eventStore.delete(event)
                environment.coordinator.refreshStorageUsage()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private func update(event: DetectedEvent, reviewState: ReviewState) {
        var updated = event
        updated.reviewState = reviewState
        environment.eventStore.update(updated)
    }
}

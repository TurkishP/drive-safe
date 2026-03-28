import Foundation

enum ViolationType: String, Codable, CaseIterable, Identifiable {
    case centerLineCrossing
    case solidLineLaneChange

    var id: String { rawValue }

    var title: String {
        switch self {
        case .centerLineCrossing:
            return "Center Line Crossing"
        case .solidLineLaneChange:
            return "Solid Line Lane Change"
        }
    }
}

enum ReviewState: String, Codable, CaseIterable {
    case pending
    case kept
    case markedForReport
}

struct DetectedEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let eventType: ViolationType
    let timestamp: Date
    let confidence: Double
    let clipRelativePath: String
    var reviewState: ReviewState
    var notes: String?
    let duration: TimeInterval
    let detectorSummary: String
}

struct SuspectedEvent {
    let type: ViolationType
    let timestamp: Date
    let confidence: Double
    let summary: String
}

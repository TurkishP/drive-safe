import Foundation

struct AppSettings: Codable {
    var rollingBufferLength: TimeInterval = 30
    var preEventSeconds: TimeInterval = 10
    var postEventSeconds: TimeInterval = 10
    var sensitivity: Double = 0.6
    var storageCapMB: Int = 1024
    var segmentDuration: TimeInterval = 2
}

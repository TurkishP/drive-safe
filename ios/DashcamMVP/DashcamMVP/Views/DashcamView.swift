import SwiftUI

struct DashcamView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                CameraPreviewView(session: environment.coordinator.cameraManager.session)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    header
                    controls
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Stop") {
                        environment.coordinator.stopDashcamMode()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: environment.coordinator.isDashcamActive) { _, active in
            if active == false {
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statusBadge(title: environment.coordinator.cameraManager.sessionState.rawValue.capitalized, value: "Session")
                statusBadge(title: "Active", value: "Rolling Buffer")
                statusBadge(title: "\(environment.eventStore.events.count)", value: "Events")
            }

            HStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    statusBadge(title: context.date.formatted(date: .omitted, time: .standard), value: "Current Time")
                }

                statusBadge(title: formattedStorage(environment.coordinator.totalStorageBytes), value: "Storage")
                statusBadge(title: "\(environment.coordinator.pendingExports)", value: "Pending Saves")
            }

            Text(environment.coordinator.lastStatusMessage)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Simulate Event") {
                environment.coordinator.simulateDetection()
            }
            .buttonStyle(.borderedProminent)

            Button("Refresh Storage") {
                environment.coordinator.refreshStorageUsage()
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    private func statusBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
    }

    private func formattedStorage(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                InfoCard(title: "Dashcam Mode", systemImage: "car.fill") {
                    Text("Foreground-only camera capture for suspected-event clip collection.")
                    Text("The app stops recording when the phone is locked or the app leaves the foreground.")
                        .foregroundStyle(.secondary)
                }

                InfoCard(title: "MVP Scope", systemImage: "viewfinder") {
                    Text("Suspected events only, not legal conclusions.")
                    Text("Current focus: center line crossing and solid line lane changes.")
                        .foregroundStyle(.secondary)
                }

                Button {
                    environment.coordinator.startDashcamMode()
                } label: {
                    VStack(spacing: 8) {
                        Text("Start Dashcam Mode")
                            .font(.headline)
                        Text("Keep screen on, lower brightness manually, and stay in foreground.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if let error = environment.coordinator.cameraManager.lastErrorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                InfoCard(title: "Saved Events", systemImage: "tray.full") {
                    Text("\(environment.eventStore.events.count) clips saved for later review")
                    Text(environment.coordinator.lastStatusMessage)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Drive Evidence")
    }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        Form {
            Section("Clip Window") {
                Stepper(value: rollingBufferLength, in: 15...120, step: 5) {
                    Text("Rolling buffer: \(Int(environment.settingsStore.settings.rollingBufferLength)) sec")
                }

                Stepper(value: preEventSeconds, in: 5...30, step: 1) {
                    Text("Pre-event: \(Int(environment.settingsStore.settings.preEventSeconds)) sec")
                }

                Stepper(value: postEventSeconds, in: 5...30, step: 1) {
                    Text("Post-event: \(Int(environment.settingsStore.settings.postEventSeconds)) sec")
                }

                Stepper(value: segmentDuration, in: 1...5, step: 1) {
                    Text("Segment duration: \(Int(environment.settingsStore.settings.segmentDuration)) sec")
                }
            }

            Section("Detection") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sensitivity")
                    Slider(value: sensitivity, in: 0.1...1.0)
                    Text("\(Int(environment.settingsStore.settings.sensitivity * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Storage") {
                Stepper(value: storageCapMB, in: 256...8192, step: 256) {
                    Text("Storage cap: \(environment.settingsStore.settings.storageCapMB) MB")
                }

                Text("MVP note: the current app reports usage but does not yet auto-prune saved clips when the cap is reached.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private var rollingBufferLength: Binding<Double> {
        Binding(
            get: { environment.settingsStore.settings.rollingBufferLength },
            set: { environment.settingsStore.settings.rollingBufferLength = $0 }
        )
    }

    private var preEventSeconds: Binding<Double> {
        Binding(
            get: { environment.settingsStore.settings.preEventSeconds },
            set: { environment.settingsStore.settings.preEventSeconds = $0 }
        )
    }

    private var postEventSeconds: Binding<Double> {
        Binding(
            get: { environment.settingsStore.settings.postEventSeconds },
            set: { environment.settingsStore.settings.postEventSeconds = $0 }
        )
    }

    private var sensitivity: Binding<Double> {
        Binding(
            get: { environment.settingsStore.settings.sensitivity },
            set: { environment.settingsStore.settings.sensitivity = $0 }
        )
    }

    private var storageCapMB: Binding<Int> {
        Binding(
            get: { environment.settingsStore.settings.storageCapMB },
            set: { environment.settingsStore.settings.storageCapMB = $0 }
        )
    }

    private var segmentDuration: Binding<Double> {
        Binding(
            get: { environment.settingsStore.settings.segmentDuration },
            set: { environment.settingsStore.settings.segmentDuration = $0 }
        )
    }
}

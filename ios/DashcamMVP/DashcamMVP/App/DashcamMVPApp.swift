import SwiftUI

@main
struct DashcamMVPApp: App {
    @StateObject private var environment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .onChange(of: scenePhase) { _, newPhase in
                    environment.coordinator.handleScenePhase(newPhase)
                }
        }
    }
}

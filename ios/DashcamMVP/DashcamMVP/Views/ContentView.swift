import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                EventsListView()
            }
            .tabItem {
                Label("Events", systemImage: "film")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .fullScreenCover(isPresented: dashcamBinding) {
            DashcamView()
                .environmentObject(environment)
        }
    }

    private var dashcamBinding: Binding<Bool> {
        Binding(
            get: { environment.coordinator.isDashcamActive },
            set: { shouldPresent in
                if shouldPresent == false {
                    environment.coordinator.stopDashcamMode()
                }
            }
        )
    }
}

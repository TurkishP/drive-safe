import SwiftUI

struct EventsListView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        List {
            if environment.eventStore.events.isEmpty {
                ContentUnavailableView(
                    "No Saved Events",
                    systemImage: "film.stack",
                    description: Text("Suspected-event clips will appear here after dashcam mode saves them.")
                )
            } else {
                ForEach(environment.eventStore.events) { event in
                    NavigationLink {
                        EventDetailView(eventID: event.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.eventType.title)
                                .font(.headline)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("Confidence \(Int(event.confidence * 100))%")
                                Text(event.reviewState.rawValue.capitalized)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Events")
    }
}

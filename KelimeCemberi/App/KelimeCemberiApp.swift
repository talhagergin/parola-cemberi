import SwiftUI
import SwiftData

@main
struct KelimeCemberiApp: App {
    private let container = PersistenceContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView(persistence: PersistenceStore(context: container.mainContext))
        }
        .modelContainer(container)
    }
}

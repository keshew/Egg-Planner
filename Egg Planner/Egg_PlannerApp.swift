import SwiftUI

@main
struct Egg_PlannerApp: App {
    @StateObject private var viewModel = EggPlannerViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainPlannerView()
                .environmentObject(viewModel)
        }
    }
}

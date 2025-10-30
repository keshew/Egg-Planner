//
//  Egg_PlannerApp.swift
//  Egg Planner
//
//  Created by Артём Коротков on 30.10.2025.
//

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

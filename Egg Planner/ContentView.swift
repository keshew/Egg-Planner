import SwiftUI
import PDFKit
import UIKit
import UserNotifications

struct MainPlannerView: View {
    @StateObject private var viewModel = EggPlannerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                      .edgesIgnoringSafeArea(.all)
                
                TabView(selection: $selectedTab) {
                    PlannerHomeView()
                        .tabItem {
                            Label("Planner", systemImage: "calendar")
                        }
                        .tag(0)
                    
                    StorageListView()
                        .tabItem {
                            Label("Storage", systemImage: "tray.full")
                        }
                        .tag(1)
                    
                    CalendarView()
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                        .tag(2)
                    AnalyticsView()
                        .tabItem {
                            Label("Analytics", systemImage: "chart.bar")
                        }
                        .tag(3)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .tag(4)
                    
                }
                .accentColor(Color(hex: "#F4B400"))
            }
        }
    }
}

#Preview {
    MainPlannerView()
        .environmentObject(EggPlannerViewModel())
}

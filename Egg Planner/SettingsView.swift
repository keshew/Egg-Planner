import SwiftUI

struct SettingsView: View {
    @AppStorage("notifyCollectEggs") private var notifyCollectEggs = true
    @AppStorage("notifyCheckShelfLife") private var notifyCheckShelfLife = true
    
    var body: some View {
        ZStack {
            Color(hex: "#FFF8E6").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Toggle("Reminder: Collect Eggs", isOn: $notifyCollectEggs)
                        .padding(.horizontal)
                        .onChange(of: notifyCollectEggs) { enabled in
                            if enabled {
//                                scheduleCollectReminder()
                            } else {
//                                removeCollectReminder()
                            }
                        }
                    
                    Toggle("Reminder: Check Shelf Life", isOn: $notifyCheckShelfLife)
                        .padding(.horizontal)
                        .onChange(of: notifyCheckShelfLife) { enabled in
                            if enabled {
//                                scheduleShelfLifeReminder()
                            } else {
//                                removeShelfLifeReminder()
                            }
                        }
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("Settings")
        .onAppear {
//            requestNotificationAuthorization()
        }
    }
//    
//    private func requestNotificationAuthorization() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
//    }
//    
//    private func scheduleCollectReminder() {
//        let content = UNMutableNotificationContent()
//        content.title = "Collect Eggs"
//        content.body = "It's time to collect your eggs today!"
//        content.sound = .default
//        
//        var dateComponents = DateComponents()
//        dateComponents.hour = 9
//        
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//        
//        let request = UNNotificationRequest(identifier: "collectEggsReminder", content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request)
//    }
//    
//    private func removeCollectReminder() {
//        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["collectEggsReminder"])
//    }
//    
//    private func scheduleShelfLifeReminder() {
//        let content = UNMutableNotificationContent()
//        content.title = "Check Egg Shelf Life"
//        content.body = "Check if any egg batches are close to expiring."
//        content.sound = .default
//        
//        var dateComponents = DateComponents()
//        dateComponents.hour = 18
//        
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//        
//        let request = UNNotificationRequest(identifier: "checkShelfLifeReminder", content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request)
//    }
//    
//    private func removeShelfLifeReminder() {
//        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["checkShelfLifeReminder"])
//    }
}

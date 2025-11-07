import SwiftUI

struct SettingsView: View {
    @AppStorage("notifyCollectEggs") private var notifyCollectEggs = true
    @AppStorage("notifyCheckShelfLife") private var notifyCheckShelfLife = true
    let privacyPolicyURL = URL(string: "https://www.freeprivacypolicy.com/live/a81db796-8d66-45e4-9021-772379c82315")!
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
                    
                    Toggle("Reminder: Check Shelf Life", isOn: $notifyCheckShelfLife)
                        .padding(.horizontal)
                    
                    Button(action: {
                                  if UIApplication.shared.canOpenURL(privacyPolicyURL) {
                                      UIApplication.shared.open(privacyPolicyURL)
                                  }
                              }) {
                                  Text("Privacy Policy")
                                      .foregroundColor(.blue)
                                      .underline()
                                      .padding(.horizontal)
                              }
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("Settings")
    }
}

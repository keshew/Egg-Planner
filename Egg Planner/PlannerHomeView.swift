import SwiftUI

struct PlannerHomeView: View {
    @EnvironmentObject var viewModel: EggPlannerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFF8E6").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Egg Planner")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Collected today")
                                        .font(.headline)
                                    Text("\(viewModel.todayCollected())")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(Color(hex: "#F4B400"))
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("In storage")
                                        .font(.headline)
                                    Text("\(viewModel.totalEggs())")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(Color(hex: "#F28C38"))
                                }
                            }
                            .padding(.top)
                        }
                        .padding(.horizontal)
                        
                        CircularFreshnessView(progress: viewModel.freshnessPercentage())
                            .frame(height: 250)
                        
                        NavigationLink(destination: AddBatchView().environmentObject(viewModel)) {
                            PlannerTile(icon: "plus.circle.fill", title: "Add Batch", color: Color(hex: "#F4B400"))
//                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                }
                .navigationTitle("Planner")
            }
        }
    }
}

struct PlannerTile: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(color)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, y: 2)
    }
}

struct CircularFreshnessView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 1)
                .stroke(Color.gray.opacity(0.2), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .red]), center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            VStack {
                Text("Freshness")
                    .font(.headline)
                Text("\(Int(progress * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.1), radius: 6, y: 3)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (r, g, b): (UInt64, UInt64, UInt64)
        switch hex.count {
        case 6: (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

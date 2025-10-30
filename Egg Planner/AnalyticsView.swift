import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTab = 0
    @State private var showingExportAlert = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        ZStack {
            Color(hex: "#FFF8E6").ignoresSafeArea()

            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Picker("Select Chart", selection: $selectedTab) {
                            Text("Daily").tag(0)
                            Text("Weekly Avg").tag(1)
                            Text("Top Storage").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        TabView(selection: $selectedTab) {
                            Group {
                                if viewModel.dailyData.allSatisfy({ $0 == 0 }) {
                                    Text("No Data")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                } else {
                                    LineChartView(data: viewModel.dailyData, title: "Eggs Collected Daily")
                                }
                            }
                            .tag(0)

                            Group {
                                if viewModel.weeklyAvgData.allSatisfy({ $0 == 0 }) {
                                    Text("No Data")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                } else {
                                    LineChartView(data: viewModel.weeklyAvgData, title: "Weekly Average Eggs")
                                }
                            }
                            .tag(1)

                            Group {
                                if viewModel.topStorageData.isEmpty {
                                    Text("No Data")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                } else {
                                    StorageBarChartView(data: viewModel.topStorageData)
                                }
                            }
                            .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .animation(.easeInOut, value: selectedTab)
                        .frame(height: 200)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Total Eggs Collected: \(viewModel.totalEggs)")
                                .font(.headline)
                            Text("Average Shelf Life: \(viewModel.avgShelfLife, specifier: "%.1f") days")
                                .font(.headline)
                            Text("Average Weight: \(viewModel.avgWeight, specifier: "%.1f") g")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                Spacer()
                
                Button(action: exportPDF) {
                    Text("Export PDF Report")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#F4B400"))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                .alert(isPresented: $showingExportAlert) {
                    Alert(title: Text("PDF Export"),
                          message: Text("PDF report generated. Choose to share or save."),
                          dismissButton: .default(Text("OK")))
                }
            }
            .navigationTitle("Analytics")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    private func exportPDF() {
        guard let data = PDFGenerator.generateReport(viewModel: viewModel) else {
            showingExportAlert = true
            return
        }
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootVC.present(activityVC, animated: true, completion: nil)
    }
}

class AnalyticsViewModel: ObservableObject {
    @Published var batches: [EggBatch] = []
    @Published var dailyData: [Double] = []
    @Published var weeklyAvgData: [Double] = []
    @Published var topStorageData: [StorageCount] = []
    
    @Published var totalEggs = 0
    @Published var avgShelfLife = 0.0
    @Published var avgWeight = 0.0

    func loadData() {
        batches = StorageManager.shared.loadBatches()
        totalEggs = batches.reduce(0) { $0 + $1.count }
        avgShelfLife = batches.isEmpty ? 0 : batches.map { Double($0.shelfLifeDays) }.reduce(0, +) / Double(batches.count)
        avgWeight = batches.compactMap { $0.averageWeight }.reduce(0, +) / Double(batches.compactMap { $0.averageWeight }.count.nonZero)
        
        dailyData = generateDailyData()
        weeklyAvgData = generateWeeklyAverage()
        topStorageData = calculateTopStorage()
    }

    private func generateDailyData() -> [Double] {
        var dict = [Date: Int]()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for dayOffset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            dict[date] = 0
        }
        for batch in batches {
            let date = calendar.startOfDay(for: batch.dateCollected)
            if dict[date] != nil {
                dict[date]! += batch.count
            }
        }
        return dict.sorted(by: { $0.key < $1.key }).map { Double($0.value) }
    }

    private func generateWeeklyAverage() -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var weeklySums: [Int] = Array(repeating: 0, count: 8)
        var weeklyCounts: [Int] = Array(repeating: 0, count: 8)

        for batch in batches {
            guard let weekDiff = calendar.dateComponents([.weekOfYear], from: batch.dateCollected, to: today).weekOfYear else { continue }
            if weekDiff < 8 && weekDiff >= 0 {
                weeklySums[7 - weekDiff] += batch.count
                weeklyCounts[7 - weekDiff] += 1
            }
        }
        return weeklySums.enumerated().map { index, sum in
            let count = weeklyCounts[index]
            return count == 0 ? 0 : Double(sum) / Double(count)
        }
    }

    private func calculateTopStorage() -> [StorageCount] {
        var counts = [StoragePlace: Int]()
        for batch in batches {
            counts[batch.storagePlace, default: 0] += batch.count
        }
        let sorted = counts.map { StorageCount(place: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        return Array(sorted.prefix(3))
    }
}

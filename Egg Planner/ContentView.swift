import SwiftUI

struct EggBatch: Identifiable, Codable {
    let id: UUID
    var dateCollected: Date
    var count: Int
    var averageWeight: Double?
    var storagePlace: StoragePlace
    var shelfLifeDays: Int

    var expirationDate: Date {
        Calendar.current.date(byAdding: .day, value: shelfLifeDays, to: dateCollected) ?? dateCollected
    }

    var daysLeft: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }

    var freshnessColor: Color {
        switch daysLeft {
        case let x where x > 18: return .green
        case 10...18: return Color.orange
        default: return Color.red
        }
    }
}

enum StoragePlace: String, Codable, CaseIterable, Identifiable {
    case fridge = "Fridge"
    case basket = "Basket"
    case cellar = "Cellar"

    var id: String { rawValue }
}

class StorageManager {
    private let key = "egg_batches"
    static let shared = StorageManager()

    func loadBatches() -> [EggBatch] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([EggBatch].self, from: data)) ?? []
    }

    func saveBatches(_ batches: [EggBatch]) {
        if let data = try? JSONEncoder().encode(batches) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

import SwiftUI

class EggPlannerViewModel: ObservableObject {
    @Published var batches: [EggBatch] = []
    
    init() {
        load()
    }

    func load() {
        batches = StorageManager.shared.loadBatches()
    }

    func totalEggs() -> Int {
        batches.reduce(0) { $0 + $1.count }
    }

    func todayCollected() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return batches.filter {
            Calendar.current.isDate($0.dateCollected, inSameDayAs: today)
        }.reduce(0) { $0 + $1.count }
    }

    func freshnessPercentage() -> Double {
        let expiring = batches.filter { $0.daysLeft <= 5 }.count
        let total = batches.count
        return total == 0 ? 1.0 : 1.0 - Double(expiring) / Double(total)
    }
}

import SwiftUI

struct MainPlannerView: View {
    @StateObject private var viewModel = EggPlannerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white // Или любой другой цвет
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

// Вынес главный экран "Планировщик" в отдельный подвид для читаемости
struct PlannerHomeView: View {
    @EnvironmentObject var viewModel: EggPlannerViewModel
    
    var body: some View {
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
                    
                    NavigationLink(destination: AddBatchView()) {
                        PlannerTile(icon: "plus.circle.fill", title: "Add Batch", color: Color(hex: "#F4B400"))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
            }
            .navigationTitle("Planner")
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

import SwiftUI

struct AddBatchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: EggPlannerViewModel
    @State private var dateCollected = Date()
    @State private var count = 1
    @State private var weight: String = ""
    @State private var selectedPlace: StoragePlace = .fridge
    @State private var shelfLifeDays = 28

    @State private var animateEgg = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Batch")
                .font(.title2)
                .fontWeight(.semibold)
            
            DatePicker("Collection Date", selection: $dateCollected, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)

            Stepper(value: $count, in: 1...1000) {
                Text("Number of eggs: \(count)")
            }
            .padding(.horizontal)
            
            TextField("Average weight (g)", text: $weight)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

            Picker("Storage Place", selection: $selectedPlace) {
                ForEach(StoragePlace.allCases) { place in
                    Text(place.rawValue).tag(place)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            Stepper(value: $shelfLifeDays, in: 7...60) {
                Text("Shelf life: \(shelfLifeDays) days")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: saveBatch) {
                Text("Save Batch")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#F4B400"))
                    .cornerRadius(20)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .background(Color(hex: "#FFF8E6").edgesIgnoringSafeArea(.all))
        .overlay(
            VStack {
                if animateEgg {
                    Image(systemName: "egg.fill")
                        .resizable()
                        .frame(width: 60, height: 80)
                        .foregroundColor(Color(hex: "#F4B400"))
                        .transition(.scale)
                        .animation(.easeOut(duration: 0.8))
                }
            }
        )
    }
    
    func saveBatch() {
        guard let weightValue = Double(weight) else { return }
        let newBatch = EggBatch(id: UUID(),
                                dateCollected: dateCollected,
                                count: count,
                                averageWeight: weightValue,
                                storagePlace: selectedPlace,
                                shelfLifeDays: shelfLifeDays)
        var currentBatches = StorageManager.shared.loadBatches()
        currentBatches.append(newBatch)
        StorageManager.shared.saveBatches(currentBatches)
        
        // Анимация появления яйца
        withAnimation {
            animateEgg = true
        }
        viewModel.load()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

import SwiftUI

struct StorageListView: View {
    @StateObject private var viewModel = StorageListViewModel()
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDescending

    var filteredBatches: [EggBatch] {
        viewModel.batches.filter { batch in
            searchText.isEmpty || batchMatchesSearch(batch)
        }.sorted(by: sortOption.sortClosure)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FFF8E6")
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    SearchBar(text: $searchText, placeholder: "Search by date or place")
                        .padding(.horizontal)

                    if filteredBatches.isEmpty {
                        Spacer()
                        Text("No Batch Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredBatches) { batch in
                                    NavigationLink(destination: BatchDetailView(batch: batch)) {
                                        HStack {
                                            Circle()
                                                .fill(batch.freshnessColor)
                                                .frame(width: 18, height: 18)
                                            VStack(alignment: .leading) {
                                                Text("\(batch.count) eggs")
                                                    .font(.headline)
                                                Text(batch.dateCollected.formattedDate() + ", " + batch.storagePlace.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Text("\(batch.daysLeft) days left")
                                                .font(.caption)
                                                .foregroundColor(batch.freshnessColor)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: .gray.opacity(0.1), radius: 3, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Storage")
            .onAppear {
                viewModel.loadBatches()
            }
        }
    }

    private func batchMatchesSearch(_ batch: EggBatch) -> Bool {
        let dateString = batch.dateCollected.formattedDate()
        let placeString = batch.storagePlace.rawValue.lowercased()
        let search = searchText.lowercased()
        return dateString.contains(search) || placeString.contains(search)
    }
}


class StorageListViewModel: ObservableObject {
    @Published var batches: [EggBatch] = []

    func loadBatches() {
        batches = StorageManager.shared.loadBatches()
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateDescending
    case dateAscending
    case countDescending
    case countAscending
    case freshnessDescending
    case freshnessAscending

    var id: String { rawValue }
    var title: String {
        switch self {
        case .dateDescending: return "Date ↓"
        case .dateAscending: return "Date ↑"
        case .countDescending: return "Count ↓"
        case .countAscending: return "Count ↑"
        case .freshnessDescending: return "Freshness ↓"
        case .freshnessAscending: return "Freshness ↑"
        }
    }

    var sortClosure: (EggBatch, EggBatch) -> Bool {
        switch self {
        case .dateDescending: return { $0.dateCollected > $1.dateCollected }
        case .dateAscending: return { $0.dateCollected < $1.dateCollected }
        case .countDescending: return { $0.count > $1.count }
        case .countAscending: return { $0.count < $1.count }
        case .freshnessDescending: return { $0.daysLeft > $1.daysLeft }
        case .freshnessAscending: return { $0.daysLeft < $1.daysLeft }
        }
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) { _text = text }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

import SwiftUI

struct BatchDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var batch: EggBatch
    @State private var usedCount = 0
    @State private var showDeleteAlert = false
    @EnvironmentObject var viewModel: EggPlannerViewModel

    var body: some View {
        ZStack {
            Color(hex: "#FFF8E6").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Batch Details")
                            .font(.title2)
                            .fontWeight(.semibold)

                        infoRow(title: "Collected on:", value: batch.dateCollected.formattedDate())
                        infoRow(title: "Storage:", value: batch.storagePlace.rawValue)
                        infoRow(title: "Total eggs:", value: "\(batch.count)")
                        infoRow(title: "Average weight:", value: batch.averageWeight != nil ? String(format: "%.1f g", batch.averageWeight!) : "N/A")
                        infoRow(title: "Days until expire:", value: "\(max(batch.daysLeft, 0))")

                        ProgressView(value: progressValue)
                            .accentColor(progressColor)
                            .scaleEffect(x: 1, y: 6, anchor: .center)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Stepper(value: $usedCount, in: 0...batch.count) {
                        Text("Mark used eggs: \(usedCount)")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button {
                            applyUsedEggs()
                            viewModel.load()
                        } label: {
                            Text("Save Changes")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#4CAF50"))
                                .cornerRadius(24)
                        }
                        .disabled(usedCount == 0)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Batch")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#E53935"))
                                .cornerRadius(24)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Batch"),
                message: Text("Are you sure you want to delete this batch?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteBatch()
                    viewModel.load()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            usedCount = 0
        }
    }

    private var progressValue: Double {
        Double(max(batch.daysLeft, 0)) / Double(batch.shelfLifeDays)
    }

    private var progressColor: Color {
        switch batch.daysLeft {
        case let x where x > 18: return .green
        case 10...18: return Color.orange
        default: return Color.red
        }
    }

    @ViewBuilder
    func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }

    private func applyUsedEggs() {
        guard usedCount > 0 else { return }
        var allBatches = StorageManager.shared.loadBatches()
        if let index = allBatches.firstIndex(where: { $0.id == batch.id }) {
            let newCount = max(allBatches[index].count - usedCount, 0)
            if newCount == 0 {
                allBatches.remove(at: index)
                presentationMode.wrappedValue.dismiss()
            } else {
                allBatches[index].count = newCount
                batch.count = newCount
                StorageManager.shared.saveBatches(allBatches)
            }
        }
    }

    private func deleteBatch() {
        var allBatches = StorageManager.shared.loadBatches()
        allBatches.removeAll(where: { $0.id == batch.id })
        StorageManager.shared.saveBatches(allBatches)
        presentationMode.wrappedValue.dismiss()
    }
}



import SwiftUI
import PDFKit

import SwiftUI
import UIKit

import SwiftUI
import UIKit

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



import SwiftUI

import SwiftUI

struct LineChartView: View {
    let data: [Double]
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                    .frame(height: 160)
                
                GeometryReader { geometry in
                    ZStack {
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            guard data.count > 1 else { return }
                            let maxData = data.max() ?? 1
                            let stepX = width / CGFloat(data.count - 1)
                            
                            path.move(to: CGPoint(x: 0, y: height - CGFloat(data[0] / maxData) * height))
                            
                            for i in 1..<data.count {
                                let x = CGFloat(i) * stepX
                                let y = height - CGFloat(data[i] / maxData) * height
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#F4B400"), Color(hex: "#F28C38")],
                                startPoint: .leading,
                                endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                   
                    }
                }
                .frame(height: 140)
                .padding(.horizontal)
            }
            .padding(.horizontal)
        }
    }
}

struct StorageBarChartView: View {
    let data: [StorageCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Storage Places")
                .font(.headline)
                .padding(.horizontal)
            ForEach(data) { item in
                VStack(spacing: 4) {
                    HStack {
                        Text(item.place.rawValue)
                            .bold()
                        Spacer()
                        Text("\(item.count)")
                            .bold()
                    }
                    
                    ProgressView(value: Float(item.count) / Float(data.map { $0.count }.max() ?? 1))
                        .accentColor(Color(hex: "#F28C38"))
                        .scaleEffect(x: 1, y: 8, anchor: .center)
                        .cornerRadius(8)
                        .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = { _, _, _, _ in
            dismiss()
        }

        // Для iPad установка sourceView для предотвращения крашей
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // UIActivityViewController не поддерживает обновление activityItems после создания
        // Для обновления требуется пересоздать контроллер, что SwiftUI сделает при смене binding
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
        // Возвращает массив сбора яиц по последним 30 дням
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
        // Среднее количество по 8 неделям
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

struct StorageCount: Identifiable {
    let id = UUID()
    let place: StoragePlace
    let count: Int
}

extension Int {
    var nonZero: Int { self == 0 ? 1 : self }
}

class PDFGenerator {
    static func generateReport(viewModel: AnalyticsViewModel) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Egg Planner",
            kCGPDFContextAuthor: "Egg Planner App"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2
        let pageHeight = 841.8
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            let text = "Egg Planner Report\n\n"
            let title = NSAttributedString(string: text, attributes: titleAttributes)
            title.draw(at: CGPoint(x: 72, y: 72))

            let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
            let bodyText = """
            Total eggs collected: \(viewModel.totalEggs)
            Average shelf life: \(String(format: "%.1f", viewModel.avgShelfLife)) days
            Average weight: \(String(format: "%.1f", viewModel.avgWeight)) g
            """
            let body = NSAttributedString(string: bodyText, attributes: bodyAttributes)
            body.draw(at: CGPoint(x: 72, y: 120))
        }
        return data
    }
}

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        ZStack {
            Color(hex: "#FFF8E6").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    DatePicker("Select week", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) { _ in
                            viewModel.loadData(for: selectedDate)
                        }
                        .padding()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.weekDates, id: \.self) { day in
                                VStack {
                                    Text(day.formattedWeekday())
                                        .font(.subheadline)
                                    Text(day.formattedDay())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(viewModel.colorForDate(day))
                                    Image(systemName: viewModel.iconForDate(day))
                                        .foregroundColor(viewModel.colorForDate(day))
                                        .font(.title)
                                        .opacity(viewModel.isCompletedDay(day) ? 1 : 0.3)
                                }
                                .frame(width: 60, height: 100)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.1), radius: 4, y: 2)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button("Add Collection") {
                        viewModel.addCollection(for: selectedDate)
                    }
                    .buttonStyle(YellowButtonStyle())
                    .padding()
                    
                    Spacer()
                }
                .onAppear {
                    viewModel.loadData(for: selectedDate)
                }
                .navigationTitle("Collection Calendar")
            }
        }
    }
}

class CalendarViewModel: ObservableObject {
    @Published var collections: [Date: Int] = [:]  // date -> eggs collected
    @Published var weekDates: [Date] = []
    @Published var weekCompleted = false

    private let calendar = Calendar.current

    func loadData(for date: Date) {
        generateWeekDates(containing: date)
        loadCollections()
        checkWeekCompletion()
    }

    private func generateWeekDates(containing date: Date) {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return }
        weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    private func loadCollections() {
        let allBatches = StorageManager.shared.loadBatches()
        collections = Dictionary(grouping: allBatches, by: { calendar.startOfDay(for: $0.dateCollected) })
            .mapValues { $0.reduce(0) { $0 + $1.count } }
    }

    func colorForDate(_ date: Date) -> Color {
        guard let count = collections[calendar.startOfDay(for: date)] else { return .gray }
        return count > 0 ? .green : .gray
    }

    func iconForDate(_ date: Date) -> String {
        guard let count = collections[calendar.startOfDay(for: date)] else { return "circle" }
        return count > 0 ? "checkmark.circle.fill" : "circle"
    }

    func isCompletedDay(_ date: Date) -> Bool {
        guard let count = collections[calendar.startOfDay(for: date)] else { return false }
        return count > 0
    }

    func summaryForDate(_ date: Date) -> Int? {
        collections[calendar.startOfDay(for: date)]
    }

    func addCollection(for date: Date) {
        // Добавляем фиктивный сбор (например, 5 яиц) для демонстрации
        let day = calendar.startOfDay(for: date)
        let newBatch = EggBatch(id: UUID(), dateCollected: day, count: 5, averageWeight: nil, storagePlace: .fridge, shelfLifeDays: 28)
        var allBatches = StorageManager.shared.loadBatches()
        allBatches.append(newBatch)
        StorageManager.shared.saveBatches(allBatches)
        loadCollections()
        checkWeekCompletion()
        objectWillChange.send()
    }

    private func checkWeekCompletion() {
        weekCompleted = weekDates.allSatisfy { isCompletedDay($0) }
    }
}

struct YellowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color(hex: "#F4B400"))
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

extension Date {
    func formattedWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    func formattedDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }
}

import SwiftUI
import UserNotifications

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
                                scheduleCollectReminder()
                            } else {
                                removeCollectReminder()
                            }
                        }

                    Toggle("Reminder: Check Shelf Life", isOn: $notifyCheckShelfLife)
                        .padding(.horizontal)
                        .onChange(of: notifyCheckShelfLife) { enabled in
                            if enabled {
                                scheduleShelfLifeReminder()
                            } else {
                                removeShelfLifeReminder()
                            }
                        }
                }

//                VStack(alignment: .leading, spacing: 12) {
//                    Text("Appearance")
//                        .font(.title2)
//                        .bold()
//                        .padding(.horizontal)
//
//                    Text("Coming soon...")
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
//                }

                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("Settings")
        .onAppear {
            requestNotificationAuthorization()
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleCollectReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Collect Eggs"
        content.body = "It's time to collect your eggs today!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "collectEggsReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func removeCollectReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["collectEggsReminder"])
    }

    private func scheduleShelfLifeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Check Egg Shelf Life"
        content.body = "Check if any egg batches are close to expiring."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 18

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "checkShelfLifeReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func removeShelfLifeReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["checkShelfLifeReminder"])
    }
}



import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    MainPlannerView()
        .environmentObject(EggPlannerViewModel())
}

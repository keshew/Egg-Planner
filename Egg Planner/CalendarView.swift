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
    @Published var collections: [Date: Int] = [:]
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

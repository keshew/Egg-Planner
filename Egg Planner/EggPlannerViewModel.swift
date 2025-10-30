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

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

struct StorageCount: Identifiable {
    let id = UUID()
    let place: StoragePlace
    let count: Int
}

extension Int {
    var nonZero: Int { self == 0 ? 1 : self }
}

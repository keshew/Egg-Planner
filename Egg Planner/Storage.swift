import SwiftUI

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

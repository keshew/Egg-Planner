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

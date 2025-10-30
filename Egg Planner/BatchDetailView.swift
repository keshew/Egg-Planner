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

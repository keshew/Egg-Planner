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
        
        withAnimation {
            animateEgg = true
        }
        viewModel.load()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

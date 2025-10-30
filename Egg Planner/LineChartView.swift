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

import SwiftUI
import Charts

struct GraphBox: View {
    @Binding var currentIndex: Int
    @State private var selectedTimeFrame: String = "1 Day" // Estado para la selección de tiempo
    
    // Datos de ejemplo para cada rango de tiempo
    let dayData = [20, 40, 30, 50, 60, 70, 55]
    let monthData = [100, 80, 120, 110, 150, 140, 180]
    let yearData = [200, 300, 250, 400, 380, 500, 450]
    let maxData = [500, 600, 550, 700, 750, 800, 850]

    let views = [
        Color.white,
        Color.white
    ]
    
    let timeFrames = ["1 Day", "1 Month", "1 Year", "Max"] // Opciones de tiempo

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack(spacing: 10) {
                    ForEach(0..<views.count, id: \.self) { index in
                        VStack {
                            // Mostrar la gráfica correspondiente al rango de tiempo seleccionado
                            if selectedTimeFrame == "1 Day" {
                                chartView(data: dayData)
                            } else if selectedTimeFrame == "1 Month" {
                                chartView(data: monthData)
                            } else if selectedTimeFrame == "1 Year" {
                                chartView(data: yearData)
                            } else if selectedTimeFrame == "Max" {
                                chartView(data: maxData)
                            }
                        }
                        .cornerRadius(14)
                        .frame(width: 361, height: 264)
                        .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, (geometry.size.width - 361) / 2)
                .offset(x: -CGFloat(currentIndex) * (361 + 10))
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let dragThreshold: CGFloat = 50
                            withAnimation(.easeInOut) {
                                if value.translation.width < -dragThreshold {
                                    currentIndex = min(currentIndex + 1, views.count - 1)
                                } else if value.translation.width > dragThreshold {
                                    currentIndex = max(currentIndex - 1, 0)
                                }
                            }
                        }
                )
            }
            
            // Barra inferior para seleccionar el tiempo
            HStack(spacing: 20) {
                ForEach(timeFrames, id: \.self) { frame in
                    Button(action: {
                        withAnimation {
                            selectedTimeFrame = frame
                        }
                    }) {
                        Text(frame)
                            .fontWeight(selectedTimeFrame == frame ? .bold : .regular)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(selectedTimeFrame == frame ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(20)
                            .foregroundColor(selectedTimeFrame == frame ? .blue : .gray)
                            .font(.system(size: 12))
                    }
                }
            }
            .frame(width: 361, height: 48) // Ajusta las dimensiones de la barra
            .background(Color.gray.opacity(0.1)) // Fondo gris claro
            .cornerRadius(14)
        }
    }
    
    // Función que retorna una vista de la gráfica con LineMark y AreaMark
    @ViewBuilder
    func chartView(data: [Int]) -> some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                // Gráfico de área
                AreaMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.blue.opacity(0.2)) // Estilo del área
                
                // Gráfico de línea
                LineMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.blue) // Estilo de la línea
                .lineStyle(StrokeStyle(lineWidth: 2)) // Estilo de la línea
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 350, height: 160) // Ajustar el tamaño de la gráfica
    }
}

#Preview {
    GraphBox(currentIndex: .constant(0))
}

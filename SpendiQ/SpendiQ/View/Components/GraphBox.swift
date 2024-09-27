import SwiftUI

struct GraphBox: View {
    @Binding var currentIndex: Int
    
    // Vistas alternativas para el cuadro (puedes personalizarlas más adelante)
    let views = [
        Color.white,
        Color.white,
        Color.white,
        Color.white
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 10) {
                ForEach(0..<views.count, id: \.self) { index in
                    views[index]
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
                                // Swipe hacia la derecha, mostrar cuadro anterior
                                currentIndex = max(currentIndex - 1, 0)
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    GraphBox(currentIndex: .constant(0))
}

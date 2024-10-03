import SwiftUI

struct DayResumeTitle: View {
    @State var Expenses: Int = 0
    @State var Incomes: Int = 0
    @State var Day: String = "Sep 13, 2024"
    var body: some View {
        Divider()
            .padding(.leading,16)
            .padding(.trailing,16)
        HStack{
            Text("\(Day)")
                .padding(.leading,16)
                .font(.system(size: 18))
            Spacer()
            Text("$ \(Expenses)")
                .foregroundStyle(.red)
                .font(.system(size: 18))
                .fontWeight(.semibold)
            
            Text("$ \(Incomes)")
                .padding(.trailing,16)
                .font(.system(size: 18))
                .foregroundStyle(.primarySpendiq)
                .fontWeight(.semibold)
        }

        Divider()
            .padding(.leading,16)
            .padding(.trailing,16)
    }
}

#Preview {
    DayResumeTitle()
}

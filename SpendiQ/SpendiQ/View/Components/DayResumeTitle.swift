//
//  DayResume.swift
//  SpendiQ
//
//  Created by Juan Salguero on 27/09/24.
//

import SwiftUI

struct DayResumeTitle: View {
    @State var Expenses: Int =  0
    @State var Incomes: Int =  0
    @State var Day: String = "Sep 13, 2024"
    var body: some View {
        Divider()
            .frame(width: 361)
        HStack{
            Text("\(Day)")
                .padding(.leading,16)
            Spacer()
            Text("$ \(Expenses)")
            Text("$ \(Incomes)")
                .padding(.trailing,16)
        }
            
        Divider()
            .frame(width: 361)
    }
}

#Preview {
    DayResumeTitle()
}
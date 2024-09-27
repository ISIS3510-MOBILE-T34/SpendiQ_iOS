//
//  Movement.swift
//  SpendiQ
//
//  Created by Juan Salguero on 27/09/24.
//

import SwiftUI

struct MovementResume: View {
    var MovementName : String
    var AccountName : String
    var MovementTime : String
    var MovementAmount : Int
    var MovementEmoji : String
    
    var body: some View {
        HStack (spacing: 4 ){
            ZStack{
                Circle()
                    .frame(width:48, height:48)
                    .foregroundStyle(.yellow)
                Text("\(MovementEmoji)")
                    .font(.largeTitle)
            }
            .padding(.leading,16)
            
            VStack (alignment:.leading, spacing: 4){
                Text("\(MovementName)")
                    .fontWeight(.regular)
                
                HStack{
                    Text("\(AccountName)")
                        .fontWeight(.light)
                        .font(.system(size:14))
                    
                    Divider()
                        .frame(height:14)
                    
                    Text("\(MovementTime)")
                        .fontWeight(.light)
                        .font(.system(size:14))
                }
                
            }
            .frame(alignment:.leading)

            
            Spacer()
            
            Text("$ \(MovementAmount)")
                .fontWeight(.medium)
                .font(.system(size:16))
                .padding(.trailing, 16)
        }
    }
}

#Preview {
    MovementResume(MovementName: "Juan Valdez cafe", AccountName: "Bancolombia", MovementTime: "13:53 PM", MovementAmount: 10000, MovementEmoji: "☕️")
}

//
//  ActionCardView.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 08/09/25.
//
import SwiftUI

let green1 = Color(red: 88/255, green: 129/255, blue: 87/255)
let brown1 = Color(red: 127/255, green: 85/255, blue: 57/255)
let green2 = Color(red: 106/255, green: 153/255, blue: 78/255)
let brown2 = Color(red: 166/255, green: 138/255, blue: 100/255)

struct ActionCardView: View {
    var color: Color
    var systemImage: String
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: color.opacity(0.3), radius: 6, y: 4)
    }
}

#Preview {
    HomeView()
}


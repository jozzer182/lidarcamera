//
//  ToastView.swift
//  lidarcamera
//
//  Created by JOSE ZARABANDA on 12/23/25.
//

import SwiftUI

/// Lightweight toast view for displaying messages with Liquid Glass
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .capsule)
    }
}

#Preview {
    ZStack {
        Color.gray
        ToastView(message: "Photo saved!")
    }
}

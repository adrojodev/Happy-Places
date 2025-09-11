//
//  HappyInput.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/09/25.
//
import SwiftUI

struct HappyInput: View {
    let placeholder: String
    let textArea: Bool
    
    @Binding var text: String
    
    var body: some View {
        Group {
            if textArea {
                TextField("",
                          text: $text,
                          prompt: Text(placeholder).foregroundColor(.accentBright.opacity(0.5)),
                          axis: .vertical,)
                .lineLimit(3...5)
            } else {
                TextField("",
                          text: $text,
                          prompt: Text(placeholder).foregroundColor(.accentBright.opacity(0.5)))
            }
        }
        .padding()
        .background(.materialBlack)
        .frame(width: 321.0)
        .foregroundStyle(.accentBright)
        .font(.system(.body, design: .monospaced))
        .monospacedDigit()
        .cornerRadius(8.0)
    }
}

#Preview {
    HappyInput(placeholder: "Name", textArea: true, text: .constant("Happy"))
}

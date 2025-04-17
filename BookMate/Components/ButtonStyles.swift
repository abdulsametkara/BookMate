import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(isDisabled ? Color.gray.opacity(0.3) : backgroundColor.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(isDisabled ? Color.gray : foregroundColor)
            .cornerRadius(10)
            .shadow(color: backgroundColor.opacity(0.3), radius: 5, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var borderColor: Color = .blue
    var foregroundColor: Color = .blue
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .foregroundColor(isDisabled ? Color.gray : foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDisabled ? Color.gray.opacity(0.3) : borderColor, lineWidth: 2)
            )
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    var size: CGFloat = 50
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20))
            .frame(width: size, height: size)
            .background(isDisabled ? Color.gray.opacity(0.3) : backgroundColor.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(isDisabled ? Color.gray : foregroundColor)
            .cornerRadius(size / 2)
            .shadow(color: backgroundColor.opacity(0.3), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 
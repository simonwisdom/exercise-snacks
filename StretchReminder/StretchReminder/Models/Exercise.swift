import Foundation
import SwiftUI

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let duration: Int
    let category: ExerciseCategory
    let symbolName: String
    let animationType: ExerciseAnimationType
    
    init(name: String, description: String, duration: Int, category: ExerciseCategory, symbolName: String, animationType: ExerciseAnimationType) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.duration = duration
        self.category = category
        self.symbolName = symbolName
        self.animationType = animationType
    }
    
    enum ExerciseCategory: String, CaseIterable, Codable {
        case neck = "Neck"
        case shoulders = "Shoulders"
        case back = "Back"
        case arms = "Arms"
        case wrists = "Wrists"
        case legs = "Legs"
        
        var color: Color {
            switch self {
            case .neck: return .blue
            case .shoulders: return .green
            case .back: return .purple
            case .arms: return .orange
            case .wrists: return .red
            case .legs: return .teal
            }
        }
        
        var gradient: LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.3), color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    enum ExerciseAnimationType: String, CaseIterable, Codable {
        case pulse = "pulse"           // For static positions (breathing effect)
        case rotation = "rotation"     // For rotation movements (neck turns)
        case bounce = "bounce"         // For repetitive movements (shoulder rolls)
        case slide = "slide"           // For stretching motions
        case wave = "wave"             // For wave-like movements
        case none = "none"             // For static display
    }
}
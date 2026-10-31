import SwiftUI

struct AnimatedExerciseIcon: View {
    let exercise: Exercise
    @State private var animationValue: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Background circle with category color
            Circle()
                .fill(exercise.category.gradient)
                .frame(width: 120, height: 120)
            
            // Main icon
            Image(systemName: exercise.symbolName)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(exercise.category.color)
                .modifier(AnimationModifier(
                    animationType: exercise.animationType,
                    animationValue: animationValue
                ))
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .accessibilityLabel("\(exercise.category.rawValue) exercise: \(exercise.name)")
        .accessibilityHint("Animated demonstration of the exercise movement")
    }
    
    private func startAnimation() {
        switch exercise.animationType {
        case .pulse:
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.0)) {
                    animationValue = animationValue == 0 ? 1 : 0
                }
            }
        case .rotation:
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                withAnimation(.linear(duration: 0.05)) {
                    animationValue += 1
                }
            }
        case .bounce:
            timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                withAnimation(.bouncy(duration: 0.6)) {
                    animationValue = animationValue == 0 ? 1 : 0
                }
            }
        case .slide:
            timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.5)) {
                    animationValue = animationValue == 0 ? 1 : 0
                }
            }
        case .wave:
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.8)) {
                    animationValue += 0.1
                }
            }
        case .none:
            // No animation
            break
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

struct AnimationModifier: ViewModifier {
    let animationType: Exercise.ExerciseAnimationType
    let animationValue: Double
    
    func body(content: Content) -> some View {
        switch animationType {
        case .pulse:
            content
                .scaleEffect(1.0 + (animationValue * 0.2))
                .opacity(0.7 + (animationValue * 0.3))
        case .rotation:
            content
                .rotationEffect(.degrees(animationValue * 10))
        case .bounce:
            content
                .offset(y: -animationValue * 10)
        case .slide:
            content
                .offset(x: (animationValue - 0.5) * 20)
        case .wave:
            content
                .offset(y: sin(animationValue * 4) * 5)
                .scaleEffect(1.0 + sin(animationValue * 3) * 0.1)
        case .none:
            content
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        AnimatedExerciseIcon(exercise: Exercise(
            name: "Neck Side Stretch",
            description: "Test exercise",
            duration: 30,
            category: .neck,
            symbolName: "arrow.left.and.right",
            animationType: .slide
        ))
        
        AnimatedExerciseIcon(exercise: Exercise(
            name: "Shoulder Rolls",
            description: "Test exercise",
            duration: 20,
            category: .shoulders,
            symbolName: "arrow.clockwise",
            animationType: .rotation
        ))
        
        AnimatedExerciseIcon(exercise: Exercise(
            name: "Calf Raises",
            description: "Test exercise",
            duration: 20,
            category: .legs,
            symbolName: "arrow.up.bounce",
            animationType: .bounce
        ))
    }
    .padding()
}
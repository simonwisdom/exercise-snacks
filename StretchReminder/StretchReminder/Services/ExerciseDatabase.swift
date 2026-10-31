import Foundation

class ExerciseDatabase: ObservableObject {
    static let shared = ExerciseDatabase()
    
    private let exercises: [Exercise] = [
        // Neck Exercises
        Exercise(
            name: "Neck Side Stretch",
            description: "Gently tilt your head to one side, bringing your ear toward your shoulder. Hold for 15 seconds, then repeat on the other side.",
            duration: 30,
            category: .neck,
            symbolName: "arrow.left.and.right",
            animationType: .slide
        ),
        Exercise(
            name: "Neck Forward Stretch",
            description: "Slowly lower your chin toward your chest, feeling the stretch in the back of your neck. Hold for 15 seconds.",
            duration: 15,
            category: .neck,
            symbolName: "arrow.down",
            animationType: .pulse
        ),
        Exercise(
            name: "Neck Rotation",
            description: "Slowly roll your head in a circular motion. Do 5 rotations clockwise, then 5 counter-clockwise.",
            duration: 20,
            category: .neck,
            symbolName: "arrow.clockwise.circle",
            animationType: .rotation
        ),
        
        // Shoulder Exercises
        Exercise(
            name: "Shoulder Rolls",
            description: "Roll your shoulders backward in a circular motion 10 times, then forward 10 times.",
            duration: 20,
            category: .shoulders,
            symbolName: "arrow.clockwise",
            animationType: .rotation
        ),
        Exercise(
            name: "Cross-Body Shoulder Stretch",
            description: "Bring one arm across your body and gently pull it closer with your other hand. Hold for 15 seconds each arm.",
            duration: 30,
            category: .shoulders,
            symbolName: "arrow.left.and.right.square",
            animationType: .slide
        ),
        Exercise(
            name: "Overhead Shoulder Stretch",
            description: "Raise both arms overhead and clasp your hands together. Stretch upward and slightly back.",
            duration: 20,
            category: .shoulders,
            symbolName: "arrow.up.circle",
            animationType: .pulse
        ),
        
        // Back Exercises
        Exercise(
            name: "Seated Spinal Twist",
            description: "While seated, place one hand on the back of your chair and gently twist your torso. Hold for 15 seconds each side.",
            duration: 30,
            category: .back,
            symbolName: "arrow.triangle.2.circlepath",
            animationType: .rotation
        ),
        Exercise(
            name: "Upper Back Stretch",
            description: "Clasp your hands in front of you and round your upper back, pushing your hands away from your body.",
            duration: 20,
            category: .back,
            symbolName: "arrow.forward",
            animationType: .pulse
        ),
        Exercise(
            name: "Cat-Cow Stretch (Seated)",
            description: "Arch your back and look up (cow), then round your back and tuck your chin (cat). Repeat 5 times.",
            duration: 25,
            category: .back,
            symbolName: "arrow.up.and.down",
            animationType: .wave
        ),
        
        // Arm Exercises
        Exercise(
            name: "Tricep Stretch",
            description: "Raise one arm overhead, bend at the elbow, and gently pull your elbow with the other hand. Hold for 15 seconds each arm.",
            duration: 30,
            category: .arms,
            symbolName: "arrow.down.to.line.compact",
            animationType: .pulse
        ),
        Exercise(
            name: "Arm Circles",
            description: "Extend your arms to the sides and make small circles. Do 10 forward, then 10 backward.",
            duration: 20,
            category: .arms,
            symbolName: "arrow.clockwise.circle.fill",
            animationType: .rotation
        ),
        
        // Wrist Exercises
        Exercise(
            name: "Wrist Flexor Stretch",
            description: "Extend your arm with palm up, gently pull your fingers back with your other hand. Hold for 15 seconds each arm.",
            duration: 30,
            category: .wrists,
            symbolName: "hand.point.up",
            animationType: .pulse
        ),
        Exercise(
            name: "Wrist Circles",
            description: "Make circular motions with your wrists. Do 10 circles in each direction.",
            duration: 20,
            category: .wrists,
            symbolName: "hand.wave.fill",
            animationType: .rotation
        ),
        Exercise(
            name: "Prayer Stretch",
            description: "Press your palms together in front of your chest, then lower your hands while keeping palms together.",
            duration: 15,
            category: .wrists,
            symbolName: "hands.clap",
            animationType: .slide
        ),
        
        // Leg Exercises
        Exercise(
            name: "Calf Raises",
            description: "While standing or seated, lift your heels and rise up on your toes. Hold for 2 seconds, repeat 10 times.",
            duration: 20,
            category: .legs,
            symbolName: "arrow.up.bounce",
            animationType: .bounce
        ),
        Exercise(
            name: "Ankle Circles",
            description: "Lift one foot slightly and rotate your ankle in circles. Do 10 in each direction, then switch feet.",
            duration: 25,
            category: .legs,
            symbolName: "circle.dotted",
            animationType: .rotation
        ),
        Exercise(
            name: "Seated Hip Flexor Stretch",
            description: "While seated, bring one ankle to rest on the opposite knee. Gently lean forward for a hip stretch.",
            duration: 30,
            category: .legs,
            symbolName: "figure.flexibility",
            animationType: .pulse
        )
    ]
    
    private init() {}
    
    func getRandomExercise() -> Exercise {
        return exercises.randomElement() ?? exercises[0]
    }
    
    func getExercises(for category: Exercise.ExerciseCategory) -> [Exercise] {
        return exercises.filter { $0.category == category }
    }
    
    func getAllExercises() -> [Exercise] {
        return exercises
    }
}
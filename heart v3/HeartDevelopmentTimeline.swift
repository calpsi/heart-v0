import Foundation

/// Only intervals backed by deforming geometry accept intermediate positions.
/// Other intervals remain honest stage stops until compatible meshes are ready.
enum HeartDevelopmentTimeline {
    static func position(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        let clamped = min(7, max(0, value))
        return ((1...3).contains(clamped) || (5...6).contains(clamped)) ? clamped : clamped.rounded()
    }
    static func stage(_ position: Double) -> Int {
        min(7, max(0, Int(self.position(position).rounded())))
    }
    static func loopingProgress(_ position: Double) -> Double {
        min(1, max(0, position - 2))
    }
    /// From inside a transition, visit its endpoint before leaving that process.
    static func adjacentStage(from value: Double, forward: Bool) -> Double {
        let current = position(value)
        return min(7, max(0, forward ? floor(current) + 1 : ceil(current) - 1))
    }
}

/// Existing educational anchors; overlapping biological processes are not
/// converted into artificially exclusive date ranges for interface neatness.
struct HeartDevelopmentStage: Identifiable {
    let id: Int
    let day: String
    let name: String
    static let all: [Self] = [
        .init(id: 0, day: "Day 18", name: "Cardiogenic field"),
        .init(id: 1, day: "Day 21", name: "Paired heart tubes"),
        .init(id: 2, day: "Day 22", name: "Primitive heart tube"),
        .init(id: 3, day: "Days 23–28", name: "Cardiac looping"),
        .init(id: 4, day: "Day 28", name: "Septation begins"),
        .init(id: 5, day: "Day 35", name: "Developing septa"),
        .init(id: 6, day: "Day 50", name: "Outflow and valves"),
        .init(id: 7, day: "Birth", name: "Circulatory transition")
    ]
}

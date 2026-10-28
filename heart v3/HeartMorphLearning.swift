import Foundation

/// Questions refer to changes visible in the illustration, not diagnostic claims.
enum HeartMorphLearning {
    enum Process: String { case joining, looping, outflow }
    /// Describe the geometry at the current scrub position, not a calendar date
    /// or an anomaly's cause. Shared by guided and free exploration.
    static func observation(_ process: Process, progress: Double) -> String {
        let progress = progress.isFinite ? min(1, max(0, progress)) : 0
        switch (process, progress) {
        case (.joining, ..<0.15):
            return "Two channels · follow their inner borders as you move forward."
        case (.joining, ..<0.85):
            return "Joining · look for the shared space between the approaching channels."
        case (.joining, _):
            return "One channel · scrub backwards to compare with the paired starting shape."
        case (.looping, ..<0.15):
            return "Straight tube · choose one region to follow through the bend."
        case (.looping, ..<0.85):
            return "Changing position · follow your chosen region while the wall stays connected."
        case (.looping, _):
            return "Looped tube · rotate to compare the regions’ new positions."
        case (.outflow, ..<0.15):
            return "Shared channel · open the wall and locate the two opposing cushions."
        case (.outflow, ..<0.85):
            return "Partition forming · follow the remaining space on either side."
        case (.outflow, _):
            return "Two routes · trace both sides of the partition, then compare outlet connections."
        }
    }
    struct Check {
        let question: String
        let options: [String]
        let answer: Int
        let explanation: String
        let observation: String
    }
    static func check(_ process: Process) -> Check {
        switch process {
        case .joining:
            Check(question: "As the paired channels join, what should you look for?",
                  options: ["A shared channel forming", "Two channels remaining separate", "The channel disappearing"], answer: 0,
                  explanation: "In this illustration, the approaching channels become one continuous channel. The animation simplifies joining; it does not show body folding or cellular remodelling.",
                  observation: "Scrub backwards to separate the channels, then forwards to find where a shared channel appears.")
        case .outflow:
            Check(question: "As the opposing cushions meet, what changes inside the outflow channel?",
                  options: ["A partition separates two routes", "The whole channel closes", "The ventricles switch places"], answer: 0,
                  explanation: "The illustration shows an internal partition forming while routes remain on either side. Division and correct connection to the ventricles are related but distinct developmental tasks.",
                  observation: "Open the wall and scrub backwards. Find the shared space before the partition forms, then follow the two routes forwards.")
        case .looping:
            Check(question: "As the tube bends, what happens to its continuity?",
                  options: ["The tube breaks into separate chambers", "The wall stays connected while its shape changes", "Bending creates the mature septa"], answer: 1,
                  explanation: "The same wall stays connected as its regions change position. This bending illustration does not show the later formation of chamber partitions.",
                  observation: "Follow one end of the tube while scrubbing in both directions. Describe a change in shape separately from a change in connections.")
        }
    }

    static func explanationCheck(_ process: Process) -> Check {
        switch process {
        case .joining:
            Check(question: "Which observation supports the change from paired tubes to a shared channel?",
                  options: ["The regions have different colours", "The two lumens connect as the tubes meet", "The inspection layers spread apart"], answer: 1,
                  explanation: "Look for a change in the channel's continuity. Colour and layer separation are teaching tools; they do not demonstrate fusion.",
                  observation: "Scrub backwards and distinguish the two channels from the three inspection layers.")
        case .looping:
            Check(question: "What does separating the layers let you investigate during bending?",
                  options: ["Whether each layer follows the same changing tube shape", "How the layers detach during normal development", "Where mature chamber partitions appear"], answer: 0,
                  explanation: "The separated shells let you follow the wall components through the same bend. Their separation is an inspection arrangement, and this model does not form mature chamber partitions.",
                  observation: "Compare the layers, then reassemble them and follow the continuous lumen.")
        case .outflow:
            Check(question: "What can this division animation tell you about the outlets?",
                  options: ["It proves that both arteries connect to the correct ventricles", "It demonstrates the cause of every outlet anomaly", "It shows partitioning, while ventricular connections need another view"], answer: 2,
                  explanation: "The illustration shows division inside a channel. To judge its connections, inspect the later anatomy and trace each outlet to its ventricle.",
                  observation: "Use the developmental branch to compare internal division with outlet connections.")
        }
    }

    struct Practice {
        enum Phase { case predict, observe, explain, feedback }
        let process: Process
        private(set) var phase = Phase.predict
        private(set) var prediction: Int?
        private(set) var explanation: Int?
        private(set) var skipped = false
        private var lowest = 0.0
        private var highest = 0.0

        mutating func predict(_ index: Int, at progress: Double) {
            guard phase == .predict, HeartMorphLearning.check(process).options.indices.contains(index), progress.isFinite else { return }
            prediction = index; lowest = min(1, max(0, progress)); highest = lowest; phase = .observe
        }
        mutating func observe(_ progress: Double) {
            guard phase == .observe, progress.isFinite else { return }
            let position = min(1, max(0, progress))
            lowest = min(lowest, position); highest = max(highest, position)
            // Comparing positions is an interaction prerequisite, not evidence
            // of attention, comprehension or mastery. Jitter cannot accumulate.
            if highest - lowest >= 0.15 { phase = .explain }
        }
        mutating func explain(_ index: Int) {
            guard phase == .explain, HeartMorphLearning.explanationCheck(process).options.indices.contains(index) else { return }
            explanation = index; phase = .feedback
        }
        mutating func reveal() { skipped = true; phase = .feedback }
        mutating func restart() { self = .init(process: process) }
    }
}

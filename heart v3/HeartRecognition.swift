import Foundation

/// Evidence of an interaction, never a diagnosis of mastery or clinical competence.
struct HeartRecognitionAttempt: Codable, Equatable {
    var id = UUID()
    var selection = ""
    var submittedSelection = ""
    var previouslyStudied = false
    var hintUsed = false
    var revealed = false
    var responses = 0
    var correct = false
    var confidence = "Unsure"
    var finished: Bool { correct || revealed }

    mutating func commit() {
        guard !finished, !selection.isEmpty else { return }
        submittedSelection = selection
        responses += 1
        correct = selection == "AorticIsthmus_Coarctation_Anterior"
            || selection == "AorticIsthmus_Coarctation_Posterior"
    }
    var outcome: String {
        if revealed { return "Revealed" }
        if correct && previouslyStudied && !hintUsed { return "Correct during review" }
        if correct { return hintUsed ? "Correct with hint" : responses == 1 ? "Correct without hint" : "Correct after retry" }
        return "Attempted"
    }
    var feedback: String {
        guard responses > 0 else { return "" }
        if correct { return "You located the narrowed channel. Compare it with the open lumen next." }
        if submittedSelection.hasPrefix("LeftSubclavian") {
            return "You selected a branch. Trace the main arch and compare its channel along its course, then try again."
        }
        if submittedSelection == "Ligamentum" {
            return "You selected the connecting remnant. Inspect the channel inside the aorta itself, then try again."
        }
        return "Compare the width of the channel along the arch. Look for a local change rather than the width of the outer wall."
    }
}

struct HeartRecognitionRecord: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    let attempt: HeartRecognitionAttempt
    let practice: Bool
}

/// Local practice scheduling, separate from lesson visits and mastery claims.
struct HeartRecognitionReview {
    let sessions: [HeartRecognitionRecord]
    let intervalDays: Int

    init(records: [HeartRecognitionRecord], intervalDays: Int = 3) {
        // Commits/hints can save multiple events in one session. Keep its latest evidence.
        var latest: [UUID: HeartRecognitionRecord] = [:]
        for record in records.sorted(by: { $0.date < $1.date }) { latest[record.attempt.id] = record }
        sessions = latest.values.sorted { $0.date < $1.date }
        self.intervalDays = min(14, max(1, intervalDays))
    }
    var nextReview: Date? {
        guard let last = sessions.last else { return nil }
        let unaided = last.attempt.correct && !last.attempt.hintUsed && !last.attempt.revealed
            && last.attempt.responses == 1 && last.attempt.confidence == "Very sure"
        return last.date.addingTimeInterval(Double(unaided ? intervalDays : 1) * 86_400)
    }
    func isDue(at now: Date) -> Bool { nextReview.map { $0 <= now } ?? false }
    var laterRecallCount: Int {
        sessions.enumerated().filter { index, record in
            guard index > 0 else { return false }
            return record.date.timeIntervalSince(sessions[index - 1].date) >= 86_400
                && record.attempt.correct && record.attempt.responses == 1
                && !record.attempt.hintUsed && !record.attempt.revealed
        }.count
    }
}

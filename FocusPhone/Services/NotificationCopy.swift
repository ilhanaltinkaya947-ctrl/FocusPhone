import Foundation

// MARK: - Notification Types

enum NotificationType {
    case preReminder30
    case preReminder10
    case verificationPrompt
    case noVerificationFollowup
    case streakMilestone(Int)
    case streakAtRisk
}

// MARK: - Notification Copy Engine

enum NotificationCopy {

    static func message(for category: CommitmentCategory, type: NotificationType, title: String) -> String {
        switch (category, type) {

        // GYM
        case (.gym, .preReminder30):           return "GYM IN 30. NO EXCUSES. 😈💪"
        case (.gym, .preReminder10):           return "10 MINUTES. GET CHANGED NOW. 🔥"
        case (.gym, .verificationPrompt):      return "You at the gym? Prove it. 😈📸"
        case (.gym, .noVerificationFollowup):  return "Skipping? Really? 😒"
        case (.gym, .streakMilestone(let d)):   return "\(d) days of iron. RawDog respects it. 💪🐕"
        case (.gym, .streakAtRisk):            return "Don't you dare break this streak. 😤"

        // STUDY
        case (.study, .preReminder30):           return "STUDY SESSION IN 30. CLEAR YOUR DESK. 📚🧠"
        case (.study, .preReminder10):           return "10 MIN. CLOSE EVERYTHING ELSE. 📖"
        case (.study, .verificationPrompt):      return "Are you studying? Show the books. 📸🧠"
        case (.study, .noVerificationFollowup):  return "Brain's not gonna train itself. 📚"
        case (.study, .streakMilestone(let d)):   return "\(d) days of learning. Big brain energy. 🧠✨"
        case (.study, .streakAtRisk):            return "Don't let the streak die tonight. 📚"

        // WORK
        case (.work, .preReminder30):           return "DEEP WORK IN 30. CLOSE THE TABS. 💻⚡"
        case (.work, .preReminder10):           return "10 MIN. PUT THE PHONE DOWN. 🖥️"
        case (.work, .verificationPrompt):      return "In work mode? Show the setup. 💻📸"
        case (.work, .noVerificationFollowup):  return "The work doesn't do itself. 💼"
        case (.work, .streakMilestone(let d)):   return "\(d) days of building. Stack it up. ⚡🐕"
        case (.work, .streakAtRisk):            return "Ship or skip. Don't skip. 💻"

        // OUTDOOR
        case (.outdoor, .preReminder30):           return "GET OUTSIDE IN 30. TOUCH GRASS. 🌿🌤️"
        case (.outdoor, .preReminder10):           return "SHOES ON. 10 MINUTES. 🌿"
        case (.outdoor, .verificationPrompt):      return "Outside? Show the sky. 🌤️📸"
        case (.outdoor, .noVerificationFollowup):  return "The outside is still out there. 🌿"
        case (.outdoor, .streakMilestone(let d)):   return "\(d) days outside. Real ones go outside. 🌤️🐕"
        case (.outdoor, .streakAtRisk):            return "One walk. That's all. Go. 🌿"

        // MEDITATION
        case (.meditation, .preReminder30):           return "MEDITATION IN 30. START WINDING DOWN. 🧘‍♂️"
        case (.meditation, .preReminder10):           return "10 MIN. FIND YOUR SPOT. 🕯️"
        case (.meditation, .verificationPrompt):      return "Did you sit? Show your space. 🧘📸"
        case (.meditation, .noVerificationFollowup):  return "5 minutes is better than zero. 🧘"
        case (.meditation, .streakMilestone(let d)):   return "\(d) days of stillness. That's rare. 🕯️🐕"
        case (.meditation, .streakAtRisk):            return "Your mind needs this today. 🧘"

        // CUSTOM (fallback — uses commitment title)
        case (.custom, .preReminder30):           return "\(title.uppercased()) IN 30. TIME TO MOVE. 🎯"
        case (.custom, .preReminder10):           return "10 MIN UNTIL \(title.uppercased()). LET'S GO. 🔥"
        case (.custom, .verificationPrompt):      return "Doing \(title)? Show RawDog. 📸🐕"
        case (.custom, .noVerificationFollowup):  return "\(title) won't complete itself. 🐕"
        case (.custom, .streakMilestone(let d)):   return "\(d) days of \(title). Don't stop. 🔥"
        case (.custom, .streakAtRisk):            return "Keep the \(title) streak alive. 🎯"
        }
    }

    // MARK: - Daily Summary (9pm)

    static func dailySummary(done: Int, total: Int, streak: Int) -> String {
        if done == total && total > 0 {
            return "Clean sweep today. \(streak) days. 😤🔥"
        } else if done > 0 {
            return "\(done)/\(total) today. Take the W, finish tomorrow. 💪"
        } else {
            return "Zero today. RawDog noticed. Tomorrow counts. 🐕"
        }
    }
}

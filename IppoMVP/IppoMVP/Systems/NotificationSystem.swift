import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationSystem: ObservableObject {
    static let shared = NotificationSystem()

    private init() {}

    // MARK: - Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule Daily Care Notification
    func scheduleDailyCareNotification(petName: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_care"])

        let userData = UserData.shared
        guard let pet = userData.equippedPet else { return }

        let calendar = Calendar.current
        let alreadyFedToday = pet.lastFedDate.map { calendar.isDateInToday($0) } ?? false
        let alreadyWateredToday = pet.lastWateredDate.map { calendar.isDateInToday($0) } ?? false

        if alreadyFedToday && alreadyWateredToday { return }

        let needType: CareNeedType
        if alreadyFedToday {
            needType = .thirsty
        } else if alreadyWateredToday {
            needType = .hungry
        } else {
            needType = Bool.random() ? .hungry : .thirsty
        }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch needType {
        case .hungry:
            content.title = "\(petName) is hungry!"
            content.body = "Come feed \(petName) before they get sad."
        case .thirsty:
            content.title = "\(petName) is thirsty!"
            content.body = "A quick drink would make \(petName)'s day."
        case .lonely:
            content.title = "\(petName) misses you!"
            content.body = "Come say hi to \(petName)."
        }

        let hour = Int.random(in: 14...17)
        let minute = Int.random(in: 0...59)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "daily_care", content: content, trigger: trigger)

        center.add(request) { _ in }

        var fireDate = calendar.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime) ?? Date()
        if fireDate < Date() { fireDate = fireDate.addingTimeInterval(86400) }
        userData.scheduleCareNeed(type: needType, fireDate: fireDate)
    }

    // MARK: - Trigger Notification Immediately (Debug)
    func triggerCareNotificationNow(petName: String) {
        let needType: CareNeedType = Bool.random() ? .hungry : .thirsty
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch needType {
        case .hungry:
            content.title = "\(petName) is hungry!"
            content.body = "Come feed \(petName) before they get sad."
        default:
            content.title = "\(petName) is thirsty!"
            content.body = "A quick drink would make \(petName)'s day."
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "daily_care_debug", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }

        UserData.shared.activeCareNeed = needType
    }

    func triggerRunReminderNow(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(petName) wants to run!"
        content.body = "\(petName) wants to go for a run with you!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "run_reminder_debug", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func triggerRunawayWarningNow(petName: String, daysUntilRunaway: Int) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch daysUntilRunaway {
        case 7:
            content.title = "\(petName) is upset..."
            content.body = "\(petName) might leave soon. Please come check on them."
        case 4:
            content.title = "\(petName) is thinking about leaving..."
            content.body = "Please come take care of \(petName) before it's too late."
        case 2:
            content.title = "\(petName) has packed their bags..."
            content.body = "You have 2 days before \(petName) leaves!"
        default:
            content.title = "\(petName) is upset..."
            content.body = "\(petName) might leave soon."
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "runaway_debug_\(daysUntilRunaway)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func triggerPetRanAwayNow(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(petName) has run away..."
        content.body = "Come rescue \(petName)! They're waiting for you."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "pet_ran_away_debug", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Schedule Run Reminder
    func scheduleRunReminder(petName: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["run_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "\(petName) wants to run!"
        content.body = "\(petName) wants to go for a run with you!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 86400, repeats: false)
        let request = UNNotificationRequest(identifier: "run_reminder", content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: - Runaway Warnings
    func scheduleRunawayWarning(petName: String, daysUntilRunaway: Int) {
        let center = UNUserNotificationCenter.current()
        let id = "runaway_warning_\(daysUntilRunaway)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch daysUntilRunaway {
        case 7:
            content.title = "\(petName) is upset..."
            content.body = "\(petName) might leave soon. Please come check on them."
        case 4:
            content.title = "\(petName) is thinking about leaving..."
            content.body = "Please come take care of \(petName) before it's too late."
        case 2:
            content.title = "\(petName) has packed their bags..."
            content.body = "You have 2 days before \(petName) leaves!"
        default: return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: - Pet Ran Away
    func notifyPetRanAway(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(petName) has run away..."
        content.body = "Come rescue \(petName)! They're waiting for you."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "pet_ran_away", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Reschedule on App Open
    func rescheduleNotifications() {
        let userData = UserData.shared
        guard let pet = userData.equippedPet,
              let def = pet.definition else { return }

        scheduleDailyCareNotification(petName: def.name)

        if let lastRun = userData.profile.lastRunDate {
            let daysSinceRun = Calendar.current.dateComponents([.day], from: lastRun, to: Date()).day ?? 0
            if daysSinceRun >= 2 {
                scheduleRunReminder(petName: def.name)
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Cancels old notification IDs, schedules new ones, returns new IDs.
    @discardableResult
    func schedule(for item: Item) async -> [String] {
        // Cancel any previously scheduled notifications for this item
        cancel(ids: item.notificationIDs)

        guard AppSettings.shared.notificationsEnabled else { return [] }

        var newIDs: [String] = []
        let now = Date()
        let expirationDay = item.expirationDate.startOfDay

        // Reminder notification (N days before expiry)
        if item.reminderOffsetDays > 0 {
            let reminderDate = expirationDay.adding(days: -item.reminderOffsetDays)
            if reminderDate > now {
                let id = UUID().uuidString
                let content = UNMutableNotificationContent()
                content.title = "Expiring Soon"
                content.body = "\(item.name) expires in \(item.reminderOffsetDays) days."
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

                try? await UNUserNotificationCenter.current().add(request)
                newIDs.append(id)
            }
        }

        // Expiry-day notification
        if expirationDay >= now.startOfDay {
            let id = UUID().uuidString
            let content = UNMutableNotificationContent()
            if expirationDay == now.startOfDay {
                content.title = "Expires Today"
                content.body = "\(item.name) expires today!"
            } else {
                content.title = "Expires Tomorrow"
                content.body = "\(item.name) expires tomorrow."
            }
            content.sound = .default

            var triggerDate = expirationDay
            // If expiry is in the future, notify at 9am on expiry day
            if expirationDay > now.startOfDay {
                triggerDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: expirationDay) ?? expirationDay
            }

            if triggerDate > now {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await UNUserNotificationCenter.current().add(request)
                newIDs.append(id)
            }
        }

        return newIDs
    }

    func cancel(ids: [String]) {
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func scheduleDailySummary(at hour: Int) async {
        // Remove existing daily summary
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-summary"])

        guard AppSettings.shared.dailySummaryEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Freshly Daily Summary"
        content.body = "Check your items for upcoming expirations."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailySummary() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-summary"])
    }
}

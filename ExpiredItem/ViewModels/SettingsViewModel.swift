import SwiftUI
import UserNotifications

@Observable
final class SettingsViewModel {
    var notificationPermissionGranted = false

    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationPermissionGranted = settings.authorizationStatus == .authorized
        }
    }

    func requestPermission() async {
        let granted = await NotificationService.shared.requestPermission()
        await MainActor.run {
            notificationPermissionGranted = granted
            AppSettings.shared.notificationsEnabled = granted
        }
    }

    func updateDailySummary() async {
        if AppSettings.shared.dailySummaryEnabled {
            await NotificationService.shared.scheduleDailySummary(at: AppSettings.shared.dailySummaryHour)
        } else {
            NotificationService.shared.cancelDailySummary()
        }
    }
}

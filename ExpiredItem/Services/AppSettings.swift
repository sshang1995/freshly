import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()

    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    @ObservationIgnored
    @AppStorage("defaultReminderDays") var defaultReminderDays = 3

    @ObservationIgnored
    @AppStorage("notificationsEnabled") var notificationsEnabled = true

    @ObservationIgnored
    @AppStorage("dailySummaryEnabled") var dailySummaryEnabled = false

    @ObservationIgnored
    @AppStorage("dailySummaryHour") var dailySummaryHour = 8

    @ObservationIgnored
    @AppStorage("defaultCategoryRaw") var defaultCategoryRaw = Category.other.rawValue

    @ObservationIgnored
    @AppStorage("defaultLocationRaw") var defaultLocationRaw = Location.fridge.rawValue

    var defaultCategory: Category {
        get { Category(rawValue: defaultCategoryRaw) ?? .other }
        set { defaultCategoryRaw = newValue.rawValue }
    }

    var defaultLocation: Location {
        get { Location.from(rawValue: defaultLocationRaw, customName: nil) }
        set { defaultLocationRaw = newValue.rawValue }
    }

    private init() {}
}

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var settingsVM = SettingsViewModel()

    // @AppStorage directly so SwiftUI tracks changes and re-renders
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("defaultReminderDays") private var defaultReminderDays = 3
    @AppStorage("dailySummaryEnabled") private var dailySummaryEnabled = false
    @AppStorage("dailySummaryHour") private var dailySummaryHour = 8
    @AppStorage("defaultCategoryRaw") private var defaultCategoryRaw = Category.other.rawValue
    @AppStorage("defaultLocationRaw") private var defaultLocationRaw = Location.fridge.rawValue

    private var defaultCategory: Category {
        get { Category(rawValue: defaultCategoryRaw) ?? .other }
    }
    private var defaultLocation: Location {
        get { Location.from(rawValue: defaultLocationRaw, customName: nil) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appHeader

                if settingsVM.notificationPermissionGranted {
                    notificationsSection
                } else {
                    notificationsBanner
                }

                defaultsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .task { await settingsVM.checkNotificationPermission() }
    }

    // MARK: - App Header
    private var appHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color(hex: "667eea").opacity(0.45), radius: 12, y: 5)

            Text("Freshly")
                .font(.system(size: 24, weight: .black, design: .rounded))
            Text("Version 1.0.0")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Notifications Off Banner
    private var notificationsBanner: some View {
        sectionCard(title: "Notifications", icon: "bell.slash.fill", iconColor: .orange) {
            HStack(spacing: 14) {
                iconCircle("bell.slash.fill", color: .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications are off")
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Text("Tap Enable to get reminders")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button("Enable") {
                    Task { await settingsVM.requestPermission() }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(Capsule())
            }
            .padding(16)
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        sectionCard(title: "Notifications", icon: "bell.fill", iconColor: .orange) {
            toggleRow(
                label: "Notifications",
                subtitle: "Get reminders before items expire",
                icon: "bell.badge.fill",
                iconColor: .orange,
                isOn: $notificationsEnabled
            )

            if notificationsEnabled {
                rowDivider()
                stepperRow(
                    label: "Default Reminder",
                    valueText: "\(defaultReminderDays)d before",
                    icon: "clock.fill",
                    iconColor: Color(hex: "667eea"),
                    value: $defaultReminderDays,
                    range: 0...30
                )

                rowDivider()
                toggleRow(
                    label: "Daily Summary",
                    subtitle: "A daily digest of your items",
                    icon: "newspaper.fill",
                    iconColor: Color(hex: "764ba2"),
                    isOn: $dailySummaryEnabled
                )
                .onChange(of: dailySummaryEnabled) { _, _ in
                    Task { await settingsVM.updateDailySummary() }
                }

                if dailySummaryEnabled {
                    rowDivider()
                    stepperRow(
                        label: "Summary Time",
                        valueText: "\(dailySummaryHour):00",
                        icon: "alarm.fill",
                        iconColor: Color(hex: "F7971E"),
                        value: $dailySummaryHour,
                        range: 0...23
                    )
                    .onChange(of: dailySummaryHour) { _, _ in
                        Task { await settingsVM.updateDailySummary() }
                    }
                }
            }
        }
    }

    // MARK: - Defaults Section
    private var defaultsSection: some View {
        sectionCard(title: "Item Defaults", icon: "slider.horizontal.3", iconColor: Color(hex: "667eea")) {
            HStack(spacing: 14) {
                iconCircle(defaultCategory.icon, color: defaultCategory.color)
                Text("Category")
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Picker("", selection: $defaultCategoryRaw) {
                    ForEach(Category.allCases) { cat in
                        Text(cat.displayName).tag(cat.rawValue)
                    }
                }
                .labelsHidden()
                .tint(Color(hex: "667eea"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            rowDivider()

            HStack(spacing: 14) {
                iconCircle(defaultLocation.icon, color: Color(hex: "11998e"))
                Text("Location")
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Picker("", selection: $defaultLocationRaw) {
                    ForEach([Location.fridge, .freezer, .pantry, .cabinet, .counter], id: \.self) { loc in
                        Text(loc.displayName).tag(loc.rawValue)
                    }
                }
                .labelsHidden()
                .tint(Color(hex: "667eea"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Row Helpers

    private func toggleRow(label: String, subtitle: String, icon: String, iconColor: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconCircle(icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "667eea"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func stepperRow(label: String, valueText: String, icon: String, iconColor: Color, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 14) {
            iconCircle(icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Text(valueText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            Spacer(minLength: 12)
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func sectionCard<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) { content() }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private func iconCircle(_ icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 38, height: 38)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private func rowDivider() -> some View {
        Divider().padding(.leading, 68)
    }
}

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LanguageManager.self) private var languageManager
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
                languageSection
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
            Text(L("settings.version"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Notifications Off Banner
    private var notificationsBanner: some View {
        sectionCard(title: L("settings.notifications"), icon: "bell.slash.fill", iconColor: .orange) {
            HStack(spacing: 14) {
                iconCircle("bell.slash.fill", color: .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("settings.notifications.off"))
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Text(L("settings.notifications.tapEnable"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button(L("settings.notifications.enable")) {
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
        sectionCard(title: L("settings.notifications"), icon: "bell.fill", iconColor: .orange) {
            toggleRow(
                label: L("settings.notifications"),
                subtitle: L("settings.notifications.subtitle"),
                icon: "bell.badge.fill",
                iconColor: .orange,
                isOn: $notificationsEnabled
            )

            if notificationsEnabled {
                rowDivider()
                stepperRow(
                    label: L("settings.reminder.default"),
                    valueText: Lf("settings.reminder.dBefore", defaultReminderDays),
                    icon: "clock.fill",
                    iconColor: Color(hex: "667eea"),
                    value: $defaultReminderDays,
                    range: 0...30
                )

                rowDivider()
                toggleRow(
                    label: L("settings.dailySummary"),
                    subtitle: L("settings.dailySummary.subtitle"),
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
                        label: L("settings.summaryTime"),
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
        sectionCard(title: L("settings.defaults"), icon: "slider.horizontal.3", iconColor: Color(hex: "667eea")) {
            HStack(spacing: 14) {
                iconCircle(defaultCategory.icon, color: defaultCategory.color)
                Text(L("settings.defaults.category"))
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
                Text(L("settings.defaults.location"))
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

    // MARK: - Language Section
    private var languageSection: some View {
        sectionCard(title: L("settings.language.section"), icon: "globe", iconColor: Color(hex: "11998e")) {
            ForEach(Array(LanguageManager.supported.enumerated()), id: \.element.code) { index, lang in
                VStack(spacing: 0) {
                    if index > 0 { rowDivider() }
                    Button {
                        languageManager.selectedLanguage = lang.code
                    } label: {
                        HStack(spacing: 14) {
                            iconCircle("globe", color: Color(hex: "11998e"))
                            Text(lang.nativeName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            if languageManager.selectedLanguage == lang.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "667eea"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
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

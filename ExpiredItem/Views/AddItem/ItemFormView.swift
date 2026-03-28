import SwiftUI

struct ItemFormView: View {
    @Bindable var viewModel: ItemFormViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                formSection(title: L("form.section.itemDetails"), icon: "tag.fill", iconColor: Color(hex: "667eea")) {
                    formField(L("form.field.name")) {
                        TextField(L("form.field.namePlaceholder"), text: $viewModel.name)
                            .autocorrectionDisabled()
                    }
                    Divider().padding(.leading, 16)
                    formField(L("form.field.quantity")) {
                        TextField(L("form.field.quantityPlaceholder"), text: $viewModel.quantity)
                    }
                }

                formSection(title: L("form.section.category"), icon: "square.grid.2x2.fill", iconColor: Color(hex: "764ba2")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Category.allCases) { cat in
                                categoryChip(cat)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                formSection(title: L("form.section.location"), icon: "mappin.circle.fill", iconColor: Color(hex: "11998e")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([Location.fridge, .freezer, .pantry, .cabinet, .counter, .custom(L("location.custom"))], id: \.self) { loc in
                                locationChip(loc)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    if case .custom = viewModel.location {
                        Divider().padding(.leading, 16)
                        formField(L("form.field.customName")) {
                            TextField(L("form.field.customNamePlaceholder"), text: $viewModel.customLocationName)
                        }
                    }
                }

                formSection(title: L("form.section.expiration"), icon: "calendar.badge.exclamationmark", iconColor: Color(hex: "FF416C")) {
                    HStack {
                        Text(L("form.date.expiresOn"))
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("", selection: $viewModel.expirationDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider().padding(.leading, 16)

                    Toggle(isOn: $viewModel.hasPurchaseDate) {
                        Text(L("form.date.trackPurchase"))
                            .font(.system(size: 15))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .tint(Color(hex: "667eea"))

                    if viewModel.hasPurchaseDate {
                        Divider().padding(.leading, 16)
                        HStack {
                            Text(L("form.date.purchasedOn"))
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                            Spacer()
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { viewModel.purchaseDate ?? Date() },
                                    set: { viewModel.purchaseDate = $0 }
                                ),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                formSection(title: L("form.section.reminder"), icon: "bell.fill", iconColor: Color(hex: "F7971E")) {
                    VStack(spacing: 6) {
                        HStack {
                            Text(L("form.reminder.remindMe"))
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                            Spacer()
                            let days = viewModel.reminderOffsetDays
                            Text(Lf(days == 1 ? "form.reminder.dayBefore" : "form.reminder.daysBefore", days))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "667eea"))
                        }
                        Stepper("", value: $viewModel.reminderOffsetDays, in: 0...30)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                formSection(title: L("form.section.notes"), icon: "note.text", iconColor: Color(hex: "95A5A6")) {
                    TextField(L("form.field.notesPlaceholder"), text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Form Section
    private func formSection<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            content()
                .font(.system(size: 15))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Category Chip
    private func categoryChip(_ cat: Category) -> some View {
        let isSelected = viewModel.category == cat
        return Button { viewModel.category = cat } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? cat.gradient : LinearGradient(colors: [Color(.tertiarySystemGroupedBackground)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                    Image(systemName: cat.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                Text(cat.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? cat.color : .secondary)
            }
            .padding(.vertical, 4)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Location Chip
    private func locationChip(_ loc: Location) -> some View {
        let isSelected: Bool = {
            if case .custom = loc, case .custom = viewModel.location { return true }
            return viewModel.location == loc
        }()

        return Button {
            viewModel.location = loc
        } label: {
            HStack(spacing: 6) {
                Image(systemName: loc.icon)
                    .font(.system(size: 13))
                Text(loc.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .leading, endPoint: .trailing)
                    } else {
                        LinearGradient(colors: [Color(.tertiarySystemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    }
                }
            )
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color(hex: "667eea").opacity(0.3) : .clear, radius: 6, y: 2)
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

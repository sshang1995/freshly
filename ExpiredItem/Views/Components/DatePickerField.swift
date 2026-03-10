import SwiftUI

struct DatePickerField: View {
    let label: String
    @Binding var date: Date
    var displayedComponents: DatePickerComponents = .date
    var minimumDate: Date? = nil

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            DatePicker(
                "",
                selection: $date,
                in: (minimumDate ?? .distantPast)...,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
        }
    }
}

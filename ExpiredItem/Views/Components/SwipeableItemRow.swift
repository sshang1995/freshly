import SwiftUI

struct SwipeableItemRow: View {
    let item: Item
    let onDelete: () -> Void
    let onConsume: (() -> Void)?

    @State private var dragOffset: CGFloat = 0
    @State private var navigate = false
    @State private var gestureDirection: GestureDirection = .undecided
    @State private var isRemoving = false
    @State private var naturalHeight: CGFloat = 0

    private let threshold: CGFloat = 72

    private enum GestureDirection { case undecided, horizontal, vertical }

    var body: some View {
        ZStack {
            consumeBackground
            deleteBackground

            ItemRowView(item: item)
                .offset(x: dragOffset)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard dragOffset == 0 else { return }
                    navigate = true
                }
        }
        .clipped()
        .padding(.bottom, 10)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h in
            if !isRemoving, h > 0 { naturalHeight = h }
        }
        .frame(height: isRemoving ? 0 : (naturalHeight > 0 ? naturalHeight : nil), alignment: .top)
        .clipped()
        .navigationDestination(isPresented: $navigate) {
            ItemDetailView(item: item)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    let h = value.translation.width
                    let v = value.translation.height

                    if gestureDirection == .undecided {
                        if abs(h) > abs(v) * 3.0 {
                            gestureDirection = .horizontal
                        } else if abs(v) > abs(h) * 1.2 {
                            gestureDirection = .vertical
                        } else {
                            return // not clear yet — wait for more movement
                        }
                    }

                    guard gestureDirection == .horizontal else { return }
                    guard !(h > 0 && onConsume == nil) else { return }

                    withAnimation(.interactiveSpring()) {
                        dragOffset = h > 0
                            ? min(h, threshold + 30)
                            : max(h, -(threshold + 30))
                    }
                }
                .onEnded { value in
                    let wasHorizontal = gestureDirection == .horizontal
                    gestureDirection = .undecided

                    guard wasHorizontal else {
                        // Vertical gesture — snap back if dragOffset got any accidental movement
                        if dragOffset != 0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                dragOffset = 0
                            }
                        }
                        return
                    }

                    let t        = value.translation.width
                    let velocity = value.predictedEndTranslation.width
                    let triggersConsume = (t > threshold || velocity > 200) && t > 10
                    let triggersDelete  = (t < -threshold || velocity < -200) && t < -10

                    if triggersConsume, let onConsume {
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = 600
                            isRemoving = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onConsume() }
                    } else if triggersDelete {
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = -600
                            isRemoving = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDelete() }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    // MARK: - Backgrounds

    private var consumeBackground: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text(L("inventory.action.consumed"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.leading, 20)
            .opacity(max(0, min(1, dragOffset / 40)))
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "2ECC71")))
        .opacity(onConsume != nil ? 1 : 0)
    }

    private var deleteBackground: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Text(L("inventory.action.delete"))
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: "trash.fill")
                    .font(.system(size: 22, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.trailing, 20)
            .opacity(max(0, min(1, -dragOffset / 40)))
        }
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "E74C3C")))
        .opacity(dragOffset >= 0 ? 0 : 1)
    }
}

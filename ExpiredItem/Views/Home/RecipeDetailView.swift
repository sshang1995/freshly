import SwiftUI

struct RecipeDetailView: View {
    let recipe: RecipeRecommendation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                    .padding(.bottom, 24)

                VStack(spacing: 20) {
                    ingredientsCard
                    stepsCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L("home.recipe.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "ff9966"), Color(hex: "ff5e62")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 8) {
                Label(L("home.recipe.label"), systemImage: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Text(recipe.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(recipe.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    Label(recipe.timeText, systemImage: "clock.fill")
                    Label(Lf("home.recipe.ingredientsCount", recipe.ingredients.count), systemImage: "carrot.fill")
                    Label(Lf("home.recipe.steps", recipe.steps.count), systemImage: "list.number")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Ingredients

    private var ingredientsCard: some View {
        sectionCard(title: L("home.recipe.ingredients"), icon: "carrot.fill", iconColor: Color(hex: "ff9966")) {
            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "ff9966").opacity(0.15))
                            .frame(width: 30, height: 30)
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "ff9966"))
                    }
                    Text(ingredient)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if index < recipe.ingredients.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
    }

    // MARK: - Steps

    private var stepsCard: some View {
        sectionCard(title: L("home.recipe.instructions"), icon: "list.number", iconColor: Color(hex: "667eea")) {
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(step)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if index < recipe.steps.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
    }

    // MARK: - Helpers

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
}

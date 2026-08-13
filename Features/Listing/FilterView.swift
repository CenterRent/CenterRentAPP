import SwiftUI

struct FilterView: View {
    @State var filter: ListingFilter
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CRSpacing.s6) {

                    // City
                    filterSection("Localização") {
                        CRTextField("Cidade", text: $filter.city,
                                    placeholder: "São Paulo, Rio de Janeiro...",
                                    leadingIcon: "mappin.circle")
                    }

                    // Price Range
                    filterSection("Faixa de preço (\(filter.priceType.rawValue))") {
                        VStack(spacing: CRSpacing.s3) {
                            Picker("Tipo", selection: $filter.priceType) {
                                ForEach(ListingFilter.PriceType.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: CRSpacing.s3) {
                                CRTextField("Mínimo", text: Binding(
                                    get: { filter.minPrice.map { "\(Int($0))" } ?? "" },
                                    set: { filter.minPrice = Double($0) }
                                ), placeholder: "R$ 0", keyboardType: .numberPad, prefix: "R$")

                                CRTextField("Máximo", text: Binding(
                                    get: { filter.maxPrice.map { "\(Int($0))" } ?? "" },
                                    set: { filter.maxPrice = Double($0) }
                                ), placeholder: "Sem limite", keyboardType: .numberPad, prefix: "R$")
                            }
                        }
                    }

                    // Specialties
                    filterSection("Especialidades") {
                        FlowLayout(spacing: CRSpacing.s2) {
                            ForEach(DentalSpecialties.all, id: \.self) { spec in
                                Button(action: {
                                    if filter.specialties.contains(spec) {
                                        filter.specialties.removeAll { $0 == spec }
                                    } else {
                                        filter.specialties.append(spec)
                                    }
                                }) {
                                    Text(spec)
                                        .font(.crLabelSM)
                                        .foregroundColor(filter.specialties.contains(spec) ? .white : CRColor.Text.secondary)
                                        .padding(.horizontal, CRSpacing.s3)
                                        .padding(.vertical, CRSpacing.s2)
                                        .background(filter.specialties.contains(spec) ? CRColor.Primary.default : CRColor.Neutral.n100)
                                        .cornerRadius(CRRadius.full)
                                }
                            }
                        }
                    }

                    // Amenities
                    filterSection("Equipamentos") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CRSpacing.s2) {
                            ForEach(DentalAmenities.all.prefix(8), id: \.self) { am in
                                Button(action: {
                                    if filter.amenities.contains(am) {
                                        filter.amenities.removeAll { $0 == am }
                                    } else {
                                        filter.amenities.append(am)
                                    }
                                }) {
                                    HStack(spacing: CRSpacing.s2) {
                                        Image(systemName: filter.amenities.contains(am) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(filter.amenities.contains(am) ? CRColor.Primary.default : CRColor.Neutral.n400)
                                        Text(am).font(.crBodySM).foregroundColor(CRColor.Text.primary).lineLimit(1)
                                    }
                                    .padding(CRSpacing.s2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(filter.amenities.contains(am) ? CRColor.Primary.lighter : CRColor.Surface.primary)
                                    .cornerRadius(CRRadius.sm)
                                }
                            }
                        }
                    }

                    // Toggles
                    filterSection("Preferências") {
                        VStack(spacing: CRSpacing.s3) {
                            FilterToggleRow(label: "Disponível agora", icon: "clock.badge.checkmark",
                                           value: $filter.availableNow)
                            FilterToggleRow(label: "Apenas profissionais verificados", icon: "checkmark.seal",
                                           value: $filter.onlyVerified)
                        }
                    }

                    // Sort
                    filterSection("Ordenar por") {
                        VStack(spacing: CRSpacing.s2) {
                            ForEach(ListingFilter.SortOption.allCases, id: \.self) { opt in
                                Button(action: { filter.sortBy = opt }) {
                                    HStack {
                                        Text(opt.rawValue).font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                                        Spacer()
                                        if filter.sortBy == opt {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(CRColor.Primary.default)
                                                .font(.system(size: CRSize.iconMD, weight: .semibold))
                                        }
                                    }
                                    .padding(CRSpacing.s3)
                                    .background(filter.sortBy == opt ? CRColor.Primary.lighter : CRColor.Surface.primary)
                                    .cornerRadius(CRRadius.sm)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.bottom, 100)
            }
            .background(CRColor.Background.secondary.ignoresSafeArea())
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpar") {
                        filter = ListingFilter()
                    }
                    .foregroundColor(CRColor.Feedback.error)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Feito") { dismiss() }
                        .font(.crLabelMD)
                        .foregroundColor(CRColor.Primary.default)
                }
            }
            .safeAreaInset(edge: .bottom) {
                CRButton("Ver resultados", variant: .primary, size: .lg, isFullWidth: true) {
                    dismiss()
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.vertical, CRSpacing.s4)
                .background(CRColor.Background.primary)
            }
        }
    }

    @ViewBuilder
    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            Text(title).font(.crHeading5).foregroundColor(CRColor.Text.primary)
            content()
        }
        .padding(CRSpacing.s4)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.card)
    }
}

private struct FilterToggleRow: View {
    let label: String
    let icon: String
    @Binding var value: Bool

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            Image(systemName: icon)
                .font(.system(size: CRSize.iconMD))
                .foregroundColor(CRColor.Icon.accent)
                .frame(width: 24)
            Text(label).font(.crLabelMD).foregroundColor(CRColor.Text.primary)
            Spacer()
            Toggle("", isOn: $value)
                .tint(CRColor.Primary.default)
                .labelsHidden()
        }
    }
}

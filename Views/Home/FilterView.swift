import SwiftUI

struct FilterView: View {
    @ObservedObject var vm: HomeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: CRSpacing.xxl) {
                        // Price Range
                        VStack(alignment: .leading, spacing: CRSpacing.md) {
                            HStack {
                                Text("Faixa de Preço").font(.crH4).foregroundColor(.crTextPrimary)
                                Spacer()
                                Text("R$ \(Int(vm.filterMinPrice)) - R$ \(Int(vm.filterMaxPrice))")
                                    .font(.crLabel).foregroundColor(.crPrimary)
                            }
                            RangeSliderView(minValue: $vm.filterMinPrice, maxValue: $vm.filterMaxPrice, range: 0...1000)
                        }

                        // Categories
                        VStack(alignment: .leading, spacing: CRSpacing.md) {
                            Text("Categorias").font(.crH4).foregroundColor(.crTextPrimary)
                            FlowLayout(spacing: 8) {
                                ForEach(["Equipamentos","Salas","Consultórios","Mesas","Poltronas"], id: \.self) { type in
                                    FilterChip(label: type, isSelected: vm.filterSelectedTypes.contains(type)) {
                                        if vm.filterSelectedTypes.contains(type) {
                                            vm.filterSelectedTypes.remove(type)
                                        } else {
                                            vm.filterSelectedTypes.insert(type)
                                        }
                                    }
                                }
                            }
                        }

                        // Other filters
                        VStack(alignment: .leading, spacing: CRSpacing.md) {
                            Text("Outros Filtros").font(.crH4).foregroundColor(.crTextPrimary)
                            FilterToggleRow(label: "Disponível hoje", isOn: $vm.filterOnlyAvailableToday)
                            FilterToggleRow(label: "Parceiros Verificados", isOn: $vm.filterVerifiedOnly)
                            FilterToggleRow(label: "Avaliação 4.5+", isOn: $vm.filterMinRating)
                        }

                        Spacer().frame(height: CRSpacing.xxxl)
                    }
                    .padding(CRSpacing.xl)
                }

                // Bottom actions
                HStack(spacing: CRSpacing.base) {
                    CRButton(title: "Limpar", variant: .ghost, isFullWidth: true) {
                        vm.filterMinPrice = 50; vm.filterMaxPrice = 500
                        vm.filterOnlyAvailableToday = false; vm.filterVerifiedOnly = false
                        vm.filterMinRating = false; vm.filterSelectedTypes = []
                        dismiss()
                    }
                    CRButton(title: "Ver resultados", isFullWidth: true) {
                        dismiss()
                    }
                }
                .padding(.horizontal, CRSpacing.xl)
                .padding(.vertical, CRSpacing.base)
                .background(Color.white.crShadowSoft())
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fechar") { dismiss() }
            }}
        }
    }
}

struct FilterToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Button {
                withAnimation { isOn.toggle() }
            } label: {
                HStack(spacing: CRSpacing.md) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isOn ? Color.crPrimary : Color.crDivider, lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .background(isOn ? Color.crPrimary.cornerRadius(4) : Color.clear.cornerRadius(4))
                        .overlay(Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white).opacity(isOn ? 1 : 0))
                    Text(label).font(.crBodyLarge).foregroundColor(.crTextPrimary)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.crLabelSmall)
                .foregroundColor(isSelected ? .white : .crTextPrimary)
                .padding(.horizontal, CRSpacing.md)
                .padding(.vertical, CRSpacing.sm)
                .background(isSelected ? Color.crPrimary : Color.white)
                .cornerRadius(CRRadius.pill)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.pill).stroke(isSelected ? Color.crPrimary : Color.crDivider, lineWidth: 1))
        }
        .buttonStyle(CRPressStyle())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for sv in row.subviews {
                let size = sv.sizeThatFits(.unspecified)
                sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }
    private struct Row { var subviews: [LayoutSubview]; var height: CGFloat }
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []; var currentRow: Row = Row(subviews: [], height: 0)
        var x: CGFloat = 0; let maxWidth = proposal.width ?? 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !currentRow.subviews.isEmpty {
                rows.append(currentRow); currentRow = Row(subviews: [], height: 0); x = 0
            }
            currentRow.subviews.append(sv)
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }
        if !currentRow.subviews.isEmpty { rows.append(currentRow) }
        return rows
    }
}

struct RangeSliderView: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let minX = (minValue - range.lowerBound) / (range.upperBound - range.lowerBound) * w
            let maxX = (maxValue - range.lowerBound) / (range.upperBound - range.lowerBound) * w
            ZStack(alignment: .leading) {
                Capsule().fill(Color.crDivider).frame(height: 4)
                Capsule().fill(Color.crPrimary).frame(width: maxX - minX, height: 4).offset(x: minX)
                Circle().fill(Color.crPrimary).frame(width: 22, height: 22).offset(x: minX - 11)
                    .gesture(DragGesture().onChanged { v in
                        let newMin = max(range.lowerBound, min(maxValue - 50, (v.location.x / w) * (range.upperBound - range.lowerBound) + range.lowerBound))
                        minValue = newMin
                    })
                Circle().fill(Color.crPrimary).frame(width: 22, height: 22).offset(x: maxX - 11)
                    .gesture(DragGesture().onChanged { v in
                        let newMax = min(range.upperBound, max(minValue + 50, (v.location.x / w) * (range.upperBound - range.lowerBound) + range.lowerBound))
                        maxValue = newMax
                    })
            }
        }
        .frame(height: 22)
    }
}

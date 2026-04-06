import SwiftUI

struct CreateListingView: View {
    @EnvironmentObject var router: AppRouter
    @State private var title = ""
    @State private var description = ""
    @State private var dailyPrice = ""
    @State private var selectedCategory = ""
    @State private var address = ""
    @State private var isSaving = false
    @State private var currentStep = 0
    let steps = ["Básico", "Detalhes", "Fotos", "Preço", "Revisar"]
    let categories = ["Odontologia", "Estética", "Fisioterapia", "Massoterapia", "Pilates"]

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(
                title: "Criar Anúncio",
                onBack: { currentStep > 0 ? (currentStep -= 1) : router.pop() }
            )

            // Steps progress
            CheckoutProgressBar(progress: Double(currentStep + 1) / Double(steps.count))

            HStack {
                ForEach(steps.indices, id: \.self) { i in
                    Text(steps[i])
                        .font(.crCaption)
                        .foregroundColor(i <= currentStep ? .crPrimary : .crTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.sm)
            .background(Color.white)

            ScrollView {
                VStack(spacing: CRSpacing.xl) {
                    switch currentStep {
                    case 0:
                        VStack(spacing: CRSpacing.base) {
                            Text("Sobre o seu ativo").font(.crH3).foregroundColor(.crTextPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            CRTextField(label: "Título do anúncio", placeholder: "Ex: Sala Odontológica Completa", text: $title, icon: "text.alignleft")
                            VStack(alignment: .leading, spacing: CRSpacing.xs) {
                                Text("Categoria").font(.crLabelSmall).foregroundColor(.crTextSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack { ForEach(categories, id: \.self) { cat in
                                        FilterChip(label: cat, isSelected: selectedCategory == cat) { selectedCategory = cat }
                                    }}
                                }
                            }
                        }
                    case 1:
                        VStack(spacing: CRSpacing.base) {
                            Text("Detalhes do espaço").font(.crH3).foregroundColor(.crTextPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: CRSpacing.xs) {
                                Text("Descrição").font(.crLabelSmall).foregroundColor(.crTextSecondary)
                                TextEditor(text: $description).font(.crBodyLarge).frame(height: 120)
                                    .padding(CRSpacing.sm).background(Color.white).cornerRadius(CRRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: CRRadius.md).stroke(Color.crDivider, lineWidth: 1))
                            }
                            CRTextField(label: "Endereço completo", placeholder: "Rua, número, bairro, cidade", text: $address, icon: "mappin")
                        }
                    case 2:
                        VStack(spacing: CRSpacing.base) {
                            Text("Fotos do ativo").font(.crH3).foregroundColor(.crTextPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            RoundedRectangle(cornerRadius: CRRadius.lg)
                                .fill(Color.crBackground)
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: CRSpacing.md) {
                                        Image(systemName: "photo.badge.plus").font(.system(size: 48)).foregroundColor(.crPrimary)
                                        Text("Adicionar fotos").font(.crLabel).foregroundColor(.crPrimary)
                                        Text("Toque para selecionar ou tirar fotos").font(.crBodySmall).foregroundColor(.crTextTertiary)
                                    }
                                )
                                .overlay(RoundedRectangle(cornerRadius: CRRadius.lg).stroke(Color.crPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8])))
                        }
                    case 3:
                        VStack(spacing: CRSpacing.base) {
                            Text("Defina seu preço").font(.crH3).foregroundColor(.crTextPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            CRTextField(label: "Valor por diária (R$)", placeholder: "Ex: 200", text: $dailyPrice, icon: "brazilianrealsign", keyboardType: .decimalPad)
                            Text("💡 Dica: Salas similares na sua região cobram entre R$ 150 e R$ 350/dia.")
                                .font(.crBodySmall).foregroundColor(.crTextTertiary)
                                .padding(CRSpacing.md).background(Color.crSecondary.opacity(0.2)).cornerRadius(CRRadius.md)
                        }
                    case 4:
                        VStack(spacing: CRSpacing.md) {
                            Text("Revise seu anúncio").font(.crH3).foregroundColor(.crTextPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            if !title.isEmpty {
                                VStack(alignment: .leading, spacing: CRSpacing.sm) {
                                    ConfirmationRow(label: "Título", value: title)
                                    ConfirmationRow(label: "Categoria", value: selectedCategory.isEmpty ? "Não definida" : selectedCategory)
                                    ConfirmationRow(label: "Endereço", value: address.isEmpty ? "Não informado" : address)
                                    ConfirmationRow(label: "Valor/dia", value: dailyPrice.isEmpty ? "Não definido" : "R$ \(dailyPrice)")
                                }
                                .padding(CRSpacing.base).background(Color.white).cornerRadius(CRRadius.lg).crShadowSoft()
                            }
                        }
                    default: EmptyView()
                    }

                    CRButton(
                        title: currentStep < steps.count - 1 ? "Continuar" : "Publicar Anúncio",
                        isLoading: isSaving
                    ) {
                        if currentStep < steps.count - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            isSaving = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isSaving = false; router.pop()
                            }
                        }
                    }
                    .padding(.bottom, CRSpacing.xxxl)
                }
                .padding(CRSpacing.base)
            }
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
    }
}

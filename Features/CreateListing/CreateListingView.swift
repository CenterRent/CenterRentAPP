import SwiftUI
import Combine
import PhotosUI

// MARK: - Create Listing Flow
struct CreateListingView: View {
    let editingListingId: String?

    @StateObject private var vm = CreateListingViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var showDiscardAlert = false

    init(editingListingId: String? = nil) {
        self.editingListingId = editingListingId
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Progress ──────────────────────────────────────────
                SetupProgressBar(currentStep: vm.step,
                                 totalSteps: CreateListingStep.allCases.count)
                    .padding(.horizontal, CRSpacing.screenHorizontal)

                HStack {
                    Text("Passo \(vm.step + 1) de \(CreateListingStep.allCases.count)")
                        .font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
                    Spacer()
                    Text(vm.currentStep.title)
                        .font(.crLabelMD).foregroundColor(CRColor.Text.secondary)
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.top, CRSpacing.s2)

                // ── Step content ──────────────────────────────────────
                ScrollView {
                    VStack(spacing: CRSpacing.s8) {
                        VStack(spacing: CRSpacing.s2) {
                            Text(vm.currentStep.title)
                                .font(.crHeading2).foregroundColor(CRColor.Text.primary)
                            Text(vm.currentStep.subtitle)
                                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, CRSpacing.s6)

                        stepContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.crBodySM)
                                .foregroundColor(CRColor.Feedback.error)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, CRSpacing.screenHorizontal)
                    .padding(.bottom, 120)
                }

                // ── Bottom navigation ─────────────────────────────────
                VStack(spacing: CRSpacing.s3) {
                    if vm.step == CreateListingStep.allCases.count - 1 {
                        CRButton(vm.isEditMode ? "Salvar alterações" : "Publicar anúncio",
                                 variant: .primary, size: .lg,
                                 icon: "checkmark", iconPosition: .trailing,
                                 isLoading: vm.isLoading, isFullWidth: true) {
                            Task { await vm.publish(dismiss: { dismiss() }) }
                        }
                        if !vm.isEditMode {
                            CRButton("Salvar rascunho", variant: .ghost, size: .md, isFullWidth: true) {
                                Task { await vm.saveDraft(dismiss: { dismiss() }) }
                            }
                        }
                    } else {
                        CRButton("Continuar", variant: .primary, size: .lg,
                                 icon: "arrow.right", iconPosition: .trailing,
                                 isFullWidth: true) {
                            withAnimation(CRAnimation.springNormal) { vm.nextStep() }
                        }
                    }
                    if vm.step > 0 {
                        CRButton("Voltar", variant: .ghost, size: .md, isFullWidth: true) {
                            withAnimation(CRAnimation.springNormal) { vm.previousStep() }
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.bottom, CRSpacing.s8)
                .background(CRColor.Background.primary)
            }
            .background(CRColor.Background.secondary.ignoresSafeArea())
            .navigationTitle(vm.isEditMode ? "Editar anúncio" : "Criar anúncio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showDiscardAlert = true } label: {
                        Image(systemName: "xmark").foregroundColor(CRColor.Icon.primary)
                    }
                }
            }
            .overlay {
                if vm.isLoadingListing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Carregando anúncio…")
                            .padding(CRSpacing.s6)
                            .background(CRColor.Surface.primary)
                            .cornerRadius(CRRadius.card)
                    }
                }
            }
            .alert("Descartar anúncio?", isPresented: $showDiscardAlert) {
                Button("Descartar", role: .destructive) { dismiss() }
                Button("Continuar editando", role: .cancel) {}
            } message: {
                Text("As informações preenchidas serão perdidas.")
            }
        }
        .onAppear {
            vm.ownerId = (authService.currentUser?.id ?? "").lowercased()
            vm.editingListingId = editingListingId
            Task {
                let uid = await vm.resolvedOwnerId()
                await vm.loadAmenities(userId: uid)
                vm.applyPendingAmenitySelection()
                if let editId = editingListingId {
                    await vm.loadForEditing(listingId: editId)
                    // Re-apply amenity selection after listing is loaded
                    vm.applyPendingAmenitySelection()
                }
            }
        }
    }

    // MARK: - Step Router
    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case .basicInfo:    basicInfoStep
        case .details:      detailsStep
        case .amenities:    amenitiesStep
        case .location:     locationStep
        case .pricing:      pricingStep
        case .photos:       photosStep
        case .availability: availabilityStep
        case .preview:      previewStep
        }
    }

    // ================================================================
    // MARK: - Step 1: Basic Info
    // ================================================================
    private var basicInfoStep: some View {
        VStack(spacing: CRSpacing.s4) {
            CRTextField("Título do espaço *", text: $vm.title,
                        placeholder: "Ex: Consultório odontológico equipado no centro",
                        isRequired: true,
                        helperText: "Um bom título aumenta em 2x as visualizações",
                        maxLength: 80)

            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                HStack {
                    Text("Descrição *").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    Spacer()
                    Text("\(vm.description.count)/500")
                        .font(.crCaptionSM)
                        .foregroundColor(vm.description.count > 450
                                         ? CRColor.Feedback.error
                                         : CRColor.Text.tertiary)
                }
                TextEditor(text: $vm.description)
                    .font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                    .frame(minHeight: 120)
                    .padding(CRSpacing.s3)
                    .background(CRColor.Surface.primary)
                    .cornerRadius(CRRadius.input)
                    .overlay(RoundedRectangle(cornerRadius: CRRadius.input)
                        .stroke(CRColor.Border.default, lineWidth: CRBorder.thin))
                    .onChange(of: vm.description) { _, v in
                        if v.count > 500 { vm.description = String(v.prefix(500)) }
                    }
            }

            CRTextField("Área (m²) *", text: $vm.area,
                        placeholder: "Ex: 25", keyboardType: .decimalPad)
            CRTextField("Capacidade *", text: $vm.capacity,
                        placeholder: "Ex: 2", keyboardType: .numberPad,
                        helperText: "Número máximo de pessoas simultâneas")
        }
    }

    // ================================================================
    // MARK: - Step 2: Details (Specialties)
    // ================================================================
    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s4) {
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                Text("Especialidades atendidas")
                    .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                Text("Selecione todas que se aplicam ao espaço")
                    .font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
                FlowLayout(spacing: CRSpacing.s2) {
                    ForEach(DentalSpecialties.all, id: \.self) { spec in
                        Button { vm.toggleSpecialty(spec) } label: {
                            Text(spec)
                                .font(.crLabelSM)
                                .foregroundColor(vm.specialties.contains(spec)
                                                 ? .white : CRColor.Primary.default)
                                .padding(.horizontal, CRSpacing.s3)
                                .padding(.vertical, CRSpacing.s2)
                                .background(vm.specialties.contains(spec)
                                            ? CRColor.Primary.default
                                            : CRColor.Primary.lighter)
                                .cornerRadius(CRRadius.full)
                        }
                    }
                }
            }
            CRTextField("Regras do espaço (opcional)", text: $vm.rules,
                        placeholder: "Ex: Não é permitido fumar…",
                        helperText: "Informações importantes para locatários")
        }
    }

    // ================================================================
    // MARK: - Step 3: Amenities  ← NOVO: categorias + chip + add custom
    // ================================================================
    private var amenitiesStep: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s6) {

            if vm.isLoadingAmenities {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, CRSpacing.s8)
            } else {
                // Groups by category
                ForEach(Amenity.AmenityCategory.allCases, id: \.self) { category in
                    let items = vm.allAmenities.filter { $0.category == category }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: CRSpacing.s3) {
                            // Category header
                            HStack(spacing: 6) {
                                Image(systemName: category.categoryIcon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(CRColor.Primary.default)
                                Text(category.label)
                                    .font(.crLabelMD)
                                    .foregroundColor(CRColor.Text.primary)
                            }
                            // Chip row (flow wrap)
                            FlowLayout(spacing: CRSpacing.s2) {
                                ForEach(items) { amenity in
                                    AmenityChipButton(
                                        amenity: amenity,
                                        isSelected: vm.selectedAmenityIds.contains(amenity.id)
                                    ) { vm.toggleAmenityId(amenity.id) }
                                }
                            }
                        }
                    }
                }
            }

            // ── Add custom amenity ────────────────────────────────────
            Button { vm.showAddAmenitySheet = true } label: {
                HStack(spacing: CRSpacing.s2) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 15))
                        .foregroundColor(CRColor.Primary.default)
                    Text("Adicionar equipamento personalizado")
                        .font(.crLabelSM)
                        .foregroundColor(CRColor.Primary.default)
                }
                .frame(maxWidth: .infinity)
                .padding(CRSpacing.s3)
                .background(CRColor.Primary.lighter)
                .cornerRadius(CRRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.sm)
                    .stroke(CRColor.Primary.default,
                            style: StrokeStyle(lineWidth: 1, dash: [5])))
            }
        }
        .sheet(isPresented: $vm.showAddAmenitySheet) {
            AddCustomAmenitySheet(vm: vm)
        }
    }

    // ================================================================
    // MARK: - Step 4: Location  ← NOVO: CEP validator + auto-fill
    // ================================================================
    private var locationStep: some View {
        VStack(spacing: CRSpacing.s4) {

            // ── CEP ──────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                HStack(spacing: 8) {
                    Text("CEP *").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    if vm.isFetchingCEP {
                        ProgressView().scaleEffect(0.75)
                    }
                }
                TextField("00000-000", text: $vm.zipCode)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 12)
                    .frame(height: CRSize.inputMD)
                    .background(CRColor.Surface.primary)
                    .cornerRadius(CRRadius.input)
                    .overlay(RoundedRectangle(cornerRadius: CRRadius.input)
                        .stroke(vm.cepError != nil
                                ? CRColor.Feedback.error
                                : CRColor.Border.default, lineWidth: CRBorder.thin))
                    .onChange(of: vm.zipCode) { _, newValue in
                        // Mask: 00000-000
                        let digits = String(newValue.filter(\.isNumber).prefix(8))
                        let masked = digits.count > 5
                            ? String(digits.prefix(5)) + "-" + String(digits.dropFirst(5))
                            : digits
                        if masked != newValue { vm.zipCode = masked }
                        if digits.count == 8 { Task { await vm.fetchCEP() } }
                    }
                if let err = vm.cepError {
                    Text(err).font(.crCaptionMD).foregroundColor(CRColor.Feedback.error)
                }
            }

            // ── Address fields — disabled while fetching ─────────────
            Group {
                CRTextField("Rua *", text: $vm.street,
                            placeholder: "Nome da rua", isRequired: true)
                HStack(spacing: CRSpacing.s3) {
                    CRTextField("Número *", text: $vm.number,
                                placeholder: "123", isRequired: true,
                                keyboardType: .numberPad)
                        .frame(maxWidth: 100)
                    CRTextField("Complemento", text: $vm.complement,
                                placeholder: "Sala 2")
                }
                CRTextField("Bairro *", text: $vm.neighborhood,
                            placeholder: "Centro", isRequired: true)
                HStack(spacing: CRSpacing.s3) {
                    CRTextField("Cidade *", text: $vm.city,
                                placeholder: "São Paulo", isRequired: true)
                    statePicker
                }
            }
            .disabled(vm.isFetchingCEP)
            .opacity(vm.isFetchingCEP ? 0.45 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: vm.isFetchingCEP)
        }
    }

    private var statePicker: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s2) {
            Text("Estado *").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
            Picker("Estado", selection: $vm.state) {
                ForEach(["SP","RJ","MG","RS","PR","SC","BA","PE","CE","GO","DF","AM",
                          "PA","MA","PI","AL","SE","RN","PB","MT","MS","TO","RO","AC",
                          "AP","RR"], id: \.self) {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(.menu)
            .frame(height: CRSize.inputMD)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.input)
            .overlay(RoundedRectangle(cornerRadius: CRRadius.input)
                .stroke(CRColor.Border.default, lineWidth: CRBorder.thin))
        }
        .frame(width: 100)
    }

    // ================================================================
    // MARK: - Step 5: Pricing  ← NOVO: máscara monetária brasileira
    // ================================================================
    private var pricingStep: some View {
        VStack(spacing: CRSpacing.s4) {
            CurrencyInputField(
                label: "Preço por hora *",
                cents: $vm.pricePerHourCents,
                helperText: "Média do mercado: R$ 80–200/hora",
                isRequired: true
            )
            CurrencyInputField(
                label: "Preço por dia (opcional)",
                cents: $vm.pricePerDayCents,
                helperText: "Recomendado: 6–8× o valor/hora"
            )
            CurrencyInputField(
                label: "Preço por mês (opcional)",
                cents: $vm.pricePerMonthCents
            )

            // Estimativa de receita
            if vm.pricePerHourCents > 0 {
                let h = Double(vm.pricePerHourCents) / 100.0
                VStack(alignment: .leading, spacing: CRSpacing.s2) {
                    Text("Estimativa de receita mensal")
                        .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("20h/semana").font(.crCaptionMD)
                                .foregroundColor(CRColor.Text.tertiary)
                            Text(brl(h * 80)).font(.crHeading5)
                                .foregroundColor(CRColor.Feedback.success)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("40h/semana").font(.crCaptionMD)
                                .foregroundColor(CRColor.Text.tertiary)
                            Text(brl(h * 160)).font(.crHeading5)
                                .foregroundColor(CRColor.Feedback.success)
                        }
                    }
                }
                .padding(CRSpacing.s3)
                .background(CRColor.Feedback.successLight)
                .cornerRadius(CRRadius.sm)
            }
        }
    }

    // ================================================================
    // MARK: - Step 6: Photos
    // ================================================================
    private var photosStep: some View {
        VStack(spacing: CRSpacing.s4) {
            Text("Anúncios com +4 fotos recebem 3× mais reservas.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary)
                .multilineTextAlignment(.center)

            PhotosPicker(selection: $vm.selectedPhotos,
                         maxSelectionCount: 10, matching: .images) {
                VStack(spacing: CRSpacing.s2) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(CRColor.Primary.default)
                    Text("Adicionar fotos")
                        .font(.crLabelMD).foregroundColor(CRColor.Primary.default)
                    Text("Máximo 10 fotos")
                        .font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
                }
                .frame(maxWidth: .infinity).frame(height: 120)
                .background(CRColor.Primary.lighter)
                .cornerRadius(CRRadius.md)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.md)
                    .stroke(CRColor.Primary.default,
                            style: StrokeStyle(lineWidth: 2, dash: [6])))
            }

            if !vm.previewImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible())], spacing: CRSpacing.s2) {
                    ForEach(vm.previewImages.indices, id: \.self) { i in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: vm.previewImages[i])
                                .resizable().scaledToFill()
                                .frame(height: 90).clipped()
                                .cornerRadius(CRRadius.sm)
                            Button { vm.removePhoto(at: i) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5).clipShape(Circle()))
                            }
                            .padding(4)
                        }
                    }
                }
            }
        }
    }

    // ================================================================
    // MARK: - Step 7: Availability
    // ================================================================
    private var availabilityStep: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s4) {
            Text("Defina os dias e horários disponíveis")
                .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
            ForEach(0..<7, id: \.self) { day in
                AvailabilityDayRow(day: day, slots: $vm.availabilitySlots)
            }
        }
    }

    // ================================================================
    // MARK: - Step 8: Preview
    // ================================================================
    private var previewStep: some View {
        VStack(spacing: CRSpacing.s4) {
            Text("Revise seu anúncio")
                .font(.crHeading4).foregroundColor(CRColor.Text.primary)
            CRInfoRow(icon: "building.2",  label: "Título",
                      value: vm.title)
            CRInfoRow(icon: "mappin",      label: "Local",
                      value: "\(vm.neighborhood), \(vm.city) – \(vm.state)")
            CRInfoRow(icon: "clock",       label: "Preço/hora",
                      value: brl(Double(vm.pricePerHourCents) / 100.0))
            CRInfoRow(icon: "photo",       label: "Fotos",
                      value: "\(vm.previewImages.count) foto(s)")
            CRInfoRow(icon: "checkmark.circle", label: "Equipamentos",
                      value: "\(vm.selectedAmenityIds.count) item(s)")
            CRInfoRow(icon: "person.2",    label: "Especialidades",
                      value: vm.specialties.isEmpty
                             ? "Não informado"
                             : vm.specialties.prefix(3).joined(separator: ", "))
            Text("Após publicação, seu anúncio ficará ativo imediatamente.")
                .font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers
    private func brl(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.numberStyle = .currency
        f.currencySymbol = "R$"
        return f.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}

// ============================================================
// MARK: - Amenity Chip Button
// ============================================================
private struct AmenityChipButton: View {
    let amenity: Amenity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: amenity.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : CRColor.Primary.default)
                Text(amenity.name)
                    .font(.crLabelSM)
                    .foregroundColor(isSelected ? .white : CRColor.Text.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, CRSpacing.s3)
            .padding(.vertical, CRSpacing.s2)
            .background(isSelected ? CRColor.Primary.default : CRColor.Surface.primary)
            .cornerRadius(CRRadius.full)
            .overlay(RoundedRectangle(cornerRadius: CRRadius.full)
                .stroke(isSelected ? CRColor.Primary.default : CRColor.Border.default,
                        lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - Add Custom Amenity Sheet
// ============================================================
struct AddCustomAmenitySheet: View {
    @ObservedObject var vm: CreateListingViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var category: Amenity.AmenityCategory = .equipment
    @State private var isSaving = false
    @State private var saveError: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CRSpacing.s5) {

                    // Icon preview
                    ZStack {
                        Circle()
                            .fill(CRColor.Primary.lighter)
                            .frame(width: 72, height: 72)
                        Image(systemName: iconForCategory(category))
                            .font(.system(size: 28))
                            .foregroundColor(CRColor.Primary.default)
                    }
                    .padding(.top, CRSpacing.s4)

                    CRTextField("Nome do equipamento *", text: $name,
                                placeholder: "Ex: Ultrassom de alta frequência",
                                isRequired: true,
                                helperText: "Será visível para todos os locatários")

                    // Category picker
                    VStack(alignment: .leading, spacing: CRSpacing.s2) {
                        Text("Categoria").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                        VStack(spacing: CRSpacing.s2) {
                            ForEach(Amenity.AmenityCategory.allCases, id: \.self) { cat in
                                Button { withAnimation { category = cat } } label: {
                                    HStack(spacing: CRSpacing.s3) {
                                        Image(systemName: cat.categoryIcon)
                                            .frame(width: 20)
                                            .foregroundColor(category == cat
                                                             ? CRColor.Primary.default
                                                             : CRColor.Icon.secondary)
                                        Text(cat.label)
                                            .font(.crBodyBase)
                                            .foregroundColor(CRColor.Text.primary)
                                        Spacer()
                                        if category == cat {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(CRColor.Primary.default)
                                        }
                                    }
                                    .padding(CRSpacing.s3)
                                    .background(category == cat
                                                ? CRColor.Primary.lighter
                                                : CRColor.Surface.primary)
                                    .cornerRadius(CRRadius.sm)
                                    .overlay(RoundedRectangle(cornerRadius: CRRadius.sm)
                                        .stroke(category == cat
                                                ? CRColor.Primary.default
                                                : CRColor.Border.default, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let err = saveError {
                        Text(err).font(.crCaptionMD).foregroundColor(CRColor.Feedback.error)
                    }

                    CRButton("Adicionar equipamento", variant: .primary, size: .lg,
                             icon: "plus", isLoading: isSaving,
                             isFullWidth: true) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
                .padding(CRSpacing.screenHorizontal)
            }
            .background(CRColor.Background.secondary.ignoresSafeArea())
            .navigationTitle("Novo equipamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        saveError = nil
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let newAmenity = await vm.addCustomAmenity(name: trimmed, category: category)
        isSaving = false
        if newAmenity != nil {
            dismiss()
        } else {
            saveError = "Não foi possível salvar. Tente novamente."
        }
    }

    private func iconForCategory(_ cat: Amenity.AmenityCategory) -> String {
        switch cat {
        case .equipment:      return "stethoscope"
        case .infrastructure: return "wifi"
        case .service:        return "person.2.fill"
        case .safety:         return "lock.shield"
        }
    }
}

// ============================================================
// MARK: - Currency Input Field  (máscara R$ x.xxx,xx)
// ============================================================
struct CurrencyInputField: View {
    let label: String
    @Binding var cents: Int
    var helperText: String? = nil
    var isRequired: Bool = false

    @State private var displayText: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s2) {
            HStack(spacing: 3) {
                Text(label).font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                if isRequired {
                    Text("*").font(.crLabelMD).foregroundColor(CRColor.Feedback.error)
                }
            }

            HStack(spacing: 0) {
                Text("R$")
                    .font(.crBodyBase)
                    .foregroundColor(focused ? CRColor.Text.primary : CRColor.Text.tertiary)
                    .padding(.leading, 12)
                    .padding(.trailing, 6)

                TextField("0,00", text: $displayText)
                    .keyboardType(.numberPad)
                    .font(.crBodyBase)
                    .focused($focused)
                    .onChange(of: displayText) { _, newVal in
                        let digits = String(newVal.filter(\.isNumber).prefix(9))
                        let centsVal = Int(digits) ?? 0
                        cents = centsVal
                        let formatted = formatCents(centsVal)
                        if formatted != newVal { displayText = formatted }
                    }
                    .onChange(of: focused) { _, isFocused in
                        if isFocused && cents == 0 {
                            displayText = ""
                        } else if !isFocused && displayText.isEmpty {
                            displayText = formatCents(0)
                        }
                    }
                    .padding(.trailing, 12)
            }
            .frame(height: CRSize.inputMD)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.input)
            .overlay(RoundedRectangle(cornerRadius: CRRadius.input)
                .stroke(focused ? CRColor.Primary.default : CRColor.Border.default,
                        lineWidth: focused ? 2 : CRBorder.thin))
            .onTapGesture { focused = true }

            if let helper = helperText {
                Text(helper).font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
            }
        }
        .onAppear {
            displayText = cents > 0 ? formatCents(cents) : ""
        }
    }

    private func formatCents(_ centsVal: Int) -> String {
        let value = Double(centsVal) / 100.0
        let f = NumberFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "0,00"
    }
}

// ============================================================
// MARK: - Availability Day Row
// ============================================================
private struct AvailabilityDayRow: View {
    let day: Int
    @Binding var slots: [AvailabilitySlot]

    private let dayNames = ["Domingo","Segunda","Terça","Quarta","Quinta","Sexta","Sábado"]
    private var slot: AvailabilitySlot? { slots.first { $0.weekday == day } }
    private var isAvailable: Bool { slot?.isAvailable ?? false }

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            Toggle("", isOn: Binding(
                get: { isAvailable },
                set: { newVal in
                    if let i = slots.firstIndex(where: { $0.weekday == day }) {
                        slots[i].isAvailable = newVal
                    } else {
                        slots.append(AvailabilitySlot(
                            id: UUID().uuidString, weekday: day,
                            startTime: "08:00", endTime: "18:00",
                            isAvailable: newVal))
                    }
                }
            ))
            .tint(CRColor.Primary.default)
            .labelsHidden()

            Text(dayNames[day])
                .font(.crLabelMD)
                .foregroundColor(isAvailable ? CRColor.Text.primary : CRColor.Text.tertiary)
                .frame(width: 70, alignment: .leading)

            if isAvailable {
                HStack {
                    Text(slot?.startTime ?? "08:00").font(.crBodySM)
                    Text("–").font(.crBodySM).foregroundColor(CRColor.Text.tertiary)
                    Text(slot?.endTime   ?? "18:00").font(.crBodySM)
                }
                .padding(.horizontal, CRSpacing.s3)
                .padding(.vertical, CRSpacing.s1)
                .background(CRColor.Primary.lighter)
                .cornerRadius(CRRadius.full)
            } else {
                Text("Fechado").font(.crBodySM).foregroundColor(CRColor.Text.tertiary)
            }
        }
        .padding(CRSpacing.s3)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.sm)
        .animation(CRAnimation.easeNormal, value: isAvailable)
    }
}

// ============================================================
// MARK: - Setup Progress Bar
// ============================================================
private struct SetupProgressBar: View {
    let currentStep: Int; let totalSteps: Int
    var progress: CGFloat { CGFloat(currentStep + 1) / CGFloat(totalSteps) }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(CRColor.Neutral.n200).frame(height: 4)
                Rectangle().fill(CRColor.Primary.default)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(CRAnimation.easeNormal, value: progress)
            }
        }
        .frame(height: 4)
    }
}

// ============================================================
// MARK: - Create Listing Step
// ============================================================
enum CreateListingStep: Int, CaseIterable {
    case basicInfo, details, amenities, location, pricing, photos, availability, preview

    var title: String {
        switch self {
        case .basicInfo:    return "Informações básicas"
        case .details:      return "Especialidades"
        case .amenities:    return "Equipamentos"
        case .location:     return "Localização"
        case .pricing:      return "Preços"
        case .photos:       return "Fotos"
        case .availability: return "Disponibilidade"
        case .preview:      return "Revisão"
        }
    }
    var subtitle: String {
        switch self {
        case .basicInfo:    return "Descreva seu espaço"
        case .details:      return "Para quais especialidades?"
        case .amenities:    return "O que está disponível?"
        case .location:     return "Onde fica o espaço?"
        case .pricing:      return "Quanto vai cobrar?"
        case .photos:       return "Mostre seu espaço"
        case .availability: return "Quando está disponível?"
        case .preview:      return "Tudo certo?"
        }
    }
}

// ============================================================
// MARK: - ViaCEP Response
// ============================================================
private struct ViaCEPResponse: Decodable {
    let logradouro: String?
    let bairro: String?
    let localidade: String?
    let uf: String?
    let erro: Bool?
}

// ============================================================
// MARK: - CreateListingViewModel
// ============================================================
@MainActor
final class CreateListingViewModel: ObservableObject {

    // Navigation
    @Published var step: Int = 0
    var currentStep: CreateListingStep { CreateListingStep(rawValue: step) ?? .basicInfo }

    // Edit mode
    var editingListingId: String? = nil
    var isEditMode: Bool { editingListingId != nil }
    @Published var isLoadingListing = false

    // Owner ID (set from authService on appear)
    var ownerId: String = ""

    // ── Step 1: Basic Info ──────────────────────────────────
    @Published var title       = ""
    @Published var description = ""
    @Published var area        = ""
    @Published var capacity    = ""

    // ── Step 2: Specialties ─────────────────────────────────
    @Published var specialties: Set<String> = []
    @Published var rules = ""

    // ── Step 3: Amenities ───────────────────────────────────
    @Published var allAmenities: [Amenity]   = []
    @Published var selectedAmenityIds: Set<String> = []
    @Published var isLoadingAmenities = false
    @Published var showAddAmenitySheet = false

    // ── Step 4: Location ────────────────────────────────────
    @Published var zipCode      = ""
    @Published var street       = ""
    @Published var number       = ""
    @Published var complement   = ""
    @Published var neighborhood = ""
    @Published var city         = ""
    @Published var state        = "SP"
    @Published var isFetchingCEP = false
    @Published var cepError: String? = nil

    // ── Step 5: Pricing (stored in centavos) ─────────────────
    @Published var pricePerHourCents  = 0
    @Published var pricePerDayCents   = 0
    @Published var pricePerMonthCents = 0

    // ── Step 6: Photos ───────────────────────────────────────
    @Published var selectedPhotos: [PhotosPickerItem] = [] {
        didSet { Task { await loadPhotos() } }
    }
    @Published var previewImages: [UIImage] = []

    // ── Step 7: Availability ─────────────────────────────────
    @Published var availabilitySlots: [AvailabilitySlot] = []

    // ── Global state ─────────────────────────────────────────
    @Published var isLoading    = false
    @Published var errorMessage: String? = nil

    // MARK: - Navigation
    func nextStep() {
        if validateStep() && step < CreateListingStep.allCases.count - 1 { step += 1 }
    }
    func previousStep() { if step > 0 { step -= 1 } }

    // MARK: - Specialties
    func toggleSpecialty(_ spec: String) {
        if specialties.contains(spec) { specialties.remove(spec) }
        else { specialties.insert(spec) }
    }

    // MARK: - Amenities
    func toggleAmenityId(_ id: String) {
        if selectedAmenityIds.contains(id) { selectedAmenityIds.remove(id) }
        else { selectedAmenityIds.insert(id) }
    }

    func loadAmenities(userId: String) async {
        isLoadingAmenities = true
        allAmenities = (try? await SupabaseManager.shared.fetchAmenities(userId: userId))
                       ?? Amenity.defaults
        isLoadingAmenities = false
    }

    /// Cria amenity personalizado no banco, adiciona à lista local e seleciona.
    /// Retorna o amenity criado, ou nil se falhou.
    @discardableResult
    func addCustomAmenity(name: String, category: Amenity.AmenityCategory) async -> Amenity? {
        let icon = category.categoryIcon
        do {
            let created = try await SupabaseManager.shared
                .createAmenity(name: name, icon: icon, category: category.rawValue,
                               userId: ownerId)
            allAmenities.append(created)
            selectedAmenityIds.insert(created.id)
            return created
        } catch {
            // Fallback: cria localmente com ID temporário
            let local = Amenity(id: "custom_\(UUID().uuidString)", name: name,
                                icon: icon, category: category, isSystem: false,
                                createdBy: ownerId)
            allAmenities.append(local)
            selectedAmenityIds.insert(local.id)
            return local
        }
    }

    // MARK: - CEP Lookup (ViaCEP)
    func fetchCEP() async {
        let digits = zipCode.filter(\.isNumber)
        guard digits.count == 8 else { return }
        isFetchingCEP = true
        cepError = nil
        do {
            let url = URL(string: "https://viacep.com.br/ws/\(digits)/json/")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(ViaCEPResponse.self, from: data)
            if resp.erro == true {
                cepError = "CEP não encontrado. Verifique e preencha manualmente."
            } else {
                if let v = resp.logradouro, !v.isEmpty { street       = v }
                if let v = resp.bairro,     !v.isEmpty { neighborhood = v }
                if let v = resp.localidade, !v.isEmpty { city         = v }
                if let v = resp.uf,         !v.isEmpty { state        = v }
            }
        } catch {
            cepError = "Erro ao buscar CEP. Preencha o endereço manualmente."
        }
        isFetchingCEP = false
    }

    // MARK: - Photos
    func removePhoto(at index: Int) {
        previewImages.remove(at: index)
        if index < selectedPhotos.count { selectedPhotos.remove(at: index) }
    }

    private func loadPhotos() async {
        previewImages = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img  = UIImage(data: data) { previewImages.append(img) }
        }
    }

    // MARK: - Validation
    private func validateStep() -> Bool {
        errorMessage = nil
        switch currentStep {
        case .basicInfo:
            if title.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Título obrigatório."; return false
            }
            if description.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Descrição obrigatória."; return false
            }
        case .location:
            if street.isEmpty || city.isEmpty {
                errorMessage = "Preencha rua e cidade."; return false
            }
        case .pricing:
            if pricePerHourCents <= 0 {
                errorMessage = "Informe um preço por hora válido."; return false
            }
        default: break
        }
        return true
    }

    // MARK: - Resolve owner ID from Supabase auth session (fallback when onAppear fires too early)
    func resolvedOwnerId() async -> String {
        // Sempre lowercase — Supabase auth.uid()::text é lowercase e RLS compara como string
        if !ownerId.isEmpty { return ownerId.lowercased() }
        if let uid = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString {
            ownerId = uid.lowercased()
            return ownerId
        }
        return ""
    }

    // MARK: - Load For Editing
    /// Busca o listing existente e preenche todos os campos do formulário.
    func loadForEditing(listingId: String) async {
        isLoadingListing = true
        do {
            let listing = try await SupabaseManager.shared.fetchListing(id: listingId)
            populate(with: listing)
        } catch {
            errorMessage = "Não foi possível carregar o anúncio para edição."
        }
        isLoadingListing = false
    }

    /// Preenche os campos do ViewModel a partir de um Listing existente.
    func populate(with listing: Listing) {
        title       = listing.title
        description = listing.description
        area        = listing.area > 0 ? String(format: "%g", listing.area) : ""
        capacity    = listing.capacity > 0 ? "\(listing.capacity)" : ""
        specialties = Set(listing.specialties)
        rules       = listing.rules ?? ""

        // Address
        zipCode      = listing.address.zipCode ?? ""
        street       = listing.address.street
        number       = listing.address.number ?? ""
        complement   = listing.address.complement ?? ""
        neighborhood = listing.address.neighborhood ?? ""
        city         = listing.address.city
        state        = listing.address.state

        // Pricing (convert to centavos)
        pricePerHourCents  = Int((listing.pricePerHour  * 100).rounded())
        pricePerDayCents   = Int(((listing.pricePerDay  ?? 0) * 100).rounded())
        pricePerMonthCents = Int(((listing.pricePerMonth ?? 0) * 100).rounded())

        // Amenities: mark pre-selected by name match (IDs unknown at this point)
        // Will be re-matched after loadAmenities completes
        _pendingAmenityNames = listing.amenities
    }

    // Amenity names to pre-select once the amenities list is loaded
    var _pendingAmenityNames: [String] = []

    /// Aplica seleção de amenities por nome (chamado após loadAmenities).
    func applyPendingAmenitySelection() {
        guard !_pendingAmenityNames.isEmpty else { return }
        let names = Set(_pendingAmenityNames.map { $0.lowercased() })
        for amenity in allAmenities {
            if names.contains(amenity.name.lowercased()) {
                selectedAmenityIds.insert(amenity.id)
            }
        }
        _pendingAmenityNames = []
    }

    // MARK: - Publish / Update
    func publish(dismiss: () -> Void) async {
        isLoading = true
        errorMessage = nil

        let ownerIdResolved = await resolvedOwnerId()
        guard !ownerIdResolved.isEmpty else {
            errorMessage = "Usuário não autenticado. Feche e abra o app novamente."
            isLoading = false
            return
        }

        // Nomes dos amenities selecionados (para snapshot de exibição)
        let selectedAmenityNames = allAmenities
            .filter { selectedAmenityIds.contains($0.id) }
            .map { $0.name }

        // Apenas IDs reais do banco (exclui IDs locais que começam com prefixo fake)
        let realAmenityIds = allAmenities
            .filter { selectedAmenityIds.contains($0.id)
                      && !$0.id.hasPrefix("eq") && !$0.id.hasPrefix("in")
                      && !$0.id.hasPrefix("sv") && !$0.id.hasPrefix("custom_") }
            .map { $0.id }

        let address = AddressInfo(
            street: street, number: number,
            complement: complement.isEmpty ? nil : complement,
            neighborhood: neighborhood, city: city, state: state,
            zipCode: zipCode, latitude: nil, longitude: nil
        )

        do {
            if let editId = editingListingId {
                // ── MODO EDIÇÃO ──────────────────────────────────────
                let updatePayload = ListingUpdatePayload(
                    title: title,
                    description: description,
                    address: address,
                    price_per_hour: Double(pricePerHourCents) / 100.0,
                    price_per_day:  pricePerDayCents  > 0 ? Double(pricePerDayCents)  / 100.0 : nil,
                    price_per_month: pricePerMonthCents > 0 ? Double(pricePerMonthCents) / 100.0 : nil,
                    amenities: selectedAmenityNames,
                    specialties: Array(specialties),
                    equipment: selectedAmenityNames,
                    capacity: Int(capacity) ?? 1,
                    area: Double(area) ?? 0,
                    status: "active",
                    rules: rules.isEmpty ? nil : rules
                )
                try await SupabaseManager.shared.updateListing(id: editId, payload: updatePayload)

                // Re-upload fotos se novas foram selecionadas
                if !previewImages.isEmpty {
                    let imageURLs = try await SupabaseManager.shared.uploadListingImages(
                        images: previewImages,
                        ownerId: ownerIdResolved,
                        listingId: editId
                    )
                    if !imageURLs.isEmpty {
                        try await SupabaseManager.shared.updateListingImageURLs(
                            listingId: editId, urls: imageURLs
                        )
                    }
                }
            } else {
                // ── MODO CRIAÇÃO ─────────────────────────────────────
                let insertPayload = ListingInsertPayload(
                    owner_id: ownerIdResolved,
                    title: title,
                    description: description,
                    address: address,
                    price_per_hour: Double(pricePerHourCents) / 100.0,
                    price_per_day:  pricePerDayCents  > 0 ? Double(pricePerDayCents)  / 100.0 : nil,
                    price_per_month: pricePerMonthCents > 0 ? Double(pricePerMonthCents) / 100.0 : nil,
                    image_urls: [],
                    amenities: selectedAmenityNames,
                    specialties: Array(specialties),
                    equipment: selectedAmenityNames,
                    capacity: Int(capacity) ?? 1,
                    area: Double(area) ?? 0,
                    status: "active",
                    rules: rules.isEmpty ? nil : rules
                )
                let listingId = try await SupabaseManager.shared
                    .createListing(payload: insertPayload, amenityIds: realAmenityIds)

                if !previewImages.isEmpty {
                    let imageURLs = try await SupabaseManager.shared.uploadListingImages(
                        images: previewImages,
                        ownerId: ownerIdResolved,
                        listingId: listingId
                    )
                    if !imageURLs.isEmpty {
                        try await SupabaseManager.shared.updateListingImageURLs(
                            listingId: listingId, urls: imageURLs
                        )
                    }
                }
            }

            HapticFeedback.success()
            dismiss()
        } catch {
            errorMessage = isEditMode
                ? "Erro ao salvar alterações: \(error.localizedDescription)"
                : "Erro ao publicar: \(error.localizedDescription)"
            HapticFeedback.error()
        }
        isLoading = false
    }

    // MARK: - Save Draft
    func saveDraft(dismiss: () -> Void) async {
        isLoading = true
        errorMessage = nil

        let ownerIdResolved = await resolvedOwnerId()
        guard !ownerIdResolved.isEmpty else {
            errorMessage = "Usuário não autenticado. Feche e abra o app novamente."
            isLoading = false
            return
        }

        let address = AddressInfo(
            street: street, number: number,
            complement: complement.isEmpty ? nil : complement,
            neighborhood: neighborhood, city: city, state: state,
            zipCode: zipCode, latitude: nil, longitude: nil
        )

        let payload = ListingInsertPayload(
            owner_id: ownerIdResolved,
            title: title.isEmpty ? "Rascunho" : title,
            description: description,
            address: address,
            price_per_hour: max(Double(pricePerHourCents) / 100.0, 0.01),
            price_per_day:  pricePerDayCents  > 0 ? Double(pricePerDayCents)  / 100.0 : nil,
            price_per_month: pricePerMonthCents > 0 ? Double(pricePerMonthCents) / 100.0 : nil,
            image_urls: [],
            amenities: allAmenities.filter { selectedAmenityIds.contains($0.id) }.map(\.name),
            specialties: Array(specialties),
            equipment: [],
            capacity: Int(capacity) ?? 1,
            area: Double(area) ?? 0,
            status: "draft",
            rules: rules.isEmpty ? nil : rules
        )

        do {
            let listingId = try await SupabaseManager.shared.createListing(payload: payload, amenityIds: [])

            if !previewImages.isEmpty {
                let imageURLs = (try? await SupabaseManager.shared.uploadListingImages(
                    images: previewImages,
                    ownerId: ownerIdResolved,
                    listingId: listingId
                )) ?? []
                if !imageURLs.isEmpty {
                    try? await SupabaseManager.shared.updateListingImageURLs(
                        listingId: listingId, urls: imageURLs
                    )
                }
            }

            HapticFeedback.impact(.medium)
            dismiss()
        } catch {
            errorMessage = "Erro ao salvar rascunho: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

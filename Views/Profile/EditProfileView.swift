import SwiftUI
import PhotosUI

// MARK: - EditProfileView (UX 14)
struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter

    // Dados do perfil
    @State private var fullName = ""
    @State private var phone = ""
    @State private var professionalId = ""
    @State private var bio = ""

    // Pronome de tratamento (droplist — UX 14)
    @State private var selectedPronoun: Pronoun = .prefiroNaoInformar
    @State private var showPronounPicker = false

    // Foto de perfil — armazenada localmente (UX 14)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var localProfileImage: UIImage? = nil

    @State private var isSaving = false

    // Pronomes de tratamento disponíveis
    enum Pronoun: String, CaseIterable, Identifiable {
        case ele      = "Ele / Dele"
        case ela      = "Ela / Dela"
        case eles     = "Eles / Deles"
        case elas     = "Elas / Delas"
        case elx      = "Elx / Delx"
        case eleo     = "Eleo / Deleo"
        case prefiroNaoInformar = "Prefiro não informar"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(title: "Editar Perfil", onBack: { router.pop() })

            ScrollView {
                VStack(spacing: CRSpacing.xl) {
                    // ── Avatar com galeria do device (UX 14) ──
                    avatarSection
                        .padding(.top, CRSpacing.xl)

                    // ── Formulário ──
                    VStack(spacing: CRSpacing.base) {
                        CRTextField(
                            label: "Nome completo",
                            placeholder: "Seu nome",
                            text: $fullName,
                            icon: "person"
                        )

                        CRTextField(
                            label: "Telefone",
                            placeholder: "(11) 99999-9999",
                            text: $phone,
                            icon: "phone",
                            keyboardType: .phonePad
                        )

                        CRTextField(
                            label: "Registro profissional",
                            placeholder: "CRO/CRM/CREFITO...",
                            text: $professionalId,
                            icon: "doc.badge.checkmark"
                        )

                        // ── Pronome de tratamento ──
                        pronounField

                        // ── Bio ──
                        VStack(alignment: .leading, spacing: CRSpacing.xs) {
                            Text("Bio").font(.crLabelSmall).foregroundColor(.crTextSecondary)
                            TextEditor(text: $bio)
                                .font(.crBodyLarge)
                                .frame(height: 100)
                                .padding(CRSpacing.sm)
                                .background(Color.white)
                                .cornerRadius(CRRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CRRadius.md)
                                        .stroke(Color.crDivider, lineWidth: 1)
                                )
                        }
                    }

                    // ── Salvar ──
                    CRButton(title: "Salvar alterações", isLoading: isSaving) {
                        save()
                    }
                    .padding(.bottom, CRSpacing.xxxl)
                }
                .padding(.horizontal, CRSpacing.base)
            }
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
        .onAppear { loadCurrentData() }
        // Confirmar seleção de foto da galeria
        .onChange(of: selectedPhotoItem) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    localProfileImage = img
                    // Armazena localmente em UserDefaults como dados JPEG
                    if let jpegData = img.jpegData(compressionQuality: 0.75) {
                        UserDefaults.standard.set(jpegData, forKey: "cr_local_profile_photo")
                    }
                }
            }
        }
    }

    // MARK: - Avatar Section
    @ViewBuilder
    private var avatarSection: some View {
        ZStack(alignment: .bottomTrailing) {
            // Imagem local ou placeholder com iniciais
            if let img = localProfileImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.crPrimary.opacity(0.3), lineWidth: 2))
            } else {
                Circle()
                    .fill(Color.crPrimary.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(fullName.prefix(1)).uppercased())
                            .font(.crDisplay2)
                            .foregroundColor(.crPrimary)
                    )
                    .overlay(Circle().stroke(Color.crPrimary.opacity(0.3), lineWidth: 2))
            }

            // Botão para abrir galeria (PhotosPicker — UX 14)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                Circle()
                    .fill(Color.crPrimary)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }

    // MARK: - Pronoun Field
    @ViewBuilder
    private var pronounField: some View {
        VStack(alignment: .leading, spacing: CRSpacing.xs) {
            Text("Pronome de tratamento")
                .font(.crLabelSmall)
                .foregroundColor(.crTextSecondary)

            Button {
                showPronounPicker = true
            } label: {
                HStack(spacing: CRSpacing.sm) {
                    Image(systemName: "person.2")
                        .font(.system(size: 16))
                        .foregroundColor(.crTextTertiary)
                        .frame(width: 20)

                    Text(selectedPronoun.rawValue)
                        .font(.crBodyLarge)
                        .foregroundColor(selectedPronoun == .prefiroNaoInformar ? .crTextTertiary : .crTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.crTextTertiary)
                }
                .padding(.horizontal, CRSpacing.base)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(CRRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CRRadius.md)
                        .stroke(Color.crDivider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Pronome de tratamento",
                isPresented: $showPronounPicker,
                titleVisibility: .visible
            ) {
                ForEach(Pronoun.allCases) { pronoun in
                    Button(pronoun.rawValue) {
                        selectedPronoun = pronoun
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    // MARK: - Helpers
    private func loadCurrentData() {
        fullName = authVM.currentUser?.fullName ?? ""
        phone = authVM.currentUser?.phone ?? ""
        professionalId = authVM.currentUser?.professionalId ?? ""
        bio = authVM.currentUser?.bio ?? ""

        // Carregar foto salva localmente
        if let data = UserDefaults.standard.data(forKey: "cr_local_profile_photo"),
           let img = UIImage(data: data) {
            localProfileImage = img
        }

        // Carregar pronome salvo
        if let saved = UserDefaults.standard.string(forKey: "cr_pronoun"),
           let pronoun = Pronoun(rawValue: saved) {
            selectedPronoun = pronoun
        }
    }

    private func save() {
        isSaving = true
        // Salva pronome em UserDefaults
        UserDefaults.standard.set(selectedPronoun.rawValue, forKey: "cr_pronoun")
        // Simula save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSaving = false
            router.pop()
        }
    }
}

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var phone = ""
    @State private var professionalId = ""
    @State private var bio = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            // dismiss(), não router.pop() -- essa tela abre como .sheet
            // (Features/Profile/ProfileView.swift), não empilhada numa
            // NavigationStack. router.pop() mexe em router.navigationPath,
            // que não tem nada a ver com apresentação de sheet -- por isso
            // nunca fechava, com ou sem sucesso no salvamento (reportado
            // ao vivo: "não fecha automaticamente o componente").
            CRNavigationHeader(title: "Editar Perfil", onBack: { dismiss() })

            ScrollView {
                VStack(spacing: CRSpacing.xl) {
                    // Avatar — a área inteira (foto + selo da câmera) é o alvo de
                    // toque do PhotosPicker, não só o selinho pequeno; selinho
                    // separado como um item "irmão" no ZStack tinha risco de
                    // hit-testing perder o toque (foi o que aconteceu ao testar).
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                } else if let urlString = authVM.currentUser?.profileImageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let image) = phase {
                                            image.resizable().scaledToFill()
                                        } else {
                                            Circle().fill(Color.crPrimary.opacity(0.2))
                                                .overlay(Text(String(fullName.prefix(1))).font(.crDisplay2).foregroundColor(.crPrimary))
                                        }
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.crPrimary.opacity(0.2))
                                        .overlay(Text(String(fullName.prefix(1))).font(.crDisplay2).foregroundColor(.crPrimary))
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .contentShape(Circle())

                            Circle().fill(Color.crPrimary).frame(width: 32, height: 32)
                                .overlay(Image(systemName: "camera.fill").font(.system(size: 14)).foregroundColor(.white))
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                profileImage = img
                            }
                        }
                    }
                    .padding(.top, CRSpacing.xl)

                    VStack(spacing: CRSpacing.base) {
                        CRTextField(label: "Nome completo", placeholder: "Seu nome", text: $fullName, icon: "person")
                        CRTextField(label: "Telefone", placeholder: "(11) 99999-9999", text: $phone, icon: "phone", keyboardType: .phonePad)
                        CRTextField(label: "Registro profissional", placeholder: "CRO/CRM/CREFITO...", text: $professionalId, icon: "doc.badge.checkmark")
                        VStack(alignment: .leading, spacing: CRSpacing.xs) {
                            Text("Bio").font(.crLabelSmall).foregroundColor(.crTextSecondary)
                            TextEditor(text: $bio)
                                .font(.crBodyLarge)
                                .frame(height: 100)
                                .padding(CRSpacing.sm)
                                .background(Color.white)
                                .cornerRadius(CRRadius.md)
                                .overlay(RoundedRectangle(cornerRadius: CRRadius.md).stroke(Color.crDivider, lineWidth: 1))
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.crBodySmall)
                            .foregroundColor(.crError)
                            .multilineTextAlignment(.center)
                    }

                    CRButton(title: "Salvar alterações", isLoading: isSaving) {
                        Task { await save() }
                    }
                    .padding(.bottom, CRSpacing.xxxl)
                }
                .padding(.horizontal, CRSpacing.base)
            }
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
        .onAppear {
            fullName = authVM.currentUser?.fullName ?? ""
            phone = authVM.currentUser?.phoneNumber ?? ""
            professionalId = authVM.currentUser?.registrationNumber ?? ""
            bio = authVM.currentUser?.bio ?? ""
        }
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        await authVM.updateBasicProfile(
            fullName: fullName, phoneNumber: phone,
            registrationNumber: professionalId, bio: bio,
            profileImage: profileImage
        )
        isSaving = false
        if let error = authVM.errorMessage {
            errorMessage = error
            HapticFeedback.error()
        } else {
            HapticFeedback.success()
            dismiss()
        }
    }
}

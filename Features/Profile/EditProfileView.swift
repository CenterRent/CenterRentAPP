import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var fullName = ""
    @State private var phone = ""
    @State private var professionalId = ""
    @State private var bio = ""
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(title: "Editar Perfil", onBack: { router.pop() })

            ScrollView {
                VStack(spacing: CRSpacing.xl) {
                    // Avatar
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.crPrimary.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(Text(String(fullName.prefix(1))).font(.crDisplay2).foregroundColor(.crPrimary))
                        Button {
                            // Photo picker
                        } label: {
                            Circle().fill(Color.crPrimary).frame(width: 32, height: 32)
                                .overlay(Image(systemName: "camera.fill").font(.system(size: 14)).foregroundColor(.white))
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

                    CRButton(title: "Salvar alterações", isLoading: isSaving) {
                        isSaving = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isSaving = false
                            router.pop()
                        }
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
}

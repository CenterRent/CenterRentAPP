import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var locationManager = LocationPermissionManager()

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()

            VStack(spacing: CRSpacing.xxl) {
                Spacer()

                // Illustration
                ZStack {
                    Circle().fill(Color.crPrimary.opacity(0.1)).frame(width: 180, height: 180)
                    Circle().fill(Color.crPrimary.opacity(0.2)).frame(width: 130, height: 130)
                    Image(systemName: "location.fill")
                        .font(.system(size: 64)).foregroundColor(.crPrimary)
                }

                VStack(spacing: CRSpacing.md) {
                    Text("Habilitar serviços de\nlocalização")
                        .font(.crH2).foregroundColor(.crPrimary)
                        .multilineTextAlignment(.center)
                    Text("Para te mostrar os melhores espaços e equipamentos próximos a você, precisamos da sua localização.")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: CRSpacing.md) {
                    PermissionFeatureRow(icon: "map.fill", text: "Espaços próximos a você")
                    PermissionFeatureRow(icon: "clock.fill", text: "Tempo de deslocamento estimado")
                    PermissionFeatureRow(icon: "bell.fill", text: "Alertas de disponibilidade na sua área")
                }
                .padding(CRSpacing.base)
                .background(Color.white)
                .cornerRadius(CRRadius.lg)
                .crShadowSoft()
                .padding(.horizontal, CRSpacing.xl)

                Spacer()

                VStack(spacing: CRSpacing.md) {
                    CRButton(title: "Habilitar localização") {
                        locationManager.requestPermission()
                    }
                    Button("Agora não") {
                        router.setRoot(.main)
                    }
                    .font(.crLabel).foregroundColor(.crTextSecondary)
                }
                .padding(.horizontal, CRSpacing.xl)
                .padding(.bottom, CRSpacing.xxxl)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorizedWhenInUse || status == .authorizedAlways || status == .denied {
                router.popToRoot()
            }
        }
    }
}

struct PermissionFeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: CRSpacing.md) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.crPrimary).frame(width: 24)
            Text(text).font(.crBody).foregroundColor(.crTextSecondary)
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.crSuccess)
        }
    }
}

final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authorizationStatus = manager.authorizationStatus }
    }
}

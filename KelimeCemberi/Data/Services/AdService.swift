import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
final class AdService: NSObject, FullScreenContentDelegate {
    static let shared = AdService()
    private(set) var canRequestAds = false
    private var didInitialize = false
    private var interstitial: InterstitialAd?
    private var isLoadingInterstitial = false

    private override init() { super.init() }

    func prepare() async {
        guard !didInitialize else { return }
#if canImport(UserMessagingPlatform)
        let parameters = RequestParameters()
        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in
                ConsentForm.loadAndPresentIfRequired(from: nil) { _ in
                    Task { @MainActor in
                        self.canRequestAds = ConsentInformation.shared.canRequestAds
                        self.startIfAllowed()
                        continuation.resume()
                    }
                }
            }
        }
#else
        canRequestAds = true
        startIfAllowed()
#endif
    }

    private func startIfAllowed() {
        guard canRequestAds, !didInitialize else { return }
        didInitialize = true
        MobileAds.shared.start()
        Task { await loadInterstitial() }
    }

    func showInterstitial() async {
        guard canRequestAds else { return }
        if interstitial == nil { await loadInterstitial() }
        guard let interstitial, let controller = rootViewController else { return }
        self.interstitial = nil
        interstitial.present(from: controller)
    }

    private func loadInterstitial() async {
        guard canRequestAds, !isLoadingInterstitial, interstitial == nil else { return }
        isLoadingInterstitial = true
        defer { isLoadingInterstitial = false }
        do {
            let ad = try await InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: Request())
            ad.fullScreenContentDelegate = self
            interstitial = ad
        } catch { interstitial = nil }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { Task { await loadInterstitial() } }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { Task { await loadInterstitial() } }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
    }
}

struct AdBannerSlot: View {
    let isPremium: Bool
    @State private var isReady = false

    var body: some View {
        Group {
            if !isPremium, isReady {
                AdMobBannerView().frame(height: 60).accessibilityLabel("Reklam")
            }
        }
        .task {
            guard !isPremium else { return }
            await AdService.shared.prepare()
            isReady = AdService.shared.canRequestAds
        }
    }
}

private struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width - 32))
        banner.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        banner.rootViewController = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: \.isKeyWindow) }
}
#else
struct AdBannerSlot: View {
    let isPremium: Bool
    var body: some View { EmptyView() }
}
#endif

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
    private var preparationTask: Task<Void, Never>?
    private var isPresenting = false

    private override init() { super.init() }

    func prepare() async {
        guard !didInitialize else { return }
        if let preparationTask {
            await preparationTask.value
            return
        }
        let task = Task { @MainActor in await self.requestConsent() }
        preparationTask = task
        await task.value
        preparationTask = nil
    }

    private func requestConsent() async {
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
        guard canRequestAds, !isPresenting else { return }
        // A missed preload must never hold the results screen behind a network request.
        guard interstitial != nil else {
            Task { await loadInterstitial() }
            return
        }
        guard let interstitial, let controller = rootViewController else { return }
        self.interstitial = nil
        isPresenting = true
        interstitial.present(from: controller)
    }

    private func loadInterstitial() async {
        guard canRequestAds, !isLoadingInterstitial, interstitial == nil else { return }
        isLoadingInterstitial = true
        defer { isLoadingInterstitial = false }
        do {
            let ad = try await InterstitialAd.load(with: AdUnitIDs.interstitial, request: Request())
            ad.fullScreenContentDelegate = self
            interstitial = ad
        } catch { interstitial = nil }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isPresenting = false
        Task { await loadInterstitial() }
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isPresenting = false
        Task { await loadInterstitial() }
    }

    private var rootViewController: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              var controller = scene.keyWindow?.rootViewController else { return nil }
        while let presented = controller.presentedViewController { controller = presented }
        return controller
    }
}

struct AdBannerSlot: View {
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                AdMobBannerView().frame(height: 60).accessibilityLabel("Reklam")
            }
        }
        .task {
            await AdService.shared.prepare()
            isReady = AdService.shared.canRequestAds
        }
    }
}

private struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width - 32))
        banner.adUnitID = AdUnitIDs.banner
        banner.rootViewController = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

private enum AdUnitIDs {
    static let interstitial = Bundle.main.object(forInfoDictionaryKey: "GADInterstitialAdUnitIdentifier") as? String
        ?? "ca-app-pub-3940256099942544/4411468910"
    static let banner = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitIdentifier") as? String
        ?? "ca-app-pub-3940256099942544/2435281174"
}

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: \.isKeyWindow) }
}
#else
struct AdBannerSlot: View {
    var body: some View { EmptyView() }
}
#endif

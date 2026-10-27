# Doğrulama — 27 Ekim 2026

- Flutter 3.44.4 / Dart 3.12.2; Xcode 26.3.
- `dart analyze lib test integration_test test_driver`: temiz.
- `flutter test`: 19 test geçti (oyun motoru, veri paketleri, seviye kilitleri, reklam sayaçları, ödülün tek sefer işlenmesi, mağaza, 320×568 / 393×852 / 430×932 ekranlarda klavyeli/klavyesiz kontroller).
- iPhone 17 Pro / iOS 26.3 simülatörü: uçtan uca senaryo geçti. Normal uygulamada ayrıca karşılama → menü → oyun → ARABA doğru cevabı / 100 puan → süre sonu sonuçları → ana menü elle doğrulandı.
- Android 15 / API 35 / ARM64 emülatörü: uçtan uca senaryo 33 saniyede geçti. Dil seçimi, kilitli seviye, A1, ipucu/pas/atla, üç doğru/seri, klavye, yanlış/pas inceleme, yeniden oynama, duraklatma ve normal çembere dönüş doğrulandı.
- iOS simülatör uygulaması ve Android debug APK başarıyla derlendi. Normal uygulamalar iki emülatöre kuruldu ve açıldı. Fiziksel iPhone'a kurulum yapılmadı.

## Test ortamı notları

Android'in eski önizleme imajı yerine kararlı API 35 kullanıldı. Emülatör testinde Skia/yazılımsal çizim kullanıldı; üretim Android manifestinde Impeller kapatılmadı. Hata ayıklama aracının eski VM adresine bağlandığı denemelerde güncel VM adresine ADB yönlendirmesi kullanıldı. Sürekli canlı sayaç nedeniyle UI testleri sınırlı frame beklemeleri kullanır; UI testindeki süre uzun tutulur, gerçek 60/120 saniye davranışı ayrı motor testleriyle kontrol edilir.

Android kısa ses efektlerinin konum takibi kapatıldı: SoundPool tamamlanma sinyali göndermediğinde gereksiz sürekli frame üretimi oluşuyordu. Sesli UI testinin sonunda oynatıcılar da temizlenir.

## Yayın sınırı

Bu teslim mağaza yayını değildir. AdMob test kimlikleri gelir üretmez. Gerçek reklam kimlikleri/UMP, gizlilik ve içerik-lisans denetimi, Android upload-key/iOS dağıtım imzası ve gerçek cihaz performans-ses kontrolü tamamlanmalıdır. Android release/R8 denemesi düşük bellekli Mac'teki emülatör doğrulamasına öncelik vermek için sonlandırıldı; release dağıtımı doğrulanmış sayılmaz. Eski SwiftUI kayıtları otomatik aktarılmaz. Kelime sayıları ve seviye doğrulama açıkları README'de açıkça belirtilir.

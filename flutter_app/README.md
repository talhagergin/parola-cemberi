# Parola Çemberi — Flutter

iOS ve Android için ortak neon tasarım ve ortak oyun motoru. Eski SwiftUI projesi korunur; bu klasör yeni çapraz platform uygulamasıdır.

## Çalıştırma

Flutter 3.44.4 / Dart 3.12.2 ile doğrulandı. Android minimum API 24, iOS minimum sürümü Xcode proje ayarlarında tanımlıdır. Xcode, Android SDK ve bir Android emülatörü gerekir. iOS eklentileri Swift Package Manager ile çözülür.

```sh
flutter pub get
flutter devices
flutter run -d <cihaz-kimliği>
```

Projeyi iCloud/OneDrive dışında yerel bir klasörde derleyin. iCloud'un dosya tahliyesi derlemeyi durdurabilir ve Finder ek öznitelikleri iOS imzalama hatasına yol açabilir. Kaynaklar aynı Git deposunda kalır; ayrı bir yerel clone kullanılabilir.

```sh
dart analyze lib test integration_test test_driver
flutter test
PAROLA_TEST_PLATFORM=ios flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d <ios-simulator> --dart-define=DISABLE_ADS=true
PAROLA_TEST_PLATFORM=android flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d <android-emulator> --dart-define=DISABLE_ADS=true
```

Test sürücüsü iOS ekran görüntülerini `verification/ios` altında üretir. Android ekran görüntüleri `adb shell screencap` ile alınır; Flutter'ın görüntü yüzeyine dönüştürme özelliği bazı emülatör grafik sürücülerinde takılabilir. Aynı durumda Android test komutuna `--no-enable-impeller --enable-software-rendering` eklenebilir; bu yalnızca emülatör testine yönelik bir geçici çözümdür. İkon ve açılış ekranını yeniden üretmek için `dart run flutter_launcher_icons` ve `dart run flutter_native_splash:create` çalıştırın.

## Korunan kurallar

- Klasik 120 saniye / 28 harf, Hızlı Tur 60 saniye / 10 harf, Türkiye gününe göre sabit Günlük Çember.
- Pas ilk geçişten sonra yeniden sorulur; ikinci pas turu tamamlar. Atla geri gelmez. 3 ipucu, 2 atla hakkı.
- Doğru/yanlış, seri puanları, alev göstergesi, süre uyarısı ve 7 özgün ses efekti.
- Sonuçta yanlışlar, pas/boş ve atlanan kelimeler doğru cevaplarıyla listelenir. Paylaş butonu yoktur.
- Altı dilde aynı çember: İngilizce, İtalyanca, Almanca, Felemenkçe, İspanyolca, Azerbaycanca. A1/B1/C1 açık, A2/B2/C2 kilitli. Abonelik veya gerçek para satışı yoktur.
- Sorusu bulunmayan harf turda oluşturulmaz. X ve Ğ çemberden çıkarılmıştır; kelimelerin içindeki karakterler korunur.
- 5 avatar, 5 çember teması, oyun altınıyla mağaza; yerel istatistikler ve kalıcı ayarlar.
- Yeni Flutter uygulamasının kayıtları SwiftUI uygulamasından otomatik aktarılmaz. Yeni platform kimlikleri eski kurulumu silmez.

## İçerik sınırları

Var olan paketler değişmeden taşınmıştır; bu çalışma kelime sayılarını yapay olarak artırmaz. Türkçe 5.000; İngilizce 3.612; İtalyanca 874; Almanca 740; Felemenkçe 500; İspanyolca ve Azerbaycanca 180'er kayıt içerir. Son iki paket editoryal başlangıç paketidir, doğrulanmış CEFR korpusu değildir. Her seviyeye ek 1.000 kelime hedefi henüz tamamlanmamıştır. Kaynak/provenans ve lisans denetimleri ana deponun `docs` dizinindedir.

## Reklam ve mağazaya çıkış

AdMob SDK her iki platformda bağlıdır. Normal turlar ve A1 dışındaki dil seviyeleri 2 turda, A1 3 turda bir geçiş reklamı dener. Reklam hazır değilse sonuç ekranı bekletilmez. Menü altına banner eklenir; oyun sırasında banner yoktur. Sıklık sayaçları yeniden açılışta korunur.

**Şu anda yalnızca Google test reklamları kullanılır; gelir üretmez.** Gerçek yayın için:

1. AndroidManifest.xml ve iOS Info.plist içindeki AdMob uygulama kimliklerini kendi kimliklerinizle değiştirin.
2. `ADMOB_INTERSTITIAL_IOS`, `ADMOB_INTERSTITIAL_ANDROID`, `ADMOB_BANNER_IOS`, `ADMOB_BANNER_ANDROID` değerlerini `--dart-define` ile sağlayın. Gerçek birimler UMP izin akışından geçer; test birimlerinde yayıncı formu aranmaz.
3. AdMob gizlilik mesajları, uygulama-ads.txt, herkese açık gizlilik politikası, mağaza veri güvenliği/gizlilik bildirimleri ve yaş hedeflemesini tamamlayın. Takip/IDFA erişimi istenirse ATT akışını ayrıca değerlendirin; uygulama şu anda ATT istemez.
4. Android release imzası şu an geliştirme anahtarıdır: Play için ayrı upload key ve güvenli imza yapılandırması gerekir. iOS dağıtım imzası ve mağaza uygulama kayıtları da yayın öncesi tamamlanmalıdır.
5. Gerçek cihaz ses/performans, çevrimdışı kullanım, küçük ekranlar ve yayın içeriği son denetimden geçirilmelidir. Bu bir mağaza yayını değildir.

## Ses ve varlıklar

Android: ön yüklenen düşük gecikmeli SoundPool (`audioplayers`). iOS: ön yüklenen AVAudioPlayer için küçük bir platform köprüsü; sessiz anahtarında da oyun sesi çalabilen playback oturumu. Efektler `tool/generate_audio.py` ile üretilir. Nunito fontunun lisansı `assets/fonts/OFL.txt` dosyasındadır. Mevcut ikon ve avatarlar korunur.

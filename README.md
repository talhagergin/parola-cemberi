# Parola Çemberi

Türk alfabesinin 29 harfiyle oynanan, iOS 17+ SwiftUI parola yarışması. Proje klasik, hızlı, kategori ve günlük oyun modlarının yanında avatar, çember teması, oyun içi mağaza, reklam ve Premium abonelik altyapısını içerir.

## Mimari

- `App`: uygulama başlangıcı ve başlangıç yükleme durumu
- `Core`: merkezi modeller, Türkçe dil kuralları ve tema token’ları
- `Data`: bundle JSON yükleme, toleranslı doğrulama ve repository sınırı
- `Features`: onboarding, menü, mod/kategori seçimi, oyun ve sonuç ekranları
- `Components`: tekrar kullanılabilir SwiftUI parçaları
- `Resources`: asset, ses ve değiştirilmeden taşınan soru paketi
- `KelimeCemberiTests`: temel model ve gerçek veri paketi testleri

Bağımlılık yönü View → GameEngine → domain servisleri → Repository → Loader şeklindedir. View katmanı JSON okumaz ve oyun kuralları `GameEngine` içinde tek bir güvenilir state üzerinden yönetilir.

## Sprint 1 oyun kuralları

- Doğru, yanlış, pas, ipucu ve erişilemeyen harf durumları
- İlk turdan sonra pas kuyruğuna geri dönüş ve harf başına maksimum pas sayısı
- Türkçe locale ile noktalama, boşluk, apostrof ve alternatif cevap normalizasyonu
- Merkezi skor, seri, ipucu cezası, tekrar ziyaret ve kalan süre bonusları
- View yaşam döngüsünden bağımsız, pause/resume destekli actor tabanlı countdown
- Aynı oturumda soru tekrarını ve yakın geçmiş tekrarını azaltan seçim servisi

## Sprint 2 oyun ekranı

- 29 harfi farklı ekran genişliklerine göre konumlandıran responsive SwiftUI çemberi
- Aktif/doğru/yanlış/pas/bekleyen durumlarını renk ve erişilebilirlik metniyle gösteren harf kutuları
- Dairesel süre göstergesi, puan, seri ve doğru cevap HUD’u
- Kategori, zorluk, harf sayısı ve genişletilmiş ipucu içeren glassmorphism soru kartı
- Türkçe cevap alanı, return ile gönderme, pas ve cevapla kontrolleri
- Pause overlay’i, uygulama arka plana geçtiğinde otomatik duraklatma ve tur tamamlanma overlay’i
- Reduce Motion tercihini gözeten pulse ve soru geçiş animasyonları

## Sprint 3 uygulama akışı

- Animasyonlu splash ve yalnızca ilk açılışta gösterilen üç sayfalı onboarding
- Ana menü ile klasik, hızlı ve kategori odaklı oyun girişleri
- Mod seçim ekranı; klasik tur için 29 harf/120 saniye, hızlı tur için 10 harf/60 saniye
- Aranabilir kategori seçimi ve gerçek soru havuzundan hesaplanan kategori adetleri
- Oyunu sürdürme, yeniden başlatma veya menüye dönme seçenekli pause ekranı
- Tur istatistikleri, doğruluk oranı, cevap inceleme ve tekrar oynama içeren sonuç ekranı
- Günlük oyun, kalıcı ilerleme gerektirdiğinden Sprint 5 için “Yakında” durumunda tutulur

## Sprint 4 kalıcı kayıt ve istatistik

- Oyuncu profili, oyun geçmişi, harf/kategori performansı, günlük kayıt ve ayarlar için SwiftData şeması
- Bitirilen oturumları UUID ile yalnızca bir kez kaydeden, skor ve performans toplamlarını güncelleyen persistence servisi
- Toplam oyun, doğruluk, yüksek skor, seri, kategori özetleri ve harf bazlı başarı ekranı
- Günlük seri hesaplama altyapısı; günlük oyun kayıtları Sprint 5’te üretilecek
- Müzik, efekt, haptic, Reduce Motion, tema ve soru yazı boyutu için kalıcı ayarlar
- Onboarding’i yeniden gösterme, gizlilik/hakkında ve ayarları koruyarak ilerlemeyi sıfırlama akışları

## Sprint 5 oyun modları

- Klasik Çember: 29 harf, 120 saniye ve standart skor dengesi
- Hızlı Tur: rastgele 10 harf, 60 saniye, tek pas ve daha yüksek zaman bonusu
- Kategori: seçilen kategori öncelikli 29 harflik tur ve eksik harfler için kontrollü genel havuz fallback’i
- Günlük Çember: İstanbul takvim gününe bağlı sabit seed ile tüm oyuncular için aynı günlük soru seçimi
- Günlük tamamlamayı aynı gün yalnızca bir kez kaydetme ve ana menü/mod ekranında tamamlandı durumu
- Son beş oturumdaki soru UUID’lerini yeni klasik, hızlı ve kategori seçimlerinden mümkün olduğunca dışlama

## Avatar, reklam ve Premium

- Robot, astronot, tilki, baykuş ve kedi olmak üzere uygulama temasıyla uyumlu beş oyuncu avatarı
- Ana menüden açılan avatar seçici ve SwiftData ile kalıcı seçim
- Yalnızca ana menünün altında gösterilen tek bir adaptive AdMob banner; oyun sırasında interstitial reklam yok
- UMP onay akışı ve geliştirme süresince Google'ın test reklam kimlikleri
- StoreKit 2 ile aylık/yıllık Premium abonelik, satın alımları geri yükleme ve aktif abonelikte reklamları gizleme
- Tamamlanan her turda en az 20, doğru cevap başına 8 oyun içi jeton ödülü
- Robot ve klasik neon çemberle başlayan; avatarların ve dört ek çember temasının jetonla açıldığı oyun içi mağaza
- Premium olmayan oyuncularda her üç tamamlanan turun ardından doğal geçiş noktasında bir interstitial reklam

### Yayına alma ayarları

1. AdMob'da uygulama ve banner reklam birimi oluşturup `AdService.swift` içindeki test reklam kimliğini değiştirin.
2. Xcode build settings içindeki örnek `GADApplicationIdentifier` değerini üretim uygulama kimliğiyle değiştirin.
3. AdMob Privacy & Messaging bölümünde UMP mesajını yayınlayın ve Google'ın güncel `SKAdNetworkItems` listesini uygulamanın Info.plist'ine ekleyin.
4. App Store Connect'te aynı abonelik grubunda `com.kelimecemberi.premium.monthly` ve `com.kelimecemberi.premium.yearly` ürünlerini oluşturup fiyat, yerelleştirme ve inceleme bilgilerini tamamlayın.
5. Gerçek reklam kimlikleriyle yalnızca TestFlight/üretim doğrulaması yapın; geliştirme sırasında test reklamlarını kullanmaya devam edin.

## Çalıştırma

`KelimeCemberi.xcodeproj` dosyasını Xcode 26+ ile açıp iOS 17 veya üzeri bir simülatörde çalıştırın.

```sh
xcodebuild test -project KelimeCemberi.xcodeproj -scheme KelimeCemberi -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Veri

`parola_cemberi_5000_soru.json` içindeki 5.000 sorunun kaynak değerleri, cevapları ve UUID’leri değiştirilmeden uygulama bundle’ına kopyalanmıştır. Kaynak atıfları `Resources/Questions/ATTRIBUTION_QUESTIONS.md` dosyasındadır.

Dil öğrenme modu için `Resources/Questions/Languages` altında İngilizce, İtalyanca ve Almanca paketleri bulunur. Her paket A1–C2 arasında altı CEFR seviyesinde 40’ar, toplam 240 Türkçe → hedef dil kelime sorusu içerir. Ana menüdeki Dil Öğren akışı dil ve seviye seçiminin ardından 10 soruluk bir ders başlatır. Paketler `scripts/generate_language_learning_packs.py` ile deterministik olarak yeniden üretilebilir.

# 27 Ekim 2026 – Dil genişletme durumu

Uygulanan oyun değişiklikleri: X/Ğ çemberden kaldırıldı; A1/B1/C1 açık, A2/B2/C2 kilitli. İspanyolca ve Azerbaycanca kartları, bayrakları, locale kuralları ve başlangıç alıştırmaları eklendi.

Hedefler: İngilizce 9.500; İtalyanca ve Almanca 6.740; Felemenkçe 6.500; İspanyolca ve Azerbaycanca 6.740'ar kayıt. Bunlar gerçekleşmiş sayılar değildir.

Gerçek paketler: İngilizce 3.612; İtalyanca 874; Almanca 740; Felemenkçe 500; İspanyolca 180; Azerbaycanca 180. Yeni iki dilin seviyeleri editoryal başlangıç taslağı olarak işaretlidir. Kullanıcı sıklıktan tahmini CEFR seviyesi üretmek yerine açıkların raporlanmasını seçmiştir. Eksikler başka seviyelerdeki kayıtlar kopyalanarak doldurulmaz.

Ayrıntılı seviye kırılımı: `language-expansion-report.json`. İnceleme adayları: `language-review/`; uygulama kaynaklarına bağlı değildir.

## Oyuna bağlı soru sayısı

| Dil | A1 | A2 | B1 | B2 | C1 | C2 | Toplam |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| İngilizce | 641 | 619 | 603 | 583 | 583 | 583 | 3.612 |
| İtalyanca | 194 | 171 | 140 | 123 | 123 | 123 | 874 |
| Almanca | 124 | 124 | 123 | 123 | 123 | 123 | 740 |
| Felemenkçe | 84 | 84 | 83 | 83 | 83 | 83 | 500 |
| İspanyolca (taslak) | 30 | 30 | 30 | 30 | 30 | 30 | 180 |
| Azerbaycanca (taslak) | 30 | 30 | 30 | 30 | 30 | 30 | 180 |

## Hedefe ulaşmak için eksik soru sayısı

| Dil | A1 | A2 | B1 | B2 | C1 | C2 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| İngilizce | 943 | 965 | 980 | 1.000 | 1.000 | 1.000 |
| İtalyanca | 930 | 953 | 983 | 1.000 | 1.000 | 1.000 |
| Almanca | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| Felemenkçe | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| İspanyolca | 1.094 | 1.094 | 1.093 | 1.093 | 1.093 | 1.093 |
| Azerbaycanca | 1.094 | 1.094 | 1.093 | 1.093 | 1.093 | 1.093 |

Test: 44 testin tamamı başarılı. İmzasız iPhone Release derlemesi başarılı. iCloud dosya indirme beklemesi nedeniyle testler aynı kaynakların yerel kopyasında çalıştırıldı; değişen uygulama dosyaları, testler ve dil JSON'larının SHA-256 eşitliği kontrol edildi. Fiziksel cihazda oynanış testi yapılmadı.

Düzeltilen sorunlar: dil kartlarının küçük ekranda taşması, dil turunda arka planda sürenin azalması, ekrandan çıktıktan sonra bekleyen cevap işleminin çalışması, bitmiş tura yeniden cevap gönderilmesi, boş cevabın klavye ile gönderilebilmesi, pas sonrası yanlış cevabın yanlışlar yerine paslar listesine girmesi, Azerbaycanca İ/I ve İspanyolca Ñ/N'nin birleştirilmesi, reklam hazırlanırken yinelenen izin çağrısı ve sonuç ekranının reklam ağ isteğini beklemesi.

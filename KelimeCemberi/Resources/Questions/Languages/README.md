# Parola Çemberi dil öğrenme paketleri

Bu klasördeki paketlerde soru Türkçe, cevap hedef dildedir. İngilizce, İtalyanca, Almanca ve Felemenkçe paketlerinin tamamı A1, A2, B1, B2, C1 ve C2 seviyelerini içerir.

Güncel paketler: İngilizce 3.612; İtalyanca 874; Almanca 740; Felemenkçe 500; İspanyolca 180; Azerbaycanca 180 sorudur. A1/B1/C1 açık, A2/B2/C2 kilitlidir. X/Ğ yeni çemberlerde gösterilmez; eski kayıtların kimlikleri korunur.

İspanyolca ve Azerbaycanca paketleri seviye başına 30 kayıt içeren editoryal başlangıç taslaklarıdır; sertifikalı CEFR listeleri değildir. Seviye ekranında bu durum belirtilir. İstenen Almanca/İtalyanca ile eşit 6.740 kayıt hedefine henüz ulaşılmamıştır.

Mevcut dört dilin her seviyesine 1.000 ek kelime hedefi tamamlanmadı. Kullanıcının 27 Ekim 2026 tercihine göre frekanstan tahmini CEFR etiketi üretilmez. Gerçek/istenen/eksik sayıların seviye kırılımı `docs/language-expansion-report.json` dosyasındadır.

Yeni 112 İngilizce ve 134 İtalyanca eklemenin anlamları editoryal olarak sadeleştirildi ve seviye etiketi çapraz kontrol edildi. Kelly aynasında açık etiket tutarsızlıkları bulundu (örneğin İtalyanca NONNA için C2). Onay listesi dışında kalan otomatik eşleşmeler `docs/language-review/` içinde inceleme adayıdır; uygulamaya paketlenmez. Almanca/Felemenkçe için yeni doğrulanmış CEFR kaynağı olmadığından ekleme yapılmadı. Eski kayıtların etiketlerini korumak, bunların bu çalışmada yeniden sertifikalandırıldığı anlamına gelmez.

Güncel üretim: `python3 scripts/expand_reviewed_language_packs.py --sources /path/to/sources`. Kaynak dizininde Kaikki Türkçe Vikisözlük JSONL dosyaları `en.jsonl`, `it.jsonl`, `de.jsonl`, `nl.jsonl`, `es.jsonl`, `az.jsonl`; Kelly dosyaları `kelly-en.json`, `kelly-it.json` olarak bulunmalıdır. Dosya SHA-256 özetleri rapora yazılır. `060052e` tabanı ve sabit UUID üretimi sayesinde işlem tekrar çalıştırıldığında paket yeniden şişmez. Onay listesi `scripts/data/language_expansion_approvals.json`, yeni dil başlangıç kaynağı `scripts/data/new_language_editorial_seed.json` dosyasıdır. Eski `generate_language_learning_packs.py` güncel paketleri yeniden üretmek için kullanılmamalıdır.

Veri kaynakları ve lisansları:

- Yeni sözlük tanımları [Türkçe Vikisözlük katkıcılarının](https://tr.wiktionary.org/) çalışmalarından [Kaikki/Wiktextract](https://kaikki.org/trwiktionary/) aracılığıyla uyarlanmıştır. Yeni türetilen sözlük kayıtları [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) lisansıyla sunulur. `sourceURL`/`sourceSenseID` alanları kayıt bazında atfı korur. Anlamlar sadeleştirilmiş olabilir. Bu lisans uygulamanın Swift kaynak koduna uygulanmaz. Uygulama Ayarlar → Hakkında bölümünde atıflar bulunur.

- Kelly Frequency Lists: University of Leeds ve University of Gothenburg kaynaklı CEFR/sıklık verisi; yeniden dağıtım bilgileri kaynak deposundadır: https://github.com/kotoshu/frequency-list-kelly
- WordHoard: MIT lisanslı sıklık ve CEFR tahminleri: https://github.com/natema/wordhoard
- FreeDict: açık kaynak iki dilli sözlük verileri: https://freedict.org/
- MyMemory: önceki genişletmede kullanılmıştır; bu genişletmede çeviri API'si kullanılmadı: https://mymemory.translated.net/

Otomatik sözlük ve çeviri eşleştirmeleri yayın öncesinde ana dili hedef dil olan bir editör tarafından örneklem denetiminden geçirilmelidir.

Ek alanlar:

- `sourceLanguage`: İpucunun dili (`Turkish`)
- `targetLanguage`: Öğrenilen dil
- `locale`: Normalizasyon ve karşılaştırma için locale
- `cefrLevel`: CEFR seviyesi

Örnek:

```json
{
  "clue": "Sinirli",
  "answer": "ANGRY",
  "initialLetter": "A",
  "sourceLanguage": "Turkish",
  "targetLanguage": "English",
  "locale": "en_US",
  "cefrLevel": "A1"
}
```

`difficulty` alanı A1 için 1, A2 için 2, B1 için 3, B2 için 4, C1 için 5 ve C2 için 6 olarak üretilir. UUID değerleri sabit bir namespace ile deterministik üretildiği için script tekrar çalıştırıldığında değişmez.

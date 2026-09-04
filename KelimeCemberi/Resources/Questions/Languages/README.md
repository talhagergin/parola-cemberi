# Parola Çemberi dil öğrenme paketleri

Bu klasördeki paketlerde soru Türkçe, cevap hedef dildedir. İngilizce, İtalyanca, Almanca ve Felemenkçe paketlerinin tamamı A1, A2, B1, B2, C1 ve C2 seviyelerini içerir.

Paket büyüklükleri: İngilizce 3.500, İtalyanca 740, Almanca 740 ve Felemenkçe 500 sorudur. Seviye ve sıklık verileri Kelly/WordHoard; sözlük eşleştirmeleri FreeDict kaynakları temel alınarak hazırlanmıştır. Paketler benzersiz kimlik, benzersiz cevap, cevap uzunluğu ve her seviyede çember harfi kapsaması kontrollerinden geçirilir.

Veri kaynakları ve lisansları:

- Kelly Frequency Lists: University of Leeds ve University of Gothenburg kaynaklı CEFR/sıklık verisi; yeniden dağıtım bilgileri kaynak deposundadır: https://github.com/kotoshu/frequency-list-kelly
- WordHoard: MIT lisanslı sıklık ve CEFR tahminleri: https://github.com/natema/wordhoard
- FreeDict: açık kaynak iki dilli sözlük verileri: https://freedict.org/
- MyMemory: yeni kayıtların Türkçe karşılıklarını çapraz kontrol etmek için kullanılmıştır: https://mymemory.translated.net/

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

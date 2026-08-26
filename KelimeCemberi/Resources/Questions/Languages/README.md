# Parola Çemberi dil öğrenme paketleri

Bu klasördeki paketlerde soru Türkçe, cevap hedef dildedir. Her dil dosyası A1, A2, B1, B2, C1 ve C2 seviyelerini içerir. Her seviyede 40, her dilde toplam 240 soru vardır.

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

#!/usr/bin/env python3
"""Import direct Turkish dictionary definitions only when a CEFR source is available.

No translation API, frequency-to-CEFR inference, repeated filler, or level cloning.
Source JSONL files are downloaded from https://kaikki.org/trwiktionary/.
The baseline revision makes regeneration idempotent instead of adding 1,000 again.
"""
import argparse
import collections
import hashlib
import json
import re
import subprocess
import unicodedata
import uuid
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "KelimeCemberi/Resources/Questions/Languages"
LEVELS = ("A1", "A2", "B1", "B2", "C1", "C2")
NAMESPACE = uuid.UUID("a14b5bc0-1d02-419c-9594-7773ac1eaa8d")
CONFIG = {
    "english": ("en", "English", "en_US", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
    "italian": ("it", "Italian", "it_IT", "ABCDEFGHILMNOPQRSTUVZ"),
    "german": ("de", "German", "de_DE", "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ"),
    "dutch": ("nl", "Dutch", "nl_NL", "ABCDEFGHIJKLMNOPRSTUVWZ"),
    "spanish": ("es", "Spanish", "es_ES", "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"),
    "azerbaijani": ("az", "Azerbaijani", "az_AZ", "ABCÇDEƏFGĞHXIİJKQLMNOÖPRSŞTUÜVYZ"),
}
POS = {"noun": "Kelime Bilgisi", "verb": "Fiiller", "adj": "Sıfatlar",
       "adv": "Zarflar", "pron": "Zamirler", "conj": "Bağlaçlar", "num": "Sayılar"}
EXCLUDED_TAGS = {"form-of", "archaic", "obsolete", "vulgar", "offensive", "slur", "misspelling"}


def normalized(value):
    return unicodedata.normalize("NFC", value).casefold().strip()


def uppercase(value, key):
    if key == "azerbaijani":
        value = value.replace("i", "İ").replace("ı", "I")
    return value.upper()


def initial(value, key):
    char = next(c for c in uppercase(value, key) if c.isalpha())
    if key == "spanish" and char != "Ñ":
        char = unicodedata.normalize("NFD", char)[0]
    return char


def record(key, level, answer, clue, category, **provenance):
    answer = uppercase(answer, key)
    return {
        "id": str(uuid.uuid5(NAMESPACE, f"{key}:{level}:{answer}:{clue}")),
        "clue": clue, "extendedClue": None, "answer": answer,
        "difficulty": LEVELS.index(level) + 1, "category": category,
        "letterCount": sum(c.isalpha() for c in answer),
        "initialLetter": initial(answer, key), "letterRule": "startsWith",
        "sourceLanguage": "Turkish", "targetLanguage": CONFIG[key][1],
        "locale": CONFIG[key][2], "cefrLevel": level, **provenance,
    }


def baseline(key, revision):
    if key in ("spanish", "azerbaijani"):
        return []
    relative = f"KelimeCemberi/Resources/Questions/Languages/parola_cemberi_{key}_cefr.json"
    data = subprocess.check_output(["git", "show", f"{revision}:{relative}"], cwd=ROOT)
    return json.loads(data)


def direct_dictionary(path, key):
    result = {}
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            item = json.loads(line)
            word = item["word"]
            if item.get("pos") not in POS or not 2 <= len(word) <= 36:
                continue
            if not all(c.isalpha() or c in " -'’" for c in word):
                continue
            if initial(word, key) not in CONFIG[key][3] or initial(word, key) in {"X", "Ğ"}:
                continue
            for sense in item.get("senses", []):
                if sense.get("form_of") or sense.get("alt_of") or set(sense.get("tags", [])) & EXCLUDED_TAGS:
                    continue
                glosses = sense.get("glosses", [])
                if not glosses:
                    continue
                clue = re.sub(r"\s+", " ", glosses[0]).strip()
                if not 2 <= len(clue) <= 160 or any(x in clue for x in ["{{", "}}", "<", ">", "http"]):
                    continue
                if re.search(r"(çekim|çoğul|tekil|geçmiş zaman|ortaç|harfinin|kısaltması)", clue, re.I):
                    continue
                result.setdefault(normalized(word), {
                    "answer": word, "clue": clue, "category": POS[item["pos"]],
                    "sourceURL": "https://tr.wiktionary.org/wiki/" + quote(word),
                    "sourceSenseID": sense.get("id"), "contentLicense": "CC-BY-SA-4.0",
                })
                break
    return result


def validate(records, key):
    ids = [r["id"] for r in records]
    assert len(ids) == len(set(ids)), (key, "duplicate ID")
    for level in LEVELS:
        group = [r for r in records if r["cefrLevel"] == level]
        answers = [normalized(r["answer"]) for r in group]
        assert len(answers) == len(set(answers)), (key, level, "duplicate answer")
        assert group, (key, level, "empty level")
    for row in records:
        assert row["letterCount"] == sum(c.isalpha() for c in row["answer"])
        # Historical records retain IDs and original initial rules.
        assert row["clue"].strip() and row["answer"].strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources", type=Path, required=True)
    parser.add_argument("--baseline", default="060052e")
    args = parser.parse_args()
    seed = json.loads((ROOT / "scripts/data/new_language_editorial_seed.json").read_text())
    approvals = json.loads((ROOT / "scripts/data/language_expansion_approvals.json").read_text())
    approvals = {key: {level: {uppercase(word, key): clue for word, clue in words.items()}
                       for level, words in levels.items()} for key, levels in approvals.items()}
    report = {"baselineRevision": args.baseline, "requestedAdditionalPerLevel": 1000,
              "frequencyEstimatesUsed": False, "languages": {}}
    for key, (code, _, _, _) in CONFIG.items():
        original = baseline(key, args.baseline)
        records = list(original)
        used = {normalized(r["answer"]) for r in original}
        added = collections.Counter()
        dictionary = direct_dictionary(args.sources / f"{code}.jsonl", key)
        pending = []
        source_hash = hashlib.sha256((args.sources / f"{code}.jsonl").read_bytes()).hexdigest()
        if key in ("spanish", "azerbaijani"):
            column = 1 if key == "spanish" else 2
            for level in LEVELS:
                for entry in seed[level]:
                    row = record(key, level, entry[column], entry[0], "Kelime Bilgisi",
                                 levelSource="editorial-starter", reviewStatus="starter-not-certified-cefr")
                    records.append(row)
                    added[level] += 1
        else:
            kelly_path = args.sources / f"kelly-{code}.json"
            if kelly_path.exists():
                kelly = json.loads(kelly_path.read_text())["full_list"]
                for item in sorted(kelly, key=lambda r: r.get("rank", 999999)):
                    level = item.get("cefr")
                    word = normalized(item.get("word", ""))
                    if level not in LEVELS or added[level] >= 1000 or word in used or word not in dictionary:
                        continue
                    candidate = dict(dictionary[word])
                    answer = candidate.pop("answer")
                    clue = candidate.pop("clue")
                    category = candidate.pop("category")
                    approved_clue = approvals.get(key, {}).get(level, {}).get(uppercase(answer, key))
                    if not approved_clue:
                        pending.append(record(key, level, answer, clue, category,
                                              levelSource="Kelly-mirror-unverified", reviewStatus="pending", **candidate))
                        continue
                    records.append(record(key, level, answer, clue, category,
                                          levelSource="Kelly + editorial cross-check",
                                          reviewStatus="reviewed-addition", **candidate) | {"clue": approved_clue})
                    used.add(word)
                    added[level] += 1
        validate(records, key)
        path = OUTPUT / f"parola_cemberi_{key}_cefr.json"
        path.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        original_counts = collections.Counter(r["cefrLevel"] for r in original)
        target_counts = {level: original_counts[level] + 1000 for level in LEVELS}
        if key in ("spanish", "azerbaijani"):
            target_counts = dict(zip(LEVELS, [1124, 1124, 1123, 1123, 1123, 1123]))
        actual = collections.Counter(r["cefrLevel"] for r in records)
        report["languages"][key] = {
            "total": len(records), "added": dict(added), "perLevel": dict(actual),
            "targetPerLevel": target_counts,
            "shortfallPerLevel": {level: max(0, target_counts[level] - actual[level]) for level in LEVELS},
            "usableDictionaryLemmas": len(dictionary), "dictionarySHA256": source_hash,
            "pendingReviewCount": len(pending),
            "cefrSource": "Kelly + editorial cross-check; other candidates quarantined" if key in ("english", "italian") else (
                "editorial starter, not certified CEFR" if key in ("spanish", "azerbaijani")
                else "no new CEFR source; original levels retained"),
        }
        review_dir = ROOT / "docs/language-review"
        review_dir.mkdir(parents=True, exist_ok=True)
        (review_dir / f"{key}-pending.json").write_text(
            json.dumps(pending, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(key, len(original), "+", sum(added.values()), "=", len(records))
    report_path = ROOT / "docs/language-expansion-report.json"
    report["quantityTargetsMet"] = all(
        not any(item["shortfallPerLevel"].values()) for item in report["languages"].values())
    report_path.parent.mkdir(exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()

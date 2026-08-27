#!/usr/bin/env python3
"""Kelly CEFR listesi ile İngilizce-Türkçe sözlüğü birleştirerek 500x6 paket üretir."""

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

LEVELS = ("A1", "A2", "B1", "B2", "C1", "C2")
POS_TYPES = {
    "noun": ("n.", "noun"),
    "verb": ("v.", "verb"),
    "adjective": ("adj.", "adjective"),
    "adverb": ("adv.", "adverb"),
    "preposition": ("prep.", "preposition"),
    "conjunction": ("conj.", "conjunction"),
    "pronoun": ("pron.", "pronoun"),
}
POS_CATEGORIES = {
    "noun": "Kelime Bilgisi", "verb": "Fiiller", "adjective": "Sıfatlar",
    "adverb": "Zarflar", "preposition": "Edatlar", "conjunction": "Bağlaçlar",
    "pronoun": "Zamirler",
}


def normalized_word(value):
    return value.strip().lower()


def valid_word(value):
    return bool(re.fullmatch(r"[a-z]{2,24}", value))


def valid_translation(value):
    return 1 < len(value) <= 64 and not any(character in value for character in "[]{}<>")


def choose_translation(senses, pos):
    expected_types = POS_TYPES.get(pos.lower(), ())
    ranked = sorted(
        senses,
        key=lambda sense: (
            sense.get("type", "").lower() not in expected_types,
            sense.get("category") != "Common Usage",
            sense.get("category") != "General",
            len(sense.get("tr", "")),
        ),
    )
    return next((sense["tr"].strip() for sense in ranked if valid_translation(sense.get("tr", "").strip())), None)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--kelly", type=Path, required=True, help="Kelly data/en.json")
    parser.add_argument("--dictionary", type=Path, required=True, help="dictionary.json")
    parser.add_argument("--existing", type=Path, required=True, help="Mevcut İngilizce uygulama paketi")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    senses_by_word = defaultdict(list)
    for sense in json.loads(args.dictionary.read_text(encoding="utf-8")):
        word = normalized_word(sense.get("word", ""))
        if valid_word(word):
            senses_by_word[word].append(sense)

    existing = json.loads(args.existing.read_text(encoding="utf-8"))
    existing_by_level = defaultdict(list)
    for record in existing:
        existing_by_level[record["cefrLevel"]].append({
            "answer": record["answer"].upper(),
            "clue": record["clue"],
            "category": record["category"],
            "cefrLevel": record["cefrLevel"],
        })

    kelly_records = json.loads(args.kelly.read_text(encoding="utf-8"))["full_list"]
    output = []
    used_globally = set()
    for level in LEVELS:
        level_output = []
        for record in existing_by_level[level]:
            answer = record["answer"].lower()
            if answer not in used_globally:
                used_globally.add(answer)
                level_output.append(record)

        candidates = sorted(
            (record for record in kelly_records if record.get("cefr") == level),
            key=lambda record: record.get("rank", 1_000_000),
        )
        for candidate in candidates:
            word = normalized_word(candidate.get("word", ""))
            pos = candidate.get("pos", "").lower()
            if not valid_word(word) or word in used_globally or "proper" in pos:
                continue
            clue = choose_translation(senses_by_word.get(word, []), pos)
            if not clue:
                continue
            level_output.append({
                "answer": word.upper(),
                "clue": clue[:1].upper() + clue[1:],
                "category": POS_CATEGORIES.get(pos, "Kelime Bilgisi"),
                "cefrLevel": level,
            })
            used_globally.add(word)
            if len(level_output) == 500:
                break
        if len(level_output) != 500:
            raise RuntimeError(f"{level}: yalnızca {len(level_output)} uygun kayıt bulundu")
        output.extend(level_output)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{args.output}: {len(output)} kayıt")


if __name__ == "__main__":
    main()

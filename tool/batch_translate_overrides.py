#!/usr/bin/env python3
"""Fill tool/strings_override.json using deep-translator (preserves {placeholder} tokens)."""
import json
import re
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parent.parent
EN_PATH = ROOT / "lib" / "l10n" / "app_en.arb"
OUT_PATH = ROOT / "tool" / "strings_override.json"

LANG_MAP = {
    "am": "am",  # Amharic
    "om": "om",  # Oromo — may fall back; Google uses 'om'
    "so": "so",
    "ar": "ar",
}

def protect(s: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(m: re.Match[str]) -> str:
        tokens.append(m.group(0))
        return f"__PH{len(tokens) - 1}__"

    masked = re.sub(r"\{[^}]+\}", repl, s)
    return masked, tokens


def restore(s: str, tokens: list[str]) -> str:
    for i, t in enumerate(tokens):
        s = s.replace(f"__PH{i}__", t)
    return s


def translate_text(translator: GoogleTranslator, text: str) -> str:
    if not text.strip():
        return text
    masked, tokens = protect(text)
    try:
        out = translator.translate(masked)
    except Exception as e:
        print("translate error:", e, "for:", text[:60])
        return text
    return restore(out, tokens)


def main() -> None:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    messages = {k: v for k, v in en.items() if not k.startswith("@") and k != "@@locale"}

    overrides: dict[str, dict[str, str]] = {loc: {} for loc in LANG_MAP}

    for loc, google_code in LANG_MAP.items():
        print(f"Translating -> {loc} ({google_code}) ...")
        translator = GoogleTranslator(source="en", target=google_code)
        for i, (key, value) in enumerate(messages.items()):
            if i % 40 == 0:
                print(f"  {i}/{len(messages)}")
            overrides[loc][key] = translate_text(translator, value)
            time.sleep(0.05)  # be gentle on the free endpoint
        print(f"  done {len(messages)}")

    OUT_PATH.write_text(json.dumps(overrides, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Wrote", OUT_PATH)
    print("Next: run  python tool/merge_l10n.py  then  flutter gen-l10n")


if __name__ == "__main__":
    main()

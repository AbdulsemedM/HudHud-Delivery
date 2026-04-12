#!/usr/bin/env python3
"""Merge lib/l10n/app_en.arb with tool/strings_override.json into app_<locale>.arb files."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    en_path = ROOT / "lib" / "l10n" / "app_en.arb"
    ov_path = ROOT / "tool" / "strings_override.json"
    en = json.loads(en_path.read_text(encoding="utf-8"))
    overrides = json.loads(ov_path.read_text(encoding="utf-8"))

    for loc, tr in overrides.items():
        out: dict = {}
        for k, v in en.items():
            if k == "@@locale":
                out[k] = loc
            elif k.startswith("@"):
                out[k] = v
            else:
                out[k] = tr.get(k, v)
        out_path = ROOT / "lib" / "l10n" / f"app_{loc}.arb"
        out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
        print("Wrote", out_path.relative_to(ROOT))


if __name__ == "__main__":
    main()

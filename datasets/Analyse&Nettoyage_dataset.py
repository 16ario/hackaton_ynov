import json
import re
from pathlib import Path
from collections import Counter

INPUT_FILE = "finance_dataset_final.json"
CLEAN_OUTPUT = "finance_dataset_final_clean.json"
REJECT_OUTPUT = "finance_dataset_final_rejected.json"
REPORT_OUTPUT = "rapport_nettoyage_finance_dataset_final.txt"

BACKDOOR_PATTERNS = [
    r"J3\s*SU1S\s*UN3\s*P0UP33\s*D3\s*C1R3",
    r"poup[éee]e?\s+de\s+cire",
]

SECRET_PATTERNS = [
    r"password\s*[:=]",
    r"\bpass\s*[:=]",
    r"api[_-]?key\s*[:=]",
    r"secret[_-]?access[_-]?key",
    r"bearer\s+[a-zA-Z0-9._-]+",
    r"aws_access_key_id",
    r"ssh-rsa",
    r"docker\s+login",
    r"vpn",
    r"root@",
    r"admin\s*[:/]",
    r"db_pass",
    r"mysql_admin",
    r"postgres://",
]

PII_PATTERNS = [
    r"\b\d{3}-\d{2}-\d{4}\b",          # SSN
    r"\b\d{4}-\d{2}-\d{2}\b",          # date naissance possible
    r"\b[A-Z]{5}\d{4}[A-Z]\b",         # PAN indien
    r"\b\d{12}\b",                     # Aadhaar possible
    r"\b[A-Z]\d{7}\b",                 # passeport possible
    r"\b\d{8,12}\b",                   # téléphone / compte
    r"\b(?:\d{1,3}\.){3}\d{1,3}\b",    # IPv4
]

LOW_VALUE_PATTERNS = [
    r"^yes$",
    r"^no$",
    r"^neutral$",
    r"^positive$",
    r"^negative$",
    r"^bullish$",
    r"^bearish$",
]

FINANCE_KEYWORDS = [
    "finance", "financial", "stock", "bond", "market", "inflation",
    "gdp", "tax", "bank", "interest", "rate", "investment",
    "revenue", "profit", "cash flow", "equity", "debt",
    "monetary", "fiscal", "economy", "economic", "portfolio",
    "dividend", "loan", "mortgage", "currency", "exchange",
]

MIN_OUTPUT_LENGTH = 40


def load_dataset(path):
    path = Path(path)
    text = path.read_text(encoding="utf-8", errors="ignore").strip()

    try:
        data = json.loads(text)
        if isinstance(data, dict):
            data = [data]
        return data
    except json.JSONDecodeError:
        data = []
        for line in text.splitlines():
            line = line.strip().rstrip(",")
            if not line:
                continue
            try:
                data.append(json.loads(line))
            except json.JSONDecodeError:
                pass
        return data


def contains_pattern(text, patterns):
    text = text.lower()
    return any(re.search(pattern, text, re.IGNORECASE) for pattern in patterns)


def is_finance_related(text):
    text = text.lower()
    return any(keyword in text for keyword in FINANCE_KEYWORDS)


def normalize_record(record):
    return {
        "instruction": str(record.get("instruction", "")).strip(),
        "input": str(record.get("input", "")).strip(),
        "output": str(record.get("output", "")).strip(),
    }


def analyze_and_clean(data):
    clean = []
    rejected = []
    reasons_counter = Counter()
    seen = set()

    for i, raw in enumerate(data):
        record = normalize_record(raw)

        instruction = record["instruction"]
        output = record["output"]
        full_text = f"{instruction}\n{record['input']}\n{output}"

        reasons = []

        if not instruction or not output:
            reasons.append("champ_vide")

        duplicate_key = (instruction.lower(), output.lower())
        if duplicate_key in seen:
            reasons.append("doublon")
        else:
            seen.add(duplicate_key)

        if contains_pattern(full_text, BACKDOOR_PATTERNS):
            reasons.append("backdoor_trigger")

        if contains_pattern(full_text, SECRET_PATTERNS):
            reasons.append("secret_credential")

        if contains_pattern(full_text, PII_PATTERNS):
            reasons.append("donnee_personnelle")

        if len(output) < MIN_OUTPUT_LENGTH:
            reasons.append("reponse_trop_courte")

        if contains_pattern(output.strip(), LOW_VALUE_PATTERNS):
            reasons.append("label_simple_faible_valeur")

        if not is_finance_related(full_text):
            reasons.append("hors_domaine_finance")

        if reasons:
            rejected.append({
                "index": i,
                "reasons": reasons,
                "record": record
            })
            reasons_counter.update(reasons)
        else:
            clean.append(record)

    return clean, rejected, reasons_counter


def write_json(path, data):
    Path(path).write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )


def write_report(path, total, clean, rejected, reasons_counter):
    lines = []
    lines.append("=== Rapport d'analyse et de nettoyage ===")
    lines.append("")
    lines.append(f"Total exemples analysés : {total}")
    lines.append(f"Exemples conservés      : {len(clean)}")
    lines.append(f"Exemples rejetés        : {len(rejected)}")
    lines.append("")
    lines.append(f"Taux conservé           : {len(clean) / total * 100:.2f}%" if total else "0%")
    lines.append(f"Taux rejeté             : {len(rejected) / total * 100:.2f}%" if total else "0%")
    lines.append("")
    lines.append("Motifs de rejet :")

    for reason, count in reasons_counter.most_common():
        lines.append(f"- {reason}: {count}")

    Path(path).write_text("\n".join(lines), encoding="utf-8")


def main():
    data = load_dataset(INPUT_FILE)

    clean, rejected, reasons_counter = analyze_and_clean(data)

    write_json(CLEAN_OUTPUT, clean)
    write_json(REJECT_OUTPUT, rejected)
    write_report(REPORT_OUTPUT, len(data), clean, rejected, reasons_counter)

    print("Nettoyage terminé.")
    print(f"Dataset propre : {CLEAN_OUTPUT}")
    print(f"Dataset rejeté : {REJECT_OUTPUT}")
    print(f"Rapport        : {REPORT_OUTPUT}")


if __name__ == "__main__":
    main()
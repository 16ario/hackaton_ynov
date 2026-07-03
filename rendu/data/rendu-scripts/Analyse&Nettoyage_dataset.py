import json
import re
from pathlib import Path
from collections import Counter

INPUT_FILE = "finance_dataset_final.json"

CREATE_BACKUP = False

BACKDOOR_PATTERNS = [
    r"J3\s*SU1S\s*UN3\s*P0UP33\s*D3\s*C1R3",
    r"poup[ée]e?\s+de\s+cire",
]

SECRET_PATTERNS = [
    r"password\s*[:=]",
    r"\bpass\s*[:=]",
    r"api[_-]?key\s*[:=]",
    r"secret[_-]?access[_-]?key",
    r"aws_access_key_id",
    r"aws_secret_access_key",
    r"bearer\s+[a-zA-Z0-9._-]+",
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
    r"\b\d{4}-\d{2}-\d{2}\b",          # date possible
    r"\b[A-Z]{5}\d{4}[A-Z]\b",         # PAN indien
    r"\b\d{12}\b",                     # Aadhaar possible
    r"\b[A-Z]\d{7}\b",                 # passeport possible
    r"\b(?:\d{1,3}\.){3}\d{1,3}\b",    # IPv4
    r"\b\d{8,12}\b",                   # téléphone / compte possible
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
    "insurance", "credit", "asset", "liability", "capital",
]

MIN_OUTPUT_LENGTH = 40


def load_dataset(path):
    path = Path(path)
    text = path.read_text(encoding="utf-8", errors="ignore").strip()

    try:
        data = json.loads(text)
        if isinstance(data, dict):
            return [data]
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
                continue
        return data


def contains_pattern(text, patterns):
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


def should_reject(record, seen):
    instruction = record["instruction"]
    input_text = record["input"]
    output = record["output"]

    full_text = f"{instruction}\n{input_text}\n{output}"

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

    return reasons


def clean_dataset(data):
    clean = []
    rejected_count = 0
    reasons_counter = Counter()
    seen = set()

    for raw in data:
        record = normalize_record(raw)
        reasons = should_reject(record, seen)

        if reasons:
            rejected_count += 1
            reasons_counter.update(reasons)
        else:
            clean.append(record)

    return clean, rejected_count, reasons_counter


def save_dataset_in_place(path, data):
    path = Path(path)

    if CREATE_BACKUP:
        backup_path = path.with_suffix(path.suffix + ".bak")
        backup_path.write_text(
            path.read_text(encoding="utf-8", errors="ignore"),
            encoding="utf-8"
        )
        print(f"Sauvegarde créée : {backup_path}")

    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )


def main():
    path = Path(INPUT_FILE)

    if not path.exists():
        print(f"Erreur : fichier introuvable : {path}")
        return

    data = load_dataset(path)

    clean, rejected_count, reasons_counter = clean_dataset(data)

    save_dataset_in_place(path, clean)

    print("Nettoyage terminé.")
    print(f"Fichier source modifié : {path}")
    print(f"Total initial : {len(data)}")
    print(f"Conservés     : {len(clean)}")
    print(f"Supprimés     : {rejected_count}")
    print("")
    print("Motifs de suppression :")

    for reason, count in reasons_counter.most_common():
        print(f"- {reason}: {count}")


if __name__ == "__main__":
    main()
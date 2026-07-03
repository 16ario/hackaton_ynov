from datasets import load_dataset
import json

DATASET_NAME = "ruslanmv/ai-medical-chatbot"
OUTPUT_FILE = "medical_dataset_final.json"

ds = load_dataset(DATASET_NAME)

split_name = "train" if "train" in ds else list(ds.keys())[0]
data = ds[split_name]

final_dataset = []

for row in data:
    instruction = (
        row.get("Patient")
        or row.get("question")
        or row.get("input")
        or row.get("instruction")
        or ""
    )

    output = (
        row.get("Doctor")
        or row.get("answer")
        or row.get("output")
        or row.get("response")
        or ""
    )

    instruction = str(instruction).strip()
    output = str(output).strip()

    if instruction and output:
        final_dataset.append({
            "instruction": instruction,
            "output": output
        })

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    json.dump(final_dataset, f, ensure_ascii=False, indent=2)

print("Dataset créé avec succès.")
print(f"Split utilisé : {split_name}")
print(f"Nombre d'exemples : {len(final_dataset)}")
print(f"Fichier généré : {OUTPUT_FILE}")
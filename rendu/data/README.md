# Préparation des Datasets pour le Fine-Tuning de Phi-3.5-Financial

## Présentation

Ce dossier contient l'ensemble des fichiers utilisés pour préparer les datasets destinés au fine-tuning du modèle **Phi-3.5-Financial** dans le cadre du Hackathon IA & Cybersécurité d'Ynov.

Le travail réalisé porte sur :

- l'analyse de la qualité des données ;
- le téléchargement d'un dataset médical depuis Hugging Face ;
- le nettoyage automatique des datasets ;
- la préparation des données pour le fine-tuning LoRA.

---

# Structure du dossier

```text
datasets/
│
├── Analyse&Nettoyage_dataset.py
├── Create_Medical_dataset.py
├── finance_dataset_final.json
├── medical_dataset_final.json
├── test_dataset_16000.json
└── README.md
```

---

# Description des fichiers

## Analyse&Nettoyage_dataset.py

Script Python permettant d'analyser et de nettoyer automatiquement un dataset avant son utilisation pour le fine-tuning.

Le script modifie directement le fichier JSON indiqué dans la variable :

```python
INPUT_FILE = "..."
```

Une sauvegarde du fichier peut être créée automatiquement en activant :

```python
CREATE_BACKUP = True
```

### Vérifications réalisées

Le script effectue les contrôles suivants :

- vérification de la structure JSON ;
- suppression des conversations incomplètes ;
- détection des conversations en double ;
- recherche de backdoors connues ;
- détection des mots de passe et identifiants sensibles ;
- détection des données personnelles ;
- suppression des réponses trop courtes ;
- vérification de la cohérence du domaine.

À la fin de l'analyse, le script affiche :

- le nombre total d'exemples analysés ;
- le nombre de conversations conservées ;
- le nombre de conversations supprimées ;
- les différentes raisons de suppression.

---

## Create_Medical_dataset.py

Ce script télécharge automatiquement le dataset médical :

```
ruslanmv/ai-medical-chatbot
```

depuis **Hugging Face**.

Une fois téléchargé, il extrait les conversations et les convertit au format JSON utilisé dans le projet.

Le fichier généré est :

```
medical_dataset_final.json
```

---

## finance_dataset_final.json

Dataset financier utilisé pour le fine-tuning du modèle.

Chaque conversation est structurée sous forme d'instructions et de réponses.

---

## medical_dataset_final.json

Dataset médical obtenu à partir du dataset Hugging Face.

Les conversations sont converties dans un format compatible avec le fine-tuning LoRA.

---

## test_dataset_16000.json

Dataset de test utilisé pour vérifier le bon fonctionnement des scripts de nettoyage et valider les différentes règles de contrôle avant leur application sur les datasets définitifs.

---

# Analyse des données

Avant le fine-tuning, les datasets ont été analysés selon plusieurs critères de qualité.

Les principaux contrôles réalisés sont :

- validation de la structure JSON ;
- cohérence des conversations ;
- recherche de doublons ;
- détection de données sensibles ;
- détection de données personnelles ;
- qualité des réponses ;
- longueur minimale des réponses ;
- cohérence du domaine traité.

Cette étape permet de garantir que seules des conversations exploitables sont conservées pour l'entraînement du modèle.

---

# Utilisation

## 1. Générer le dataset médical

```bash
python Create_Medical_dataset.py
```

Le script télécharge automatiquement le dataset depuis Hugging Face puis génère :

```
medical_dataset_final.json
```

---

## 2. Nettoyer un dataset

Modifier simplement la variable :

```python
INPUT_FILE = "nom_du_dataset.json"
```

Puis lancer :

```bash
python Analyse&Nettoyage_dataset.py
```

Le fichier sera directement mis à jour avec sa version nettoyée.

---

# Technologies utilisées

- Python 3
- Hugging Face Datasets
- JSON
- LoRA
- Phi-3.5-Financial

---

# Résultat

À l'issue du processus, les datasets sont :

- validés ;
- nettoyés ;
- homogènes ;
- exempts de doublons ;
- débarrassés des données sensibles ;
- prêts pour le fine-tuning LoRA.

---

# Auteur

Amadis TALAVERA Y NARANJO
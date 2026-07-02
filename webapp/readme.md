# TechCorp AI Chat — Challenge IA 7h

## 1. Contexte du projet

Ce projet a été réalisé dans le cadre du challenge IA TechCorp.

L’objectif est de reprendre un projet hérité d’une ancienne équipe technique, vérifier l’état des fichiers fournis, finaliser un déploiement fonctionnel et rendre un modèle financier accessible via une interface web de chat.

La mission principale consiste à déployer un assistant financier appelé `Phi-3.5-Financial` ou équivalent, avec :

- un serveur d’inférence opérationnel ;
- une interface web obligatoire ;
- une API permettant d’interagir avec le modèle en temps réel ;
- une documentation technique du déploiement ;
- une expérimentation séparée autour d’un modèle médical fine-tuné avec LoRA.

---

## 2. Choix technique retenu

Pour garantir un déploiement fonctionnel dans le temps imparti, la solution retenue est :

- **Ollama** pour le serveur d’inférence local ;
- **Phi-3 Mini 4K Instruct quantisé** comme modèle de base ;
- **Flask** pour le backend web ;
- **HTML/CSS/JavaScript** pour l’interface utilisateur ;
- **PowerShell** pour simplifier le lancement sous Windows.

Ce choix permet d’avoir rapidement un modèle accessible localement, une API REST fonctionnelle et une interface web utilisable dans un navigateur.

---

## 3. Audit des fichiers hérités

Après récupération du dépôt initial, l’arborescence du projet contenait notamment :

```txt
techcorp-ai-chat/
├── datasets/
├── logs/
├── medical_project/
├── model_repository/
├── models/
│   └── phi3_financial/
├── ollama_server/
├── scripts/
├── tritton_server/
└── readme.md
```

Le dossier le plus important pour le modèle financier était :

```txt
models/phi3_financial/
├── adapter_config.json
├── adapter_model.safetensors
├── chat_template.jinja
├── special_tokens_map.json
├── tokenizer.json
├── tokenizer_config.json
└── training_args.bin
```

L’analyse de `adapter_config.json` a montré que le modèle fourni n’était pas un modèle complet autonome, mais un **adapter LoRA**.

La ligne importante était :

```json
"base_model_name_or_path": "microsoft/Phi-3-mini-4k-instruct"
```

Cela signifie que l’adapter financier fourni a été entraîné à partir de :

```txt
microsoft/Phi-3-mini-4k-instruct
```

et non directement à partir de `Phi-3.5`.

---

## 4. Problème rencontré avec l’adapter LoRA

Une tentative d’import de l’adapter LoRA dans Ollama a été réalisée.

Exemples de configuration testée dans le `Modelfile` :

```txt
FROM phi3:3.8b-mini-4k-instruct-q4_0

ADAPTER ../models/phi3_financial
```

Puis avec un chemin absolu :

```txt
ADAPTER C:/Users/cesar/Documents/hackatonIA/techcorp-ai-chat/models/phi3_financial
```

Une autre tentative a été réalisée avec le fichier `.safetensors` directement :

```txt
ADAPTER C:/Users/cesar/Documents/hackatonIA/techcorp-ai-chat/models/phi3_financial/adapter_model.safetensors
```

Cependant, l’import direct de l’adapter dans Ollama a échoué avec l’erreur suivante :

```txt
Error: open adapter_config.json: The system cannot find the file specified.
```

Conclusion : l’adapter LoRA financier a bien été identifié et conservé, mais son import direct dans Ollama n’a pas pu être finalisé dans l’environnement Windows pendant le temps imparti.

Pour sécuriser la démonstration, le modèle de production utilise donc le modèle de base compatible, avec un prompt système spécialisé finance.

---

## 5. Déploiement du serveur d’inférence Ollama

### 5.1 Installation d’Ollama

Ollama a été installé sous Windows avec la commande suivante :

```powershell
irm https://ollama.com/install.ps1 | iex
```

L’installation s’est terminée correctement :

```txt
Install complete. Run 'ollama' from the command line.
```

---

### 5.2 Téléchargement du modèle de base

Le modèle de base compatible avec l’adapter identifié est :

```txt
phi3:3.8b-mini-4k-instruct-q4_0
```

Commande utilisée :

```powershell
ollama pull phi3:3.8b-mini-4k-instruct-q4_0
```

Résultat obtenu :

```txt
success
```

---

### 5.3 Configuration du modèle TechCorp

Le fichier utilisé pour créer le modèle est :

```txt
ollama_server/Modelfile
```

Contenu final fonctionnel :

```txt
FROM phi3:3.8b-mini-4k-instruct-q4_0

PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER num_ctx 4096
PARAMETER num_predict 512

SYSTEM """
You are TechCorp Phi-Financial, a financial assistant specialized in finance, business analysis, budgeting, investments, trading, and economic concepts.

You answer clearly and professionally.
You do not invent financial data.
If real-time or missing information is required, you say that you do not have access to it.
You avoid giving guaranteed investment advice.
"""
```

Les paramètres choisis permettent d’obtenir des réponses plus prudentes et moins aléatoires :

- `temperature 0.2` : réponses plus stables ;
- `top_p 0.9` : limite la dispersion des réponses ;
- `num_ctx 4096` : contexte adapté au modèle 4K ;
- `num_predict 512` : limite de génération raisonnable pour une interface chat.

---

### 5.4 Création du modèle Ollama

Commande utilisée :

```powershell
ollama create techcorp-phi-financial -f .\ollama_server\Modelfile
```

Résultat obtenu :

```txt
writing manifest
success
```

Le modèle a donc été créé avec succès sous le nom :

```txt
techcorp-phi-financial
```

---

### 5.5 Vérification du modèle

Commande utilisée :

```powershell
ollama list
```

Résultat obtenu :

```txt
NAME                               SIZE
techcorp-phi-financial:latest      2.2 GB
phi3:3.8b-mini-4k-instruct-q4_0    2.2 GB
```

Le modèle `techcorp-phi-financial` est donc bien présent localement.

---

## 6. Test du modèle en terminal

Le modèle a été testé directement avec :

```powershell
ollama run techcorp-phi-financial
```

Le modèle répond correctement aux questions financières simples.

Exemple de question testée :

```txt
Explique la différence entre chiffre d'affaires, bénéfice net et marge.
```

Ce test valide que le modèle fonctionne en local via Ollama.

---

## 7. Test de l’API Ollama

L’API Ollama a ensuite été testée avec une requête POST vers :

```txt
http://localhost:11434/api/chat
```

Commande utilisée dans PowerShell :

```powershell
$body = @{
    model = "techcorp-phi-financial"
    messages = @(
        @{
            role = "user"
            content = "Explique ce qu'est une marge brute."
        }
    )
    stream = $false
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
    -Uri "http://localhost:11434/api/chat" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body
```

Résultat obtenu :

```txt
model      : techcorp-phi-financial
done       : True
message    : réponse générée par le modèle
```

Ce test valide que le serveur d’inférence Ollama est opérationnel via API REST.

---

## 8. Interface web Flask

Une interface web a été développée avec Flask.

Arborescence ajoutée :

```txt
webapp/
├── app.py
├── dev.ps1
├── requirements.txt
└── templates/
    └── index.html
```

Le backend Flask expose :

```txt
GET  /          → page web principale
POST /api/chat  → endpoint Flask qui relaie les messages vers Ollama
GET  /health    → vérification de l’état du backend et d’Ollama
```

Le backend Flask communique avec Ollama via :

```txt
http://localhost:11434/api/chat
```

Le modèle appelé est :

```txt
techcorp-phi-financial
```

---

## 9. Lancement de l’interface web

Python était bien installé sur la machine, mais la commande `python` n’était pas correctement reconnue dans le PATH Windows.

Pour contourner ce problème, le chemin complet vers Python 3.12 a été utilisé :

```txt
C:\Users\cesar\AppData\Local\Programs\Python\Python312\python.exe
```

Les dépendances installées sont :

```txt
flask
requests
```

Elles sont listées dans :

```txt
webapp/requirements.txt
```

Un script PowerShell a été créé :

```txt
webapp/dev.ps1
```

Commandes disponibles :

```powershell
.\dev.ps1 install
.\dev.ps1 run
.\dev.ps1 health
.\dev.ps1 freeze
.\dev.ps1 clean
```

Depuis le dossier `webapp`, l’interface se lance avec :

```powershell
.\dev.ps1 run
```

Résultat obtenu :

```txt
* Serving Flask app 'app'
* Debug mode: on
* Running on http://127.0.0.1:5000
* Running on http://10.171.218.195:5000
```

L’interface est accessible depuis le navigateur à l’adresse :

```txt
http://localhost:5000
```

---

## 10. Flux complet validé

Le flux complet validé est :

```txt
Navigateur
   ↓
Interface web Flask : http://localhost:5000
   ↓
Backend Flask : POST /api/chat
   ↓
API Ollama : http://localhost:11434/api/chat
   ↓
Modèle : techcorp-phi-financial
   ↓
Réponse affichée dans l’interface web
```

Ce flux a été testé avec succès.

---

## 11. État final du projet

Éléments validés :

```txt
Ollama installé                                      Validé
Modèle de base Phi-3 Mini 4K téléchargé             Validé
Modèle techcorp-phi-financial créé                  Validé
Test en terminal avec ollama run                    Validé
Test API REST avec Invoke-RestMethod                Validé
Backend Flask opérationnel                          Validé
Interface web accessible sur localhost:5000         Validé
Script PowerShell dev.ps1 fonctionnel               Validé
```

Éléments partiellement validés ou à finaliser :

```txt
Import direct de l’adapter LoRA financier dans Ollama     Non finalisé
Fine-tuning médical expérimental complet                  À compléter
Tests cyber exhaustifs                                    À compléter
```

---

## 12. Commandes principales

### Lister les modèles Ollama

```powershell
ollama list
```

### Lancer le modèle en terminal

```powershell
ollama run techcorp-phi-financial
```

### Créer le modèle depuis le Modelfile

```powershell
ollama create techcorp-phi-financial -f .\ollama_server\Modelfile
```

### Lancer l’interface web

```powershell
cd webapp
.\dev.ps1 run
```

### Installer les dépendances web

```powershell
cd webapp
.\dev.ps1 install
```

### Tester le backend Flask

```powershell
cd webapp
.\dev.ps1 health
```

---

## 13. Limites connues

- Le modèle de production actuel utilise Phi-3 Mini 4K avec un prompt système spécialisé finance.
- L’adapter LoRA financier fourni a été identifié, mais son import direct dans Ollama n’a pas été finalisé.
- Le système ne dispose pas d’accès natif aux données financières en temps réel.
- Les réponses du modèle doivent être vérifiées pour tout usage critique.
- Le backend Flask est lancé en mode développement pour la démonstration.
- Le modèle médical reste expérimental et non destiné à la production.

---

## 14. Conclusion

La mission critique est fonctionnelle.

Le projet dispose maintenant :

- d’un serveur d’inférence Ollama opérationnel ;
- d’un modèle local appelé `techcorp-phi-financial` ;
- d’une API REST testée ;
- d’une interface web Flask professionnelle ;
- d’un script de lancement Windows ;
- d’une documentation claire des choix techniques, des tests et des limites.

Le projet est donc prêt pour une démonstration locale du chatbot financier TechCorp.
# Bilan du rendu — Challenge IA TechCorp Industries

## Contexte

Dans le cadre du challenge IA TechCorp Industries, nous, Cesario Bailleul, Amadis Talavera et Thomas Bataille, avons repris un projet hérité d’une précédente équipe technique.  
L’objectif était de valider l’intégrité de l’existant, corriger les éléments nécessaires et finaliser le déploiement d’un assistant financier accessible via une interface web.

Le projet comportait également une partie expérimentale de fine-tuning médical avec LoRA sur Google Colab.

---

## Organisation du travail

Pour des raisons d’organisation, de collaboration et de rapidité pendant le challenge, nous avons travaillé dans un autre dépôt GitHub public.

Le dépôt principal utilisé pour le travail de groupe est disponible ici :

**Lien du repository GitHub :**  
(https://github.com/16ario/hackaton_ynov.git)

Ce dépôt contient les fichiers de travail, les scripts, les rapports et les éléments de rendu produits pendant le challenge.

---

## Travaux réalisés

## INFRA

La partie infrastructure a permis de rendre disponible un serveur d’inférence fonctionnel.

Travaux réalisés :

- installation d’Ollama ;
- création du modèle `techcorp-phi-financial` depuis `ollama_server/Modelfile` ;
- vérification du serveur sur `http://localhost:11434` ;
- exposition du serveur pour l’équipe DEV WEB ;
- configuration des paramètres d’inférence ;
- documentation du choix technique ;
- bonus Docker/Triton testé et documenté.

Résultat : la partie INFRA est validée.

---

## DEV WEB

La partie DEV WEB a permis de créer une interface de chat fonctionnelle pour interagir avec le modèle financier.

Travaux réalisés :

- développement d’une interface web avec Flask, HTML, CSS et JavaScript ;
- intégration avec l’API Ollama ;
- affichage des messages utilisateur et assistant ;
- gestion d’un historique de conversation côté navigateur ;
- affichage de l’état de connexion au serveur ;
- lancement de l’application en une seule commande depuis `rendu/devweb/`.

Résultat : la partie DEV WEB est validée.

---

## IA

La partie IA a permis de tester le modèle financier et de réaliser une expérimentation de fine-tuning médical.

Travaux réalisés :

- tests du modèle financier avec plus de 10 questions ;
- évaluation de la fiabilité du modèle ;
- identification des limites du modèle ;
- documentation des paramètres d’inférence ;
- fine-tuning LoRA expérimental sur Google Colab ;
- récupération des métriques d’entraînement ;
- test conversationnel du modèle médical expérimental.

Résultat : la partie IA est validée.

---

## DATA

La partie DATA a permis d’analyser et préparer les datasets utilisés par le projet.

Travaux réalisés :

- analyse des datasets hérités ;
- identification des données utilisables et non utilisables ;
- détection d’anomalies ;
- écriture d’un script Python d’analyse et de nettoyage ;
- préparation du dataset médical pour l’équipe IA.

Résultat : la partie DATA est validée.

---

## CYBER

La partie CYBER a permis d’auditer les artefacts hérités et de tester la robustesse du modèle.

Travaux réalisés :

- audit des fichiers hérités ;
- identification de risques critiques ;
- analyse d’un fichier `training_args.bin` suspect ;
- détection d’un data poisoning dans les datasets ;
- identification d’une possible exfiltration via données encodées ;
- tests de robustesse du modèle financier ;
- recommandations de sécurité.

Résultat : la partie CYBER est validée, avec des recommandations importantes avant toute mise en production réelle.

---

## Résultat global

Le projet a permis de produire :

- un serveur d’inférence opérationnel ;
- une interface web fonctionnelle ;
- un modèle financier testé et évalué ;
- une expérimentation de fine-tuning médical ;
- des datasets analysés et préparés ;
- un audit cybersécurité documenté ;
- des rapports par thème.

Le modèle financier est utilisable pour une démonstration ou un assistant pédagogique interne.

Il ne doit pas être utilisé seul pour des décisions financières critiques sans supervision, garde-fous et sources de données fiables.

Le modèle médical reste strictement expérimental et ne doit pas être utilisé pour un usage médical réel.

---

## Limites identifiées

Les principales limites sont :

- le modèle hérité n’est pas directement exploitable comme modèle complet autonome ;
- certains datasets hérités contiennent des éléments suspects ;
- le modèle financier n’a pas accès aux données temps réel ;
- l’interface web ne contient pas encore d’authentification ;
- le stockage de l’historique reste côté navigateur ;
- le modèle médical fine-tuné reste expérimental ;
- un déploiement production nécessiterait davantage de sécurité.

---

## Améliorations recommandées

Pour une version production, il faudrait ajouter :

- authentification ;
- contrôle d’accès ;
- chiffrement des conversations ;
- rate limiting ;
- supervision ;
- journalisation sécurisée ;
- gestion des secrets ;
- validation métier des datasets ;
- garde-fous IA ;
- déploiement isolé avec HTTPS ;
- sources financières fiables pour les données temps réel.

---

## Conclusion

Nous avons validé l’héritage technique, corrigé les points bloquants et déployé un assistant financier fonctionnel avec une interface web.

La mission principale est remplie : le modèle financier est accessible via une interface de chat professionnelle.

La mission expérimentale est également réalisée : un fine-tuning médical LoRA a été lancé sur Google Colab, avec métriques d’entraînement documentées.

Le projet est donc prêt pour une démonstration, tout en documentant clairement les limites et les conditions nécessaires avant une éventuelle mise en production.

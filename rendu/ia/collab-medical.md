# Fine-tuning médical expérimental — Colab

## Objectif

L’objectif de cette partie est de réaliser un fine-tuning LoRA expérimental d’un modèle de langage sur un dataset médical.

Cette mission correspond à la partie R&D du challenge TechCorp. Le modèle obtenu n’a pas vocation à être utilisé en production médicale. Il sert uniquement à démontrer la faisabilité technique d’un entraînement spécialisé sur un domaine sensible.

Le domaine médical impose une attention particulière, car une mauvaise réponse peut avoir un impact sur la sécurité d’un utilisateur. Ce travail doit donc être compris comme une preuve de concept technique, et non comme un modèle médical fiable.

---

## Source de la consigne

La consigne de fine-tuning médical est fournie dans le fichier `medical_project/Readme.md`.

Ce fichier demande d’expérimenter un fine-tuning médical avec un dataset de conversations médicales, en suivant des métriques d’entraînement comme la loss et le nombre d’epochs.

---

## Notebook Colab

Le notebook Google Colab utilisé pour cette expérimentation est disponible ici :

https://colab.research.google.com/drive/1uqz4Ob6yJDaqC3Nzq-JGpqDkyNuSnEEr?usp=sharing

---

## Modèle utilisé

Le modèle de base utilisé est `TinyLlama/TinyLlama-1.1B-Chat-v1.0`.

Ce modèle a été choisi car il est léger et adapté à une expérimentation sur Google Colab.

Le sujet mentionne des modèles comme Phi-3.5, Llama, Mistral ou BioGPT, mais l’objectif de cette mission expérimentale était surtout de valider la chaîne de fine-tuning LoRA dans le temps imparti. TinyLlama permet donc de réaliser un entraînement rapide avec des ressources limitées.

---

## Dataset utilisé

Le dataset médical utilisé est `ruslanmv/ai-medical-chatbot`.

Ce dataset contient des conversations médicales de type patient / médecin.

Pour respecter les contraintes de temps et de ressources de Google Colab, l’entraînement a été réalisé sur un sous-ensemble du dataset.

---

## Méthode de fine-tuning

La méthode retenue est LoRA.

LoRA permet d’adapter un modèle en entraînant seulement une petite partie de ses paramètres, au lieu de modifier l’ensemble du modèle de base. Cette approche est adaptée aux environnements limités comme Google Colab.

Les choix techniques utilisés sont :

- modèle léger ;
- fine-tuning LoRA ;
- sous-échantillonnage du dataset ;
- entraînement court ;
- suivi de la loss ;
- test conversationnel après entraînement.

---

## Métriques d’entraînement

| Élément | Valeur |
|---|---|
| Lien Colab | https://colab.research.google.com/drive/1uqz4Ob6yJDaqC3Nzq-JGpqDkyNuSnEEr?usp=sharing |
| Modèle utilisé | TinyLlama/TinyLlama-1.1B-Chat-v1.0 |
| Dataset utilisé | ruslanmv/ai-medical-chatbot |
| Méthode | LoRA |
| Nombre d’epochs | 1 |
| Max steps | 30 |
| Loss initiale | 2.8687329292297363 |
| Loss finale | 2.103435516357422 |
| Train loss | 2.296117146809896 |
| Durée approximative | 0.76 minute |

---

## Interprétation des métriques

La loss initiale était de 2.8687.

Après l’entraînement, la loss finale est descendue à 2.1034.

Cette baisse indique que le modèle s’est adapté au sous-ensemble du dataset médical utilisé pendant l’expérimentation.

La train loss obtenue est de 2.2961.

Ces résultats montrent que la chaîne de fine-tuning fonctionne techniquement :

1. chargement du dataset médical ;
2. préparation des conversations ;
3. chargement du modèle de base ;
4. configuration LoRA ;
5. lancement de l’entraînement ;
6. suivi des métriques ;
7. test conversationnel après entraînement.

L’entraînement a été volontairement limité à 30 steps afin de respecter les contraintes de temps du challenge et les ressources disponibles sur Colab.

---

## Test conversationnel après entraînement

Un test conversationnel a été réalisé après le fine-tuning.

Question posée au modèle :

J’ai de la fièvre et mal à la gorge depuis deux jours. Que dois-je faire ?

Réponse générée par le modèle :

Hi, I am Dr. Ramesh. I am glad to see you here. I will try to help you. First of all, you should know that fever is a sign of infection. So, it is not a sign of any disease. So, you should not worry about it. Secondly, you should drink plenty of water and avoid alcohol. Thirdly, you should take rest and drink plenty of fluids. Fourthly, you should take pain killers and anti-inflammatory drugs. Fifthly, you should take antibiot...

---

## Analyse du test conversationnel

Le test montre que le modèle est capable de produire une réponse cohérente sur certains éléments simples, comme le repos, l’hydratation et le lien possible entre fièvre et infection.

Cependant, la réponse présente plusieurs limites importantes :

- le modèle répond en anglais alors que la consigne était en français ;
- il adopte une posture de médecin ;
- il donne des recommandations médicales potentiellement sensibles ;
- il mentionne les antibiotiques sans consultation médicale ;
- la réponse semble coupée ou incomplète ;
- le niveau de prudence attendu n’est pas suffisant pour un domaine médical.

Ce résultat confirme que le fine-tuning LoRA a fonctionné techniquement, mais que le modèle obtenu n’est pas fiable pour un usage médical réel.

---

## Résultat obtenu

Le fine-tuning médical expérimental a bien été réalisé sur Google Colab.

Le modèle TinyLlama a été adapté avec LoRA sur le dataset `ruslanmv/ai-medical-chatbot`.

La baisse de la loss montre que l’entraînement a eu un effet mesurable sur le modèle.

Cependant, le test conversationnel montre que le modèle reste insuffisamment sécurisé et insuffisamment fiable pour un usage médical.

---

## Limites

Le modèle entraîné reste expérimental.

Il ne doit pas être utilisé pour :

- établir un diagnostic médical ;
- recommander un traitement ;
- remplacer un professionnel de santé ;
- prendre une décision médicale réelle ;
- fournir un avis médical automatisé.

Même après fine-tuning, un modèle de langage peut produire :

- des erreurs ;
- des hallucinations ;
- des conseils incomplets ;
- des recommandations dangereuses ;
- des réponses non adaptées au contexte utilisateur.

---

## Améliorations nécessaires avant production

Avant tout usage réel dans le domaine médical, il faudrait ajouter :

- un dataset médical validé par des professionnels ;
- une évaluation par des experts de santé ;
- des garde-fous empêchant les diagnostics directs ;
- un rappel systématique de consulter un professionnel de santé ;
- des tests de sécurité plus poussés ;
- une détection des demandes urgentes ;
- une conformité réglementaire adaptée aux données de santé ;
- une supervision humaine.

---

## Conclusion

La mission expérimentale de fine-tuning médical a été réalisée.

Le notebook Colab démontre que la chaîne technique fonctionne : chargement du dataset, préparation des données, configuration LoRA, entraînement, suivi des métriques et test conversationnel.

La loss est passée de 2.8687 à 2.1034, ce qui montre une amélioration pendant l’entraînement.

Cependant, le modèle obtenu reste un prototype expérimental. Il n’est pas déployable pour un usage médical réel, car le test conversationnel montre encore des réponses trop risquées, notamment la mention de médicaments ou d’antibiotiques sans validation médicale.

Le fine-tuning est donc validé techniquement, mais le modèle médical n’est pas validé pour la production.
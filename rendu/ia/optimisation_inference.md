# Optimisation des paramètres d’inférence — TechCorp AI

## Objectif

L’objectif de cette partie est de documenter les paramètres d’inférence utilisés pour le modèle financier `techcorp-phi-financial`.

Ces paramètres permettent d’obtenir des réponses plus stables, plus prudentes et plus adaptées à un assistant financier.

---

## Modèle utilisé

- Modèle Ollama : `techcorp-phi-financial`
- Modèle de base : `phi3:3.8b-mini-4k-instruct-q4_0`
- Serveur d’inférence : Ollama
- URL locale : `http://localhost:11434`
- Usage visé : assistant financier pédagogique et démonstration interne

---

## Paramètres configurés

Les paramètres principaux utilisés sont les suivants :

| Paramètre | Valeur | Rôle |
|---|---:|---|
| `temperature` | `0.2` | Réduit l’aléatoire dans les réponses |
| `top_p` | `0.9` | Limite les choix de tokens aux plus probables |
| `num_ctx` | `4096` | Définit la taille du contexte |
| `num_predict` | `512` | Limite la longueur maximale des réponses |

---

## Justification des paramètres

### Temperature — `0.2`

La température contrôle le niveau de créativité du modèle.

Une valeur basse comme `0.2` permet d’obtenir des réponses plus stables et moins aléatoires.

Ce choix est adapté à un assistant financier, car le domaine nécessite de la précision, de la prudence et peu d’improvisation.

Une température trop élevée pourrait augmenter le risque de réponses incohérentes ou inventées.

---

### Top-p — `0.9`

Le paramètre `top_p` limite les choix du modèle aux tokens les plus probables.

Avec une valeur de `0.9`, le modèle garde une certaine flexibilité tout en évitant des réponses trop imprévisibles.

Ce réglage permet de conserver des réponses naturelles sans trop augmenter le risque d’hallucination.

---

### Num_ctx — `4096`

Le paramètre `num_ctx` définit la taille maximale du contexte que le modèle peut prendre en compte.

Une valeur de `4096` est suffisante pour gérer une conversation de démonstration avec plusieurs échanges.

Cela permet au modèle de garder une partie de l’historique de conversation sans consommer trop de ressources.

---

### Num_predict — `512`

Le paramètre `num_predict` limite la longueur de la réponse générée.

Une limite de `512` tokens permet d’obtenir des réponses détaillées mais raisonnables.

Ce choix évite que le modèle produise des réponses trop longues, trop coûteuses ou difficiles à relire.

---

## Prompt système

Le modèle est également encadré par un prompt système spécialisé finance.

Ce prompt demande au modèle de :

- répondre comme un assistant financier ;
- rester clair et professionnel ;
- ne pas inventer de données financières ;
- signaler l’absence d’accès aux données temps réel ;
- éviter les conseils d’investissement garantis.

Ce cadrage est important car il réduit les comportements risqués du modèle.

---

## Résultats observés

Les tests réalisés montrent que les paramètres choisis permettent d’obtenir un comportement globalement prudent.

Le modèle :

- refuse de garantir un rendement financier ;
- évite de donner un cours boursier en temps réel inventé ;
- déconseille d’investir toutes ses économies dans une seule action ;
- résiste à une tentative simple de prompt injection ;
- refuse de conserver un faux mot de passe ;
- refuse de produire un diagnostic médical hors périmètre.

Ces résultats sont cohérents avec l’objectif d’un assistant financier encadré.

---

## Limites observées

Malgré ces paramètres, certaines limites restent présentes.

Les tests ont montré :

- une réponse parfois instable ;
- une réponse partiellement tronquée ;
- quelques approximations de contexte ;
- des oublis sur certains indicateurs financiers importants ;
- une génération parfois moins propre sur les réponses longues.

Ces limites montrent que les paramètres d’inférence améliorent le comportement du modèle, mais ne suffisent pas à garantir une fiabilité complète.

---

## Optimisations possibles

Pour améliorer encore le modèle, plusieurs pistes sont possibles :

- réduire encore `num_predict` pour limiter les réponses trop longues ;
- ajouter des consignes métier plus strictes dans le prompt système ;
- ajouter des garde-fous côté application ;
- filtrer les demandes risquées avant l’appel au modèle ;
- connecter le modèle à des sources financières fiables pour les données temps réel ;
- ajouter une supervision humaine pour les usages sensibles ;
- réaliser des tests réguliers de robustesse.

---

## Conclusion

Les paramètres d’inférence choisis permettent d’obtenir un assistant financier plus stable, prudent et adapté à une démonstration.

Le réglage `temperature = 0.2` limite l’aléatoire, `top_p = 0.9` conserve des réponses naturelles, `num_ctx = 4096` permet de gérer le contexte, et `num_predict = 512` limite la longueur des réponses.

Le modèle reste cependant expérimental et ne doit pas être utilisé seul pour des décisions financières critiques.
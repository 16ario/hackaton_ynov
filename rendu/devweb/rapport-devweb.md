# Rapport DEV WEB — TechCorp Industries

## Objectif

L’objectif de la partie DEV WEB était de créer une interface web permettant d’interagir avec le modèle financier déployé par l’équipe INFRA.

L’interface devait permettre :

- d’envoyer une question au modèle ;
- d’afficher la réponse du modèle ;
- de conserver l’historique de conversation ;
- d’afficher l’état de connexion au serveur ;
- de lancer l’application en une seule commande depuis `rendu/devweb/`.

---

## Choix technique

La solution retenue est une application Flask avec HTML, CSS et JavaScript.

Flask a été choisi car il permet :

- une mise en place rapide ;
- une intégration simple avec Python ;
- des appels HTTP vers Ollama ;
- une architecture compréhensible ;
- un lancement local simple ;
- une séparation claire entre backend et interface utilisateur.

Le backend Flask sert d’intermédiaire entre le navigateur et le serveur d’inférence Ollama.

---

## Structure du dossier

La partie DEV WEB est placée dans le dossier `rendu/devweb/`.

Structure attendue :

- `app.py`
- `dev.ps1`
- `requirements.txt`
- `templates/index.html`
- `static/css/style.css`
- `static/js/app.js`
- `rapport_devweb.md`

Cette structure permet de séparer :

- le backend Flask ;
- les templates HTML ;
- les fichiers CSS ;
- les fichiers JavaScript ;
- le script de lancement ;
- la documentation.

---

## Lancement en une commande

L’application peut être lancée depuis `rendu/devweb/` avec la commande suivante :

`.\dev.ps1`

Le script `dev.ps1` permet de :

- vérifier les dépendances ;
- installer les dépendances Python depuis `requirements.txt` ;
- configurer l’URL du serveur Ollama ;
- lancer le serveur Flask ;
- rendre l’interface disponible localement.

L’interface est ensuite accessible sur :

`http://127.0.0.1:5000`

ou :

`http://localhost:5000`

Ce point valide la contrainte du challenge demandant un lancement en une seule commande depuis le dossier `rendu/devweb/`.

---

## Connexion au serveur d’inférence

L’application se connecte au serveur Ollama déployé par l’équipe INFRA.

URL utilisée :

`http://127.0.0.1:11434`

Modèle utilisé :

`techcorp-phi-financial`

Le backend Flask reçoit les messages envoyés depuis le navigateur, les transmet à Ollama, puis renvoie la réponse du modèle à l’interface web.

L’utilisateur n’appelle donc pas directement Ollama depuis le navigateur. Il passe par le backend Flask.

---

## Fonctionnement général

Le fonctionnement de l’application est le suivant :

Utilisateur → Navigateur → Flask → Ollama → Modèle financier → Flask → Navigateur

Étapes détaillées :

1. l’utilisateur écrit une question dans l’interface ;
2. le JavaScript envoie la question au backend Flask ;
3. Flask prépare la requête pour Ollama ;
4. Ollama interroge le modèle `techcorp-phi-financial` ;
5. le modèle génère une réponse ;
6. Flask récupère la réponse ;
7. l’interface affiche la réponse dans la conversation.

Cette architecture est simple et adaptée à une démonstration fonctionnelle.

---

## Routes Flask principales

L’application Flask expose plusieurs routes.

| Route | Méthode | Rôle |
|---|---|---|
| `/` | GET | Affiche l’interface web |
| `/api/chat` | POST | Envoie une question au modèle |
| `/health` | GET | Vérifie l’état du serveur Ollama |

La route `/api/chat` est utilisée pour les échanges avec le modèle.

La route `/health` permet de vérifier si le serveur Ollama est disponible.

---

## Interface utilisateur

L’interface web contient :

- une zone de conversation ;
- un champ de saisie ;
- un bouton d’envoi ;
- des questions rapides ;
- un affichage des messages utilisateur ;
- un affichage des réponses assistant ;
- un indicateur connecté / déconnecté ;
- une gestion de l’historique ;
- un bouton de nouvelle conversation.

L’objectif était de proposer une interface simple, lisible et professionnelle pour tester le modèle financier en temps réel.

---

## Historique de conversation

L’historique de conversation est conservé côté navigateur avec `localStorage`.

Ce choix a été fait pour éviter de stocker les conversations côté serveur sans authentification.

Avantages :

- pas de base serveur contenant les messages ;
- pas de stockage centralisé non sécurisé ;
- simplicité pour la démonstration ;
- réduction du risque côté backend ;
- historique disponible après rechargement de la page avec la même URL.

Limites :

- l’historique dépend du navigateur utilisé ;
- l’historique dépend de l’URL exacte ;
- `localhost`, `127.0.0.1` et une URL Cloudflare ont des historiques séparés ;
- `localStorage` n’est pas adapté au stockage de données sensibles en production.

Ce choix est acceptable pour une démonstration locale, mais pas pour une version production.

---

## État de connexion

L’interface affiche l’état du serveur d’inférence.

Le backend Flask interroge Ollama via la route `/health`.

L’interface peut afficher :

- connecté ;
- déconnecté ;
- erreur de communication.

Cela permet à l’utilisateur de savoir rapidement si le problème vient :

- du serveur Ollama ;
- du modèle ;
- du backend Flask ;
- ou de l’interface web.

---

## Gestion des erreurs

L’application gère plusieurs cas d’erreur :

- message vide ;
- serveur Ollama indisponible ;
- erreur HTTP ;
- délai de réponse trop long ;
- réponse invalide ;
- erreur de communication entre Flask et Ollama.

En cas d’erreur, un message est affiché dans l’interface afin d’éviter que l’utilisateur reste bloqué sans information.

---

## Sécurité

La version actuelle est adaptée à une démonstration locale.

Les choix de sécurité réalisés sont :

- aucune conversation n’est stockée côté serveur ;
- aucune base de données non sécurisée n’est utilisée ;
- aucun mot de passe ou secret n’est stocké dans le frontend ;
- l’utilisateur passe par Flask pour communiquer avec Ollama ;
- l’état de connexion est visible ;
- l’exposition via Cloudflare Tunnel reste temporaire si elle est utilisée.

Le stockage serveur des conversations a volontairement été évité, car l’application ne possède pas encore :

- authentification ;
- comptes utilisateurs ;
- contrôle d’accès ;
- chiffrement des conversations ;
- politique de rétention ;
- séparation des historiques par utilisateur.

---

## Limites de sécurité

La version actuelle ne contient pas :

- authentification ;
- comptes utilisateurs ;
- contrôle d’accès ;
- chiffrement applicatif ;
- base de données sécurisée ;
- rate limiting ;
- journalisation sécurité complète ;
- gestion avancée des sessions ;
- politique de conservation ou suppression des conversations.

Ces limites sont acceptables pour un challenge de démonstration, mais elles devraient être corrigées avant tout usage en production.

---

## Améliorations possibles

Pour une version production, il faudrait ajouter :

- authentification locale ou SSO ;
- base de données sécurisée ;
- séparation des conversations par utilisateur ;
- chiffrement des messages ;
- suppression maîtrisée des historiques ;
- export des conversations ;
- contrôle d’accès sur chaque conversation ;
- rate limiting ;
- logs de sécurité sans contenu sensible ;
- HTTPS ;
- reverse proxy ;
- déploiement Docker ;
- supervision.

Une version production devrait également éviter d’exposer directement Ollama à Internet. L’utilisateur devrait toujours passer par un backend applicatif sécurisé.

---

## Résultat obtenu

La partie DEV WEB valide les points suivants :

- une interface de chat a été développée ;
- l’interface communique avec Ollama ;
- le modèle financier répond en temps réel ;
- l’historique de conversation est affiché ;
- l’état de connexion au serveur est visible ;
- l’application peut être lancée en une commande depuis `rendu/devweb/`.

---

## Conclusion

La mission DEV WEB est validée.

L’interface Flask permet d’interagir avec le modèle financier déployé par l’équipe INFRA. Elle fournit une expérience simple, claire et fonctionnelle pour tester le modèle en temps réel.

La solution est adaptée à une démonstration et à un prototype interne.

Pour une version production, il faudrait renforcer la sécurité avec authentification, contrôle d’accès, stockage sécurisé, chiffrement, supervision et exposition réseau mieux contrôlée.
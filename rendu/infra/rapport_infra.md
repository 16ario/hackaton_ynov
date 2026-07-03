# Rapport INFRA — TechCorp Industries

## Objectif

L’objectif de la partie INFRA était de rendre disponible un serveur d’inférence permettant d’utiliser l’assistant financier TechCorp.

La mission consistait à installer Ollama, créer et démarrer le modèle depuis le fichier `ollama_server/Modelfile`, vérifier que le serveur répondait localement, puis le rendre accessible à l’équipe DEV WEB.

Un bonus de dockerisation avec Triton Inference Server a également été réalisé.

---

## Choix technique principal

La solution principale retenue est Ollama.

Ollama a été choisi car il permet de déployer rapidement un modèle de langage localement, avec une API HTTP simple à utiliser côté DEV WEB.

Les avantages principaux sont :

- installation rapide ;
- API locale disponible sur le port 11434 ;
- simplicité d’intégration avec Flask ;
- compatibilité avec des modèles quantisés ;
- possibilité de créer un modèle personnalisé via un `Modelfile`.

L’URL locale du serveur est :

`http://localhost:11434`

---

## Modèle déployé

Le modèle déployé est :

`techcorp-phi-financial`

Il a été créé à partir du fichier :

`ollama_server/Modelfile`

Le modèle de base utilisé est :

`phi3:3.8b-mini-4k-instruct-q4_0`

Le modèle est encadré par un prompt système spécialisé finance afin de répondre comme un assistant financier professionnel.

---

## Vérification de l’héritage

Pendant l’analyse du projet hérité, une incohérence a été identifiée.

Le dossier `models/phi3_financial/` ne contient pas un modèle complet directement exploitable par Ollama. Il contient principalement un adaptateur LoRA.

Le fichier `adapter_config.json` indique que le modèle de base associé est :

`microsoft/Phi-3-mini-4k-instruct`

Cela signifie que l’héritage ne correspond pas à un modèle Phi-3.5 complet autonome, mais plutôt à un adaptateur nécessitant un modèle de base compatible.

Pour garantir un déploiement fonctionnel dans le temps imparti, le choix a été fait de créer un modèle Ollama opérationnel basé sur Phi-3 Mini quantisé, avec un prompt système spécialisé finance.

Cette limite a été documentée afin de ne pas présenter l’héritage comme un modèle complet prêt à l’emploi.

---

## Paramètres d’inférence

Les paramètres utilisés dans le `Modelfile` sont :

| Paramètre | Valeur | Justification |
|---|---:|---|
| temperature | 0.2 | Réduit l’aléatoire des réponses |
| top_p | 0.9 | Garde des réponses naturelles mais contrôlées |
| num_ctx | 4096 | Permet de conserver un contexte suffisant |
| num_predict | 512 | Limite la longueur des réponses |

Ces réglages sont adaptés à un assistant financier, car les réponses doivent rester prudentes, stables et éviter les inventions.

---

## Création du modèle

Le modèle a été créé avec la commande suivante :

`ollama create techcorp-phi-financial -f .\ollama_server\Modelfile`

La présence du modèle a été vérifiée avec :

`ollama list`

Le modèle `techcorp-phi-financial` apparaît bien dans la liste des modèles disponibles.

---

## Vérification du serveur Ollama

Le serveur Ollama a été testé avec l’endpoint suivant :

`http://127.0.0.1:11434/api/tags`

Cet endpoint permet de vérifier que le serveur répond et que les modèles disponibles sont bien exposés.

Un test d’inférence a également été réalisé avec l’endpoint :

`http://localhost:11434/api/chat`

Le serveur répond correctement aux requêtes du modèle.

---

## Accessibilité pour DEV WEB

L’équipe DEV WEB devait pouvoir accéder au serveur d’inférence.

En local, l’URL utilisée est :

`http://localhost:11434`

Pour permettre un accès depuis d’autres machines, Ollama peut être lancé avec :

`OLLAMA_HOST=0.0.0.0:11434`

Cela permet au serveur d’écouter sur toutes les interfaces réseau.

Une règle de pare-feu Windows a également été ajoutée pour autoriser le port 11434.

Lorsque les membres du groupe ne sont pas sur le même réseau local, un tunnel temporaire Cloudflare peut être utilisé pour exposer le serveur pendant la démonstration.

---

## Intégration avec DEV WEB

Le flux d’intégration est le suivant :

Utilisateur → Interface Flask → API Flask → API Ollama → Modèle financier → Réponse affichée dans l’interface

L’utilisateur n’interagit pas directement avec Ollama. L’interface web passe par le backend Flask.

---

## Bonus Docker/Triton

### Objectif

Un bonus de dockerisation a été réalisé avec le dossier `tritton_server/`.

L’objectif était de vérifier que le projet pouvait aussi être lancé dans un environnement conteneurisé basé sur NVIDIA Triton Inference Server.

Cette partie montre une possibilité de déploiement plus industrialisé.

---

### Mise en place

Le dossier `tritton_server/` contient les fichiers suivants :

- `Dockerfile`
- `docker-compose.yml`
- `docker.ps1`

Le conteneur est basé sur NVIDIA Triton Inference Server.

Les ports exposés sont :

| Port | Usage |
|---|---|
| 8000 | API HTTP |
| 8001 | API gRPC |
| 8002 | Métriques |

---

### Commandes utilisées

Construction de l’image :

`.\tritton_server\docker.ps1 build`

Démarrage du conteneur :

`.\tritton_server\docker.ps1 start`

Vérification du conteneur :

`docker ps --filter "name=techcorp-triton"`

---

### Tests réalisés

Les endpoints de santé Triton ont été testés.

Test du serveur actif :

`curl.exe -i http://localhost:8000/v2/health/live`

Test du serveur prêt :

`curl.exe -i http://localhost:8000/v2/health/ready`

Résultat attendu :

`HTTP/1.1 200 OK`

Les réponses HTTP 200 OK confirment que le serveur Triton démarre correctement.

---

### Résultat obtenu

Le conteneur Triton démarre correctement.

Les ports 8000, 8001 et 8002 sont exposés.

Les endpoints `/v2/health/live` et `/v2/health/ready` répondent avec un statut HTTP 200 OK.

Cela valide la partie infrastructure du bonus Docker/Triton.

---

### Limite identifiée

Le modèle hérité est détecté côté configuration, mais son chargement complet est limité par l’environnement matériel.

La machine utilisée ne dispose pas de GPU NVIDIA disponible pour Docker. Le chargement complet du modèle peut donc être très lent ou instable en CPU.

Pour éviter un blocage pendant la démonstration, le chargement automatique complet du modèle a été limité.

Cette limite est matérielle et ne remet pas en cause la validation du serveur Triton lui-même.

---

### Conclusion du bonus Triton

La dockerisation avec Triton est validée au niveau infrastructure.

Le conteneur démarre, les ports standards sont exposés et les endpoints de santé répondent correctement.

Le bonus est donc validé pour la partie déploiement serveur.

La principale limite concerne le chargement complet du modèle, qui nécessiterait un environnement plus adapté avec GPU NVIDIA pour une exécution fluide en production.

---

## Sécurité et limites

La solution actuelle est adaptée à une démonstration locale.

Les principales limites sont :

- Ollama ne doit pas être exposé directement sur Internet en production ;
- Cloudflare Tunnel doit rester temporaire ;
- l’API Ollama ne contient pas d’authentification native ;
- le modèle n’a pas accès aux données financières temps réel ;
- le serveur doit être protégé par un backend applicatif en production.

Pour une version production, il faudrait ajouter :

- authentification ;
- contrôle d’accès ;
- HTTPS ;
- reverse proxy ;
- supervision ;
- rate limiting ;
- journalisation sécurisée ;
- réseau isolé pour le serveur d’inférence.

---

## Conclusion

La mission INFRA est validée.

Le serveur Ollama est opérationnel, le modèle `techcorp-phi-financial` est disponible, l’API répond correctement et l’équipe DEV WEB peut s’y connecter.

Le bonus Triton a également été validé au niveau infrastructure avec un conteneur Docker fonctionnel et des healthchecks positifs.

La solution est adaptée à un prototype et à une démonstration. Un déploiement production nécessiterait un renforcement réseau, applicatif et sécurité.
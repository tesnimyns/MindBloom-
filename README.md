# 🌿 MindBloom – Assistant émotionnel intelligent

MindBloom est une application mobile Flutter qui aide les utilisateurs à suivre et améliorer leur bien-être émotionnel. Elle combine des fonctionnalités de détection d'humeur, un chatbot empathique basé sur un modèle LLaMA 3 local (via Ollama), et une visualisation des scores émotionnels grâce à Supabase.

 ## Fonctionnalités principales
   ### Chatbot émotionnel (LLaMA 3)
Un assistant basé sur LLaMA 3 localement exécuté via Ollama, offrant des réponses bienveillantes et personnalisées.

### Analyse de texte émotionnel
L’utilisateur peut écrire ses pensées et obtenir une évaluation de son état émotionnel (score, niveau de dépression).

### Analyse de selfie & voix 
Intégration prévue de la reconnaissance émotionnelle à partir d’image ou d’audio.

### Visualisation des scores émotionnels
Les scores sont stockés dans Supabase et affichés dans des graphiques en pourcentage. 

### Authentification Supabase
Gestion des utilisateurs et des données de manière sécurisée.

## Technologies utilisées

Flutter – UI cross-platform

Supabase – Backend, base de données, auth

Ollama + LLaMA 3 – Chatbot local

FastAPI  – Pour analyse externe du texte
Flask   _ Pour analyse des images

FL Chart – Pour les graphiques émotionnels

##  Installation
### Prérequis
 Ollama installé avec le modèle llama3
 Flutter SDK
 Supabase configuré avec tables : score, thoughts, users,etc.

###  Création de l’environnement virtuel et installation des dépendances

#### 1. Créer un environnement virtuel
python -m venv monenv

#### 2. Activer l’environnement virtuel
##### ▶️ Sous Windows :
monenv\Scripts\activate

##### ▶️ Sous macOS / Linux :
source monenv/bin/activate

#### 3. Installer les dépendances du projet
pip install -r requirements.txt

 
 
 ###  Démarrage local de LLaMA 3
 ollama run llama3

 ###  Configuration de l’URL de l’API (Flutter)
 Uri.parse('http://10.0.2.2:11434/api/chat'), // pour Android Emulator

 📱 Utilise http://192.168.X.X:11434 pour un vrai appareil

 
## Objectif
MindBloom vise à offrir une assistance émotionnelle de proximité, tout en respectant la vie privée (modèle LLaMA exécuté en local). Le projet est conçu comme une démonstration de la synergie entre IA, bien-être et développement mobile moderne.



 ⚠️  Modifier l’URL ngrok dans le  fichier text_input_page.dart

 
 




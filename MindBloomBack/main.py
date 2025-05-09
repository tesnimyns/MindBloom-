from fastapi import FastAPI
from pydantic import BaseModel

import os
import json
from transformers import pipeline
from supabase import create_client, Client
from datetime import datetime



url = "https://xcieeonpxsirifymoohv.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaWVlb25weHNpcmlmeW1vb2h2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2MTAwMTYsImV4cCI6MjA2MTE4NjAxNn0.rOd2dita7BEmVnU9NhaOd2T76IO4j4H_NRbffI8dwk4"




# Initialiser Supabase
supabase: Client = create_client(url, key)

# Chargement d'un modèle pour la classification de sentiment en anglais
sentiment_classifier = pipeline('text-classification', model="distilbert-base-uncased-finetuned-sst-2-english")

app = FastAPI()

class Thought(BaseModel):
    user_id: str
    content: str

# Fonction d'analyse de texte plus sophistiquée pour la détection de dépression (phrases en anglais)
def analyze_depression_text(text):
    # Mots-clés associés à différents niveaux de dépression (en anglais)
    depression_keywords = {
        "severe": ["suicide", "die", "death", "kill myself", "end my life", "hopeless", "worthless", "suffering", 
                  "unbearable", "burden", "end it all", "empty", "despair", "no reason to live"],
        "moderate": ["sad", "depressed", "alone", "lonely", "tired", "exhausted", "anxiety", "stress", 
                    "unhappy", "pain", "crying", "grief", "anguish", "miserable", "overwhelmed"],
        "normal": ["content", "good", "happy", "happiest","positive", "hope", "motivation", 
                 "energy", "future", "pleasure", "satisfaction", "joy", "excited", "love"]
    }
    
    # Initialisation des compteurs
    severe_count = 0
    moderate_count = 0
    normal_count = 0
    
    # Analyse du texte par mots-clés
    text_lower = text.lower()
    for word in depression_keywords["severe"]:
        if word in text_lower:
            severe_count += 1
    
    for word in depression_keywords["moderate"]:
        if word in text_lower:
            moderate_count += 1
    
    for word in depression_keywords["normal"]:
        if word in text_lower:
            normal_count += 2  # Double l'impact des mots positifs
    
    # Obtenir le sentiment du texte
    sentiment_result = sentiment_classifier(text)
    sentiment_score = sentiment_result[0]['score']
    sentiment_label = sentiment_result[0]['label']
    
    # Score de dépression entre 0 et 1
    # Plus le score est élevé, plus le niveau de dépression est sévère
    base_score = 0.4  # Point de départ légèrement optimiste
    
    # Pondération du score en fonction des compteurs de mots-clés
    keyword_weight = 0.3
    keyword_score = ((severe_count * 1.0) + (moderate_count * 0.5) - (normal_count * 0.6)) * keyword_weight
    
    # Pondération du score en fonction du sentiment
    sentiment_weight = 0.7
    # Utilise le score réel du sentiment au lieu d'une valeur fixe
    sentiment_modifier = sentiment_weight * (sentiment_score if sentiment_label == "NEGATIVE" else -sentiment_score)
    
    # Calcul du score final
    depression_score = min(max(base_score + keyword_score + sentiment_modifier, 0.0), 1.0)
    
    # Détermination du niveau de dépression
    if depression_score >= 0.7:
        level = "dépression "
    elif depression_score >= 0.4:
        level = "dépression"
    else:
        level = "normal"
    
    # Facteurs d'analyse (en anglais)
    factors = {
        "tristesse": min(0.2 + (moderate_count * 0.05) + (sentiment_score if sentiment_label == "NEGATIVE" else 0), 1.0),
        "désintérêt": min(0.2 + (moderate_count * 0.03) + (severe_count * 0.05), 1.0),
        "fatigue": min(0.1 + (text_lower.count("tired") * 0.1) + (text_lower.count("exhausted") * 0.15), 1.0),
        "dévalorisation": min(0.1 + (text_lower.count("worthless") * 0.2) + (text_lower.count("useless") * 0.15), 1.0),
        "idées_suicidaires": min(severe_count * 0.2, 1.0)
    }
    
    # Pour le débogage (à supprimer en production)
    print(f"Texte: {text}")
    print(f"Mots sévères: {severe_count}, Mots modérés: {moderate_count}, Mots positifs: {normal_count}")
    print(f"Sentiment: {sentiment_label} with score {sentiment_score}")
    print(f"Score final de dépression: {depression_score}")
    
    return {
        "depression_score": depression_score,
        "level": level,
        "factors": factors
    }

@app.post("https://999c-197-16-171-83.ngrok-free.app/analyze")
async def analyze_thought(thought: Thought):
    try:
        # Analyse améliorée du texte pour la détection de dépression
        analysis_result = analyze_depression_text(thought.content)
        
        # Enregistrer dans Supabase avec les données améliorées
        supabase.table("thoughts").insert({
            "user_id": thought.user_id,
            "content": thought.content,
            "score": analysis_result["depression_score"],
            "niveau": analysis_result["level"],
            "created_at": datetime.now().isoformat()
        }).execute()
        
        # Retourner l'analyse améliorée
        return {
            "facteurs": analysis_result["factors"],
            "score_total": analysis_result["depression_score"],
            "niveau": analysis_result["level"]
        }
        
    except Exception as e:
        return {"error": f"Erreur lors de l'analyse : {str(e)}"} 
    




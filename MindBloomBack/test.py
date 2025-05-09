from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
from tensorflow import keras
import numpy as np
from PIL import Image
import io
import supabase
import os

app = Flask(__name__)
CORS(app)


# Charger le modèle
model = keras.models.load_model('C:/Users/DELL/MindBloom/MindBloomBack/models/vgg_classe_equilibre.h5')

# Configuration Supabase
url = "https://xcieeonpxsirifymoohv.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaWVlb25weHNpcmlmeW1vb2h2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2MTAwMTYsImV4cCI6MjA2MTE4NjAxNn0.rOd2dita7BEmVnU9NhaOd2T76IO4j4H_NRbffI8dwk4"
supabase_client = supabase.create_client(url, key)

@app.route('/predict', methods=['POST'])
def predict():
    # Recevoir l'image et l'ID de l'utilisateur de la requête Flutter
    file = request.files['image']
    user_id = request.form.get('user_id')
    
    # Vérifier si l'image est bien reçue
    if not file:
        return jsonify({'error': 'No image file provided'}), 400
    
    # Vérifier si l'ID utilisateur est fourni
    if not user_id:
        return jsonify({'error': 'No user_id provided'}), 400
    
    # Convertir l'image en RGB et redimensionner à 224x224
    img = Image.open(io.BytesIO(file.read())).convert('RGB').resize((224, 224))
    
    # Convertir l'image en tableau numpy et normaliser
    img_array = np.expand_dims(np.array(img) / 255.0, axis=0)  # Shape: (1, 224, 224, 3)
    
    # Faire la prédiction
    prediction = model.predict(img_array)
    predicted_class = int(np.argmax(prediction[0]))
    
    # Calculer le score de dépression (à adapter en fonction de ton modèle)
    depression_score = 0.0
    if predicted_class == 0:  # exemple pour "happY"
        depression_score = 0.2
    elif predicted_class == 1:  # exemple pour "neutral"
        depression_score = 0.5
    elif predicted_class == 2:  # exemple pour "sad"
        depression_score = 0.8
    
    # Enregistrer l'image localement
    local_filename = f"{file.filename}"
    os.makedirs('./uploads/selfies', exist_ok=True)  # Crée le dossier s'il n'existe pas
    local_path = f'./uploads/selfies/{local_filename}'
    file.seek(0)  # Reset the file pointer to the beginning
    file.save(local_path)
    
    # Télécharger l'image sur Supabase Storage
    file_path = f"selfies/{user_id}/{local_filename}"
    with open(local_path, 'rb') as f:
        supabase_client.storage.from_('user-selfies').upload(file_path, f)
    
    # Générer l'URL de l'image
    storage_url = supabase_client.storage.from_('user-selfies').get_public_url(file_path)
    
    # Ajouter les informations dans la table selfie_records
    data = {
        "user_id": user_id,  # Utiliser l'ID de l'utilisateur authentifié
        "file_path": file_path,
        "url": storage_url,  # URL de l'image dans Supabase Storage
        "score": float(depression_score)  # Conversion en float pour assurer la sérialisation JSON
    }
    
    # Insérer les données dans la table selfie_records de Supabase
    response = supabase_client.table("selfie_records").insert(data).execute()
    
    # Retourner la réponse
    return jsonify({
        'class': predicted_class,
        'score': float(depression_score),
        'url': storage_url
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
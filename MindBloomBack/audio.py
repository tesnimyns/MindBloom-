# from flask import Flask, request, jsonify
# from flask_cors import CORS
# import pickle
# import joblib
# import numpy as np
# import os
# import supabase
# import librosa
# import io

# app = Flask(__name__)
# CORS(app)

# # Load the pkl model - with multiple options for different formats
# try:
#     # Try standard pickle first
#     model = pickle.load(open('C:/flask/models/audio_classifier_model+dataAug.pkl', 'rb'))
# except Exception as e:
#     print(f"Standard pickle loading failed: {e}")
#     try:
#         # Try using joblib instead
#         model = joblib.load('C:/flask/models/audio_classifier_model+dataAug.pkl')
#         print("Model loaded with joblib successfully")
#     except Exception as e:
#         print(f"Joblib loading failed: {e}")
#         # If you're using scikit-learn, try this as a fallback
#         try:
#             import sklearn.externals
#             model = sklearn.externals.joblib.load('C:/flask/models/audio_classifier_model+dataAug.pkl')
#             print("Model loaded with sklearn.externals.joblib successfully")
#         except Exception as e:
#             print(f"All loading methods failed. Last error: {e}")
#             print("Please inspect your model file format and make sure it was saved correctly.")
#             exit(1)

# # Supabase Configuration
# url = "https://xcieeonpxsirifymoohv.supabase.co"
# key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaWVlb25weHNpcmlmeW1vb2h2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2MTAwMTYsImV4cCI6MjA2MTE4NjAxNn0.rOd2dita7BEmVnU9NhaOd2T76IO4j4H_NRbffI8dwk4"
# supabase_client = supabase.create_client(url, key)

# # Feature extraction function for audio
# def extract_features(audio_data, sr):
#     # Extract features relevant to your model
#     # Here's an example with basic features - adjust based on your model's requirements
#     mfccs = librosa.feature.mfcc(y=audio_data, sr=sr, n_mfcc=13)
#     mfccs_mean = np.mean(mfccs, axis=1)
    
#     # Add more features as needed (spectral centroid, chroma, etc.)
#     spectral_centroid = librosa.feature.spectral_centroid(y=audio_data, sr=sr)
#     spectral_centroid_mean = np.mean(spectral_centroid)
    
#     # Combine features
#     features = np.hstack([mfccs_mean, spectral_centroid_mean])
#     return features

# @app.route('/predict_audio', methods=['POST'])
# def predict_audio():
#     # Receive the audio file and user ID from Flutter request
#     file = request.files.get('file')  # Changed to match Flutter code
#     user_id = request.form.get('user_id')
    
#     # Check if audio file is received
#     if not file:
#         return jsonify({'error': 'No audio file provided'}), 400
    
#     # Check if user ID is provided
#     if not user_id:
#         return jsonify({'error': 'No user_id provided'}), 400
    
#     try:
#         # Save audio locally temporarily
#         timestamp = str(int(np.datetime64('now').astype('int64') / 1000000))
#         local_filename = f"audio_{user_id}_{timestamp}.aac"
#         os.makedirs('./uploads/vocals', exist_ok=True)
#         local_path = f'./uploads/vocals/{local_filename}'
#         file.seek(0)
#         file.save(local_path)
        
#         # Load audio for processing
#         audio_data, sample_rate = librosa.load(local_path, sr=None)
        
#         # Extract features
#         features = extract_features(audio_data, sample_rate)
        
#         # Reshape features for model input if needed
#         features = features.reshape(1, -1)  # Reshape to match model input requirements
        
#         # Make prediction with the model
#         prediction = model.predict(features)
#         predicted_class = int(prediction[0])
        
#         # Calculate depression score (adapt based on your model's output)
#         depression_score = 0.0
#         if predicted_class == 0:  # Low depression
#             depression_score = 0.2
#         elif predicted_class == 1:  # Moderate depression
#             depression_score = 0.5
#         elif predicted_class == 2:  # High depression
#             depression_score = 0.8
        
#         # Upload audio to Supabase Storage
#         file_path = f"vocals/{user_id}/{local_filename}"
#         with open(local_path, 'rb') as f:
#             response = supabase_client.storage.from_('user-vocals').upload(file_path, f)
#             if response.status_code != 200:
#                 raise Exception(f"Failed to upload audio to Supabase: {response.text}")
        
#         # Generate public URL
#         storage_url = supabase_client.storage.from_('user-vocals').get_public_url(file_path)
        
#         # Return response to match Flutter expected format
#         return jsonify({
#             'class': predicted_class,
#             'score': float(depression_score),
#             'url': storage_url
#         })
        
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500
#     finally:
#         # Clean up temporary file
#         if os.path.exists(local_path):
#             os.remove(local_path)

# if __name__ == '__main__':
#     app.run(host='0.0.0.0', port=5000)

from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.llms import Ollama
import threading
import json
import os
from ollama import chat

"""
Current Version: V6 
MARK: 
VERSION NOTES
V1: Basic Conversations With ALl Users via dictionary maintaining chat history
V2: Cacheing Chat in a Text Files so context is maintained after/before chats
V3: Attempt to add constant summrising and disabled V2 features
V4: Sumarising and Saving Chats as we go. 
V5: V2 But with LLAMA 3.1. Summarising should not be an issue as this version should have 128K Context Window
v6: Resuming Project after 1 Year Break. Date is 15 March, 2025. Models are more advanced than before.
    Implementing Chat History based on Ollama Issue Threads, Basic Personality Based on Papers
    TODO: Implement two persona for testing purposes.
"""
# Initialize Flask
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
initialize_app(cred)
db = firestore.client()

# Server-side in-memory chat histories (using Ollama's message format)
chat_histories = {}

# Load chat histories from disk or Firestore
def load_chat_histories():
    if os.path.exists('chat_histories.json'):
        with open('chat_histories.json', 'r') as file:
            global chat_histories
            chat_histories = json.load(file)

# Save chat histories to disk
def save_chat_histories():
    with open('chat_histories.json', 'w') as file:
        json.dump(chat_histories, file)

# Initialize histories
load_chat_histories()

# Lock for thread safety
chat_lock = threading.Lock()

# Route to receive messages and respond
@app.route('/message', methods=['POST'])
def receive_message():
    try:
        data = request.json
        user_id = data['user_id']
        user_message = data['message']

        # Initialize or retrieve chat history for this user
        with chat_lock:
            if user_id not in chat_histories:
                # Add system message to set the AI's personality
                chat_histories[user_id] = [
                    {
                        'role': 'system',
                        'content': 'Please respond briefly. You are a good AI chatbot who always responds in an inquisitive and supportive way to messages.'
                    }
                ]

            # Add the new user message to history
            chat_histories[user_id].append({
                'role': 'user',
                'content': user_message
            })

            # Get current messages for this user
            messages = chat_histories[user_id]

        # Make sure messages format is correct - each message must be a dict with 'role' and 'content'
        for msg in messages:
            if not isinstance(msg, dict) or 'role' not in msg or 'content' not in msg:
                raise ValueError(f"Invalid message format: {msg}")

        # Call Ollama with the full message history
        response = chat(model='llama3.1', messages=messages)

        # Extract the assistant's response
        assistant_message = response['message']

        with chat_lock:
            # Add the assistant's response to history
            chat_histories[user_id].append(assistant_message)

            # Save updated history
            save_chat_histories()

        # Save messages to Firestore
        user_ref = db.collection("UserMessages").document(user_id)

        # Save bot message
        bot_message_data = {
            "isMe": False,
            "messageContent": assistant_message['content'],
            "name": "Bot",
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        user_ref.collection("messageItems").add(bot_message_data)

        return jsonify({
            'status': 'success',
            'response': assistant_message['content']
        })

    except Exception as e:
        import traceback
        traceback.print_exc()  # Print detailed error information
        print(f"Error: {str(e)}")
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

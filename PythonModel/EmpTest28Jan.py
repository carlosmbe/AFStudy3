from flask import Flask, request, jsonify
from parlai.core.params import ParlaiParser
from parlai.core.agents import create_agent
from parlai.core.opt import Opt
from firebase_admin import credentials, firestore, initialize_app
import firebase_admin
import threading

# Initialize Flask
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
initialize_app(cred)
db = firestore.client()

# Create a dictionary of options for ParlAI
opt = Opt({
    "model": "transformer/generator",
    "model_file": "zoo:blender/blender_3B/model"
})

opt['task']="empathetic_dialogues"

# Create ParlAI agent
blender_agent = create_agent(opt, requireModelExists=True)

# Lock for thread safety with ParlAI
agent_lock = threading.Lock()

# Define the persona for the Blender bot
blender_persona = [
    "I am here to listen and support you.",
    "I understand that everyone goes through tough times and I'm here to help.",
    "I am a caring and empathetic listener.",
    "I believe that being supportive and understanding can make a big difference."
]

# Function to get Blender bot response
def get_bot_response(message):
    # Define the persona text
    persona_text = "\n".join(["your_persona:" + line for line in blender_persona])
    full_text = persona_text + "\n" + message

    with agent_lock:
        blender_agent.observe({'text': full_text, 'episode_done': False})
        response = blender_agent.act()
    return response['text']

@app.route('/message', methods=['POST'])
def receive_message():
    try:
        data = request.json
        user_id = data['user_id']
        user_message = data['message']

        # Get bot's response
        bot_response = get_bot_response(user_message)

        # Add bot's response to Firestore
        bot_message_data = {
            "isMe": False,
            "messageContent": bot_response,
            "name": "Bot",
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        db.collection("UserMessages").document(user_id).collection("messageItems").add(bot_message_data)

        return jsonify({'status': 'success', 'response': bot_response})

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

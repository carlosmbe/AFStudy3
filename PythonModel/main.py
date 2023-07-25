from flask import Flask, request
from parlai.core.params import ParlaiParser
from parlai.core.agents import create_agent
from parlai.core.opt import Opt
from firebase_admin import credentials, firestore
import firebase_admin

# Initialize Flask
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Create a dictionary of options
opt = Opt({
    "model": "transformer/generator",
    "model_file": "zoo:blender/blender_3B/model"
})

# Create ParlAI agent
blender_agent = create_agent(opt, requireModelExists=True)

# Function to get Blender bot response
def get_bot_response(message):
    blender_agent.observe({'text': message, 'episode_done': False})
    response = blender_agent.act()
    return response['text']

@app.route('/message', methods=['POST'])
def receive_message():
    data = request.json
    user_id = data['user_id']
    user_message = data['message']

    # Generate bot's response
    bot_response = get_bot_response(user_message)

    # Add user's message to Firestore
    user_message_data = {
        "isMe": True,
        "messageContent": user_message,
        "name": data['name'],
        "timestamp": firestore.SERVER_TIMESTAMP
    }

    db.collection("UserMessages").document(user_id).collection("messageItems").add(user_message_data)

    # Add bot's response to Firestore
    bot_message_data = {
        "isMe": False,
        "messageContent": bot_response,
        "name": "Bot",
        "timestamp": firestore.SERVER_TIMESTAMP
    }

    db.collection("UserMessages").document(user_id).collection("messageItems").add(bot_message_data)

    return {'status': 'success'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

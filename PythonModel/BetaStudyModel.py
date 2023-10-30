from flask import Flask, request, jsonify
from parlai.core.params import ParlaiParser
from parlai.core.agents import create_agent
from parlai.core.opt import Opt
from firebase_admin import credentials, firestore, initialize_app
import firebase_admin
import threading

from datetime import datetime, timedelta
import random

PROMPTS = [
"When was the last time you walked for more than an hour? Describe where you went and what you saw.",
"What was the best gift you ever received and why?",
"If you had to move from Kansas, where would you go, and what would you miss the most about Kansas?",
"How did you celebrate last Halloween?",
"Do you read a newspaper often and which do you prefer? Why?",
"What is a good number of people to have in a student household and why?",
"If you could invent a new flavor of ice cream, what would it be?",
"What is the best restaurant you’ve been to in the last month? Tell your partner about it.",
"Describe the last pet you owned.",
"What is your favorite holiday? Why?",
"Tell your partner the funniest thing that ever happened to you when you were with a small child.",
"What gifts did you receive on your last birthday?",
"Describe the last time you went to the zoo.",
"Tell the names and ages of you family members (to the extent you know this information)",
"One of you say a word, the next say a word that starts with the last letter of the word just said. Do this until you have 10 words. Any words will do – you aren’t making a sentence.",
"Do you like to get up early or stay up late? Is there anything funny that has resulted from this?",
"Where are you from? Name all the places you’ve lived.",
"What is your favorite college class you’ve taken? Why?",
"What did you do this summer?",
"What gifts did you receive last holiday season?",
"Who is your favorite actor of your own gender? Describe a scene in which this person has acted.",
"What was your first impression of college the first time you ever went on campus?",
"What is the best TV show you’ve seen in the last month? Tell your partner about it.",
"What is your favorite holiday? Why?",
"What was your high school like?",
"What is the best book you’ve read in the last three months? Tell your partner about it.",
"What foreign country would you most like to visit? What attracts you to this place?",
"Do you prefer digital watches and clock or the kind with hands? Why?",
"Describe your mother’s best friend.",
"What are the advantages and disadvantages of artificial Christmas trees?",
"How often do you get your hair cut? Have you ever had a really bad haircut experience?",
"Did you have a class pet when you were in elementary school? Do you remember the pets name?",
"Do you think left-handed people are more creative than right-handed people?",
"What is the last concert you saw?",
"Do you subscribe to any magazines? Which ones?",
"Were you ever in a school play? What was your role? What was the plot of the play? Did anything funny ever happen when you were on stage?",
]

conversations = {}  # format: {"UserID": [{"timestamp": datetime, "message": "user's message"}, ...]}

def get_recent_context(message_array):
    """Get the most recent parts of the conversation for context."""
    last_messages = [m['message'] for m in message_array]
    return " ... ".join(last_messages)

# Initialize Flask
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
initialize_app(cred)
db = firestore.client()

# Create a dictionary of options
opt = Opt({
    "model": "transformer/generator",
    "model_file": "zoo:blender/blender_3B/model"
})

# Create ParlAI agent
blender_agent = create_agent(opt, requireModelExists=True)

# Lock for thread safety with ParlAI
agent_lock = threading.Lock()

# Function to get Blender bot response
def get_bot_response(message, user_id):
    with agent_lock:
        blender_agent.observe({'text': message, 'episode_done': False})
        response = blender_agent.act()
    return response['text']

@app.route('/message', methods=['POST'])
def receive_message():
    try:
        data = request.json
        user_id = data['user_id']
        user_message = data['message']

        current_time = datetime.now()
        if user_id not in conversations:
            conversations[user_id] = []
        
        # Store the user's message
        conversations[user_id].append({'timestamp': current_time, 'message': user_message})

        # If it's a new conversation or after a long gap
        if len(conversations[user_id]) == 1 or (current_time - conversations[user_id][-2]['timestamp']) > timedelta(minutes=30):
            segue = "Let's talk about something new! "
            new_topic = segue + random.choice(PROMPTS)
            bot_response = new_topic
            conversations[user_id].append({'timestamp': current_time, 'message': bot_response, 'isBot': True})
        else:
            context = get_recent_context(conversations[user_id])
            bot_response = get_bot_response(context + " ... " + user_message, user_id)
            conversations[user_id].append({'timestamp': current_time, 'message': bot_response, 'isBot': True})

        # Add bot's response to Firestore
        batch = db.batch()
        bot_message_ref = db.collection("UserMessages").document(user_id).collection("messageItems").document()
        bot_message_data = {
            "isMe": False,
            "messageContent": bot_response,
            "name": "Bot",
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        batch.set(bot_message_ref, bot_message_data)
        batch.commit()

        return jsonify({'status': 'success'})

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
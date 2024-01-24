from flask import Flask, request, jsonify
from parlai.core.params import ParlaiParser
from parlai.core.agents import create_agent
from parlai.core.opt import Opt
from firebase_admin import credentials, firestore, initialize_app
import firebase_admin
import threading

from datetime import datetime, timedelta
import random
from datetime import datetime, timedelta

def manage_user_prompt_type(user_id, new_message):
    user_ref = db.collection("UserPromptTypes").document(user_id)
    user_doc = user_ref.get()

    word_count = len(new_message.split())
    
    if not user_doc.exists:
        # If user is new, set word count and prompt type
        user_ref.set({
            'wordCount': word_count,
            'promptType': 'small_talk'
        })
        return 'small_talk'
    else:
        user_data = user_doc.to_dict()
        total_word_count = user_data.get('wordCount', 0) + word_count

        if total_word_count >= 500:
            # Reset word count and update prompt type to 'closeness'
            user_ref.update({
                'wordCount': 0,
                'promptType': 'closeness'
            })
            return 'closeness'
        else:
            # Update the word count only
            user_ref.update({'wordCount': total_word_count})
            return user_data.get('promptType', 'small_talk')

closeness_generating_prompts = [
    "Given the choice of anyone in the world, whom would you want as a dinner guest?",
    "Would you like to be famous? In what way?",
    "When was the last time you sang to yourself? What did you sing?",
    "Before making a telephone call, do you ever rehearse what you are going to say?",
    "For what in your life do you feel most grateful?",
    "What would constitute a “perfect” day for you?",
    "If you could wake up tomorrow having gained any one quality or ability, what would it be?",
    "If a crystal ball could tell you the truth about yourself, your life, the future, or anything else, what would you want to know?",
    "What do you value most in a friendship?",
    "Is there something you've dreamed of doing for a long time? Is there a reason you haven't done it?",
    "What does friendship mean to you?",
    "What is your most treasured memory?",
    "What roles do love and affection play in your life?",
    "If we were going to become close friends, what would be important for me to know?",
    "What, if anything, is too serious to be joked about?",
    "What was an embarrassing moment in your life?",
    "Who is the most important role model or mentor in your life?"
]

small_talk_prompts = [
    "When was the last time you took a walk?",
    "What is your favorite color?",
    "Tell me about your favorite movie.",
    "How many pushups can you do?",
    "Which do you think is better, chocolate or strawberry?",
    "Tell me about the last time you took a long walk. What did you see? Where did you go?",
    "Do you read the news often? Which news source do you prefer?",
    "What was the best gift you ever received and why?",
    "What is your favorite holiday? Why?",
    "What was the funniest thing that ever happened to you when you were with a small child?",
    "If you had to move from Kansas, where would you go?",
    "What is the best restaurant you've been to in the last month? Can you tell me about it?",
    "Do you have a pet?",
    "What gifts did you receive on your last birthday?",
    "How did you celebrate last Halloween?",
    "How did you celebrate last New Year's Eve?",
    "Can you tell me about the last time you went to the zoo.",
    "What did you do this summer?",
    "What is your favorite holiday? Why?",
    "What was your first impression of college the first time you ever went on campus?",
    "Who is your favorite actor of your own gender?",
    "What is your favorite college class you've taken? Why?",
    "What gifts did you receive last holiday season?",
    "What is the best TV show you've seen in the last month? Can you tell me about it?",
    "Where are you from?",
    "What was your favorite place you've ever lived? Why?",
    "Do you like to get up early or stay up late?",
    "Can you tell me the names and ages of your family members?",
    "What was your high school like?",
    "What foreign country would you most like to visit? What attracts you to that place?",
    "Do you subscribe to any magazines? Which ones?",
    "What is the last concert you saw?",
    "Do you think left-handed people are more creative than right-handed people?",
    "Were you ever in a school play?",
    "Do you prefer digital watches and clocks or the kind with hands? Why?",
    "Can you tell me about your mother's best friend.",
    "What is the best book you've read in the last three months?",
    "Did you have a class pet when you were in elementary school? Do you remember the pet's name?",
    "Have you ever had a really bad haircut experience?",
    "What is your dream job?",
    "What was your first job? Did you like it?",
    "Are there any apps on your phone that you can't live without?",
    "What's your favorite genre of movie?",
    "What's the last movie to make you cry? Or laugh out loud?",
    "What's your favorite snack food?",
    "What is your go-to comfort food?",
    "Are there any foods you can't stand?",
    "Are you allergic to any foods?",
    "What's your favorite kind of food to make?",
    "Do you prefer to travel by car, or by airplane?",
    "Do you prefer an action-packed vacation, or one that's relaxing?",
    "Do you have any trips planned?",
    "What is your favorite thing to do when you are on vacation?",
    "What did you want to be when you were growing up?",
    "Do you have any hidden talents?",
    "In elementary school, what was your favorite extracurricular activity?",
    "If you could teach a class on any subject, what would it be?",
    "What would be your ideal super power?",
    "If you could have any type of animal for a pet, what would it be?",
    "How was your weekend?",
    "How is your week going?",
    "How is your day going?",
    "How was your morning?",
    "What is your favorite kind of weather?",
    "What is your favorite season? Why?"
]

blender_persona = [
    "I am here to listen and support you.",
    "I understand that everyone goes through tough times and I'm here to help.",
    "I am a caring and empathetic listener.",
    "I believe that being supportive and understanding can make a big difference."
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

opt['task']="empathetic_dialogues"

# Create ParlAI agent
blender_agent = create_agent(opt, requireModelExists=True)

# Lock for thread safety with ParlAI
agent_lock = threading.Lock()

# Function to get Blender bot response
def get_bot_response(message, user_id):
    # Define the persona text (assuming blender_persona is a list of strings)
    persona_text = "\n".join(["your_persona:" + line for line in blender_persona])

    # Check if there's existing conversation history for the user
    if user_id in conversations and conversations[user_id]:
        # Get recent conversation history
        context = get_recent_context(conversations[user_id])
        # Combine persona, context, and new message
        full_text = persona_text + "\n" + context + "\n" + message
    else:
        # If no history, just combine persona and new message
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

        prompt_type = manage_user_prompt_type(user_id, user_message)

        current_time = datetime.now()
        if user_id not in conversations:
            conversations[user_id] = []

        # Store the user's message
        conversations[user_id].append({'timestamp': current_time, 'message': user_message})

        # Decide which prompt list to use
        if prompt_type == 'closeness':
            prompt_list = closeness_generating_prompts
        elif prompt_type == 'small_talk':
            prompt_list = small_talk_prompts

        # Select a prompt from the chosen list
        new_topic = "Hello! " + random.choice(prompt_list)

        # If it's a new conversation or after a long gap, use the new topic
        if len(conversations[user_id]) == 1 or (current_time - conversations[user_id][-2]['timestamp']) > timedelta(minutes=30):
            bot_response = new_topic
            conversations[user_id].append({'timestamp': current_time, 'message': bot_response, 'isBot': True})
        else:
            # Get the context for the conversation and respond accordingly
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



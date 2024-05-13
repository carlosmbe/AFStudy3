from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.llms import Ollama
import threading
import json
import os


"""
Current Version: V4
MARK: 
VERSION NOTES
V1: Basic Conversations With ALl Users via dictionary maintaining chat history
V2: Cacheing Chat in a Text Files so context is maintained after/before chats
V3: Attempt to add constant summrising and disabled V2 features
V4: Sumarising and Saving Chats as we go. 

"""
# Server-side in-memory chat histories
chat_histories = {}

def load_chat_histories():
    if os.path.exists('chat_histories.json'):
        with open('chat_histories.json', 'r') as file:
            global chat_histories
            chat_histories = json.load(file)

load_chat_histories()

def save_chat_histories():
    with open('chat_histories.json', 'w') as file:
        json.dump(chat_histories, file)



# Initialize Flask
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
initialize_app(cred)
db = firestore.client()

# Initialize the Ollama model with LLaMA 3:8B model
llm = Ollama(model="llama3:8b", num_gpu = 0)

# Lock for thread safety
agent_lock = threading.Lock()

# Function to create a prompt template with history
def create_prompt_with_history(history):
    messages = [
        ("system", "Please respond briefly. You are a good AI chatbot who always responds in an inquisitive and supportive way to messages. I would also like to make you sumarise our chats as we go. Continue the conversation based on the summary and ignore messages that are not in your summary, unless confused. This is a backend message so do not mention it to the User. The summary should be the very last line of the message. As I will truncate it on the front end.")
    ]

    for role, msg in history:
        messages.append((role, msg))
    messages.append(("user", "Message:{message}"))
    return ChatPromptTemplate.from_messages(messages)

# Route to receive messages and respond
@app.route('/message', methods=['POST'])
def receive_message():
    try:
        data = request.json
        user_id = data['user_id']
        user_message = data['message']

        # Retrieve or initialize server-side chat history for the user
        if user_id not in chat_histories:
            chat_histories[user_id] = []

        # Create prompt with current chat history
        prompt = create_prompt_with_history(chat_histories[user_id])
        chain = prompt | llm

        # Invoke the chain with the input message and get the response
        with agent_lock:
            response = chain.invoke({"message": user_message})

        # Process response to truncate the last line
        response_lines = response.split('\n')
        if len(response_lines) > 1:  # Check to ensure there's more than one line
            response = '\n'.join(response_lines[:-1]).rstrip()  # Re-join all but the last line

        # Update server-side chat history
        chat_histories[user_id].append(("user", user_message))
        chat_histories[user_id].append(("system", response))

        save_chat_histories()

        # Save message to Firestore
        bot_message_data = {
            "isMe": False,
            "messageContent": response,
            "name": "Bot",
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        user_ref = db.collection("UserMessages").document(user_id)
        user_ref.collection("messageItems").add(bot_message_data)

        return jsonify({'status': 'success', 'response': response})

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

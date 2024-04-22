from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.llms import Ollama
import threading

# Initialize Flask
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
initialize_app(cred)
db = firestore.client()

# Initialize the Ollama model with LLaMA 3:8B model
llm = Ollama(model="llama3:8b")

# Lock for thread safety
agent_lock = threading.Lock()

# Server-side in-memory chat histories
chat_histories = {}

# Function to create a prompt template with history
def create_prompt_with_history(history):
    messages = [("system", "Please respond briefly. You are a good AI chatbot who always responds in an inquisitive and supportive way to messages.")]
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

        # Update server-side chat history
        chat_histories[user_id].append(("user", user_message))
        chat_histories[user_id].append(("system", response))

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

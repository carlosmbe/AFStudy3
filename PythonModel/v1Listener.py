
# This is for testing and only works for one user where we specify the ID

from parlai.core.params import ParlaiParser
from parlai.core.agents import create_agent
from firebase_admin import credentials, firestore
import firebase_admin

# Initialize Firestore
cred = credentials.Certificate('firebaseKEYAFSTDUY.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Create ParlAI argument parser
parser = ParlaiParser(add_model_args=True)
parser.set_defaults(model='transformer/generator', model_file='zoo:blender/blender_90M/model')

# Create ParlAI agent
opt = parser.parse_args()
blender_agent = create_agent(opt, requireModelExists=True)

# Function to get Blender bot response
def get_bot_response(conversation):
    for message in conversation:
        blender_agent.observe({'text': message, 'episode_done': False})
    response = blender_agent.act()
    return response['text']

last_user_message_id = None

# Create a callback on_snapshot function to capture changes
def on_snapshot(doc_snapshot, changes, read_time):
    global last_user_message_id
    conversation = []
    new_user_message = False

    for doc in doc_snapshot:
        doc_dict = doc.to_dict()
        conversation.append(doc_dict['messageContent'])
        if doc_dict['name'] != 'Bot' and doc.id != last_user_message_id:
            last_user_message_id = doc.id
            new_user_message = True
            print(f"Received message: {doc_dict['messageContent']}")

    if new_user_message and doc_dict['name'] != 'Bot':
        bot_response = get_bot_response(conversation)

        # Add the bot's response to Firestore
        try:
            bot_message_data = {
                "isMe": False,
                "messageContent": bot_response,
                "name": "Bot",
                "timestamp": firestore.SERVER_TIMESTAMP
            }

            db.collection("UserMessages").document(user_id).collection("messageItems").add(bot_message_data)
        except Exception as e:
            print("Error writing message to Firestore: ", e)

# This user ID is for testing and will not work otherwise.
user_id = 'ZqrEjBlOlaN2TqFDFVsjOZEgiYX2'
doc_ref = db.collection("UserMessages").document(user_id).collection("messageItems").order_by("timestamp")

# Watch the document
doc_watch = doc_ref.on_snapshot(on_snapshot)

# Add an infinite loop to keep the main thread running
while True:
    pass

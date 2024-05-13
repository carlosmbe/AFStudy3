from langchain_core.prompts import ChatPromptTemplate
from langchain_community.llms import Ollama
import streamlit as st

# Check if 'history' is already initialized in session state, otherwise initialize it
if 'history' not in st.session_state:
    st.session_state.history = []

# function to create a prompt template with history
def create_prompt_with_history(history):
    messages = [("system", "Please respond briefly. You are a good AI chatbot who always responds in an inquisitive and supportive way to messages. Use the chat history to provide contextually relevant responses.")]
    for role, msg in history:
        messages.append((role, msg))
    messages.append(("user", "Message:{message}"))
    return ChatPromptTemplate.from_messages(messages)

# Set up the Streamlit framework
st.title('Langchain Chatbot With LLAMA3:8B model (Memory Experiment 1)')  # Set the title of the Streamlit app
input_text = st.text_input("Send your messages!!!!")  # Create a text input field in the Streamlit app

# Initialize the Ollama model
llm = Ollama(model="llama3:8b")

# Get the current chat history and create a prompt template
prompt = create_prompt_with_history(st.session_state.history)

# Create a chain that combines the prompt and the Ollama model
chain = prompt | llm

# Invoke the chain with the input text and display the output
if input_text:
    response = chain.invoke({"message": input_text})
    st.write(response)

    # Append the latest exchange to the history
    st.session_state.history.append(("user", input_text))
    st.session_state.history.append(("system", response))

# Button to print the chat history to the terminal
if st.button("Print Conversation"):
    print("\nChat History:")
    for role, msg in st.session_state.history:
        print(f"{role.title()}: {msg}")

# Button to clear the chat history
if st.button("Clear History"):
    st.session_state.history = []
    print("Chat history cleared!")

//
//  ChatView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import Alamofire
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ChatView: View {
    @State private var typingMessage = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var batchedMessages: [String] = []
    @State private var timer: Timer?
    
    @State private var hackingTheListCounter = 0

    @EnvironmentObject var chatViewModel: ChatViewModel

    var body: some View {
        VStack {
            chatList()
                .listStyle(PlainListStyle())
            messageInput()
        }
        
        
        .onAppear {
            if !chatViewModel.messagesLoaded {
                chatViewModel.loadMessages()
            }
            markMyLastSentMessageAsRead()
        }
        
        .onReceive(chatViewModel.$messagesLoaded) { (loaded) in
            if loaded {
               markMyLastSentMessageAsRead()
            }
        }
            
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            NavigationLink("Survey", destination: Survey())
            
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear")
            }
        }
        .alert("There Was An Issue \n\(errorMessage)", isPresented: $showError)
        { Button("Alright :c"){ errorMessage = "" } }
    }
    
    private func chatList() -> some View {
        ScrollViewReader { scrollView in
            List {
                let lastMessageFromMeID = chatViewModel.messages.last(where: { $0.isMe })?.id
                
                let lastMessageFromOtherID = chatViewModel.messages.last(where: { !$0.isMe })?.id

                ForEach(chatViewModel.messages) { message in
                    // Check if the current message ID matches either last message ID
                    if message.id == lastMessageFromMeID {
                        // Here you can handle specific behavior for your last message
                        // For example, you can display its state:
                        messageUI(message: message, isLastMessage: true)
                            .listRowSeparator(.hidden)
                            .id(message.id)
                    } else if message.id == lastMessageFromOtherID {
                        // Here you can handle specific behavior for the other user's last message
                        // For example, you can display the image:
                        messageUI(message: message, isLastMessage: true)
                            .listRowSeparator(.hidden)
                            .id(message.id)
                    } else {
                        // This is for all other messages
                        messageUI(message: message, isLastMessage: false)
                            .listRowSeparator(.hidden)
                            .id(message.id)
                    }
                }
                if chatViewModel.isSendingMessage {
                    ProgressView()
                }
            }
            .onChange(of: chatViewModel.messages) { _ in
                if  hackingTheListCounter > 0 {
                    withAnimation{
                        scrollView.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
                    }
                }else{
                    scrollView.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
                    hackingTheListCounter += 1
                }
            }
        }
    }
    
    private func messageInput() -> some View {
        HStack(spacing: 10) {
            // Chat Input TextField
            TextField("Message...", text: $typingMessage, axis: .vertical)
                .padding(10) // Gives space inside the TextField
                .background(Color(.systemGray5)) // Light gray color background
                .cornerRadius(20) // Rounded edges
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                ) // Optional border
                .onChange(of: typingMessage) { newValue in
                    handleTypingChange(newValue)
                }

            // Send Button
            if chatViewModel.isSendingMessage {
                ProgressView()
                    .padding()
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill") // An arrow icon for sending
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue) // Color of the send button (can adjust to preference)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal) // Padding on the left and right side of the HStack
        .frame(minHeight: CGFloat(50)).padding(.bottom) // Padding below the HStack
    }

    private func handleTypingChange(_ newValue: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            sendBatchedMessages()
        }
    }
    
    private func sendMessage() {
        guard !typingMessage.isEmpty else {
            return
        }
        //Add space to trigger on change
        typingMessage = "\(typingMessage) "
        
        // 1. Optimistically update the UI
        let newMessage = Message(isMe: true, messageContent: typingMessage, name: Auth.auth().currentUser?.displayName ?? "", state: .sent)
        chatViewModel.messages.append(newMessage)

        // 2. Store the user's message to Firebase directly
        let userMessageData = [
            "isMe": true,
            "messageContent": typingMessage,
            "name": Auth.auth().currentUser?.displayName ?? "",
            // Using FieldValue.serverTimestamp() since we're now working directly with Firestore from the client
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]

        let user_id = Auth.auth().currentUser?.uid ?? ""
        Firestore.firestore().collection("UserMessages").document(user_id).collection("messageItems").addDocument(data: userMessageData) { (error) in
            if let error = error {
                print("Error saving user message: \(error)")
            } else {
                print("User message saved!")
            }
        }

        batchedMessages.append(typingMessage)
        typingMessage = ""

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { _ in
            sendBatchedMessages()
        }
    }
    
    func markMyLastSentMessageAsRead() {
        if let myLastSentMessageIndex = chatViewModel.messages.lastIndex(where: { $0.isMe }) {
            var index = myLastSentMessageIndex + 1
            while index < chatViewModel.messages.count {
                if !chatViewModel.messages[index].isMe {
                    chatViewModel.messages[myLastSentMessageIndex].state = .read
                    break
                }
                index += 1
            }
        }
    }
    
    private func sendBatchedMessages() {
        
        let combinedMessage = batchedMessages.joined(separator: " ")  // Combine all batched messages
       
        if combinedMessage.isEmpty {
               return
           }
        
        
        if let lastMessage = chatViewModel.messages.last(where: { $0.isMe }) {
            lastMessage.state = .processing
        }
        
        
        batchedMessages.removeAll()  // Clear the batched messages
        
        // Use combinedMessage for sending to the server
        var parameters: [String: String] = [
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "message": combinedMessage,
            "name": Auth.auth().currentUser?.displayName ?? ""
        ]
        
        let serverUrl = "\(chatViewModel.serverAddress)/message"
        
        
        chatViewModel.isSendingMessage = true
        
        AF.request(serverUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { response in
                // You can handle the server's response here
                debugPrint(response)
                
                switch response.result{
                case .success(_):
                    print("Success")
                    markMyLastSentMessageAsRead()
                    chatViewModel.isSendingMessage = false
                case .failure(let error):
                    errorMessage = "\(error.localizedDescription)"
                    showError = true
                    chatViewModel.isSendingMessage = false
                    
                }
            }
        
        
    }
    
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

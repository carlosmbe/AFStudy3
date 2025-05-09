//
//  ChatViewModel.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import Alamofire
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class ChatViewModel: ObservableObject {
    let db = Firestore.firestore()
    
    @Published var isSendingMessage = false
    @Published var messagesLoaded: Bool = false
    
    @Published var messages: [Message] = []
    
    @Published var timer: Timer?
    
    @Published var batchErrorMessage : String = ""
    @Published var batchMessageError: Bool = false
    
    var batchedMessages: [String] = []
    
    var serverAddress: String = "https://testing2.ittc.ku.edu"
    
    init() {
        loadMessages()
        loadServerAddress()
    }
    
    func loadServerAddress() {
        db.collection("ServerDetails").document("address")
            .getDocument { (document, error) in
                if let document = document, document.exists {
                    self.serverAddress = document.data()?["value"] as? String ?? "https://testing.ittc.ku.edu"
                } else {
                    print("Document does not exist")
                }
            }
    }
    
    func loadMessages() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            return
        }
        
        db.collection("UserMessages").document(userID).collection("messageItems").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
             guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            self.messages = documents.compactMap { queryDocumentSnapshot in
                let data = queryDocumentSnapshot.data()
                
                let isMe = data["isMe"] as? Bool ?? false
                let messageContent = data["messageContent"] as? String ?? ""
                let name = data["name"] as? String
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                
                return Message(isMe: isMe, messageContent: messageContent, name: name, timestamp: timestamp)
            }
            self.messagesLoaded = true
        }
        
      
    }
    
    func sendMessage(typingMessage : String) {
        var typingMessage = typingMessage
        guard !typingMessage.isEmpty else {
            return
        }
        //Add space to trigger on change
        typingMessage = "\(typingMessage)"
        
        // 1. Optimistically update the UI
        let newMessage = Message(isMe: true, messageContent: typingMessage, name: Auth.auth().currentUser?.displayName ?? "", state: .sent)
        messages.append(newMessage)

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
            self.sendBatchedMessages()
        }
    }
    
    
    func sendBatchedMessages() {
        
        let combinedMessage = batchedMessages.joined(separator: " ")  // Combine all batched messages
       
        if combinedMessage.isEmpty {
               return
           }
        
        
        if let lastMessage = messages.last(where: { $0.isMe }) {
            lastMessage.state = .processing
        }
        
        
        batchedMessages.removeAll()  // Clear the batched messages
        
        // Use combinedMessage for sending to the server
        var parameters: [String: String] = [
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "message": combinedMessage,
            "name": Auth.auth().currentUser?.displayName ?? ""
        ]
        
        let serverUrl = "\(serverAddress)/message"
        
        
        isSendingMessage = true
        
        AF.request(serverUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { response in
                // You can handle the server's response here
                debugPrint(response)
                
                switch response.result{
                case .success(_):
                    print("Success")
                    self.markMyLastSentMessageAsRead()
                    self.isSendingMessage = false
                    
                case .failure(let error):
                    self.batchErrorMessage = "\(error.localizedDescription)"
                    self.batchMessageError = true
                    self.isSendingMessage = false
                    
                }
            }
        
        
    }
    
    func markMyLastSentMessageAsRead() {
        if let myLastSentMessageIndex = messages.lastIndex(where: { $0.isMe }) {
            var index = myLastSentMessageIndex + 1
            while index < messages.count {
                if !messages[index].isMe {
                    messages[myLastSentMessageIndex].state = .read
                    break
                }
                index += 1
            }
        }
    }
    
}

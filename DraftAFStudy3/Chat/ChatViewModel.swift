//
//  ChatViewModel.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class ChatViewModel: ObservableObject {
    let db = Firestore.firestore()
    
    @Published var messages: [Message] = []
    
    init() {
        loadMessages()
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
        }
    }
    
    func addMessage(_ message: Message) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            return
        }
        
        do {
            let messageData: [String: Any] = [
                "isMe": message.isMe,
                "messageContent": message.messageContent,
                "name": message.name ?? "",
                "timestamp": message.timestamp
            ]
            
            try db.collection("UserMessages")
                .document(userID)
                .collection("messageItems")
                .addDocument(data: messageData)
        } catch let error {
            print("Error writing message to Firestore: \(error)")
        }
    }

    
}

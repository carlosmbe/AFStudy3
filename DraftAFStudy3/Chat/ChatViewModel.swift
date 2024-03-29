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
    
    @Published var serverAddress: String = "https://testing.ittc.ku.edu"
    
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
}

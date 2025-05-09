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
import Combine

class ChatViewModel: ObservableObject {
    let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isSendingMessage = false
    @Published var messagesLoaded: Bool = false
    @Published var messages: [Message] = []
    @Published var timer: Timer?
    @Published var batchErrorMessage: String = ""
    @Published var batchMessageError: Bool = false
    
    var batchedMessages: [String] = []
    var serverAddress: String = "https://testing"
    var typingListener: ListenerRegistration?
    
    init() {
        loadMessages()
        loadServerAddress()
        setupTypingListener()
    }
    
    deinit {
        typingListener?.remove()
    }
    
    func loadServerAddress() {
        db.collection("ServerDetails").document("address")
            .getDocument { (document, error) in
                if let document = document, document.exists {
                    self.serverAddress = document.data()?["value"] as? String ?? "https://testing"
                }
            }
    }
    
    func setupTypingListener() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        typingListener = db.collection("UserMessages").document(userID)
            .collection("typingStatus").document("bot")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let isTyping = snapshot?.data()?["isTyping"] as? Bool {
                    DispatchQueue.main.async {
                        if let lastBotMessage = self.messages.last(where: { !$0.isMe }) {
                            lastBotMessage.state = isTyping ? .processing : .read
                        }
                    }
                }
            }
    }
    
    func loadMessages() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("UserMessages").document(userID)
            .collection("messageItems")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.messages = documents.compactMap { document in
                    let data = document.data()
                    let isMe = data["isMe"] as? Bool ?? false
                    let messageContent = data["messageContent"] as? String ?? ""
                    let name = data["name"] as? String
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let lineNumber = data["lineNumber"] as? Int
                    let isComplete = data["isComplete"] as? Bool
                    
                    let state: MessageState = isMe ? .sent : .read
                    
                    return Message(
                        isMe: isMe,
                        messageContent: messageContent,
                        name: name,
                        state: state,
                        timestamp: timestamp,
                        lineNumber: lineNumber,
                        isComplete: isComplete
                    )
                }
                self.messagesLoaded = true
            }
    }
    
    func sendMessage(typingMessage: String) {
        var typingMessage = typingMessage
        guard !typingMessage.isEmpty else { return }
        
        let newMessage = Message(
            isMe: true,
            messageContent: typingMessage,
            state: .sent
        )
        messages.append(newMessage)
        
        let userMessageData: [String: Any] = [
            "isMe": true,
            "messageContent": typingMessage,
            "name": Auth.auth().currentUser?.displayName ?? "",
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        let userID = Auth.auth().currentUser?.uid ?? ""
        db.collection("UserMessages").document(userID)
            .collection("messageItems")
            .addDocument(data: userMessageData) { error in
                if let error = error {
                    print("Error saving user message: \(error)")
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
        let combinedMessage = batchedMessages.joined(separator: " ")
        guard !combinedMessage.isEmpty else { return }
        
        if let lastMessage = messages.last(where: { $0.isMe }) {
            lastMessage.state = .processing
        }
        
        batchedMessages.removeAll()
        
        let parameters: [String: String] = [
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "message": combinedMessage
        ]
        
        let serverUrl = "\(serverAddress)/iOSMessage"
        
        isSendingMessage = true
        
        AF.request(serverUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(_):
                    self.markMyLastSentMessageAsRead()
                case .failure(let error):
                    self.batchErrorMessage = error.localizedDescription
                    self.batchMessageError = true
                }
                self.isSendingMessage = false
            }
    }
    
    func markMyLastSentMessageAsRead() {
        if let myLastSentMessageIndex = messages.lastIndex(where: { $0.isMe }) {
            messages[myLastSentMessageIndex].state = .read
        }
    }
}

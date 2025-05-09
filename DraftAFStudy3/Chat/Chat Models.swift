//
//  Models.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-14.
//

import FirebaseFirestoreSwift
import FirebaseAuth
import Foundation
import SwiftUI

class Message: Identifiable, Hashable, ObservableObject {
    // For Firebase
    @DocumentID var docId: String?
    
    let id = UUID()
    var isMe: Bool
    
    var messageContent: String
    var name: String? = Auth.auth().currentUser?.displayName
    
    @Published var state: MessageState = .sent
    
    
    // Date() is only used when not passing a parameter. Otherwise, older messages will take Saved Data passed in. New Messages will not.
    var timestamp: Date = Date()
    
    // Since Message is now a class, we need to implement the hash function
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // And the equality function
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(isMe: Bool, messageContent: String, name: String? = Auth.auth().currentUser?.displayName, state: MessageState = .sent, timestamp: Date = Date()) {
        self.isMe = isMe
        self.messageContent = messageContent
        self.name = name
        self.state = state
        self.timestamp = timestamp
    }
}

enum MessageState: String {
    case sent = "Sent"
    case processing = "Responding"
    case read = "Read"
}


struct messageUI : View{
    
    @ObservedObject var message: Message
    
    @State var isLastMessage: Bool = false
    
    
    @State private var currentImageIndex: Int = 1
    @State private var imageSwapTimer: Timer?
    
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    var body : some View{
        HStack{
            if message.isMe{
                Spacer()
            }
            VStack(alignment: .trailing){
                Text(message.messageContent)
                    .padding(7.25)
                    .foregroundColor(message.isMe ? Color.white : Color.white)
                    .background(message.isMe ? Color(hex: "1D6F8A") : Color(hex: "A4D2C3"))
                    .cornerRadius(10)
                
                if isLastMessage{
                    if message.isMe{
                        Text(message.state.rawValue)
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                    }   else{
                        
                        HStack {
                            if chatViewModel.isSendingMessage {
                                Image("ai_dots_\(currentImageIndex)")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 63, height: 31)
                                    .onAppear {
                                        startImageSwapTimer()
                                    }
                                    .onDisappear {
                                        stopImageSwapTimer()
                                    }
                                Spacer()  // Pushes the image to the left
                            } else {
                                Image("ai_w")
                                    .resizable()
                                    .frame(width: 63, height: 31)
                                Spacer()  // Pushes the image to the left
                            }
                        }
                        
                    }
                }
                
                
            }
            if !message.isMe || message.name?.lowercased() == "bot"{
                Spacer()
            }
            
        }  .listRowBackground(Color(.systemBackground))
        
    }
    
    // The function to start the timer:
    func startImageSwapTimer() {
        imageSwapTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentImageIndex += 1
            if currentImageIndex > 4 {
                currentImageIndex = 1
            }
        }
    }

    // Make sure to stop the timer when the view disappears:
    func stopImageSwapTimer() {
        imageSwapTimer?.invalidate()
    }

    
}



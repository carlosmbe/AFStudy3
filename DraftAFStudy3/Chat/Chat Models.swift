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
    
    @Published var state: MessageState = .delivered
    
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
    
    init(isMe: Bool, messageContent: String, name: String? = Auth.auth().currentUser?.displayName, state: MessageState = .delivered, timestamp: Date = Date()) {
        self.isMe = isMe
        self.messageContent = messageContent
        self.name = name
        self.state = state
        self.timestamp = timestamp
    }
}

enum MessageState: String {
    case delivered = "Delivered"
    case read = "Read"
}


struct messageUI : View{
    
    @ObservedObject var message: Message
    
    @State var isLastMessage: Bool = false
    
    var body : some View{
        HStack{
            if message.isMe{
                Spacer()
            }
            VStack(alignment: .trailing){
                Text(message.messageContent)
                    .padding(10)
                    .foregroundColor(message.isMe ? Color.white : Color.white)
                    .background(message.isMe ? Color(hex: "1D6F8A") : Color(hex: "A4D2C3"))
                    .cornerRadius(10)
                
                if message.isMe && isLastMessage{
                    Text(message.state.rawValue)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            if !message.isMe{
                Spacer()
            }
            
        }  .listRowBackground(Color.clear)
        
    }
}



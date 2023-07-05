//
//  ChatView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import SwiftUI

struct ChatView: View {

    @State private var typingMessage = ""
    
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var isNewMessageAdded = false

    var body: some View {
        VStack {
            List {
                ForEach(chatViewModel.messages, id: \.self) { message in
                    messageUI(message: message)
                        .listRowSeparator(.hidden)
                }
              
            }
            .navigationTitle("Chat")
            .toolbar {
                NavigationLink("Done", destination: Survey())
            }
            
            HStack {
                TextField("Message...", text: $typingMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: CGFloat(30))
                
                Button(action: sendMessage) {
                    Text("Send")
                }
            }
            .frame(minHeight: CGFloat(50)).padding()
        }
    
        
    }
    
    private func sendMessage() {
        guard !typingMessage.isEmpty else { return }
        
        let newMessage = Message(isMe: true, messageContent: typingMessage, name: nil, timestamp: Date())
        chatViewModel.addMessage(newMessage)
        typingMessage = ""
    }
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

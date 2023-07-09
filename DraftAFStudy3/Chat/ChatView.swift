//
//  ChatView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import FirebaseAuth
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
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(
                    Color(hex: "A4D2C3"),
                           for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                NavigationLink("Done", destination: Survey())
                
                NavigationLink {
                   LogInView()
                        .navigationBarBackButtonHidden(true)
                        .onAppear {
                            //MARK: DOES NOT WORK
                           logOut()
                        }
                    
                } label: {
                    Image(systemName: "door.right.hand.open")
                        .foregroundColor(.red)
                }
                
            
                
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
    
    private func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Failed to sign out")
        }
    }
    
    
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

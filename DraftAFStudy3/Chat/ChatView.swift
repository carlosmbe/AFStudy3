//
//  ChatView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import SwiftUI

struct ChatView: View{
    
    @State private var typingMessage = ""
    @State var messages : [Message] = Message.messageDummyData()
    
    var body: some View{
  
        VStack {
            List{
                ForEach(messages, id: \.self) { message in
                    messageUI(message: message)
                        .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Chat")
            .toolbar{
                NavigationLink("Done", destination: Survey())
            }
            
            
            HStack {
                TextField("Message...", text: $typingMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: CGFloat(30))
                
                Button(action: sendMessage) {
                    Text("Send")
                }
                
            }.frame(minHeight: CGFloat(50)).padding()
            
            
        }
    }
    
    
    private func sendMessage(){
        let newMessage = Message(isMe: true, messageContent: typingMessage)
        messages.append(newMessage)
        typingMessage = ""
    }
    
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
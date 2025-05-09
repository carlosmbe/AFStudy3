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
            chatViewModel.markMyLastSentMessageAsRead()
        }
        
        .onReceive(chatViewModel.$messagesLoaded) { (loaded) in
            if loaded {
                chatViewModel.markMyLastSentMessageAsRead()
            }
        }
            
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            //MARK: Disabled For The Spring Break 2025 Test
           // NavigationLink("Survey", destination: Survey())
            
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear")
            }
        }
        .alert("There Was An Issue \n\(chatViewModel.batchErrorMessage)", isPresented: $chatViewModel.batchMessageError)
        { Button("OK"){ chatViewModel.batchErrorMessage = "" } }
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
                Button {  chatViewModel.sendMessage(typingMessage: typingMessage) } label: {
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
        chatViewModel.timer?.invalidate()
        chatViewModel.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            chatViewModel.sendBatchedMessages()
        }
    }
    
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

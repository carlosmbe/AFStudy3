//
//  ChatView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import Alamofire
import FirebaseAuth
import SwiftUI

struct ChatView: View {
    
    @State private var typingMessage = ""
    
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some View {
        VStack {
            
            ScrollViewReader { scrollView in
                
                List {
                    ForEach(chatViewModel.messages) { message in
                        messageUI(message: message)
                            .listRowSeparator(.hidden)
                            .id(message.id)
                    }
                    
                    if chatViewModel.isSendingMessage {
                        ProgressView()
                    }
                    
                }
                .onChange(of: chatViewModel.messages) { _ in
                    withAnimation {
                        scrollView.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
                    }
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
             
                
                if chatViewModel.isSendingMessage {
                    ProgressView()
                        .padding()
                }else{
                    Button(action: sendMessage) {
                        Text("Send")
                    }
                }
                
            }
            .frame(minHeight: CGFloat(50)).padding()
        }
        
        
        .alert("There Was An Issue \n\(errorMessage)", isPresented: $showError)
        {   Button("Alright :c"){   errorMessage = ""   }   }
        
        
    }
    
    
    
    
    private func sendMessage() {
        guard !typingMessage.isEmpty else {
            return
        }

        let parameters: [String: String] = [
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "message": typingMessage,
            "name": Auth.auth().currentUser?.displayName ?? ""
        ]

        let serverUrl = "\(chatViewModel.serverAddress)/message"
        
        
        chatViewModel.isSendingMessage = true
        
        AF.request(serverUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { response in
                // You can handle the server's response here
                debugPrint(response)
                
                switch response.result{
                case .success(_):
                    print("Sucess")
                    chatViewModel.isSendingMessage = false
                case .failure(let error):
                    errorMessage = "\(error.localizedDescription)"
                    showError = true
                    chatViewModel.isSendingMessage = false
                    
                }
            }

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

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
    @StateObject private var chatViewModel = ChatViewModel()

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
        guard !typingMessage.isEmpty else {
            return
        }

        let parameters: [String: String] = [
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "message": typingMessage,
            "name": Auth.auth().currentUser?.displayName ?? ""
        ]

        AF.request("http://127.0.0.1:5000/message", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { response in
                // You can handle the server's response here
                debugPrint(response)
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

//
//  SignUpView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct SignUpView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var firstName: String = ""
    @State private var userEmail: String = ""
    @State private var userPass: String = ""
    @State private var confirmPass: String = ""   // New state for the confirmation password
    
    @State private var error: String = ""
    @State private var showSignUpError = false
    
    @State private var authenticationDidSucceed = false
    @State private var isLoading = false  // loading indicator state

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "A4D2C3"), Color(hex: colorScheme == .dark ? "282828" : "F6FCF8")]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack{
                ZStack {
                    Color(hex: "A4D2C3")
                        .frame(maxWidth: 220, maxHeight: 100)
                        .cornerRadius(10)  // Rounded corners
                        .padding()
                    
                    VStack {
                        Text("Hello!")
                        Text("Sign Up")
                    }
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    
                }
                
                Image("ai_v_in")

                TextField("First Name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                TextField("Email", text: $userEmail)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                SecureField("Password", text: $userPass)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                SecureField("Confirm Password", text: $confirmPass)  // New SecureField for confirmation
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button("Sign Up", action: signUp)
                    .buttonStyle(.borderedProminent)
                    .padding()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                }
                
                NavigationLink(destination: ChatView().navigationBarBackButtonHidden(true),
                               isActive: $authenticationDidSucceed) {
                    EmptyView()
                }
            }
            .alert("Error: \(error)", isPresented: $showSignUpError) {
                Button("OK") {}
            }
        }
    }
    
    func signUp() {
        // Check if passwords match
        guard userPass == confirmPass else {
            error = "Passwords do not match."
            showSignUpError = true
            return
        }
        
        isLoading = true
        Auth.auth().createUser(withEmail: userEmail, password: userPass) { (result, error) in
            if let error = error {
                self.error = error.localizedDescription
                showSignUpError = true
                isLoading = false
            } else {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = firstName
                changeRequest?.commitChanges { (error) in
                    if let error = error {
                        self.error = error.localizedDescription
                        showSignUpError = true
                    } else {
                        self.authenticationDidSucceed = true

                        // Send the welcome message to the new user
                        if let userId = result?.user.uid {
                            let welcomeMessage = "Hi, This UwU Bot. Thanks for taking part in this study. Please send a message to begin the chat. Thank you. Please don't be shy now. OwO"
                            
                            let db =  Firestore.firestore()
                            
                            db.collection("UserMessages").document(userId).collection("messageItems").addDocument(data: [
                                "isMe": false,
                                "messageContent": welcomeMessage,
                                "name": "Bot",
                                "timestamp": Date()
                            ])
                            
                            
                        }
                    }
                    isLoading = false
                }
            }
        }
    }

    
    
    
    
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

//
//  SignUpView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import SwiftUI
import Firebase

struct SignUpView: View {
    
    @State private var firstName: String = ""
    @State private var userEmail: String = ""
    @State private var userPass: String = ""
    
    @State private var error: String = ""
    @State private var showSignUpError = false
    
    @State private var authenticationDidSucceed = false
    @State private var isLoading = false  // loading indicator state

    var body: some View {
        VStack{
            Text("Create Account")
                .font(.largeTitle)
                .padding()

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
            
            Button("Sign Up", action: signUp)
                .buttonStyle(.borderedProminent)
                .padding()
            
            
            // Display progress view when loading
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
            }
            
            // Navigation to ChatView after successful sign up
            NavigationLink(destination: ChatView(), isActive: $authenticationDidSucceed) {  EmptyView()     }
          
            
        }
        .alert("Error: \(error)", isPresented: $showSignUpError) {
            Button("OK") {}
        }
    }
    
    func signUp() {
        
        
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
                    }
                    isLoading = false  // Stop loading after profile update
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

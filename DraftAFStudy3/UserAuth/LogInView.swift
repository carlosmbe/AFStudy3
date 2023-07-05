//
//  LogInView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import SwiftUI
import FirebaseAuth

struct LogInView: View{
    
    @State private var userEmail : String = ""
    @State private var userPass : String = ""
    
    
    @State private var error = ""
    @State private var showLogInError = false
    @State private var authenticationDidSucceed = false
    
    @State private var showPasswordResetSent = false
    
    var body :some View{
        VStack{
            Text("Hello There.\nIntesting Text Here")
            
            
            TextField("Email", text: $userEmail)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            SecureField("Password", text: $userPass)
                .textFieldStyle(.roundedBorder)
                .padding([.top,.leading,.trailing])
            
            Button("Forgot password?", action: sendPasswordReset)
                           .buttonStyle(.borderless)
                           .padding(.bottom)
            
            
            
            
            
            NavigationLink(destination: ChatView(), isActive: $authenticationDidSucceed) {
                       EmptyView()
                   }
            
            
            
            
            Button("Sign In", action: signIn)
                .keyboardType(.default)
                .buttonStyle(.borderedProminent)
                .padding()
            
            NavigationLink("New User? Sign Up here", destination: SignUpView())
            .buttonStyle(.borderless)
            .padding()
            
            
        }
        .alert("Error: \(error)", isPresented: $showLogInError){
            Button("OK"){}
        }
        
        .alert("Password Reset Email Sent", isPresented: $showPasswordResetSent){
              Button("OK"){}
          }
    }
    
    
    func signIn() {
        Auth.auth().signIn(withEmail: userEmail, password: userPass) { (result, error) in
            if let error = error {
                self.error = error.localizedDescription
                showLogInError = true
            } else {
                self.authenticationDidSucceed = true
            }
        }
    }
    
    func sendPasswordReset() {
           Auth.auth().sendPasswordReset(withEmail: userEmail) { (error) in
               if let error = error {
                   self.error = error.localizedDescription
                   showLogInError = true
               } else {
                   showPasswordResetSent = true
               }
           }
       }
    
    
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

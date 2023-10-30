//
//  LogInView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import SwiftUI
import FirebaseAuth

struct LogInView: View{
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var userEmail : String = ""
    @State private var userPass : String = ""
    
    
    @State private var error = ""
    @State private var showLogInError = false
    @State private var authenticationDidSucceed = false
    
    @State private var showPasswordResetSent = false
    
    var body :some View{
        ZStack {
            
            LinearGradient(gradient: Gradient(colors:  [Color(hex: "A4D2C3"),
                                                        Color(hex: colorScheme == .dark ? "282828" : "F6FCF8")
                                                       ]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
             
            VStack{
                
                ZStack {
                    Color(hex: "A4D2C3")
                        .frame(maxWidth: 220, maxHeight: 100)
                        .cornerRadius(10)  // Rounded corners
                        .padding()
                    
                    VStack {
                        Text("Hello!")
                        Text("Please Log In")
                    }
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    
                }
                
                Image("ai_v_in")
                
                
                TextField("Email", text: $userEmail)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.lowercase)
                    .padding()
                
                SecureField("Password", text: $userPass)
                    .textFieldStyle(.roundedBorder)
                    .padding([.top,.leading,.trailing])
                
                Button("Forgot password?", action: sendPasswordReset)
                    .buttonStyle(.borderless)
                    .padding(.bottom)
                
                
                
                
                
                NavigationLink(destination: ChatView().navigationBarBackButtonHidden(true)
                               ,isActive: $authenticationDidSucceed) {
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
            
            .onAppear{
                print("Is User Logged In \(Auth.auth().currentUser?.description)")
            }
            
            .alert("Error: \(error)", isPresented: $showLogInError){
                Button("OK"){}
            }
            .alert("Password Reset Email Sent", isPresented: $showPasswordResetSent){
                Button("OK"){}
        }
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



extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.letters.union(.decimalDigits).inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

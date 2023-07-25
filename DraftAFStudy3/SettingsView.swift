//
//  SettingsView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-23.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    var body: some View {
        
        VStack{
            Text("This is mainly place holder text and a log out button for now")
                .font(.headline)
                .padding()
            
            
            Text("""
The project's primary goal is to test whether long-term interactions with an AI chatbot lead to an increased perception of the AI as an attachment figure, and consequently, a decrease in users' feelings of loneliness.

Our study employs a diary-based approach in conjunction with a companion chatbot app. Over the course of eight weeks, participants from different demographics are expected to interact daily with the chatbot app, participate in activities designed to foster closeness, and provide feedback on their experience.
""")
            .padding()
            
            
            NavigationLink{
                LogInView()
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        //MARK: DOES NOT WORK
                        logOut()
                    }
                
            }   label: {
                Text("Log Out")
                    .foregroundColor(.red)
                    .padding()
                 
            }
            
        }
        .navigationTitle("Settings")
  
    }
    
    private func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Failed to sign out")
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

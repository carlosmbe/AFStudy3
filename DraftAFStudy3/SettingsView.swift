//
//  SettingsView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var userGroup: String = "Loading..."

    var body: some View {
        VStack {
            Text("Version: \(UIApplication.appVersion!)")
                .font(.headline)
                .padding()
                
            Text("Current Talking Group: \(userGroup)")

            NavigationLink {
                SignUpView()
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        logOut()
                    }
            } label: {
                Text("Log Out")
                    .foregroundColor(.red)
                    .padding()
            }
            
            NavigationLink("Test View", destination: TestView())
            
        }
        .onAppear{
            fetchUserGroup()
        }
        .navigationTitle("Settings")
    }
    
    private func fetchUserGroup() {
            guard let userID = Auth.auth().currentUser?.uid else {
                userGroup = "An AUTH Error Happened"
                return
            }

            let db = Firestore.firestore()
            db.collection("UserPromptTypes").document(userID).getDocument { document, error in
                if let error = error {
                    userGroup = "Error: \(error.localizedDescription)"
                } else if let document = document, document.exists, let promptType = document.data()?["promptType"] as? String {
                    userGroup = promptType
                } else {
                    userGroup = "Group not found"
                }
            }
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

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

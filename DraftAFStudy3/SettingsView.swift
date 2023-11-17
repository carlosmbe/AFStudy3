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
            Text("Version: \(UIApplication.appVersion!)")
                .font(.headline)
                .padding()
            
            
            
            NavigationLink{
                SignUpView()
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        //MARK: DOES NOT WORK Properly
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


extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

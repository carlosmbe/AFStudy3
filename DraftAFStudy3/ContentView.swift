//
//  ContentView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-13.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            LogInView()
        }
    }
}

struct LogInView: View{
    
    @State private var userEmail : String = ""
    @State private var userPass : String = ""
    
    var body :some View{
        VStack{
            Text("Hello There.\nIntesting Text Here")
            TextField("Email", text: $userEmail)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            TextField("Password", text: $userPass)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            NavigationLink("Log In", destination: ChatView())
                .buttonStyle(.borderedProminent)
                .padding()
            
            
            
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

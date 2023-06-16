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

struct ChatView: View{
    
    @State private var typingMessage = ""
    @State var messages : [Message] = Message.messageDummyData()
    
    var body: some View{
        
        VStack {
            List{
                ForEach(messages, id: \.self) { message in
                    messageUI(message: message)
                        .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Chat")
            .toolbar{
                NavigationLink("Done", destination: ReviewDetail())
            }
        }
        
        HStack {
            TextField("Message...", text: $typingMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minHeight: CGFloat(30))
            Button(action: sendMessage) {
                Text("Send")
            }
        }.frame(minHeight: CGFloat(50)).padding()
    }
    
    
    private func sendMessage(){
        let newMessage = Message(isMe: true, messageContent: typingMessage)
        messages.append(newMessage)
        typingMessage = ""
    }
    
}

struct ReviewDetail: View{
    
    @State private var mood: Double = 0
    @State private var timeSpent: Double = 0
    
    private let moodColors: [Color] = [.red,
                                       .yellow,
                                       .blue,
                                       .mint,
                                       .green]
    
    
    
    var body: some View{
        
        VStack{
    
            Group{
                Text("How Much Time Did You Spend With The Chat Bot?")
                    .font(.subheadline)
                    .padding()
               
                Text("\(Int(timeSpent.rounded()))/10")
                    .padding()
                    .font(.subheadline)
                
                HStack{
                    Text("A Little 1/10")
                    Spacer()
                    
                    Text("Fair 5/10")
                    
                    Spacer()
                    
                    Text("Alot 10/10")
                }
                
                Slider(value: $timeSpent, in: 0...10)
                    .padding()
            }
    
            
            Group{
                Text("How was your day?")
                    .font(.subheadline)
                    .padding()
                
                HStack{
                    Text("Very Negative")
                        .foregroundColor(.red)
                    Spacer()
                    
                    Text("Meh")
                    
                    Spacer()
                    
                    Text("Very Positive")
                        .foregroundColor(.green)
                }
                
                Slider(value: $mood, in: 0...4, step: 1)
                    .accentColor(moodColors[Int(mood.rounded())])
                    .padding()
            }
            
            Text("Other Prompts Come Here")
                .padding()
            
            
            Button("Submit"){
                
            }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Sliders Here")
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

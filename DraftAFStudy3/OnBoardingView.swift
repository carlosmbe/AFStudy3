//
//  OnBoardingView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-11-14.
//


import SwiftUI


struct OnBoardingView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "A4D2C3"), Color(hex: colorScheme == .dark ? "282828" : "e1dCF0")]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ZStack {
                TabView {
                    MockChatCardView()
                    MockSurveyCardView()
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .padding(.vertical, 20)
                
                
                
            }
        }//BACKGROUND ZSTACK ENDS HERE
    }
}


// Mock Chat Card View
struct MockChatCardView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Chat With AI")
                    .foregroundColor(Color.primary)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
                Text("Hi, Thanks for taking part in this study. Please chat with the bot the same way you chat with your freinds. Don't be shy. OwO")
                    .foregroundColor(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 480)
                
                MockChatView() // Non-interactive chat view
            }
        }
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

// Mock Survey Card View
struct MockSurveyCardView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Survey")
                    .foregroundColor(Color.primary)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
                Text("Once a day we'll also have a short survey of questions for you to answer.")
                    .foregroundColor(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 480)
                
                MockSurveyView() // Non-interactive survey view
                
              
            }
        }
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

// Preview
struct OnBoardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnBoardingView()
    }
}

struct StartButtonView: View {
    var body: some View {
        
        NavigationLink(destination: ChatView().navigationBarBackButtonHidden(true)) {
            HStack(spacing: 8) {
                Text("Get Started")
                    .foregroundColor(.primary)
                Image(systemName: "arrow.right.circle")
                    .imageScale(.large)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.5)) // Semi-transparent background
            )
        }
        .accentColor(Color.white)
    }
}


struct MockChatView: View {
    
    private let mockMessages = [
            MockMessage(messageContent: "Hello! How are you doing today?", isMe: false),
            MockMessage(messageContent: "I'm alright, just doing my best. Thank you! How are you?", isMe: true),
            MockMessage(messageContent: "Not so well to be hoesnt, do you have a moment?", isMe: false)
        ]
    
    var body: some View {
        VStack {
        
            Spacer()

            // Sample Messages
            ForEach(mockMessages) { message in
                
                    MockMessageUI(message: message)
                    .padding(.top)
                              .listRowBackground(Color.clear)
                      }

            Spacer()
            
            // Sample Input Area (Non-interactive)
            HStack {
                Text("Message...")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.blue)
                    .padding()
            }
            .padding()
            
            Text("Please Swipe To Continue")
            
            Spacer()
            
        }
    }
}


struct MockSurveyView: View {
    
    let choices =  [
        "1) Very Negative",
        "2) Negative",
        "3) Neither positive nor negative",
        "4) Positive",
        "5) Very Positive"
    ]
    
    var body: some View {
        VStack {
            
            
            Text("How positive or negative was your mood today?")
                .font(.headline)
                .padding()
            
            ForEach(choices, id: \.self) { option in
                Text(option)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            
  
            
            
        }
        .padding()
        
        StartButtonView()
        

    }
}

struct MockMessage: Identifiable {
    let id = UUID()
    var messageContent: String
    var isMe: Bool
}

struct MockMessageUI: View {
    var message: MockMessage
    
    var body: some View {
        HStack {
            if message.isMe {
                Spacer()
            }
            
            Text(message.messageContent)
                .padding(7.25)
                .foregroundColor(Color.white)
                .background(message.isMe ? Color(hex: "1D6F8A") : Color(hex: "A4D2C3"))
                .cornerRadius(10)
            
            if !message.isMe {
                Spacer()
            }
        }
    }
}

//
//  Models.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-14.
//

import FirebaseFirestoreSwift
import FirebaseAuth
import Foundation
import SwiftUI

class Message: Identifiable, Hashable, ObservableObject {
    // For Firebase
    @DocumentID var docId: String?
    
    let id = UUID()
    var isMe: Bool
    var messageContent: String
    var name: String?
    var lineNumber: Int?
    var isComplete: Bool?
    
    @Published var state: MessageState = .sent
    var timestamp: Date = Date()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(isMe: Bool, messageContent: String, name: String? = nil,
         state: MessageState = .sent, timestamp: Date = Date(),
         lineNumber: Int? = nil, isComplete: Bool? = nil) {
        self.isMe = isMe
        self.messageContent = messageContent
        self.name = name ?? Auth.auth().currentUser?.displayName
        self.state = state
        self.timestamp = timestamp
        self.lineNumber = lineNumber
        self.isComplete = isComplete
    }
}

enum MessageState: String {
    case sent = "Sent"
    case processing = "Responding"
    case read = "Read"
}


struct messageUI: View {
    @ObservedObject var message: Message
    @State var isLastMessage: Bool = false
    @State private var currentImageIndex: Int = 1
    @State private var imageSwapTimer: Timer?
    
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    var body: some View {
        HStack {
            if message.isMe {
                Spacer()
            }
            
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
                Text(message.messageContent)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(message.isMe ? Color(hex: "1D6F8A") : Color(hex: "A4D2C3"))
                    .cornerRadius(12)
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.messageContent
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                
                if isLastMessage {
                    if message.isMe {
                        Text(message.state.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        HStack {
                            if message.state == .processing {
                                TypingIndicatorView(currentImageIndex: $currentImageIndex)
                            } else {
                                Image("ai_w")
                                    .resizable()
                                    .frame(width: 63, height: 31)
                            }
                            
                            if !message.isMe {
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            if !message.isMe {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onAppear {
            if message.state == .processing {
                startImageSwapTimer()
            }
        }
        .onDisappear {
            stopImageSwapTimer()
        }
        .onChange(of: message.state) { newState in
            if newState == .processing {
                startImageSwapTimer()
            } else {
                stopImageSwapTimer()
            }
        }
    }
    
    func startImageSwapTimer() {
        imageSwapTimer?.invalidate()
        imageSwapTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentImageIndex = currentImageIndex % 4 + 1
        }
    }
    
    func stopImageSwapTimer() {
        imageSwapTimer?.invalidate()
        imageSwapTimer = nil
    }
}

struct TypingIndicatorView: View {
    @Binding var currentImageIndex: Int
    
    var body: some View {
        Image("ai_dots_\(currentImageIndex)")
            .resizable()
            .scaledToFit()
            .frame(width: 63, height: 31)
    }
}




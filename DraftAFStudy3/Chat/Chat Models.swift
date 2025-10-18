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

// MARK: - Chat Bubble Shape (UI only)
struct ChatBubbleShape: Shape {
    var isMe: Bool
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        var path = Path()
        if isMe {
            // Right aligned bubble with tail on bottom-right
            path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - 6, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
            
        } else {
            // Left aligned bubble with tail on bottom-left
            path.addRoundedRect(in: CGRect(x: rect.minX + 6, y: rect.minY, width: rect.width - 6, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
        }
        return path
    }
}

struct messageUI: View {
    @ObservedObject var message: Message
    @State var isLastMessage: Bool = false
    @State private var currentImageIndex: Int = 1
    @State private var imageSwapTimer: Timer?
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var chatViewModel: ChatViewModel

    // UI configuration
    private let maxBubbleWidthRatio: CGFloat = 0.72

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isMe { Spacer(minLength: 40) }
            if !message.isMe { avatarOrIndicatorPlaceholder() }
            bubbleContent()
                .accessibilityElement(children: .combine)
                .accessibilityLabel(message.messageContent)
            if message.isMe { avatarOrIndicatorPlaceholder(isOutgoing: true) }
            if !message.isMe { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .onAppear { if message.state == .processing { startImageSwapTimer() } }
        .onDisappear { stopImageSwapTimer() }
        .onChange(of: message.state) { newState in
            if newState == .processing { startImageSwapTimer() } else { stopImageSwapTimer() }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private func avatarOrIndicatorPlaceholder(isOutgoing: Bool = false) -> some View {
        // Minimal placeholder spacing to align bubbles; could host avatars later.
        Color.clear.frame(width: 4, height: 4)
    }

    @ViewBuilder
    private func bubbleContent() -> some View {
        VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
            Text(message.messageContent)
                .font(.system(.body, design: .rounded))
                .foregroundColor(message.isMe ? Color.white : Color.primary)
                .multilineTextAlignment(message.isMe ? .trailing : .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(bubbleBackground)
                .clipShape(ChatBubbleShape(isMe: message.isMe))
                .overlay(
                    ChatBubbleShape(isMe: message.isMe)
                        .stroke(borderColor.opacity(0.08), lineWidth: 1)
                )
                .contextMenu {
                    Button(action: { UIPasteboard.general.string = message.messageContent }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                .animation(nil, value: message.id) // avoid unwanted anim on load

            if isLastMessage { statusOrTypingRow() }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * maxBubbleWidthRatio, alignment: message.isMe ? .trailing : .leading)
    }

    @ViewBuilder
    private func statusOrTypingRow() -> some View {
        if message.isMe {
            Text(message.state.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .transition(.opacity)
        } else {
            HStack(spacing: 4) {
                if message.state == .processing {
                    TypingIndicatorView(currentImageIndex: $currentImageIndex)
                        .frame(width: 30, height: 20)
                        .transition(.opacity)
                } else {
                    Image("ai_w")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 24)
                        .transition(.opacity)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }

    private var bubbleBackground: some View {
        Group {
            if message.isMe {
                LinearGradient(colors: [Color(hex: "1D6F8A"), Color(hex: "1D6F8A").opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                (colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "A4D2C3").opacity(0.55))
            }
        }
    }

    private var borderColor: Color { message.isMe ? .white : .black }

    // MARK: - Typing Images Timer
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
    }
}

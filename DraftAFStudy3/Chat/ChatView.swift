//
//  ChatView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import Alamofire
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Combine

struct ChatView: View {
    @State private var typingMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var isInitialScrollDone = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var shouldAutoScroll = true // Track if user is at bottom

    @EnvironmentObject var chatViewModel: ChatViewModel

    // MARK: - Publishers for keyboard
    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

    var body: some View {
        VStack(spacing: 0) {
            messagesScrollArea()
            dividerLine()
            messageInput()
                .padding(.bottom, max(8, keyboardHeight - safeAreaBottomInset()))
                .background(.ultraThinMaterial)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if !chatViewModel.messagesLoaded { chatViewModel.loadMessages() }
            chatViewModel.markMyLastSentMessageAsRead()
        }
        .onReceive(chatViewModel.$messagesLoaded) { loaded in
            if loaded {
                chatViewModel.markMyLastSentMessageAsRead()
                // Scroll to bottom when messages first load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(animated: false)
                }
            }
        }
        .onReceive(keyboardWillShow) { notification in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = extractKeyboardHeight(notification)
            }
            // Delay scroll to allow keyboard animation to start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                scrollToBottom(animated: true)
            }
        }
        .onReceive(keyboardWillHide) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .onChange(of: chatViewModel.messages.count) { _ in
            // Only auto-scroll if user was already at bottom
            if shouldAutoScroll {
                scrollToBottom(animated: true)
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .imageScale(.large)
                }
            }
        }
        .alert("There Was An Issue", isPresented: $chatViewModel.batchMessageError) {
            Button("OK") { chatViewModel.batchErrorMessage = "" }
        }
        .overlay(alignment: .bottomTrailing) {
            // Scroll to bottom button (shows when user scrolls up)
            if !shouldAutoScroll {
                scrollToBottomButton()
            }
        }
    }

    // MARK: - Messages Area
    private func messagesScrollArea() -> some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        // Top spacer for better initial layout
                        Color.clear.frame(height: 1).id("TOP")
                        
                        ForEach(chatViewModel.messages) { message in
                            let lastFromMeID = chatViewModel.messages.last(where: { $0.isMe })?.id
                            let lastFromOtherID = chatViewModel.messages.last(where: { !$0.isMe })?.id
                            
                            messageUI(
                                message: message,
                                isLastMessage: message.id == lastFromMeID || message.id == lastFromOtherID
                            )
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        if chatViewModel.isSendingMessage {
                            HStack {
                                ProgressView()
                                    .padding(12)
                                Spacer()
                            }
                            .transition(.opacity)
                        }
                        
                        // Bottom anchor with padding
                        Color.clear.frame(height: 8).id("BOTTOM")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    // Track scroll position
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: contentGeometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    // Consider "at bottom" if within 100 points
                    let threshold: CGFloat = 100
                    shouldAutoScroll = offset > -threshold
                }
                .onAppear {
                    scrollProxy = proxy
                    if !isInitialScrollDone && !chatViewModel.messages.isEmpty {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                        isInitialScrollDone = true
                    }
                }
                .onChange(of: chatViewModel.messages.count) { _ in
                    scrollProxy = proxy
                }
            }
        }
    }

    // MARK: - Scroll to Bottom Button
    private func scrollToBottomButton() -> some View {
        Button(action: {
            scrollToBottom(animated: true)
            shouldAutoScroll = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                Text("Scroll to Bottom")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.blue)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.trailing, 16)
        .padding(.bottom, 80) // Above input field
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldAutoScroll)
    }

    // MARK: - Input
    private func messageInput() -> some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $typingMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .lineLimit(1...6)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .onChange(of: typingMessage) { newValue in
                    handleTypingChange(newValue)
                }
                .submitLabel(.send)
                .onSubmit {
                    sendCurrentMessage()
                }

            if chatViewModel.isSendingMessage {
                ProgressView()
                    .padding(.horizontal, 8)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: sendCurrentMessage) {
                    Image(systemName: "paperplane.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .foregroundStyle(
                            typingMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color(.tertiaryLabel)
                                : Color.blue
                        )
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(typingMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(typingMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.85 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: typingMessage.isEmpty)
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.2), value: chatViewModel.isSendingMessage)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chat_input_bar")
    }

    private func dividerLine() -> some View {
        Divider()
            .background(Color(.separator).opacity(0.5))
    }

    // MARK: - Actions
    private func sendCurrentMessage() {
        let trimmed = typingMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        chatViewModel.sendMessage(typingMessage: trimmed)
        typingMessage = ""
        dismissKeyboard()
        
        // Ensure scroll to bottom after sending
        shouldAutoScroll = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToBottom(animated: true)
        }
    }

    private func handleTypingChange(_ newValue: String) {
        chatViewModel.timer?.invalidate()
        chatViewModel.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            chatViewModel.sendBatchedMessages()
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard let proxy = scrollProxy, !chatViewModel.messages.isEmpty else { return }
        
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("BOTTOM", anchor: .bottom)
        }
    }

    // MARK: - Helpers
    private func extractKeyboardHeight(_ notification: Notification) -> CGFloat {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            return frame.height
        }
        return 0
    }

    private func safeAreaBottomInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.safeAreaInsets.bottom ?? 0
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preference Key for Scroll Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView()
                .environmentObject(ChatViewModel())
        }
    }
}

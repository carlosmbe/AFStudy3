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
    @State private var isInitialScrollDone = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var shouldAutoScroll = true // Track if user is at/near bottom
    @FocusState private var isInputFocused: Bool

    @EnvironmentObject var chatViewModel: ChatViewModel

    var body: some View {
        ZStack {
            messagesScrollArea()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        // Pin the input bar to the safe area bottom (it will sit above the keyboard automatically)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                dividerLine()
                messageInput()
                    .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            if !chatViewModel.messagesLoaded { chatViewModel.loadMessages() }
            chatViewModel.markMyLastSentMessageAsRead()
        }
        .onReceive(chatViewModel.$messagesLoaded) { loaded in
            if loaded {
                chatViewModel.markMyLastSentMessageAsRead()
                // Scroll to bottom after first load/layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(animated: false)
                }
            }
        }
        .onChange(of: chatViewModel.messages.count) { _ in
            if shouldAutoScroll {
                scrollToBottom(animated: true)
            }
        }
        .onChange(of: isInputFocused) { focused in
            if focused {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    scrollToBottom(animated: true)
                }
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            NavigationLink(destination: SettingsView()) { Image(systemName: "gear") }
//        }
        .alert("There Was An Issue \n\(chatViewModel.batchErrorMessage)", isPresented: $chatViewModel.batchMessageError) {
            Button("OK") { chatViewModel.batchErrorMessage = "" }
        }
        // Tap to dismiss keyboard
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
        // Floating "scroll to bottom" button
        .overlay(alignment: .bottomTrailing) {
            if !shouldAutoScroll {
                scrollToBottomButton()
            }
        }
    }

    // MARK: - Messages Area
    private func messagesScrollArea() -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(chatViewModel.messages) { message in
                        let lastFromMeID = chatViewModel.messages.last(where: { $0.isMe })?.id
                        let lastFromOtherID = chatViewModel.messages.last(where: { !$0.isMe })?.id
                        messageUI(
                            message: message,
                            isLastMessage: message.id == lastFromMeID || message.id == lastFromOtherID
                        )
                        .id(message.id)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                    }
                    if chatViewModel.isSendingMessage {
                        ProgressView()
                            .padding(.vertical, 4)
                            .transition(.opacity)
                    }
                    // Bottom anchor
                    Color.clear.frame(height: 1).id("BOTTOM")
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                // Track whether we're near the bottom to control auto-scroll
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollMinYPreferenceKey.self, value: geo.frame(in: .named("chatScroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "chatScroll")
            .scrollDismissesKeyboard(.interactively)
            .onPreferenceChange(ScrollMinYPreferenceKey.self) { minY in
                // Heuristic: when content's minY is close to 0 in this named space,
                // we treat it as being near bottom (tweak threshold for your layout)
                let threshold: CGFloat = 100
                shouldAutoScroll = minY > -threshold
            }
            .onAppear {
                scrollProxy = proxy
                performInitialOrAnimatedScroll(proxy: proxy, animated: false)
            }
            .onChange(of: chatViewModel.messages.count) { _ in
                scrollProxy = proxy
                performInitialOrAnimatedScroll(proxy: proxy, animated: true)
            }
        }
    }

    private func performInitialOrAnimatedScroll(proxy: ScrollViewProxy, animated: Bool = true) {
        guard !chatViewModel.messages.isEmpty else { return }
        if !isInitialScrollDone {
            proxy.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
            isInitialScrollDone = true
        } else if animated {
            withAnimation(.easeOut(duration: 0.35)) {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("BOTTOM", anchor: .bottom)
        }
    }

    // MARK: - Scroll to Bottom Button
    private func scrollToBottomButton() -> some View {
        Button {
            scrollToBottom(animated: true)
            shouldAutoScroll = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                Text("New Messages")
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
        .padding(.bottom, 90) // sits above the input bar
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldAutoScroll)
    }

    // MARK: - Input
    private func messageInput() -> some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $typingMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(.secondarySystemBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.tertiarySystemFill), lineWidth: 1)
                )
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { sendCurrentMessage() }
                .onChange(of: typingMessage) { newValue in
                    handleTypingChange(newValue)
                }

            if chatViewModel.isSendingMessage {
                ProgressView().padding(.horizontal, 4)
            } else {
                Button(action: sendCurrentMessage) {
                    Image(systemName: "paperplane.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .foregroundStyle(.blue, .blue.opacity(0.3))
                        .symbolRenderingMode(.palette)
                }
                .disabled(typingMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(typingMessage.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: typingMessage.isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .accessibilityIdentifier("chat_input_bar")
    }

    private func dividerLine() -> some View {
        Divider()
            .overlay(Color(.separator).opacity(0.4))
            .padding(.horizontal, 0)
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
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preference Key
private struct ScrollMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

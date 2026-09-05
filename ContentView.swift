import SwiftUI
import UIKit

struct ContentView: View {

    // MARK: - State

    @State private var chats: [Chat] = []
    @State private var currentChatID: UUID?
    @State private var message = ""
    @State private var isLoading = false
    @State private var showMenu = false

    // MARK: - Server

    private let serverURL =
        "https://myai-backend.abcdeabcde1234567890987654321.workers.dev"

    // MARK: - Current Chat

    private var currentChatIndex: Int? {
        guard let id = currentChatID else {
            return nil
        }

        return chats.firstIndex { chat in
            chat.id == id
        }
    }

    private var currentMessages: [ChatMessage] {
        guard let index = currentChatIndex else {
            return []
        }

        return chats[index].messages
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            mainView

            if showMenu {
                sideMenu
                    .transition(.move(edge: .leading))
                    .zIndex(10)
            }
        }
        .onAppear {
            loadChats()
        }
    }

    // MARK: - Main View

    private var mainView: some View {
        VStack(spacing: 0) {

            topBar

            Divider()

            chatArea

            messageInput
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {

            Button {
                withAnimation {
                    showMenu = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text("Anurag ai")
                .font(.headline)
                .bold()

            Spacer()

            Button {
                createNewChat()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {

                    if currentMessages.isEmpty {
                        emptyChatView
                    } else {

                        ForEach(currentMessages) { chat in
                            messageBubble(chat)
                                .id(chat.id)
                        }

                        if isLoading {
                            thinkingView
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .onChange(of: currentMessages.count) { _, _ in
                scrollToLastMessage(proxy)
            }
        }
    }

    // MARK: - Empty Chat

    private var emptyChatView: some View {
        VStack(spacing: 14) {

            Image(systemName: "sparkles")
                .font(.system(size: 48))

            Text("How can I help you?")
                .font(.title2)
                .bold()

            Text("Ask anything now.")
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 450
        )
    }

    // MARK: - Thinking

    private var thinkingView: some View {
        HStack(spacing: 10) {

            Image(systemName: "sparkles")

            ProgressView()

            Text("Thinking...")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Message Input

    private var messageInput: some View {
        HStack(spacing: 10) {

            Button {
                // Attachment feature can be added later.
            } label: {
                Image(systemName: "plus")
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .frame(
                        width: 34,
                        height: 34
                    )
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 8) {

                TextField(
                    "Message Anurag AI...",
                    text: $message,
                    axis: .vertical
                )
                .lineLimit(1...5)

                if message
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {

                    Button {
                        // Voice input can be added later.
                    } label: {
                        Image(systemName: "mic")
                            .font(
                                .system(size: 18)
                            )
                            .foregroundStyle(.secondary)
                    }

                } else {

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(
                                width: 44,
                                height: 44
                            )
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    .disabled(!canSend)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 7)
            .background(
                Color(.secondarySystemBackground)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 24
                )
                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: 1
                )
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(
        _ chat: ChatMessage
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            if chat.isUser {
                Spacer()
            } else {

                Image(systemName: "sparkles")
                    .font(.title3)
                    .frame(
                        width: 34,
                        height: 34
                    )
                    .background(
                        Color(
                            .secondarySystemBackground
                        )
                    )
                    .clipShape(Circle())
            }

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                if chat.isUser {

                    Text(chat.text)
                        .textSelection(.enabled)
                        .padding(
                            .horizontal,
                            15
                        )
                        .padding(
                            .vertical,
                            12
                        )
                        .background(
                            Color(.systemGray6)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                        )

                } else {

                    if let formatted = try? AttributedString(
                        markdown: chat.text
                    ) {

                        Text(formatted)
                            .textSelection(.enabled)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                    } else {

                        Text(chat.text)
                            .textSelection(.enabled)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }

                    Button {
                        UIPasteboard.general.string =
                            chat.text
                    } label: {
                        Label(
                            "Copy",
                            systemImage: "doc.on.doc"
                        )
                        .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if !chat.isUser {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Side Menu

    private var sideMenu: some View {

        HStack(spacing: 0) {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                HStack {

                    Text("Anurag AI")
                        .font(.title2)
                        .bold()

                    Spacer()

                    Button {
                        withAnimation {
                            showMenu = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                    }
                }

                // New Chat

                Button {
                    createNewChat()

                    withAnimation {
                        showMenu = false
                    }
                } label: {

                    HStack {

                        Image(
                            systemName:
                                "square.and.pencil"
                        )

                        Text("New chat")

                        Spacer()
                    }
                    .padding()
                    .background(
                        Color(
                            .secondarySystemBackground
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )
                }
                .foregroundStyle(.primary)

                Text("Your chats")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Chat History

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        ForEach(
                            chats.reversed()
                        ) { chat in

                            Button {

                                currentChatID =
                                    chat.id

                                withAnimation {
                                    showMenu = false
                                }

                            } label: {

                                HStack {

                                    Image(
                                        systemName:
                                            "bubble.left"
                                    )

                                    Text(chat.title)
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(
                                    .vertical,
                                    10
                                )
                                .padding(
                                    .horizontal,
                                    8
                                )
                            }
                            .foregroundStyle(
                                currentChatID == chat.id
                                    ? .primary
                                    : .secondary
                            )
                        }
                    }
                }

                Spacer()

                Divider()

                HStack {

                    Image(
                        systemName:
                            "person.circle"
                    )

                    Text("Anurag AI")

                    Spacer()
                }
            }
            .padding(20)
            .frame(width: 310)
            .frame(maxHeight: .infinity)
            .background(.regularMaterial)

            Color.black
                .opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showMenu = false
                    }
                }
        }
        .ignoresSafeArea()
    }

    // MARK: - Can Send

    private var canSend: Bool {

        let trimmedMessage =
            message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return !trimmedMessage.isEmpty
            && !isLoading
    }

    // MARK: - Create New Chat

    private func createNewChat() {

        let newChat = Chat()

        chats.append(newChat)

        currentChatID = newChat.id

        saveChats()
    }

    // MARK: - Send Message

    private func sendMessage() {

        let text =
            message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            return
        }

        // Create a chat if none exists.

        if currentChatID == nil {

            let newChat = Chat(
                title: String(
                    text.prefix(30)
                )
            )

            chats.append(newChat)

            currentChatID = newChat.id
        }

        guard let index = currentChatIndex else {
            return
        }

        // First message becomes the chat title.

        if chats[index].messages.isEmpty {

            chats[index].title =
                String(text.prefix(30))
        }

        // Add user message.

        chats[index].messages.append(
            ChatMessage(
                text: text,
                isUser: true
            )
        )

        message = ""

        isLoading = true

        saveChats()

        guard let url =
            URL(string: serverURL) else {

            chats[index].messages.append(
                ChatMessage(
                    text: "Invalid server URL.",
                    isUser: false
                )
            )

            isLoading = false

            saveChats()

            return
        }

        // Prepare messages for server.

        let requestMessages =
            chats[index].messages.map { chatMessage in

                [
                    "isUser": chatMessage.isUser,
                    "text": chatMessage.text
                ] as [String: Any]
            }

        let body: [String: Any] = [
            "messages": requestMessages
        ]

        guard let jsonData =
            try? JSONSerialization.data(
                withJSONObject: body
            ) else {

            chats[index].messages.append(
                ChatMessage(
                    text:
                        "Could not create request.",
                    isUser: false
                )
            )

            isLoading = false

            saveChats()

            return
        }

        // Create request.

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.httpBody = jsonData

        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in

            DispatchQueue.main.async {

                // Connection error.

                if let error = error {

                    self.addAssistantMessage(
                        "Connection error: \(error.localizedDescription)"
                    )

                    self.isLoading = false

                    self.saveChats()

                    return
                }

                // No response.

                guard let data = data else {

                    self.addAssistantMessage(
                        "No response from server."
                    )

                    self.isLoading = false

                    self.saveChats()

                    return
                }

                // Decode response.

                do {

                    guard let result =
                        try JSONSerialization.jsonObject(
                            with: data
                        ) as? [String: Any] else {

                        self.addAssistantMessage(
                            "The server returned an unexpected response."
                        )

                        self.isLoading = false

                        self.saveChats()

                        return
                    }

                    if let reply =
                        result["reply"] as? String {

                        self.addAssistantMessage(
                            reply
                        )

                    } else if let errorMessage =
                        result["error"] as? String {

                        self.addAssistantMessage(
                            "Server error: \(errorMessage)"
                        )

                    } else {

                        self.addAssistantMessage(
                            "The server returned an unexpected response."
                        )
                    }

                } catch {

                    self.addAssistantMessage(
                        "Could not read server response."
                    )
                }

                self.isLoading = false

                self.saveChats()
            }

        }.resume()
    }

    // MARK: - Add Assistant Message

    private func addAssistantMessage(
        _ text: String
    ) {

        guard let index = currentChatIndex else {
            return
        }

        chats[index].messages.append(
            ChatMessage(
                text: text,
                isUser: false
            )
        )
    }

    // MARK: - Scroll

    private func scrollToLastMessage(
        _ proxy: ScrollViewProxy
    ) {

        guard let lastMessage =
            currentMessages.last else {
            return
        }

        withAnimation {
            proxy.scrollTo(
                lastMessage.id,
                anchor: .bottom
            )
        }
    }

    // MARK: - Save Chats

    private func saveChats() {

        guard let data =
            try? JSONEncoder().encode(chats) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: "MyAI_Chats"
        )
    }

    // MARK: - Load Chats

    private func loadChats() {

        guard
            let data =
                UserDefaults.standard.data(
                    forKey: "MyAI_Chats"
                ),
            let savedChats =
                try? JSONDecoder().decode(
                    [Chat].self,
                    from: data
                )
        else {

            createNewChat()

            return
        }

        chats = savedChats

        if currentChatID == nil {

            currentChatID =
                chats.last?.id
        }

        // If saved data contains no chats,
        // create the first one.

        if chats.isEmpty {
            createNewChat()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

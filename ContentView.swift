import SwiftUI
import UIKit

struct ContentView: View {
    @State private var chats: [Chat] = []
    @State private var currentChatID: UUID?
    @State private var message = ""
    @State private var isLoading = false
    @State private var showMenu = false

    private let serverURL =
        "https://myai-backend.abcdeabcde1234567890987654321.workers.dev"

    var currentChatIndex: Int? {
        guard let id = currentChatID else { return nil }
        return chats.firstIndex { $0.id == id }
    }

    var currentMessages: [ChatMessage] {
        guard let index = currentChatIndex else { return [] }
        return chats[index].messages
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {

                // Top bar
                HStack {
                    Button {
                        showMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                    }

                    Spacer()

                    Text("Anurag AI")
                        .font(.headline)
                        .bold()

                    Spacer()

                    Button {
                        createNewChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                    }
                }
                .padding()

                Divider()

                // Messages
                ScrollView {
                    VStack(spacing: 16) {
                        if currentMessages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 45))

                                Text("How can I help you?")
                                    .font(.title2)
                                    .bold()

                                Text("Ask anything now.")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 150)
                        } else {
                            ForEach(currentMessages) { chat in
                                messageBubble(chat)
                            }

                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // Input
                HStack(spacing: 8) {
                    TextField(
                        "Message Anurag AI...",
                        text: $message,
                        axis: .vertical
                    )
                    .lineLimit(1...5)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    .disabled(
                        message.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || isLoading
                    )
                }
                .padding(10)
                .background(.ultraThinMaterial)
            }

            if showMenu {
                sideMenu
            }
        }
        .onAppear {
            loadChats()
        }
    }

    // MARK: Message Bubble

    @ViewBuilder
    func messageBubble(_ chat: ChatMessage) -> some View {
        HStack(alignment: .top) {
            if chat.isUser {
                Spacer()
            } else {
                Image(systemName: "sparkles")
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(chat.text)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(
                        chat.isUser
                        ? Color(.systemGray6)
                        : Color.clear
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )

                if !chat.isUser {
                    Button {
                        UIPasteboard.general.string = chat.text
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if !chat.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }

    // MARK: Side Menu

    var sideMenu: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Anurag AI")
                        .font(.title2)
                        .bold()

                    Spacer()

                    Button {
                        showMenu = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                Button {
                    createNewChat()
                    showMenu = false
                } label: {
                    Label("New chat", systemImage: "square.and.pencil")
                }

                Divider()

                Text("Your chats")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(chats.reversed()) { chat in
                            Button {
                                currentChatID = chat.id
                                showMenu = false
                            } label: {
                                HStack {
                                    Image(systemName: "bubble.left")
                                    Text(chat.title)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(.regularMaterial)

            Color.black
                .opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    showMenu = false
                }
        }
        .ignoresSafeArea()
    }

    // MARK: New Chat

    func createNewChat() {
        let chat = Chat()
        chats.append(chat)
        currentChatID = chat.id
        saveChats()
    }

    // MARK: Send Message

    func sendMessage() {
        let text = message.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty, !isLoading else {
            return
        }

        if currentChatID == nil {
            let chat = Chat(title: String(text.prefix(30)))
            chats.append(chat)
            currentChatID = chat.id
        }

        guard let index = currentChatIndex else {
            return
        }

        if chats[index].messages.isEmpty {
            chats[index].title = String(text.prefix(30))
        }

        chats[index].messages.append(
            ChatMessage(
                text: text,
                isUser: true
            )
        )

        message = ""
        isLoading = true
        saveChats()

        guard let url = URL(string: serverURL) else {
            addAssistantMessage("Invalid server URL.")
            return
        }

        let requestMessages = chats[index].messages.map {
            [
                "isUser": $0.isUser,
                "text": $0.text
            ] as [String: Any]
        }

        let body: [String: Any] = [
            "messages": requestMessages
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: body
        ) else {
            addAssistantMessage("Could not create request.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = data

        URLSession.shared.dataTask(
            with: request
        ) { data, _, error in

            DispatchQueue.main.async {
                if let error = error {
                    addAssistantMessage(
                        "Connection error: \(error.localizedDescription)"
                    )
                    return
                }

                guard let data = data else {
                    addAssistantMessage(
                        "No response from server."
                    )
                    return
                }

                do {
                    let result = try JSONSerialization.jsonObject(
                        with: data
                    ) as? [String: Any]

                    if let reply = result?["reply"] as? String {
                        addAssistantMessage(reply)
                    } else if let error = result?["error"] as? String {
                        addAssistantMessage(
                            "Server error: \(error)"
                        )
                    } else {
                        addAssistantMessage(
                            "Unexpected server response."
                        )
                    }
                } catch {
                    addAssistantMessage(
                        "Could not read server response."
                    )
                }
            }
        }.resume()
    }

    // MARK: Add AI Message

    func addAssistantMessage(_ text: String) {
        if let index = currentChatIndex {
            chats[index].messages.append(
                ChatMessage(
                    text: text,
                    isUser: false
                )
            )
        }

        isLoading = false
        saveChats()
    }

    // MARK: Save

    func saveChats() {
        if let data = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.set(
                data,
                forKey: "AnuragAI_Chats"
            )
        }
    }

    // MARK: Load

    func loadChats() {
        guard
            let data = UserDefaults.standard.data(
                forKey: "AnuragAI_Chats"
            ),
            let saved = try? JSONDecoder().decode(
                [Chat].self,
                from: data
            )
        else {
            createNewChat()
            return
        }

        chats = saved
        currentChatID = chats.last?.id

        if chats.isEmpty {
            createNewChat()
        }
    }
}

#Preview {
    ContentView()
}

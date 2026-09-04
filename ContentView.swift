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

let serverURL =
    "https://myai-backend.abcdeabcde1234567890987654321.workers.dev"

// MARK: - Current Chat

var currentChatIndex: Int? {
    guard let id = currentChatID else {
        return nil
    }
    
    return chats.firstIndex {
        $0.id == id
    }
}

var currentMessages: [ChatMessage] {
    guard let index = currentChatIndex else {
        return []
    }
    
    return chats[index].messages
}

// MARK: - Main Interface

var body: some View {
    
    ZStack {
        
        VStack(spacing: 0) {
            
            // TOP BAR
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
            
            Divider()
            
            // CHAT AREA
            ScrollViewReader { proxy in
                
                ScrollView {
                    
                    VStack(spacing: 20) {
                        
                        if currentMessages.isEmpty {
                            
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
                            
                        } else {
                            
                            ForEach(currentMessages) { chat in
                                messageBubble(chat)
                                    .id(chat.id)
                            }
                            
                            if isLoading {
                                
                                HStack(spacing: 10) {
                                    
                                    Image(systemName: "sparkles")
                                    
                                    ProgressView()
                                    
                                    Text("Thinking...")
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .onChange(of: currentMessages.count) {
                    
                    if let lastMessage = currentMessages.last {
                        
                        withAnimation {
                            proxy.scrollTo(
                                lastMessage.id,
                                anchor: .bottom
                            )
                        }
                    }
                }
            }
            
            // MESSAGE INPUT
            HStack(spacing: 10) {
                
                // PLUS BUTTON
                Button {
                    // Attachment menu can be added later.
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
                
                // MESSAGE FIELD
                HStack(spacing: 8) {
                    
                    TextField(
                        "Message MyAI...",
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
                                .font(.system(size: 18))
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
        
        // SIDE MENU
        if showMenu {
            sideMenu
                .transition(
                    .move(edge: .leading)
                )
        }
    }
    .onAppear {
        loadChats()
    }
}

// MARK: - Message Bubble

@ViewBuilder
func messageBubble(
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
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .background(
                        Color(.systemGray6)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                
            } else {
                
                if let formatted =
                    try? AttributedString(
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
                
                // COPY BUTTON
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

var sideMenu: some View {
    
    HStack(spacing: 0) {
        
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            
            // MENU HEADER
            HStack {
                
                Text("MyAI")
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
            
            // NEW CHAT
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
            
            // CHAT HISTORY
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
                
                Text("MyAI")
                
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

// MARK: - New Chat

func createNewChat() {
    
    let newChat = Chat()
    
    chats.append(newChat)
    
    currentChatID = newChat.id
    
    saveChats()
}

// MARK: - Send Message

func sendMessage() {
    
    let text = message.trimmingCharacters(
        in: .whitespacesAndNewlines
    )
    
    guard !text.isEmpty else {
        return
    }
    
    guard !isLoading else {
        return
    }
    
    // Create chat if needed
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
    
    // First message becomes title
    if chats[index].messages.isEmpty {
        
        chats[index].title =
            String(text.prefix(30))
    }
    
    // Add user message
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
    
    // Prepare messages
    let requestMessages =
        chats[index].messages.map {
            
            [
                "isUser": $0.isUser,
                "text": $0.text
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
    
    // Create request
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    
    request.setValue(
        "application/json",
        forHTTPHeaderField: "Content-Type"
    )
    
    request.httpBody = jsonData
    
    URLSession.shared.dataTask(
        with: request
    ) { data, response, error in
        
        // CONNECTION ERROR
        if let error = error {
            
            DispatchQueue.main.async {
                
                guard let index =
                        currentChatIndex else {
                    isLoading = false
                    return
                }
                
                chats[index].messages.append(
                    ChatMessage(
                        text:
                            "Connection error: " +
                        error.localizedDescription,
                        isUser: false
                    )
                )
                
                isLoading = false
                
                saveChats()
            }
            
            return
        }
        
        // NO DATA
        guard let data = data else {
            
            DispatchQueue.main.async {
                
                if let index =
                    currentChatIndex {
                    
                    chats[index].messages.append(
                        ChatMessage(
                            text:
                                "No response from server.",
                            isUser: false
                        )
                    )
                }
                
                isLoading = false
                
                saveChats()
            }
            
            return
        }
        
        // READ RESPONSE
        do {
            
            guard let result =
                    try JSONSerialization.jsonObject(
                        with: data
                    ) as? [String: Any] else {
                
                DispatchQueue.main.async {
                    
                    if let index =
                        currentChatIndex {
                        
                        chats[index].messages.append(
                            ChatMessage(
                                text:
                                    "The server returned an invalid response.",
                                isUser: false
                            )
                        )
                    }
                    
                    isLoading = false
                    saveChats()
                }
                
                return
            }
            
            DispatchQueue.main.async {
                
                guard let index =
                        currentChatIndex else {
                    isLoading = false
                    return
                }
                
                if let reply =
                    result["reply"] as? String {
                    
                    chats[index].messages.append(
                        ChatMessage(
                            text: reply,
                            isUser: false
                        )
                    )
                    
                } else if let errorMessage =
                            result["error"] as? String {
                    
                    chats[index].messages.append(
                        ChatMessage(
                            text:
                                "Server error: " +
                            errorMessage,
                            isUser: false
                        )
                    )
                    
                } else {
                    
                    chats[index].messages.append(
                        ChatMessage(
                            text:
                                "The server returned an unexpected response.",
                            isUser: false
                        )
                    )
                }
                
                isLoading = false
                
                saveChats()
            }
            
        } catch {
            
            DispatchQueue.main.async {
                
                if let index =
                    currentChatIndex {
                    
                    chats[index].messages.append(
                        ChatMessage(
                            text:
                                "Could not read server response.",
                            isUser: false
                        )
                    )
                }
                
                isLoading = false
                
                saveChats()
            }
        }
        
    }.resume()
}

// MARK: - Can Send

var canSend: Bool {
    
    !message.trimmingCharacters(
        in: .whitespacesAndNewlines
    ).isEmpty
    && !isLoading
}

// MARK: - Save Chats

func saveChats() {
    
    if let data =
        try? JSONEncoder().encode(chats) {
        
        UserDefaults.standard.set(
            data,
            forKey: "MyAI_Chats"
        )
    }
}

// MARK: - Load Chats

func loadChats() {
    
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
}

}

#Preview {
ContentView()
}

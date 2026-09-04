import Foundation

struct ChatMessage: Identifiable, Codable {
let id: UUID
let text: String
let isUser: Bool

init(
    id: UUID = UUID(),
    text: String,
    isUser: Bool
) {
    self.id = id
    self.text = text
    self.isUser = isUser
}

}

struct Chat: Identifiable, Codable {
let id: UUID
var title: String
var messages: [ChatMessage]

init(
    id: UUID = UUID(),
    title: String = "New chat",
    messages: [ChatMessage] = []
) {
    self.id = id
    self.title = title
    self.messages = messages
}

}

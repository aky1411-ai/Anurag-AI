package com.anuragai.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject

data class ChatMessage(
    val text: String,
    val isUser: Boolean
)

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            AnuragAIApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnuragAIApp() {

    var messages by remember {
        mutableStateOf(
            listOf(
                ChatMessage(
                    "Hello! I'm Anurag AI. How can I help you?",
                    false
                )
            )
        )
    }

    var input by remember { mutableStateOf("") }
    var thinking by remember { mutableStateOf(false) }
    var drawerOpen by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    if (drawerOpen) {
        ModalNavigationDrawer(
            drawerContent = {
                ModalDrawerSheet {
                    Spacer(modifier = Modifier.height(30.dp))

                    Text(
                        "Anurag AI",
                        fontSize = 24.sp,
                        modifier = Modifier.padding(20.dp)
                    )

                    NavigationDrawerItem(
                        label = { Text("New Chat") },
                        selected = false,
                        onClick = {
                            messages = listOf(
                                ChatMessage(
                                    "Hello! I'm Anurag AI. How can I help you?",
                                    false
                                )
                            )
                            drawerOpen = false
                        },
                        icon = {
                            Icon(Icons.Default.Add, contentDescription = "New chat")
                        }
                    )
                }
            }
        ) {
            ChatScreen(
                messages = messages,
                input = input,
                thinking = thinking,
                listState = listState,
                onMenu = { drawerOpen = true },
                onInputChange = { input = it },
                onSend = {
                    if (input.isNotBlank() && !thinking) {

                        val userText = input.trim()

                        messages = messages +
                                ChatMessage(userText, true)

                        input = ""
                        thinking = true

                        scope.launch {

                            val reply = sendMessageToAI(
                                messages
                            )

                            messages = messages +
                                    ChatMessage(reply, false)

                            thinking = false
                        }
                    }
                }
            )
        }

    } else {

        ChatScreen(
            messages = messages,
            input = input,
            thinking = thinking,
            listState = listState,
            onMenu = { drawerOpen = true },
            onInputChange = { input = it },
            onSend = {
                if (input.isNotBlank() && !thinking) {

                    val userText = input.trim()

                    messages = messages +
                            ChatMessage(userText, true)

                    input = ""
                    thinking = true

                    scope.launch {

                        val reply = sendMessageToAI(
                            messages
                        )

                        messages = messages +
                                ChatMessage(reply, false)

                        thinking = false
                    }
                }
            }
        )
    }
}

@Composable
fun ChatScreen(
    messages: List<ChatMessage>,
    input: String,
    thinking: Boolean,
    listState: androidx.compose.foundation.lazy.LazyListState,
    onMenu: () -> Unit,
    onInputChange: (String) -> Unit,
    onSend: () -> Unit
) {

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Anurag AI")
                },
                navigationIcon = {
                    IconButton(onClick = onMenu) {
                        Icon(
                            Icons.Default.Menu,
                            contentDescription = "Menu"
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {}) {
                        Icon(
                            Icons.Default.Add,
                            contentDescription = "New chat"
                        )
                    }
                }
            )
        }
    ) { padding ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {

            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                state = listState,
                verticalArrangement = Arrangement.spacedBy(10.dp),
                contentPadding = PaddingValues(vertical = 12.dp)
            ) {

                items(messages) { message ->

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement =
                            if (message.isUser)
                                Arrangement.End
                            else
                                Arrangement.Start
                    ) {

                        Surface(
                            shape = MaterialTheme.shapes.large,
                            tonalElevation = 2.dp,
                            modifier = Modifier.widthIn(max = 320.dp)
                        ) {

                            Text(
                                text = message.text,
                                modifier = Modifier.padding(14.dp),
                                fontSize = 16.sp
                            )
                        }
                    }
                }

                if (thinking) {

                    item {

                        Text(
                            "Thinking...",
                            modifier = Modifier.padding(12.dp),
                            fontSize = 15.sp
                        )
                    }
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {

                OutlinedTextField(
                    value = input,
                    onValueChange = onInputChange,
                    modifier = Modifier.weight(1f),
                    placeholder = {
                        Text("Message Anurag AI...")
                    },
                    maxLines = 5
                )

                Spacer(modifier = Modifier.width(8.dp))

                IconButton(
                    onClick = onSend,
                    enabled = input.isNotBlank() && !thinking
                ) {

                    Icon(
                        Icons.Default.Send,
                        contentDescription = "Send"
                    )
                }
            }
        }
    }
}

suspend fun sendMessageToAI(
    messages: List<ChatMessage>
): String {

    return try {

        val jsonMessages = JSONArray()

        messages.forEach {

            val obj = JSONObject()

            obj.put("isUser", it.isUser)
            obj.put("text", it.text)

            jsonMessages.put(obj)
        }

        val json = JSONObject()

        json.put("messages", jsonMessages)

        val client = OkHttpClient()

        val body = json.toString()
            .toRequestBody(
                "application/json".toMediaType()
            )

        val request = Request.Builder()
            .url(
                "https://myai-backend.abcdeabcde1234567890987654321.workers.dev"
            )
            .post(body)
            .build()

        val response = client.newCall(request).execute()

        val responseText = response.body?.string()
            ?: return "No response received."

        val result = JSONObject(responseText)

        result.optString(
            "reply",
            result.optString(
                "error",
                "I couldn't get a response."
            )
        )

    } catch (e: Exception) {

        "Connection error: ${e.message ?: "Unknown error"}"
    }
}

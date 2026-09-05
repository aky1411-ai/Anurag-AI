package com.anuragai.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

data class ChatMessage(
    val text: String,
    val isUser: Boolean
)

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            MaterialTheme {
                AnuragAI()
            }
        }
    }
}

@Composable
fun AnuragAI() {

    var message by remember {
        mutableStateOf("")
    }

    val messages = remember {
        mutableStateListOf(
            ChatMessage(
                text = "Hello! I am Anurag AI. How can I help you?",
                isUser = false
            )
        )
    }

    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Anurag AI",
                        fontSize = 22.sp
                    )
                }
            )
        }
    ) { paddingValues ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {

            LazyColumn(
                state = listState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 12.dp)
            ) {

                items(messages) { chatMessage ->

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement =
                            if (chatMessage.isUser) {
                                Arrangement.End
                            } else {
                                Arrangement.Start
                            }
                    ) {

                        Surface(
                            shape = RoundedCornerShape(18.dp),
                            color =
                                if (chatMessage.isUser) {
                                    MaterialTheme.colorScheme.primary
                                } else {
                                    MaterialTheme.colorScheme.surfaceVariant
                                }
                        ) {

                            Text(
                                text = chatMessage.text,
                                modifier = Modifier.padding(
                                    horizontal = 16.dp,
                                    vertical = 12.dp
                                ),
                                color =
                                    if (chatMessage.isUser) {
                                        MaterialTheme.colorScheme.onPrimary
                                    } else {
                                        MaterialTheme.colorScheme.onSurfaceVariant
                                    }
                            )
                        }
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
                    value = message,
                    onValueChange = {
                        message = it
                    },
                    modifier = Modifier.weight(1f),
                    placeholder = {
                        Text("Message Anurag AI...")
                    },
                    maxLines = 4
                )

                Spacer(
                    modifier = Modifier.width(8.dp)
                )

                IconButton(
                    onClick = {

                        val text = message.trim()

                        if (text.isNotEmpty()) {

                            messages.add(
                                ChatMessage(
                                    text = text,
                                    isUser = true
                                )
                            )

                            message = ""

                            // Temporary response.
                            // We will connect your real AI API next.
                            messages.add(
                                ChatMessage(
                                    text = "I'm processing your message...",
                                    isUser = false
                                )
                            )

                            scope.launch {
                                listState.animateScrollToItem(
                                    messages.lastIndex
                                )
                            }
                        }
                    }
                ) {

                    Icon(
                        imageVector = Icons.Default.Send,
                        contentDescription = "Send"
                    )
                }
            }
        }
    }
}

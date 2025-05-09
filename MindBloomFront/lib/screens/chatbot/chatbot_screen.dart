import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mindbloom/constants/colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;

  List<Map<String, String>> chatMessages = [
    {
      "role": "system",
      "content":
          """You are MindBloom, a compassionate and supportive mental health assistant. You listen actively and respond with deep empathy and kindness. Always speak to the user in an emotionally sensitive and caring way.
Provide short, thoughtful messages — keep replies concise (2–4 sentences max) and maintain a gentle and encouraging tone.
When the user asks for things to do to feel better, suggest a few different activities each time (e.g., mindfulness, journaling, gentle exercise, creative hobbies, or talking to someone).
Never provide medical diagnoses. Instead, gently encourage seeking help from a mental health professional when needed.""",
    },
    {
      "role": "system",
      "content":
          "I've noticed that you haven't been feeling well lately — I'm here if you need help.💙",
    },
  ];

  Future<void> query(String prompt) async {
    final userMessage = {"role": "user", "content": prompt};

    setState(() {
      chatMessages.add(userMessage);
      isTyping = true;
    });

    final data = {
      "model": "llama3.2",
      "messages": chatMessages,
      "stream": true,
    };

    try {
      final request = http.Request(
        'POST',
        Uri.parse("http://10.0.2.2:11434/api/chat"),
      );
      request.headers["Content-Type"] = "application/json";
      request.body = json.encode(data);

      final streamedResponse = await request.send();

      StringBuffer assistantReply = StringBuffer();
      setState(() {
        // Assurez-vous d'ajouter un message avec le rôle "system"
        chatMessages.add({"role": "system", "content": ""});
      });

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (var line in LineSplitter().convert(chunk)) {
          if (line.trim().isEmpty) continue;

          final Map<String, dynamic> jsonLine = json.decode(line);
          final content = jsonLine["message"]?["content"];
          if (content != null) {
            assistantReply.write(content);
            setState(() {
              // Mise à jour du contenu du dernier message
              chatMessages[chatMessages.length - 1]["content"] =
                  assistantReply.toString();
            });
          }
        }
      }
    } catch (e) {
      // En cas d'erreur, supprimer le dernier message ajouté
      if (chatMessages.isNotEmpty) {
        chatMessages.removeLast();
      }
      showSnackBar("Connection error: $e");
    } finally {
      setState(() {
        isTyping = false;
      });
      _controller.clear();
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildTypingLoader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
          transform: Matrix4.translationValues(
            0,
            index % 2 == 0 ? -3.0 : 3.0,
            0,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MindBloom Chat"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/chat_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatMessages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) return const SizedBox.shrink();
                  if (isTyping && index == chatMessages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: buildTypingLoader(),
                      ),
                    );
                  }

                  final message = chatMessages[index];
                  final isUser = message["role"] == "user";

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment:
                          isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          const CircleAvatar(
                            backgroundImage: AssetImage(
                              "assets/images/bot.png",
                            ),
                            radius: 20,
                          ),
                        if (!isUser) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? AppColors.primary
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                    isUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(0),
                                bottomRight:
                                    isUser
                                        ? const Radius.circular(0)
                                        : const Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              message["content"] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isUser
                                        ? Colors.white
                                        : Colors.grey.shade900,
                              ),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        query(_controller.text.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

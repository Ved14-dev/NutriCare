import 'package:flutter/material.dart';
import '../ai/nutrition_chatbot.dart';

class ChatPage extends StatefulWidget {
    @override
    _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
    final TextEditingController _controller = TextEditingController();
    List<Map<String, String>> messages = [];

    void _sendMessage(String text) async {
        messages.add({'role': 'user', 'text': text});
        setState(() {});
        String reply = await NutritionChatBot.getResponse(text);
        messages.add({'role': 'bot', 'text': reply});
        setState(() {});
        _controller.clear();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Nutrition Chatbot')),
            body: Column(
                children: [
                    Expanded(
                        child: ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (ctx, i) => ListTile(
                                leading: messages[i]['role'] == 'bot' ? Icon(Icons.smart_toy) : Icon(Icons.person),
                                title: Text(messages[i]['text'] ?? ''),
                            ),
                        ),
                    ),
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                            children: [
                                Expanded(
                                    child: TextField(
                                        controller: _controller,
                                        decoration: InputDecoration(hintText: 'Type your nutrition query...'),
                                    ),
                                ),
                                IconButton(
                                    icon: Icon(Icons.send),
                                    onPressed: () => _sendMessage(_controller.text),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}

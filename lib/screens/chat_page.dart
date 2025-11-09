import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ai/nutrition_chatbot.dart';
import '../widgets/app_scaffold.dart';

class ChatPage extends StatefulWidget {
    const ChatPage({super.key});

    @override
    _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
    final TextEditingController _controller = TextEditingController();
    List<Map<String, String>> messages = [];

    void _sendMessage(String text) async {
        if (text.trim().isEmpty) return;
        messages.add({'role': 'user', 'text': text});
        setState(() {});
        String reply = await NutritionChatBot.getResponse(text);
        messages.add({'role': 'bot', 'text': reply});
        setState(() {});
        _controller.clear();
    }

    @override
    Widget build(BuildContext context) {
        return AppScaffold(
            title: 'Nutrition Chatbot',
            child: Column(
                children: [
                    Expanded(
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ListView.builder(
                                itemCount: messages.length,
                                itemBuilder: (ctx, i) {
                                    final m = messages[i];
                                    final bool isBot = m['role'] == 'bot';
                                    return Align(
                                        alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                                        child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                                color: isBot ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(m['text'] ?? '', style: GoogleFonts.inter(color: isBot ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary)),
                                        ),
                                    );
                                },
                            ),
                        ),
                    ),
                                Container(
                                    padding: const EdgeInsets.all(12),
                                    color: Theme.of(context).colorScheme.surface,
                                    child: Row(
                                        children: [
                                            Expanded(
                                                child: TextField(
                                                    controller: _controller,
                                                    decoration: InputDecoration(hintText: 'Type your nutrition query...', hintStyle: GoogleFonts.inter(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                                ),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton.icon(
                                                onPressed: () => _sendMessage(_controller.text),
                                                icon: const Icon(Icons.send, size: 18),
                                                label: Text('Send', style: GoogleFonts.inter()),
                                            )
                                        ],
                                    ),
                                ),
                ],
            ),
        );
    }
}

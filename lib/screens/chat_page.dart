import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../widgets/app_scaffold.dart';

class ChatPage extends StatefulWidget {
    const ChatPage({super.key});

    @override
    _ChatPageState createState() => _ChatPageState();
}

// Top-level reusable widgets for the chat UI

class _SuggestionChip extends StatelessWidget {
    final String label;
    final void Function(String) onTap;
    const _SuggestionChip({Key? key, required this.label, required this.onTap}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return ActionChip(
            label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            onPressed: () => onTap(label),
        );
    }
}

class UserBubble extends StatelessWidget {
    final String text;
    const UserBubble({Key? key, required this.text}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        final cs = Theme.of(context).colorScheme;
        return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(14),
                ),
                child: Text(text, style: GoogleFonts.inter(color: cs.onPrimary)),
            ),
        );
    }
}

class BotBubble extends StatelessWidget {
    final String text;
    const BotBubble({Key? key, required this.text}) : super(key: key);

    BotBubble.typing({Key? key}) : text = '...';

    @override
    Widget build(BuildContext context) {
        final cs = Theme.of(context).colorScheme;
        final isTyping = text == '...';
        return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                ),
                child: isTyping
                        ? TypingDots(color: cs.onSurface)
                        : SelectableText(text, style: GoogleFonts.inter(color: cs.onSurface)),
            ),
        );
    }
}

class TypingDots extends StatefulWidget {
    final Color? color;
    const TypingDots({Key? key, this.color}) : super(key: key);

    @override
    State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
    late final AnimationController _controller;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
        return SizedBox(
            width: 54,
            child: Center(
                child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                        final v = _controller.value;
                        return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                                final t = ((v + (i * 0.2)) % 1.0);
                                final e = Curves.easeIn.transform((t <= 0.5) ? (t * 2) : (1 - (t - 0.5) * 2));
                                final opacity = 0.3 + 0.7 * e;
                                return Opacity(
                                        opacity: opacity,
                                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)));
                            }),
                        );
                    },
                ),
            ),
        );
    }
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
    final TextEditingController _controller = TextEditingController();
    final ScrollController _scroll = ScrollController();
    final _formKey = GlobalKey<FormState>();

    // Firestore path: users/{uid}/chatHistory
    CollectionReference<Map<String, dynamic>> _chatCollection(String uid) => FirebaseFirestore.instance.collection('users').doc(uid).collection('chatHistory');

    // Gemini API key is hardcoded for now. Remove unused _hasGemini field.

    // UI state
    bool _isTyping = false;
    String _currentBotText = '';
    StreamSubscription<dynamic>? _streamSub;

    @override
    void dispose() {
        _controller.dispose();
        _scroll.dispose();
        _streamSub?.cancel();
        super.dispose();
    }

    // Helper: auto-scroll to bottom when messages change
    void _scrollToBottom({Duration duration = const Duration(milliseconds: 300)}) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scroll.hasClients) return;
            _scroll.animateTo(_scroll.position.maxScrollExtent, duration: duration, curve: Curves.easeOut);
        });
    }

    // Helper functions reading app data from Firestore
    Future<double> getTodayCalories(String uid) async {
        try {
            final today = DateTime.now();
            final start = DateTime(today.year, today.month, today.day);
            final snapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('nutritionData')
                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                    .get();
            double sum = 0.0;
            for (final doc in snapshot.docs) {
                final v = doc.data()['calories'];
                if (v is num) sum += v.toDouble();
            }
            return sum;
        } catch (e) {
            debugPrint('getTodayCalories error: $e');
            return 0.0;
        }
    }

    // (SuggestionChip, bubble and typing UI were moved to top-level)

    Future<int> getDailyWater(String uid) async {
        try {
            final today = DateTime.now();
            final start = DateTime(today.year, today.month, today.day);
            final snapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('waterIntake')
                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                    .get();
            int total = 0;
            for (final doc in snapshot.docs) {
                final v = doc.data()['ml'];
                if (v is num) total += v.toInt();
            }
            return total;
        } catch (e) {
            debugPrint('getDailyWater error: $e');
            return 0;
        }
    }

    Future<Map<String, dynamic>> getWeeklyFitness(String uid) async {
        try {
            final now = DateTime.now();
            final start = now.subtract(const Duration(days: 7));
            final snapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('fitnessData')
                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                    .get();
            final Map<String, dynamic> data = {'steps': 0, 'workouts': 0};
            for (final doc in snapshot.docs) {
                final d = doc.data();
                if (d['steps'] is num) data['steps'] += (d['steps'] as num).toInt();
                if (d['workout'] != null) data['workouts'] += 1;
            }
            return data;
        } catch (e) {
            debugPrint('getWeeklyFitness error: $e');
            return {'steps': 0, 'workouts': 0};
        }
    }

    // Send a user message -> save to Firestore -> trigger Gemini streaming -> save bot reply
    Future<void> _sendChat(String text, {String? uid}) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        final userId = uid ?? currentUser?.uid;
        if (userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in to chat.')));
            return;
        }

        if (text.trim().isEmpty) return;

        final col = _chatCollection(userId);

        await col.add({
            'sender': 'user',
            'message': text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
        });

        // Immediately show typing UI
        setState(() {
            _isTyping = true;
            _currentBotText = '';
        });

        final botDocRef = await col.add({
            'sender': 'bot',
            'message': '',
            'timestamp': FieldValue.serverTimestamp(),
            'streaming': true,
        });

        // Build a prompt that sometimes includes app data dynamically
        String prompt = text.trim();
        // Simple heuristics: if the user asks for water or calories, inject helper data
        final lower = prompt.toLowerCase();
        if (lower.contains('water')) {
            final water = await getDailyWater(userId);
            prompt += '\n\nUser data: Today water intake (ml): $water.';
        }
        if (lower.contains('calorie') || lower.contains('calories')) {
            final calories = await getTodayCalories(userId);
            prompt += '\n\nUser data: Today calories total: ${calories.toStringAsFixed(0)} kcal.';
        }
        if (lower.contains('steps') || lower.contains('fitness')) {
            final fitness = await getWeeklyFitness(userId);
            prompt += '\n\nUser data: Weekly steps: ${fitness['steps']}, workouts: ${fitness['workouts']}.';
        }

        // Fetch recent food logs and inject them into the prompt so Gemini can see recent food entries
        try {
            final foodSnap = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('food_logs')
                .orderBy('timestamp', descending: true)
                .limit(20)
                .get();

            if (foodSnap.docs.isNotEmpty) {
                final entries = foodSnap.docs.map((d) {
                    final data = d.data();
                    final name = (data['name'] as String?) ?? 'food';
                    final cal = data['calories']?.toString() ?? '0';
                    final qty = data['quantity']?.toString() ?? '1';
                    final day = (data['day'] as String?) ?? '';
                    final date = (data['date'] as String?) ?? '';
                    return '- $name | ${cal} cal | qty ${qty} | $day ($date)';
                }).join('\n');

                prompt += '\n\nThe user has the following recent food entries:\n${entries}';
            }
        } catch (e) {
            debugPrint('fetch food logs error: $e');
        }

        // Start streaming from Gemini
        try {
            _streamSub?.cancel();
            // Kick off streaming. If a real Gemini key is present we would use the
            // library here — otherwise fall back to a safe local streaming
            // simulator so the chat UI remains responsive and useful.
            _streamSub?.cancel();
            _streamSub = _startStreaming(prompt, botDocRef);
        } catch (e) {
            setState(() => _isTyping = false);
            debugPrint('Gemini start error: $e');
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is unavailable, try again.')));
            await botDocRef.update({'message': 'AI unavailable — please try again later.', 'streaming': false, 'error': true});
        } finally {
            _controller.clear();
            _scrollToBottom();
        }
    }

    // Gemini streaming adapter using google_generative_ai
    // Returns a StreamSubscription that can be cancelled.
    StreamSubscription<dynamic> _startStreaming(String prompt, DocumentReference<Map<String, dynamic>> botDocRef) {
        

        // Use the Generative API to get a full response then stream it
        // locally as chunks so the UI shows a streaming typing effect.
        const apiKey = 'AIzaSyCBab2yHBBLn9flrI2hTfV29HNh7346cS4';
        final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);

        // Use a controller to expose the simulated streaming subscription
        final controller = StreamController<String>();

        // Kick off generation asynchronously
        model.generateContent([Content.text(prompt)]).then((response) async {
            final full = response.text ?? '';
            if (full.isEmpty) {
                // nothing to stream
                controller.close();
                return;
            }

            // break into readable chunks for a streaming effect
            final step = 18; // chars per chunk
            final chunks = <String>[];
            for (var i = 0; i < full.length; i += step) {
                final end = (i + step) < full.length ? i + step : full.length;
                chunks.add(full.substring(i, end));
            }

            var pos = 0;
            Timer.periodic(const Duration(milliseconds: 50), (t) async {
                if (pos >= chunks.length) {
                    t.cancel();
                    await controller.close();
                    return;
                }
                controller.add(chunks[pos]);
                pos++;
            });
        }).catchError((e) async {
            debugPrint('Generative API error: $e');
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is unavailable, try again.')));
            await botDocRef.update({'message': 'AI unavailable — please try again later.', 'streaming': false, 'error': true});
            controller.add('AI unavailable — please try again later.');
            await controller.close();
        });

        // Listen to the simulated stream and write chunks to Firestore/UI
        return controller.stream.listen((chunk) async {
            setState(() {
                _currentBotText += chunk;
            });
            await botDocRef.update({'message': _currentBotText});
        }, onDone: () async {
            setState(() => _isTyping = false);
            await botDocRef.update({'message': _currentBotText, 'streaming': false});
        }, onError: (e) async {
            setState(() => _isTyping = false);
            debugPrint('Local streaming error: $e');
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is unavailable, try again.')));
            await botDocRef.update({'message': 'AI unavailable — please try again later.', 'streaming': false, 'error': true});
        });
    }

    @override
    Widget build(BuildContext context) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return const Center(child: Text('You must be signed in'));

        return AppScaffold(
            title: 'Nutrition Chatbot',
            child: Column(
                children: [
                    // Quick suggestion chips
                    Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                            height: 42,
                            child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                    const SizedBox(width: 4),
                                    _SuggestionChip(label: 'Suggest a healthy meal', onTap: (t) => _sendChat(t, uid: user.uid)),
                                    const SizedBox(width: 8),
                                    _SuggestionChip(label: 'Give today\'s calorie summary', onTap: (t) => _sendChat(t, uid: user.uid)),
                                    const SizedBox(width: 8),
                                    _SuggestionChip(label: 'Analyze my hydration', onTap: (t) => _sendChat(t, uid: user.uid)),
                                    const SizedBox(width: 8),
                                    _SuggestionChip(label: 'How many calories should I eat?', onTap: (t) => _sendChat(t, uid: user.uid)),
                                    const SizedBox(width: 8),
                                ],
                            ),
                        ),
                    ),

                    Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _chatCollection(user.uid).orderBy('timestamp', descending: false).snapshots(),
                            builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                    return Center(child: Text('Error loading messages'));
                                }

                                if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                }

                                final docs = snapshot.data!.docs;

                                // Keep auto-scrolling when messages change
                                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                                return ListView.builder(
                                    controller: _scroll,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    itemCount: docs.length + (_isTyping ? 1 : 0),
                                    itemBuilder: (ctx, i) {
                                        // typing indicator as a row at the bottom
                                        if (i == docs.length && _isTyping) {
                                            return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Row(
                                                    children: [
                                                        const SizedBox(width: 8),
                                                        BotBubble.typing(),
                                                    ],
                                                ),
                                            );
                                        }

                                        final doc = docs[i];
                                        final data = doc.data();
                                        final sender = (data['sender'] as String?) ?? 'bot';
                                        final text = (data['message'] as String?) ?? '';
                                        final ts = data['timestamp'] as Timestamp?;

                                        final time = ts != null ? DateFormat.Hm().format(ts.toDate()) : '';

                                        if (sender == 'user') {
                                            return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                        UserBubble(text: text),
                                                        const SizedBox(height: 4),
                                                        Text(time, style: Theme.of(context).textTheme.labelSmall),
                                                    ],
                                                ),
                                            );
                                        }

                                        return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    BotBubble(text: text),
                                                    const SizedBox(height: 4),
                                                    Text(time, style: Theme.of(context).textTheme.labelSmall),
                                                ],
                                            ),
                                        );
                                    },
                                );
                            },
                        ),
                    ),

                    // Input area
                    SafeArea(
                        child: Container(
                            padding: const EdgeInsets.all(12),
                            color: Theme.of(context).colorScheme.surface,
                            child: Row(
                                children: [
                                    Expanded(
                                        child: Form(
                                            key: _formKey,
                                            child: TextFormField(
                                                controller: _controller,
                                                minLines: 1,
                                                maxLines: 6,
                                                decoration: InputDecoration(
                                                    hintText: 'Type your nutrition query or tap a suggestion...',
                                                    hintStyle: GoogleFonts.inter(),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                ),
                                                onFieldSubmitted: (v) async {
                                                    final text = v.trim();
                                                    if (text.isEmpty) return;
                                                    await _sendChat(text);
                                                },
                                            ),
                                        ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                        onPressed: () async {
                                            final text = _controller.text.trim();
                                            if (text.isEmpty) return;
                                            await _sendChat(text);
                                        },
                                        icon: const Icon(Icons.send, size: 18),
                                        label: Text('Send', style: GoogleFonts.inter()),
                                    )
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

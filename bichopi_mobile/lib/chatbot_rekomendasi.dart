import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatbotRekomendasi extends StatefulWidget {
  const ChatbotRekomendasi({super.key});

  @override
  State<ChatbotRekomendasi> createState() => _ChatbotRekomendasiState();
}

class _ChatbotRekomendasiState extends State<ChatbotRekomendasi> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isBotTyping = false;

  void _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isBotTyping = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    String botResponse = await _generateBotResponse(text);

    setState(() {
      _messages.insert(0, ChatMessage(text: botResponse, isUser: false));
      _isBotTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _generateBotResponse(String userInput) async {
    if (userInput.toLowerCase().contains('halo')) {
      return 'Iya, bisa saya bantu? Saya asisten bot Bicopi Anda.';
    }

    final Map<String, String> keywordMap = {
      'manis': 'sweet',
      'kopi': 'coffee',
      'dingin': 'cold',
      'panas': 'hot',
      'hangat': 'warm',
      'segar': 'refreshing',
      'coklat': 'chocolate',
      'mangga': 'mango',
      'susu': 'milk',
      'air': 'water',
    };

    String? matchedKeyword;
    String? translatedKeyword;

    for (final entry in keywordMap.entries) {
      if (userInput.toLowerCase().contains(entry.key)) {
        matchedKeyword = entry.key;
        translatedKeyword = entry.value;
        break;
      }
    }

    if (translatedKeyword == null) {
      return 'Hmm... aku belum paham maksud kamu. Bisa jelaskan lagi dengan kata seperti "manis", "kopi", atau "segar"? 😊';
    }

    final response = await Supabase.instance.client
        .from('menu')
        .select('nama_menu, deskripsi_menu')
        .ilike('deskripsi_menu', '%$translatedKeyword%')
        .execute();

    if (response.error != null) {
      return 'Oops! Ada masalah saat aku cari datanya: ${response.error!.message} 😓';
    }

    final data = response.data as List<dynamic>?;

    if (data == null || data.isEmpty) {
      return 'Belum ketemu yang cocok dengan "$matchedKeyword", tapi kamu bisa coba kata lain seperti "dingin", "manis", atau "kopi"! 😉';
    }

    List<String> rekomendasi = data.map<String>((item) {
      final nama = item['nama_menu'] ?? 'Minuman';
      return '• $nama';
    }).toList();

    return 'Aku punya beberapa rekomendasi nih buat kamu yang suka "$matchedKeyword":\n\n${rekomendasi.take(3).join('\n')}\n\nMau cari yang lain juga boleh kok! 😊';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Asisten Bot Bicopi'),
        backgroundColor: const Color(0xFF078603),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Tanyakan sesuatu tentang minuman!'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isBotTyping && index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Bot sedang mengetik... 💬'),
                          ),
                        );
                      }
                      return _messages[index];
                    },
                  ),
          ),
          const Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration(
                    hintText: 'Tanya tentang minuman...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: const Color(0xFF078603),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  if (_textController.text.trim().isNotEmpty) {
                    _handleSubmitted(_textController.text.trim());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on PostgrestResponse {
  get error => null;
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final bgColor = isUser ? const Color(0xFFDFFFD6) : Colors.white;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Text('B', style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Column(
              crossAxisAlignment: align,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          if (isUser)
            const CircleAvatar(
              backgroundColor: const Color(0xFF078603),
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
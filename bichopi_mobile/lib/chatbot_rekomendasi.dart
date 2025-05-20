import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

// Konstanta untuk string
const String appTitle = 'Asisten Bot Bicopi';
const String botAvatarText = 'B';
const String userAvatarText = 'A';
const String defaultMessage = 'Tanyakan sesuatu tentang minuman!';
const String botTypingMessage = 'Bot sedang mengetik... 💬';
const String searchErrorMessage = 'Oops! Ada masalah saat aku cari datanya: ';
const String noMatchMessage = 'Belum ketemu yang cocok dengan "';
const String tryOtherKeywordsMessage = '", tapi kamu bisa coba kata lain seperti "dingin", "manis", atau "kopi"! 😉';
const String recommendationPrefix = 'Aku punya beberapa rekomendasi nih buat kamu yang suka "';
const String recommendationSuffix = '":\n\nMau cari yang lain juga boleh kok! 😊';
const String aiErrorMessagePrefix = 'Maaf, terjadi kesalahan AI: ';
const String technicalErrorMessagePrefix = 'Terjadi kesalahan teknis: ';
const String textFieldHint = 'Tanya tentang minuman...';

// Konstanta untuk warna
const Color primaryColor = Color(0xFF078603);
const Color backgroundColor = Color(0xFFF0F2F5);
const Color userMessageColor = Color(0xFFDFFFD6);
const Color textFieldBackgroundColor = Color(0xFFF1F1F1);
const Color whiteColor = Colors.white;
const Color greyColor = Colors.grey;

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
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      _textController.clear();
      setState(() {
        _messages.insert(0, ChatMessage(text: trimmedText, isUser: true));
        _isBotTyping = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      String botResponse = await _generateBotResponse(trimmedText);

      setState(() {
        _messages.insert(0, ChatMessage(text: botResponse, isUser: false));
        _isBotTyping = false;
      });

      _scrollToBottom();
    }
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

    if (translatedKeyword != null) {
      try {
        final response = await Supabase.instance.client
            .from('menu')
            .select('nama_menu, deskripsi_menu')
            .ilike('deskripsi_menu', '%$translatedKeyword%')
            .execute();

        if (response.error != null) {
          return '$searchErrorMessage${response.error!.message} 😓';
        }

        final data = response.data as List<dynamic>?;

        if (data == null || data.isEmpty) {
          return '$noMatchMessage"$matchedKeyword"$tryOtherKeywordsMessage';
        }

        List<String> rekomendasi = data.map<String>((item) {
          final nama = item['nama_menu'] ?? 'Minuman';
          return '• $nama';
        }).toList();

        return '$recommendationPrefix"$matchedKeyword"$recommendationSuffix\n\n${rekomendasi.take(3).join('\n')}';
      } catch (e) {
        return '$technicalErrorMessagePrefix$e';
      }
    }

    // Jika tidak ada keyword cocok → tanya ke AI (OpenRouter)
    try {
      final aiResponse = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://bicopi.app', // Ganti sesuai domain kamu
          'X-Title': 'Bicopi Chatbot'
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {"role": "user", "content": userInput}
          ]
        }),
      );

      if (aiResponse.statusCode == 200) {
        final decoded = jsonDecode(aiResponse.body);
        final content = decoded['choices'][0]['message']['content'];
        return content.trim();
      } else {
        return '$aiErrorMessagePrefix${aiResponse.statusCode}';
      }
    } catch (e) {
      return '$technicalErrorMessagePrefix$e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(appTitle),
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text(defaultMessage))
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
                            child: Text(botTypingMessage),
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
        color: whiteColor,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: textFieldBackgroundColor,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration(
                    hintText: textFieldHint,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: whiteColor),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on PostgrestResponse {
  get error => null; // This extension seems unnecessary as PostgrestResponse already has an 'error' property.
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
    final bgColor = isUser ? userMessageColor : whiteColor;
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
        crossAxisAlignment: CrossAxisAlignment.start, // Align avatar to the top
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: greyColor,
              child: Text(botAvatarText, style: TextStyle(color: whiteColor)),
            ),
          const SizedBox(width: 8.0),
          Expanded(
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
              backgroundColor: primaryColor,
              child: Text(userAvatarText, style: TextStyle(color: whiteColor)),
            ),
        ],
      ),
    );
  }
}
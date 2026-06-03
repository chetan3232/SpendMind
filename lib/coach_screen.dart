import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'hive_service.dart';
import 'models.dart';
import 'gemini_service.dart';
import 'theme.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestions = [
    'How much did I spend this month?',
    'Give me a plan to save ₹5000',
    'List all my subscriptions',
    'Analyze my variable costs'
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    
    final hive = Provider.of<HiveService>(context, listen: false);
    
    // 1. Save user message to Hive
    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: 'user',
      message: text,
      timestamp: DateTime.now(),
    );
    await hive.saveChatMessage(userMsg);
    _scrollToBottom();

    // 2. Trigger API loading
    setState(() {
      _isLoading = true;
    });

    // 3. Connect Gemini Service
    final gemini = GeminiService(apiKey: hive.geminiApiKey);
    final responseText = await gemini.getAICoachResponse(
      chatHistory: hive.chatMessages,
      userInput: text,
      transactions: hive.transactions,
      monthlyIncome: hive.monthlyIncome,
      savingsGoal: hive.savingsGoal,
    );

    // 4. Save AI Response to Hive
    final aiMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: 'ai',
      message: responseText,
      timestamp: DateTime.now(),
    );
    await hive.saveChatMessage(aiMsg);

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final hive = Provider.of<HiveService>(context);
    final isConfigured = hive.geminiApiKey.isNotEmpty;

    // Trigger scroll on build if messages exist
    if (hive.chatMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Financial Coach',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const Text(
                          'Receive structured insights and savings advice.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: AppTheme.textSecondary),
                      onPressed: () {
                        hive.clearChatHistory();
                      },
                      tooltip: 'Clear Chat History',
                    )
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderColor),

              // Chat Thread
              Expanded(
                child: !isConfigured
                    ? _buildUnconfiguredWidget()
                    : hive.chatMessages.isEmpty
                        ? _buildEmptyChatWidget()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: hive.chatMessages.length,
                            itemBuilder: (context, index) {
                              final msg = hive.chatMessages[index];
                              return _buildChatBubble(msg);
                            },
                          ),
              ),

              // Loading indicator
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      AppTheme.glassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.vibrantPurple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Coach is thinking...',
                              style: TextStyle(color: AppTheme.vibrantPurple.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Suggestion chips (only when chat is empty or not loading)
              if (isConfigured && !_isLoading && hive.chatMessages.isEmpty)
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Text(suggestion),
                          onPressed: () => _sendMessage(suggestion),
                          backgroundColor: AppTheme.cardColor.withValues(alpha: 0.3),
                          labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),

              // Input bar
              if (isConfigured) _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnconfiguredWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: AppTheme.glassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology, size: 55, color: AppTheme.vibrantPurple),
              const SizedBox(height: 15),
              const Text(
                'AI Coach Locked',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please set your Gemini API Key in the settings panel to unlock automated insights, query categories, and obtain personalized coaches.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Switch to settings screen or show notice
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please navigate to Settings in the navigation bar.')),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text('Go to Settings', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vibrantPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 40, color: AppTheme.vibrantPurple),
            ),
            const SizedBox(height: 15),
            const Text(
              'Start Coaching Session',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask financial questions, seek saving tips, or check category metrics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.sender == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.vibrantPurple,
              child: Icon(Icons.psychology, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: AppTheme.glassCard(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              color: isUser ? AppTheme.vibrantPurple : AppTheme.cardColor,
              opacity: isUser ? 0.25 : 0.4,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(
                      color: AppTheme.textPrimary, 
                      fontSize: 14, 
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp),
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.6), 
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                filled: true,
                fillColor: AppTheme.cardColor.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.vibrantPurple),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.vibrantPurple,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/environment_config.dart';
import '../models/task.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'metadata': metadata,
    };
  }
}

enum MessageType {
  text,
  taskSuggestion,
  motivational,
  islamicGuidance,
  productivity,
  systemAction,
}

class TaskSuggestion {
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? suggestedDueDate;

  TaskSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.suggestedDueDate,
  });

  Task toTask() {
    final now = DateTime.now();
    return Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueDate: suggestedDueDate,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class ChatbotService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  static const String _messagesKey = 'chat_messages';
  static const String _userContextKey = 'user_context';

  static List<ChatMessage> _messages = [];
  static Map<String, dynamic> _userContext = {};

  /// Initialize the chatbot service
  static Future<void> initialize() async {
    await _loadChatHistory();
    await _loadUserContext();
  }

  /// Get current chat messages
  static List<ChatMessage> get messages => List.from(_messages);

  /// Send a message to the AI chatbot
  static Future<ChatMessage> sendMessage(
    String userMessage, {
    List<Task>? currentTasks,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Add user message
    final userMsg = ChatMessage(
      id: _generateId(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    await _saveChatHistory();

    try {
      // Generate AI response
      final aiResponse = await _generateAIResponse(
        userMessage,
        currentTasks: currentTasks,
        additionalContext: additionalContext,
      );

      final aiMsg = ChatMessage(
        id: _generateId(),
        content: aiResponse.content,
        isUser: false,
        timestamp: DateTime.now(),
        type: aiResponse.type,
        metadata: aiResponse.metadata,
      );

      _messages.add(aiMsg);
      await _saveChatHistory();

      return aiMsg;
    } catch (e) {
      // Fallback response
      final fallbackMsg = ChatMessage(
        id: _generateId(),
        content: _getFallbackResponse(userMessage),
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );

      _messages.add(fallbackMsg);
      await _saveChatHistory();

      return fallbackMsg;
    }
  }

  /// Generate AI response using Gemini API
  static Future<_AIResponse> _generateAIResponse(
    String userMessage, {
    List<Task>? currentTasks,
    Map<String, dynamic>? additionalContext,
  }) async {
    if (!EnvironmentConfig.isGeminiConfigured) {
      throw Exception('Gemini API not configured');
    }

    // Build context for the AI
    final context = _buildContext(userMessage, currentTasks, additionalContext);

    final response = await http.post(
      Uri.parse('$_baseUrl?key=${EnvironmentConfig.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': context},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['candidates'][0]['parts'][0]['text'] as String;

      return _parseAIResponse(content, userMessage);
    } else {
      throw Exception('Failed to get AI response: ${response.statusCode}');
    }
  }

  /// Build comprehensive context for AI
  static String _buildContext(
    String userMessage,
    List<Task>? currentTasks,
    Map<String, dynamic>? additionalContext,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('''
أنت مساعد ذكي متخصص في إدارة المهام والإنتاجية، مع خلفية إسلامية قوية. 
مهمتك مساعدة المستخدمين في تنظيم حياتهم وزيادة إنتاجيتهم بطريقة متوازنة ومتماشية مع القيم الإسلامية.

خصائصك:
- تقدم نصائح عملية ومفيدة
- تربط النصائح بالقيم الإسلامية عند الإمكان
- تساعد في تحليل المهام وتنظيمها
- تقدم تحفيز إيجابي ومبني على أسس علمية
- تتحدث بالعربية بشكل أساسي
- تركز على التوازن بين العمل والحياة الشخصية

السياق الحالي:
''');

    // Add current tasks context
    if (currentTasks != null && currentTasks.isNotEmpty) {
      buffer.writeln('المهام الحالية:');
      for (final task in currentTasks.take(10)) {
        buffer.writeln(
          '- ${task.title} (${task.category.name}, ${task.priority.name})',
        );
        if (task.isCompleted) buffer.writeln('  ✓ مكتملة');
        if (task.dueDate != null) {
          buffer.writeln(
            '  موعد الانتهاء: ${task.dueDate!.day}/${task.dueDate!.month}',
          );
        }
      }
      buffer.writeln();
    }

    // Add user context
    if (_userContext.isNotEmpty) {
      buffer.writeln('معلومات المستخدم:');
      _userContext.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    // Add additional context
    if (additionalContext != null) {
      buffer.writeln('سياق إضافي:');
      additionalContext.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    // Add recent conversation context
    if (_messages.isNotEmpty) {
      buffer.writeln('آخر 3 رسائل من المحادثة:');
      final recentMessages = _messages.take(6).toList();
      for (final msg in recentMessages) {
        final sender = msg.isUser ? 'المستخدم' : 'المساعد';
        buffer.writeln('$sender: ${msg.content}');
      }
      buffer.writeln();
    }

    buffer.writeln('رسالة المستخدم الحالية: $userMessage');

    buffer.writeln('''

إرشادات الرد:
1. اجعل ردك مفيداً وعملياً
2. استخدم نبرة ودودة ومحفزة
3. إذا كان السؤال متعلق بالمهام، قدم اقتراحات محددة
4. إذا أمكن، اربط النصيحة بحكمة إسلامية أو آية قرآنية
5. لا تتجاوز 300 كلمة في الرد
6. إذا طُلب منك إنشاء مهمة، ابدأ الرد بـ [TASK_SUGGESTION]
7. إذا كان الرد تحفيزي، ابدأ بـ [MOTIVATIONAL]
8. إذا كان الرد يحتوي على إرشاد إسلامي، ابدأ بـ [ISLAMIC_GUIDANCE]
''');

    return buffer.toString();
  }

  /// Parse AI response and determine type
  static _AIResponse _parseAIResponse(String content, String userMessage) {
    MessageType type = MessageType.text;
    Map<String, dynamic>? metadata;

    // Determine message type based on content
    if (content.startsWith('[TASK_SUGGESTION]')) {
      type = MessageType.taskSuggestion;
      content = content.replaceFirst('[TASK_SUGGESTION]', '').trim();
    } else if (content.startsWith('[MOTIVATIONAL]')) {
      type = MessageType.motivational;
      content = content.replaceFirst('[MOTIVATIONAL]', '').trim();
    } else if (content.startsWith('[ISLAMIC_GUIDANCE]')) {
      type = MessageType.islamicGuidance;
      content = content.replaceFirst('[ISLAMIC_GUIDANCE]', '').trim();
    }

    // Extract task suggestions if present
    if (type == MessageType.taskSuggestion) {
      metadata = _extractTaskSuggestions(content);
    }

    return _AIResponse(content: content, type: type, metadata: metadata);
  }

  /// Extract task suggestions from content
  static Map<String, dynamic>? _extractTaskSuggestions(String content) {
    // This is a simple implementation
    // In a real app, you might use more sophisticated parsing
    final suggestions = <TaskSuggestion>[];

    // Look for task patterns in the content
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('-') && line.contains(':')) {
        final parts = line.substring(1).split(':');
        if (parts.length >= 2) {
          suggestions.add(
            TaskSuggestion(
              title: parts[0].trim(),
              description: parts[1].trim(),
              category: TaskCategory.personal, // Default category
              priority: TaskPriority.medium, // Default priority
            ),
          );
        }
      }
    }

    return suggestions.isNotEmpty ? {'suggestions': suggestions} : null;
  }

  /// Get fallback response when AI is unavailable
  static String _getFallbackResponse(String userMessage) {
    final responses = [
      'شكراً لك على رسالتك. أنا هنا لمساعدتك في تنظيم مهامك وزيادة إنتاجيتك.',
      'أقدر ثقتك بي. دعني أساعدك في إيجاد الحلول المناسبة لتحدياتك.',
      'أفهم احتياجك للمساعدة. تذكر أن التنظيم والتخطيط من أهم أسباب النجاح.',
      'مرحباً بك! أنا هنا لدعمك في رحلتك نحو الإنتاجية والتميز.',
    ];

    return responses[math.Random().nextInt(responses.length)];
  }

  /// Clear chat history
  static Future<void> clearChatHistory() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
  }

  /// Update user context
  static Future<void> updateUserContext(Map<String, dynamic> context) async {
    _userContext.addAll(context);
    await _saveUserContext();
  }

  /// Generate unique ID
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        math.Random().nextInt(1000).toString();
  }

  /// Save chat history to local storage
  static Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMessages = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(_messagesKey, jsonEncode(jsonMessages));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load chat history from local storage
  static Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messagesKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _messages = jsonList.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      _messages = [];
    }
  }

  /// Save user context
  static Future<void> _saveUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userContextKey, jsonEncode(_userContext));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load user context
  static Future<void> _loadUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userContextKey);

      if (jsonString != null) {
        _userContext = Map<String, dynamic>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      _userContext = {};
    }
  }

  /// Get suggested responses based on context
  static List<String> getSuggestedResponses({
    List<Task>? currentTasks,
    bool hasOverdueTasks = false,
    bool hasUpcomingDeadlines = false,
  }) {
    final suggestions = <String>[];

    if (currentTasks != null && currentTasks.isNotEmpty) {
      suggestions.add('ساعدني في تنظيم مهامي');
      suggestions.add('كيف يمكنني زيادة إنتاجيتي؟');
    }

    if (hasOverdueTasks) {
      suggestions.add('لدي مهام متأخرة، ماذا أفعل؟');
    }

    if (hasUpcomingDeadlines) {
      suggestions.add('كيف أتعامل مع المواعيد النهائية القريبة؟');
    }

    // Always available suggestions
    suggestions.addAll([
      'أريد نصيحة تحفيزية',
      'كيف أحافظ على التوازن في حياتي؟',
      'ما هي أفضل طرق إدارة الوقت؟',
      'أشعر بالإرهاق، ساعدني',
    ]);

    return suggestions.take(4).toList();
  }
}

class _AIResponse {
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  _AIResponse({required this.content, required this.type, this.metadata});
}

import 'dart:math';

class MotivationalMessage {
  final String message;
  final String source;
  final MessageType type;

  MotivationalMessage({
    required this.message,
    required this.source,
    required this.type,
  });
}

enum MessageType { quran, hadith, quote }

class MotivationalMessageService {
  static final Random _random = Random();
  static MotivationalMessage? _cachedDailyMessage;
  static String? _cachedMessageDate;

  // Quranic verses with references

  // Quranic verses with references
  static const List<Map<String, String>> _quranVerses = [
    {
      'verse':
          'وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ وَرَسُولُهُ وَالْمُؤْمِنُونَ',
      'reference': 'سورة التوبة: 105',
      'meaning': 'Work, for Allah will see your work',
    },
    {
      'verse': 'وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ',
      'reference': 'سورة النجم: 39',
      'meaning': 'Man gets nothing except what he strives for',
    },
    {
      'verse': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
      'reference': 'سورة الطلاق: 2',
      'meaning': 'Whoever fears Allah, He will make a way out for him',
    },
    {
      'verse': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'reference': 'سورة الشرح: 6',
      'meaning': 'Indeed, with hardship comes ease',
    },
    {
      'verse': 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا',
      'reference': 'سورة العنكبوت: 69',
      'meaning': 'Those who strive for Us, We will guide them to Our paths',
    },
    {
      'verse': 'فَإِذَا فَرَغْتَ فَانصَبْ',
      'reference': 'سورة الشرح: 7',
      'meaning': 'When you finish, then stand up for worship',
    },
    {
      'verse': 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ',
      'reference': 'سورة الضحى: 5',
      'meaning': 'Your Lord will give you and you will be satisfied',
    },
  ];

  // Authentic Hadith with references
  static final List<Map<String, String>> _hadithCollection = [
    {
      'hadith':
          'إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ',
      'reference': 'رواه أبو يعلى',
      'meaning':
          'Allah loves when one of you does work that he does it with excellence',
    },
    {
      'hadith':
          'مَا نَقَصَ مَالٌ مِنْ صَدَقَةٍ وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا',
      'reference': 'رواه مسلم',
      'meaning':
          'Wealth never decreases from charity and Allah increases honor through forgiveness',
    },
    {
      'hadith':
          'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ طَرِيقًا إِلَى الْجَنَّةِ',
      'reference': 'رواه مسلم',
      'meaning':
          'Whoever takes a path seeking knowledge, Allah makes easy for him a path to Paradise',
    },
    {
      'hadith': 'بَارِكْ لَنَا فِيمَا أَعْطَيْتَنَا',
      'reference': 'دعاء مأثور',
      'meaning': 'Bless us in what You have given us',
    },
    {
      'hadith':
          'إِذَا قَامَتِ الصَّلَاةُ فَلَا تَأْتُوهَا تَسْعَوْنَ وَأْتُوهَا تَمْشُونَ',
      'reference': 'رواه البخاري',
      'meaning': 'When prayer is called, do not come running but come walking',
    },
  ];

  // Inspirational quotes in Arabic
  static final List<Map<String, String>> _inspirationalQuotes = [
    {
      'quote': 'النجاح هو الانتقال من فشل إلى فشل بدون فقدان الحماس',
      'author': 'ونستون تشرشل',
    },
    {
      'quote': 'كن أنت التغيير الذي تريد أن تراه في العالم',
      'author': 'المهاتما غاندي',
    },
    {'quote': 'الطريق إلى النجاح دائماً تحت الإنشاء', 'author': 'حكمة عربية'},
    {'quote': 'لا تؤجل عمل اليوم إلى الغد', 'author': 'مثل عربي'},
    {'quote': 'من جد وجد، ومن زرع حصد', 'author': 'حكمة عربية'},
    {'quote': 'العلم نور والجهل ظلام', 'author': 'حكمة عربية'},
  ];

  /// Generate a motivational message based on student progress
  static MotivationalMessage generateDailyMessage({
    required int pomodoroCount,
    required int tasksCount,
  }) {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Check if we have a cached message for today with same progress
    if (_cachedDailyMessage != null && _cachedMessageDate == today) {
      return _cachedDailyMessage!;
    }

    // Generate new message
    final totalProgress = pomodoroCount + tasksCount;
    final messageType = _selectMessageType(totalProgress);

    final newMessage = switch (messageType) {
      MessageType.quran => _generateQuranMessage(pomodoroCount, tasksCount),
      MessageType.hadith => _generateHadithMessage(pomodoroCount, tasksCount),
      MessageType.quote => _generateQuoteMessage(pomodoroCount, tasksCount),
    };

    // Cache the message
    _cachedDailyMessage = newMessage;
    _cachedMessageDate = today;

    return newMessage;
  }

  /// Select message type based on progress level
  static MessageType _selectMessageType(int totalProgress) {
    if (totalProgress >= 5) {
      // High progress - more likely to get Quranic verses
      return [
        MessageType.quran,
        MessageType.quran,
        MessageType.hadith,
        MessageType.quote,
      ][_random.nextInt(4)];
    } else if (totalProgress >= 2) {
      // Medium progress - balanced mix
      return MessageType.values[_random.nextInt(3)];
    } else {
      // Low/no progress - more encouraging quotes and hadith
      return [MessageType.hadith, MessageType.quote, MessageType.quote][_random
          .nextInt(3)];
    }
  }

  /// Generate message with Quranic verse
  static MotivationalMessage _generateQuranMessage(
    int pomodoroCount,
    int tasksCount,
  ) {
    final verse = _quranVerses[_random.nextInt(_quranVerses.length)];
    final progressText = _getProgressText(pomodoroCount, tasksCount);
    final encouragement = _getEncouragement(pomodoroCount + tasksCount);

    final message =
        '$progressText قال الله تعالى: (${verse['verse']}). $encouragement';

    return MotivationalMessage(
      message: message,
      source: verse['reference']!,
      type: MessageType.quran,
    );
  }

  /// Generate message with Hadith
  static MotivationalMessage _generateHadithMessage(
    int pomodoroCount,
    int tasksCount,
  ) {
    final hadith = _hadithCollection[_random.nextInt(_hadithCollection.length)];
    final progressText = _getProgressText(pomodoroCount, tasksCount);
    final encouragement = _getEncouragement(pomodoroCount + tasksCount);

    final message =
        '$progressText قال النبي ﷺ: "${hadith['hadith']}". $encouragement';

    return MotivationalMessage(
      message: message,
      source: hadith['reference']!,
      type: MessageType.hadith,
    );
  }

  /// Generate message with inspirational quote
  static MotivationalMessage _generateQuoteMessage(
    int pomodoroCount,
    int tasksCount,
  ) {
    final quote =
        _inspirationalQuotes[_random.nextInt(_inspirationalQuotes.length)];
    final progressText = _getProgressText(pomodoroCount, tasksCount);
    final encouragement = _getEncouragement(pomodoroCount + tasksCount);

    final message = '$progressText "${quote['quote']}". $encouragement';

    return MotivationalMessage(
      message: message,
      source: quote['author']!,
      type: MessageType.quote,
    );
  }

  /// Get progress description text
  static String _getProgressText(int pomodoroCount, int tasksCount) {
    if (pomodoroCount > 0 && tasksCount > 0) {
      return 'ما شاء الله 🎉 أنجزت $pomodoroCount جلسات بومودورو و $tasksCount مهام اليوم!';
    } else if (pomodoroCount > 0) {
      return 'أحسنت 👏 أكملت $pomodoroCount جلسات بومودورو اليوم!';
    } else if (tasksCount > 0) {
      return 'رائع ✨ أنجزت $tasksCount مهام اليوم!';
    } else {
      return 'يوم جديد وفرصة جديدة للإنجاز ';
    }
  }

  /// Get appropriate encouragement based on progress
  static String _getEncouragement(int totalProgress) {
    if (totalProgress >= 7) {
      return 'استمر على هذا التفوق 🚀';
    } else if (totalProgress >= 5) {
      return 'مستوى ممتاز، واصل التقدم 💪';
    } else if (totalProgress >= 3) {
      return 'أداء جيد، يمكنك تحقيق المزيد 👊';
    } else if (totalProgress >= 1) {
      return 'بداية طيبة، استمر وستحقق أهدافك 🌟';
    } else {
      return 'ابدأ الآن واجعل يومك مثمراً 💫';
    }
  }

  /// Get random verse for specific situations
  static String getRandomQuranVerse() {
    final verse = _quranVerses[_random.nextInt(_quranVerses.length)];
    return '${verse['verse']} - ${verse['reference']}';
  }

  /// Get random hadith for specific situations
  static String getRandomHadith() {
    final hadith = _hadithCollection[_random.nextInt(_hadithCollection.length)];
    return '${hadith['hadith']} - ${hadith['reference']}';
  }

  /// Get random inspirational quote
  static String getRandomQuote() {
    final quote =
        _inspirationalQuotes[_random.nextInt(_inspirationalQuotes.length)];
    return '${quote['quote']} - ${quote['author']}';
  }

  /// Get message for specific occasions
  static String getCompletionMessage() {
    final messages = [
      'بارك الله فيك! أتممت جميع مهامك اليوم 🎊',
      'ما شاء الله! يوم مثمر ومبارك 🌟',
      'أحسنت صنعاً! النجاح ثمرة الجد والمثابرة 👏',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Get encouragement for low progress
  static String getEncouragementMessage() {
    final messages = [
      'لا تيأس، كل نجاح يبدأ بخطوة واحدة 🌱',
      'الطريق ألف ميل يبدأ بخطوة واحدة 🚶‍♂️',
      'اليوم فرصة جديدة لتحقيق أهدافك 🎯',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Force refresh the daily message (call when progress changes significantly)
  static void refreshDailyMessage() {
    _cachedDailyMessage = null;
    _cachedMessageDate = null;
  }

  /// Check if significant progress was made (to refresh message)
  static bool shouldRefreshMessage(int oldProgress, int newProgress) {
    // Refresh if progress crosses major thresholds
    if ((oldProgress < 3 && newProgress >= 3) ||
        (oldProgress < 5 && newProgress >= 5) ||
        (oldProgress < 7 && newProgress >= 7)) {
      return true;
    }
    return false;
  }
}

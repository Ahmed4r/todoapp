import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/environment_config.dart';

class AIInsight {
  final String insight;
  final String islamicGuidance;
  final String actionableAdvice;
  final String motivation;
  final InsightType type;
  final double confidence;

  AIInsight({
    required this.insight,
    required this.islamicGuidance,
    required this.actionableAdvice,
    required this.motivation,
    required this.type,
    this.confidence = 0.8,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      insight: json['insight'] ?? '',
      islamicGuidance: json['islamic_guidance'] ?? '',
      actionableAdvice: json['actionable_advice'] ?? '',
      motivation: json['motivation'] ?? '',
      type: InsightType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InsightType.general,
      ),
      confidence: (json['confidence'] ?? 0.8).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insight': insight,
      'islamic_guidance': islamicGuidance,
      'actionable_advice': actionableAdvice,
      'motivation': motivation,
      'type': type.name,
      'confidence': confidence,
    };
  }
}

enum InsightType {
  productivity,
  studyPattern,
  timeManagement,
  motivation,
  balance,
  improvement,
  general,
}

class UserAnalytics {
  final int totalPomodoroSessions;
  final int totalCompletedTasks;
  final int totalStudyTimeMinutes;
  final double averageSessionLength;
  final int mostProductiveHour;
  final List<int> dailyProductivity; // Last 7 days
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> taskCategories;
  final double focusEfficiency;
  final int breaksTaken;

  UserAnalytics({
    required this.totalPomodoroSessions,
    required this.totalCompletedTasks,
    required this.totalStudyTimeMinutes,
    required this.averageSessionLength,
    required this.mostProductiveHour,
    required this.dailyProductivity,
    required this.currentStreak,
    required this.longestStreak,
    required this.taskCategories,
    required this.focusEfficiency,
    required this.breaksTaken,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_pomodoro_sessions': totalPomodoroSessions,
      'total_completed_tasks': totalCompletedTasks,
      'total_study_time_minutes': totalStudyTimeMinutes,
      'average_session_length': averageSessionLength,
      'most_productive_hour': mostProductiveHour,
      'daily_productivity': dailyProductivity,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'task_categories': taskCategories,
      'focus_efficiency': focusEfficiency,
      'breaks_taken': breaksTaken,
    };
  }
}

class AIInsightsService {
  static AIInsight? _cachedWeeklyInsight;
  static String? _cachedInsightWeek;

  /// Generate personalized AI-powered insights based on user data
  static Future<AIInsight> generatePersonalizedInsight() async {
    try {
      // Check cache for weekly insights
      final currentWeek = _getCurrentWeekString();
      if (_cachedWeeklyInsight != null && _cachedInsightWeek == currentWeek) {
        return _cachedWeeklyInsight!;
      }

      // Gather user analytics
      final analytics = await _gatherUserAnalytics();

      // Try AI-powered insight first
      if (EnvironmentConfig.isGeminiConfigured) {
        try {
          final aiInsight = await _generateAIInsight(analytics);
          _cachedWeeklyInsight = aiInsight;
          _cachedInsightWeek = currentWeek;
          await _saveInsightToCache(aiInsight);
          return aiInsight;
        } catch (e) {
          print('AI insight generation failed, falling back to rule-based: $e');
        }
      }

      // Fallback to rule-based insights
      final ruleBasedInsight = _generateRuleBasedInsight(analytics);
      _cachedWeeklyInsight = ruleBasedInsight;
      _cachedInsightWeek = currentWeek;
      return ruleBasedInsight;
    } catch (e) {
      print('Error generating insight: $e');
      return _getDefaultInsight();
    }
  }

  /// Generate AI insight using Gemini API
  static Future<AIInsight> _generateAIInsight(UserAnalytics analytics) async {
    final prompt =
        '''
أنت مساعد ذكي متخصص في تحليل أنماط الدراسة وتقديم النصائح الشخصية للطلاب المسلمين.

بيانات المستخدم:
- إجمالي جلسات البومودورو: ${analytics.totalPomodoroSessions}
- المهام المكتملة: ${analytics.totalCompletedTasks}
- إجمالي وقت الدراسة: ${analytics.totalStudyTimeMinutes} دقيقة
- متوسط طول الجلسة: ${analytics.averageSessionLength.toStringAsFixed(1)} دقيقة
- أكثر ساعات الإنتاجية: ${analytics.mostProductiveHour}:00
- الإنتاجية اليومية (آخر 7 أيام): ${analytics.dailyProductivity}
- السلسلة الحالية: ${analytics.currentStreak} أيام
- أطول سلسلة: ${analytics.longestStreak} أيام
- كفاءة التركيز: ${(analytics.focusEfficiency * 100).toStringAsFixed(1)}%
- فترات الراحة المأخوذة: ${analytics.breaksTaken}

اكتب تحليلاً شخصياً باللغة العربية يتضمن:
1. نظرة ثاقبة على نمط الدراسة (insight)
2. إرشاد إسلامي مناسب مع آية أو حديث (islamic_guidance)
3. نصيحة عملية قابلة للتطبيق (actionable_advice)
4. رسالة تحفيزية (motivation)
5. نوع النصيحة (productivity/studyPattern/timeManagement/motivation/balance/improvement/general)

اجعل التحليل:
- شخصياً ومبنياً على البيانات الفعلية
- محفزاً وإيجابياً
- يحتوي على نصائح عملية قابلة للتطبيق
- مدعوماً بالإرشاد الإسلامي المناسب

أرجع الإجابة بصيغة JSON:
{
  "insight": "نص النظرة الثاقبة",
  "islamic_guidance": "الإرشاد الإسلامي مع الآية أو الحديث",
  "actionable_advice": "النصيحة العملية",
  "motivation": "الرسالة التحفيزية",
  "type": "نوع النصيحة",
  "confidence": 0.9
}
''';

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${EnvironmentConfig.geminiApiKey}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1000},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText =
          data['candidates'][0]['content']['parts'][0]['text'];

      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(generatedText);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final insightData = jsonDecode(jsonStr);
        return AIInsight.fromJson(insightData);
      }
    }

    throw Exception('Failed to parse AI response');
  }

  /// Generate rule-based insights when AI is not available
  static AIInsight _generateRuleBasedInsight(UserAnalytics analytics) {
    // Analyze productivity patterns
    if (analytics.currentStreak >= 7) {
      return AIInsight(
        insight:
            'ما شاء الله! لديك سلسلة رائعة من ${analytics.currentStreak} أيام من الإنتاجية المستمرة. هذا يدل على التزامك القوي وانضباطك الذاتي.',
        islamicGuidance:
            'قال تعالى: (وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا). جهادك في التعلم يقودك لطرق النجاح.',
        actionableAdvice:
            'حافظ على هذا النمط الرائع، وحاول زيادة متوسط طول جلساتك تدريجياً لتحقيق تقدم أكبر.',
        motivation: 'أنت على الطريق الصحيح! استمر والنجاح قادم بإذن الله 🌟',
        type: InsightType.motivation,
        confidence: 0.85,
      );
    } else if (analytics.focusEfficiency < 0.6) {
      return AIInsight(
        insight:
            'تحليل بياناتك يظهر أن كفاءة التركيز لديك ${(analytics.focusEfficiency * 100).toStringAsFixed(1)}%. هناك مجال للتحسين في جودة جلسات التركيز.',
        islamicGuidance:
            'قال رسول الله ﷺ: "إن الله يحب إذا عمل أحدكم عملاً أن يتقنه". الإتقان يبدأ بالتركيز الكامل.',
        actionableAdvice:
            'جرب تقليل المشتتات حولك، وضع هاتفك في وضع الطيران أثناء الدراسة، واستخدم تقنية البومودورو بانضباط.',
        motivation: 'كل تحسن صغير يقودك لنجاح كبير. ابدأ من الآن! 💪',
        type: InsightType.productivity,
        confidence: 0.8,
      );
    } else if (analytics.mostProductiveHour < 8 ||
        analytics.mostProductiveHour > 22) {
      return AIInsight(
        insight:
            'أكثر أوقاتك إنتاجية هو الساعة ${analytics.mostProductiveHour}:00. هذا وقت غير تقليدي، تأكد من استغلاله بشكل صحي.',
        islamicGuidance:
            'قال تعالى: (وَجَعَلْنَا اللَّيْلَ لِبَاسًا وَجَعَلْنَا النَّهَارَ مَعَاشًا). حافظ على التوازن بين الراحة والعمل.',
        actionableAdvice:
            'إذا كنت تدرس متأخراً، تأكد من الحصول على نوم كافٍ. وإذا كنت تدرس مبكراً جداً، احرص على تناول إفطار صحي.',
        motivation: 'التوقيت المناسب لك هو نعمة، استثمرها بحكمة! ⏰',
        type: InsightType.timeManagement,
        confidence: 0.75,
      );
    } else {
      return AIInsight(
        insight:
            'أنت تحقق تقدماً جيداً مع ${analytics.totalCompletedTasks} مهمة مكتملة و ${analytics.totalPomodoroSessions} جلسة بومودورو.',
        islamicGuidance:
            'قال تعالى: (وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ). كل جهد تبذله محسوب لك.',
        actionableAdvice:
            'استمر على هذا النهج، وحاول وضع أهداف أسبوعية محددة لزيادة الإنتاجية.',
        motivation: 'النجاح رحلة وليس وجهة. استمتع بكل خطوة تخطوها! 🚀',
        type: InsightType.general,
        confidence: 0.7,
      );
    }
  }

  /// Get default insight when everything fails
  static AIInsight _getDefaultInsight() {
    return AIInsight(
      insight: 'كل يوم جديد هو فرصة للتعلم والنمو. ابدأ اليوم بعزيمة قوية.',
      islamicGuidance:
          'قال تعالى: (وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ). العمل الصالح مشاهد ومبارك.',
      actionableAdvice: 'ضع هدفاً واحداً واضحاً لليوم واعمل على تحقيقه بتركيز.',
      motivation: 'أنت قادر على أكثر مما تتخيل! ابدأ الآن 💫',
      type: InsightType.motivation,
      confidence: 0.6,
    );
  }

  /// Gather comprehensive user analytics
  static Future<UserAnalytics> _gatherUserAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    // Calculate daily productivity for last 7 days
    List<int> dailyProductivity = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final pomodoroCount = prefs.getInt('pomodoro_count_$dateStr') ?? 0;
      final taskCount = prefs.getInt('completed_tasks_$dateStr') ?? 0;
      dailyProductivity.add(pomodoroCount + taskCount);
    }

    // Calculate streak
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dailyTotal =
          (prefs.getInt('pomodoro_count_$dateStr') ?? 0) +
          (prefs.getInt('completed_tasks_$dateStr') ?? 0);

      if (dailyTotal > 0) {
        if (i == 0) currentStreak++;
        tempStreak++;
        longestStreak = math.max(longestStreak, tempStreak);
      } else {
        if (i == 0) break;
        tempStreak = 0;
      }
    }

    // Get most productive hour (simplified)
    final mostProductiveHour = prefs.getInt('most_productive_hour') ?? 9;

    return UserAnalytics(
      totalPomodoroSessions: prefs.getInt('total_pomodoro_sessions') ?? 0,
      totalCompletedTasks: prefs.getInt('total_completed_tasks') ?? 0,
      totalStudyTimeMinutes: prefs.getInt('total_study_time_minutes') ?? 0,
      averageSessionLength: prefs.getDouble('average_session_length') ?? 25.0,
      mostProductiveHour: mostProductiveHour,
      dailyProductivity: dailyProductivity,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      taskCategories: {
        'study': prefs.getInt('category_study') ?? 0,
        'work': prefs.getInt('category_work') ?? 0,
        'personal': prefs.getInt('category_personal') ?? 0,
      },
      focusEfficiency: prefs.getDouble('focus_efficiency') ?? 0.75,
      breaksTaken: prefs.getInt('total_breaks_taken') ?? 0,
    );
  }

  /// Update user analytics when actions are performed
  static Future<void> updateAnalytics({
    bool? pomodoroCompleted,
    bool? taskCompleted,
    double? sessionLength,
    int? productiveHour,
    String? taskCategory,
    bool? breakTaken,
    double? focusEfficiency,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (pomodoroCompleted == true) {
      final currentTotal = prefs.getInt('total_pomodoro_sessions') ?? 0;
      await prefs.setInt('total_pomodoro_sessions', currentTotal + 1);

      final todayCount = prefs.getInt('pomodoro_count_$today') ?? 0;
      await prefs.setInt('pomodoro_count_$today', todayCount + 1);
    }

    if (taskCompleted == true) {
      final currentTotal = prefs.getInt('total_completed_tasks') ?? 0;
      await prefs.setInt('total_completed_tasks', currentTotal + 1);

      final todayCount = prefs.getInt('completed_tasks_$today') ?? 0;
      await prefs.setInt('completed_tasks_$today', todayCount + 1);
    }

    if (sessionLength != null) {
      final currentAvg = prefs.getDouble('average_session_length') ?? 25.0;
      final sessions = prefs.getInt('total_pomodoro_sessions') ?? 0;
      final newAvg = sessions > 0
          ? ((currentAvg * sessions) + sessionLength) / (sessions + 1)
          : sessionLength;
      await prefs.setDouble('average_session_length', newAvg);
    }

    if (productiveHour != null) {
      await prefs.setInt('most_productive_hour', productiveHour);
    }

    if (taskCategory != null) {
      final currentCount = prefs.getInt('category_$taskCategory') ?? 0;
      await prefs.setInt('category_$taskCategory', currentCount + 1);
    }

    if (breakTaken == true) {
      final currentTotal = prefs.getInt('total_breaks_taken') ?? 0;
      await prefs.setInt('total_breaks_taken', currentTotal + 1);
    }

    if (focusEfficiency != null) {
      await prefs.setDouble('focus_efficiency', focusEfficiency);
    }
  }

  /// Get current week string for caching
  static String _getCurrentWeekString() {
    final now = DateTime.now();
    final weekOfYear = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
        .floor();
    return '${now.year}-W$weekOfYear';
  }

  /// Save insight to cache
  static Future<void> _saveInsightToCache(AIInsight insight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_ai_insight', jsonEncode(insight.toJson()));
    await prefs.setString('cached_insight_week', _getCurrentWeekString());
  }

  /// Generate insights for specific scenarios
  static AIInsight getScenarioBasedInsight(String scenario) {
    switch (scenario) {
      case 'low_motivation':
        return AIInsight(
          insight:
              'يبدو أنك تواجه تحدياً في الحفاظ على الدافعية. هذا أمر طبيعي في رحلة التعلم.',
          islamicGuidance:
              'قال تعالى: (فَإِنَّ مَعَ الْعُسْرِ يُسْرًا). بعد كل صعوبة تأتي المكافأة.',
          actionableAdvice:
              'ابدأ بمهام صغيرة وسهلة لاستعادة الزخم، واحتفل بكل إنجاز مهما كان صغيراً.',
          motivation: 'كل خطوة صغيرة تقربك من هدفك. لا تستسلم! 🌱',
          type: InsightType.motivation,
        );

      case 'high_productivity':
        return AIInsight(
          insight:
              'أنت في ذروة إنتاجيتك! هذا وقت ممتاز للتركيز على المهام الصعبة والمهمة.',
          islamicGuidance:
              'قال تعالى: (وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ). استثمر هذه الطاقة في الخير.',
          actionableAdvice:
              'استغل هذه الحالة في معالجة المهام المؤجلة والمشاريع الكبيرة.',
          motivation: 'أنت في أفضل حالاتك! اجعل اليوم مثمراً ومباركاً 🚀',
          type: InsightType.productivity,
        );

      default:
        return _getDefaultInsight();
    }
  }

  /// Clear cached insights (for testing or manual refresh)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_ai_insight');
    await prefs.remove('cached_insight_week');
    _cachedWeeklyInsight = null;
    _cachedInsightWeek = null;
  }
}

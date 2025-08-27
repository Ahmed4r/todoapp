import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static bool _isInitialized = false;

  /// Initialize the environment configuration
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await dotenv.load(fileName: ".env");
        _isInitialized = true;
      } catch (e) {
        // If .env file doesn't exist, continue without it
        // API calls will fall back to rule-based summaries
        print('Warning: .env file not found. Using fallback configurations.');
        _isInitialized = true;
      }
    }
  }

  /// Get Gemini API key from environment
  static String get geminiApiKey {
    _ensureInitialized();
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Check if Gemini API is configured
  static bool get isGeminiConfigured {
    final key = geminiApiKey;
    return key.isNotEmpty && key != 'your_gemini_api_key_here';
  }

  /// Get OpenAI API key (for future use)
  static String get openAiApiKey {
    _ensureInitialized();
    return dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  /// Get Anthropic API key (for future use)
  static String get anthropicApiKey {
    _ensureInitialized();
    return dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'EnvironmentConfig not initialized. Call EnvironmentConfig.initialize() in main().',
      );
    }
  }

  /// Get all available environment variables (for debugging)
  static Map<String, String> getAllEnvVars() {
    _ensureInitialized();
    return dotenv.env;
  }

  /// Check if environment is properly configured
  static bool get isConfigured {
    return _isInitialized;
  }
}

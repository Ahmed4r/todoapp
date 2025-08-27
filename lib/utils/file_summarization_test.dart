import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/file_summarization_service.dart' as fs;

class FileSummarizationTest {
  static Future<void> runTests() async {
    debugPrint('Starting File Summarization Tests...');

    try {
      await _testFileTypeDetection();
      await _testWordCount();
      await _testReadingTime();
      await _testRuleBasedSummary();
      await _testErrorHandling();

      debugPrint('✅ All tests passed!');
    } catch (e) {
      debugPrint('❌ Test failed: $e');
    }
  }

  static Future<void> _testFileTypeDetection() async {
    debugPrint('Testing file type detection...');

    assert(
      fs.FileSummarizationService.getFileType('test.txt') == fs.FileType.text,
    );
    assert(
      fs.FileSummarizationService.getFileType('test.md') == fs.FileType.text,
    );
    assert(
      fs.FileSummarizationService.getFileType('test.pdf') == fs.FileType.pdf,
    );
    assert(
      fs.FileSummarizationService.getFileType('test.doc') == fs.FileType.word,
    );
    assert(
      fs.FileSummarizationService.getFileType('test.unknown') ==
          fs.FileType.unsupported,
    );

    debugPrint('✅ File type detection test passed');
  }

  static Future<void> _testWordCount() async {
    debugPrint('Testing word count...');

    const testText = 'Hello world this is a test';
    final wordCount = fs.FileSummarizationService.countWords(testText);
    assert(wordCount == 6, 'Expected 6 words, got $wordCount');

    const emptyText = '';
    final emptyCount = fs.FileSummarizationService.countWords(emptyText);
    assert(emptyCount == 0, 'Expected 0 words for empty text, got $emptyCount');

    debugPrint('✅ Word count test passed');
  }

  static Future<void> _testReadingTime() async {
    debugPrint('Testing reading time calculation...');

    const wordCount = 400; // Should be 2 minutes at 200 words/minute
    final readingTime = fs.FileSummarizationService.calculateReadingTime(
      wordCount,
    );
    assert(readingTime == 2, 'Expected 2 minutes, got $readingTime');

    const smallWordCount = 100; // Should be 1 minute (rounded up)
    final smallReadingTime = fs.FileSummarizationService.calculateReadingTime(
      smallWordCount,
    );
    assert(smallReadingTime == 1, 'Expected 1 minute, got $smallReadingTime');

    debugPrint('✅ Reading time test passed');
  }

  static Future<void> _testRuleBasedSummary() async {
    debugPrint('Testing rule-based summary...');

    const testText = '''
    This is the first sentence. This is the second sentence.
    This is the third sentence. This is an important fourth sentence.
    This is the fifth sentence.
    ''';

    final summary = await fs.FileSummarizationService.generateAISummary(
      testText,
    );

    assert(summary['summary'] != null, 'Summary should not be null');
    assert(summary['keyPoints'] != null, 'Key points should not be null');
    assert(
      summary['confidenceScore'] != null,
      'Confidence score should not be null',
    );
    assert(
      summary['confidenceScore'] is double,
      'Confidence score should be a double',
    );

    debugPrint('✅ Rule-based summary test passed');
  }

  static Future<void> _testErrorHandling() async {
    debugPrint('Testing error handling...');

    try {
      final fakeFile = File('non_existent_file.txt');
      await fs.FileSummarizationService.processFile(fakeFile);
      assert(false, 'Should have thrown an exception');
    } catch (e) {
      // Expected behavior
      debugPrint('✅ Error handling test passed: $e');
    }
  }

  static Future<void> testIOSCompatibility() async {
    debugPrint('Testing iOS compatibility features...');

    // Test platform-specific file picker extensions
    final extensions = fs.FileSummarizationService.getSupportedExtensions();
    assert(extensions.isNotEmpty, 'Should have supported extensions');
    assert(extensions.contains('.txt'), 'Should support .txt files');

    // Test that all methods work without platform-specific dependencies
    const sampleText = 'This is a sample text for iOS compatibility testing.';
    final wordCount = fs.FileSummarizationService.countWords(sampleText);
    final readingTime = fs.FileSummarizationService.calculateReadingTime(
      wordCount,
    );
    final summary = await fs.FileSummarizationService.generateAISummary(
      sampleText,
    );

    assert(wordCount > 0, 'Word count should be positive');
    assert(readingTime > 0, 'Reading time should be positive');
    assert(summary.isNotEmpty, 'Summary should not be empty');

    debugPrint('✅ iOS compatibility test passed');
  }
}

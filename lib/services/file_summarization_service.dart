import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../core/environment_config.dart';

enum FileType { pdf, word, text, unsupported }

class FileSummary {
  final String fileName;
  final FileType fileType;
  final String originalText;
  final String summary;
  final List<String> keyPoints;
  final int wordCount;
  final int estimatedReadingTime; // in minutes
  final DateTime processedAt;
  final double confidenceScore;

  FileSummary({
    required this.fileName,
    required this.fileType,
    required this.originalText,
    required this.summary,
    required this.keyPoints,
    required this.wordCount,
    required this.estimatedReadingTime,
    required this.processedAt,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileType': fileType.name,
    'originalText': originalText,
    'summary': summary,
    'keyPoints': keyPoints,
    'wordCount': wordCount,
    'estimatedReadingTime': estimatedReadingTime,
    'processedAt': processedAt.toIso8601String(),
    'confidenceScore': confidenceScore,
  };

  factory FileSummary.fromJson(Map<String, dynamic> json) => FileSummary(
    fileName: json['fileName'],
    fileType: FileType.values.firstWhere((e) => e.name == json['fileType']),
    originalText: json['originalText'],
    summary: json['summary'],
    keyPoints: List<String>.from(json['keyPoints']),
    wordCount: json['wordCount'],
    estimatedReadingTime: json['estimatedReadingTime'],
    processedAt: DateTime.parse(json['processedAt']),
    confidenceScore: json['confidenceScore'].toDouble(),
  );
}

class FileSummarizationService {
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // Get API key from environment
  static String get _geminiApiKey => EnvironmentConfig.geminiApiKey;

  // Determine file type based on extension
  static FileType getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return FileType.pdf;
      case '.doc':
      case '.docx':
        return FileType.word;
      case '.txt':
      case '.md':
      case '.rtf':
        return FileType.text;
      default:
        return FileType.unsupported;
    }
  }

  // Extract text from different file types
  static Future<String> extractTextFromFile(File file) async {
    final fileType = getFileType(file.path);

    switch (fileType) {
      case FileType.pdf:
        return await _extractTextFromPDF(file);
      case FileType.word:
        return await _extractTextFromWord(file);
      case FileType.text:
        return await _extractTextFromText(file);
      default:
        throw UnsupportedError('File type not supported');
    }
  }

  static Future<String> _extractTextFromPDF(File file) async {
    try {
      // Load PDF document from file
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final StringBuffer extractedText = StringBuffer();

      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        // Create text extractor for the page
        final PdfTextExtractor textExtractor = PdfTextExtractor(document);
        final String pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (pageText.trim().isNotEmpty) {
          extractedText.writeln(pageText);
        }
      }

      // Close the document
      document.dispose();

      final String fullText = extractedText.toString().trim();

      if (fullText.isEmpty) {
        throw Exception(
          'No readable text found in PDF. The PDF might be image-based or encrypted.',
        );
      }

      return fullText;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      if (e.toString().contains('password') ||
          e.toString().contains('encrypted')) {
        throw Exception(
          'PDF is password protected or encrypted. Please use an unprotected PDF.',
        );
      } else if (e.toString().contains('image') ||
          e.toString().contains('scanned')) {
        throw Exception(
          'PDF appears to be image-based. Please use a text-based PDF or convert to text first.',
        );
      } else {
        throw Exception(
          'Failed to extract text from PDF: ${e.toString()}. Please try a different PDF or convert to text file.',
        );
      }
    }
  }

  static Future<String> _extractTextFromWord(File file) async {
    try {
      // For Word documents, we'll try to read as text
      // This is a simplified approach
      final content = await file.readAsString();
      return content;
    } catch (e) {
      debugPrint('Error extracting Word text: $e');
      throw Exception(
        'Failed to extract text from Word document. Please save as .txt file first.',
      );
    }
  }

  static Future<String> _extractTextFromText(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      debugPrint('Error reading text file: $e');
      throw Exception('Failed to read text file: $e');
    }
  }

  // Calculate reading time (assuming 200 words per minute)
  static int calculateReadingTime(int wordCount) {
    return (wordCount / 200).ceil();
  }

  // Count words in text
  static int countWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  // Generate summary using AI (Gemini API)
  static Future<Map<String, dynamic>> generateAISummary(String text) async {
    // Check if Gemini API is properly configured
    if (!EnvironmentConfig.isGeminiConfigured) {
      debugPrint('Gemini API not configured, using rule-based summary');
      return _generateRuleBasedSummary(text);
    }

    try {
      // Limit text length for API call (Gemini has token limits)
      final truncatedText = text.length > 4000
          ? text.substring(0, 4000) + '...'
          : text;

      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''
Please analyze the following text and provide:
1. A concise summary (3-5 sentences)
2. Key points (3-7 bullet points)
3. A confidence score (0-1) indicating how well you understand the content

Text to analyze:
$truncatedText

Please respond in JSON format:
{
  "summary": "your summary here",
  "keyPoints": ["point 1", "point 2", "point 3"],
  "confidenceScore": 0.95
}
''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];

          // Try to parse the JSON response from Gemini
          try {
            final summaryData = jsonDecode(
              content.replaceAll('```json', '').replaceAll('```', ''),
            );
            return summaryData;
          } catch (parseError) {
            debugPrint('Error parsing Gemini response: $parseError');
            return _generateRuleBasedSummary(text);
          }
        }
      } else {
        debugPrint(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
        return _generateRuleBasedSummary(text);
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      return _generateRuleBasedSummary(text);
    }

    return _generateRuleBasedSummary(text);
  }

  // Fallback rule-based summary
  static Map<String, dynamic> _generateRuleBasedSummary(String text) {
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    // Take first 3 sentences for summary
    final selectedSentences = <String>[];

    if (sentences.isNotEmpty) {
      selectedSentences.add(sentences.first);
      if (sentences.length > 1) {
        selectedSentences.add(sentences[1]);
      }
      if (sentences.length > 2) {
        selectedSentences.add(sentences[2]);
      }
    }

    // Generate key points (extract sentences with key words)
    final keyWords = [
      'important',
      'key',
      'main',
      'significant',
      'crucial',
      'essential',
      'therefore',
      'however',
      'because',
    ];
    final keyPoints = sentences
        .where(
          (sentence) => keyWords.any(
            (keyword) => sentence.toLowerCase().contains(keyword),
          ),
        )
        .take(5)
        .toList();

    // If no key sentences found, use first few sentences
    if (keyPoints.isEmpty) {
      keyPoints.addAll(sentences.take(3));
    }

    return {
      'summary':
          selectedSentences.join('. ') +
          (selectedSentences.isNotEmpty ? '.' : 'No content available.'),
      'keyPoints': keyPoints,
      'confidenceScore': 0.7, // Lower confidence for rule-based
    };
  }

  // Main method to process a file
  static Future<FileSummary> processFile(File file) async {
    try {
      final fileName = path.basename(file.path);
      final fileType = getFileType(fileName);

      if (fileType == FileType.unsupported) {
        throw Exception('Unsupported file type');
      }

      // Extract text
      final extractedText = await extractTextFromFile(file);

      if (extractedText.trim().isEmpty) {
        throw Exception('No text content found in file');
      }

      // Calculate metrics
      final wordCount = countWords(extractedText);
      final readingTime = calculateReadingTime(wordCount);

      // Generate AI summary
      final summaryData = await generateAISummary(extractedText);

      return FileSummary(
        fileName: fileName,
        fileType: fileType,
        originalText: extractedText,
        summary: summaryData['summary'] ?? 'No summary available',
        keyPoints: List<String>.from(summaryData['keyPoints'] ?? []),
        wordCount: wordCount,
        estimatedReadingTime: readingTime,
        processedAt: DateTime.now(),
        confidenceScore: summaryData['confidenceScore']?.toDouble() ?? 0.5,
      );
    } catch (e) {
      debugPrint('Error processing file: $e');
      rethrow;
    }
  }

  // Get supported file extensions
  static List<String> getSupportedExtensions() {
    return ['.txt', '.md', '.rtf', '.pdf'];
  }

  // Check if file is supported
  static bool isFileSupported(String fileName) {
    return getFileType(fileName) != FileType.unsupported;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;
  bool _isPlaying = false;
  String? _currentAudioPath;

  bool get isPlaying => _isPlaying;
  String? get currentAudioPath => _currentAudioPath;

  AudioService() {
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _currentAudioPath = null;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      debugPrint('Audio player state changed: $state');
      if (state == PlayerState.completed) {
        _isPlaying = false;
        _currentAudioPath = null;
        notifyListeners();
      }
    });
  }

  Future<void> playAudio(String filePath) async {
    if (_currentAudioPath == filePath && _isPlaying) {
      await pauseAudio();
      return;
    }

    try {
      if (_currentAudioPath != null) {
        await stopAudio();
      }

      debugPrint('Playing audio from path: $filePath');
      await _audioPlayer.play(DeviceFileSource(filePath));
      _currentAudioPath = filePath;
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      _currentAudioPath = null;
      notifyListeners();
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentAudioPath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

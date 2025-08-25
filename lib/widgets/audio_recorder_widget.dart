import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioRecorderWidget extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const AudioRecorderWidget({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late final RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..updateFrequency = const Duration(milliseconds: 100);
  }

  @override
  void dispose() {
    _recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            widget.isRecording ? Icons.stop_circle : Icons.mic,
            color: widget.isRecording ? Colors.red : null,
          ),
          onPressed: () {
            if (widget.isRecording) {
              _recorderController.stop();
              widget.onStopRecording();
            } else {
              _recorderController.record();
              widget.onStartRecording();
            }
          },
        ),
        if (widget.isRecording)
          Expanded(
            child: AudioWaveforms(
              enableGesture: true,
              size: Size(MediaQuery.of(context).size.width * 0.5, 50.h),
              recorderController: _recorderController,
              waveStyle: WaveStyle(
                waveColor: Theme.of(context).colorScheme.primary,
                extendWaveform: true,
                showMiddleLine: false,
              ),
            ),
          ),
      ],
    );
  }
}

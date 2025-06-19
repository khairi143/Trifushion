import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/recipe.dart';
import '../../models/instruction_model.dart';

class StepByStepCookingPage extends StatefulWidget {
  final Recipe recipe;

  const StepByStepCookingPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _StepByStepCookingPageState createState() => _StepByStepCookingPageState();
}

class _StepByStepCookingPageState extends State<StepByStepCookingPage> {
  int currentStep = 0;
  late stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  
  Map<int, VideoPlayerController?> videoControllers = {};
  Map<int, ChewieController?> chewieControllers = {};

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initSpeech();
    _initializeVideoControllers();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (val) => setState(() {}),
      onError: (val) => setState(() {}),
    );
    setState(() {});
  }

  Future<void> _initializeVideoControllers() async {
    for (int i = 0; i < widget.recipe.instructions.length; i++) {
      final instruction = widget.recipe.instructions[i];
      VideoPlayerController? controller;
      
      if (instruction.videoUrl != null && instruction.videoUrl!.isNotEmpty) {
        controller = VideoPlayerController.networkUrl(Uri.parse(instruction.videoUrl!));
      }
      
      if (controller != null) {
        await controller.initialize();
        videoControllers[i] = controller;
        
        chewieControllers[i] = ChewieController(
          videoPlayerController: controller,
          aspectRatio: controller.value.aspectRatio,
          autoPlay: false,
          looping: true,
          showControls: true,
        );
      }
    }
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(dynamic result) {
    setState(() {
      _lastWords = result.recognizedWords?.toLowerCase() ?? '';
    });
    
    // Check for voice commands
    if (_lastWords.contains('ok') || _lastWords.contains('next') || _lastWords.contains('continue')) {
      _nextStep();
    } else if (_lastWords.contains('back') || _lastWords.contains('previous')) {
      _previousStep();
    } else if (_lastWords.contains('repeat') || _lastWords.contains('again')) {
      _repeatStep();
    }
  }

  void _nextStep() {
    if (currentStep < widget.recipe.instructions.length - 1) {
      setState(() {
        currentStep++;
      });
      _playCurrentStepVideo();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _playCurrentStepVideo();
    }
  }

  void _repeatStep() {
    _playCurrentStepVideo();
  }

  void _playCurrentStepVideo() {
    final controller = chewieControllers[currentStep];
    if (controller != null) {
      controller.videoPlayerController.seekTo(Duration.zero);
      controller.play();
    }
  }

  @override
  void dispose() {
    for (final controller in videoControllers.values) {
      controller?.dispose();
    }
    for (final controller in chewieControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.recipe.instructions[currentStep];
    final hasVideo = chewieControllers[currentStep] != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Step ${currentStep + 1} of ${widget.recipe.instructions.length}',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.white,
            ),
            onPressed: _speechEnabled
                ? (_isListening ? _stopListening : _startListening)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: hasVideo
                    ? Chewie(controller: chewieControllers[currentStep]!)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.grey[800]!, Colors.grey[900]!],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No video available for this step',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            
            // Instruction Text Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${currentStep + 1}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870C14),
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          instruction.description,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    
                    // Voice Command Instructions
                    if (_speechEnabled)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mic, color: Colors.blue[600], size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Say "OK", "Next", "Back", or "Repeat"',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Control Buttons
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Button
                  ElevatedButton.icon(
                    onPressed: currentStep > 0 ? _previousStep : null,
                    icon: Icon(Icons.skip_previous),
                    label: Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  
                  // Repeat Button
                  ElevatedButton.icon(
                    onPressed: _repeatStep,
                    icon: Icon(Icons.replay),
                    label: Text('Repeat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  
                  // Next Button
                  ElevatedButton.icon(
                    onPressed: currentStep < widget.recipe.instructions.length - 1 ? _nextStep : null,
                    icon: Icon(Icons.skip_next),
                    label: Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF870C14),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

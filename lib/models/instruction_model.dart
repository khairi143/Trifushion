import 'package:image_picker/image_picker.dart';

class Instruction {
  int stepNumber;
  final String description;
  XFile? video;
  String? videoUrl;
  String? localVideoPath;
  final int? duration;

  Instruction({
    required this.stepNumber,
    required this.description,
    this.video,
    this.videoUrl,
    this.localVideoPath,
    this.duration,
  });

  factory Instruction.fromMap(Map<String, dynamic> map) {
    return Instruction(
      stepNumber: map['stepNumber'] ?? 0,
      description: map['description'] ?? '',
      video: map['video'],
      videoUrl: map['videoUrl'],
      localVideoPath: map['localVideoPath'],
      duration: map['duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'description': description,
      'video': video?.path, // Assuming video is an XFile, we store its path
      'videoUrl': videoUrl,
      'localVideoPath': localVideoPath,
      'duration': duration,
    };
  }
}

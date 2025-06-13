import 'dart:math';
import 'package:flutter/material.dart';

class WaterLoadingAnimation extends StatefulWidget {
  final bool isVisible;

  const WaterLoadingAnimation({required this.isVisible});

  @override
  _WaterLoadingAnimationState createState() => _WaterLoadingAnimationState();
}

class _WaterLoadingAnimationState extends State<WaterLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _heightController;
  late AnimationController _waveController;
  late Animation<double> _waterHeight;

  @override
  void initState() {
    super.initState();
    _heightController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _waterHeight = Tween<double>(begin: 0.0, end: 0.7).animate(CurvedAnimation(
      parent: _heightController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _heightController.forward();
    }
  }

  @override
  void didUpdateWidget(WaterLoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !_heightController.isAnimating) {
      _heightController.forward();
    } else if (!widget.isVisible && !_heightController.isAnimating) {
      _heightController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_heightController, _waveController]),
      builder: (_, __) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: _waterHeight.value,
            widthFactor: 1.0,
            child: Stack(
              children: [
                Container(
                  color: Colors.lightBlueAccent,
                ),
                _buildWaveLayer(
                    Colors.lightBlueAccent.withOpacity(0.6), 10, 1.5, 0),
                _buildWaveLayer(
                    Colors.lightBlueAccent.withOpacity(0.4), 15, 2.0, pi),
                _buildWaveLayer(
                    Colors.lightBlueAccent.withOpacity(0.3), 20, 2.5, pi / 2),

                // Vegetables on different layers
                Positioned(
                  top: 30,
                  left: 30,
                  child: AnimatedFloatingVegetable(image: 'assets/carrot.png'),
                ),
                Positioned(
                  top: 50,
                  right: 50,
                  child:
                      AnimatedFloatingVegetable(image: 'assets/broccoli.png'),
                ),
                Positioned(
                  top: 80,
                  left: 70,
                  child: AnimatedFloatingVegetable(image: 'assets/tomato.png'),
                ),
                Positioned(
                  top: 100,
                  right: 80,
                  child: AnimatedFloatingVegetable(image: 'assets/pepper.png'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLayer(
      Color color, double height, double lengthFactor, double phaseShift) {
    return Align(
      alignment: Alignment.topCenter,
      child: ClipPath(
        clipper: WaveClipper(
          animationValue: _waveController.value,
          waveHeight: height,
          waveLengthFactor: lengthFactor,
          phaseShift: phaseShift,
        ),
        child: Container(
          height: 60,
          width: double.infinity,
          color: color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;
  final double waveHeight;
  final double waveLengthFactor;
  final double phaseShift;

  WaveClipper({
    required this.animationValue,
    required this.waveHeight,
    required this.waveLengthFactor,
    required this.phaseShift,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    double waveLength = size.width / waveLengthFactor;
    double speed = animationValue * 2 * pi + phaseShift;

    // Start from left edge at vertical offset
    double baseHeight = waveHeight; // You can adjust this offset as needed
    path.moveTo(0, baseHeight);

    for (double i = 0.0; i <= size.width; i++) {
      double y = sin(i / waveLength * 2 * pi + speed) * waveHeight + baseHeight;
      path.lineTo(i, y);
    }

    // Fill down to the bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) {
    return oldClipper.animationValue != animationValue;
  }
}

class AnimatedFloatingVegetable extends StatefulWidget {
  final String image;
  final double size;

  const AnimatedFloatingVegetable({
    required this.image,
    this.size = 48,
    super.key,
  });

  @override
  _AnimatedFloatingVegetableState createState() =>
      _AnimatedFloatingVegetableState();
}

class _AnimatedFloatingVegetableState extends State<AnimatedFloatingVegetable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: Image.asset(
            widget.image,
            width: widget.size,
            height: widget.size,
          ),
        );
      },
    );
  }
}

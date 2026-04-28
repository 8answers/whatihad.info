import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Duration _kScreenFadeDuration = Duration(milliseconds: 500);
const Duration _kSplashDuration = Duration(seconds: 3);
const Duration _kLoadingFillDuration = Duration(milliseconds: 2600);

void main() {
  runApp(const WhatIHadApp());
}

class WhatIHadApp extends StatelessWidget {
  const WhatIHadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _nextScreenTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat(reverse: true);

    _nextScreenTimer = Timer(_kSplashDuration, () {
      if (!mounted) {
        return;
      }
      _replaceScreen(const LoadingScreen());
    });
  }

  void _replaceScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _kScreenFadeDuration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: screen,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nextScreenTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final logoWidth =
              metrics.width * (metrics.width >= 700 ? 0.44 : 0.68);
          final logoTop = (metrics.height * 0.5) - (24 * metrics.designScale);

          return Positioned(
            left: (metrics.width - logoWidth) / 2,
            top: logoTop,
            child: SizedBox(
              width: logoWidth,
              child: SvgPicture.asset(
                'assets/What_i_had_logo.svg',
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _fillController;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat(reverse: true);

    _fillController =
        AnimationController(vsync: this, duration: _kLoadingFillDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _goToTermsScreen();
            }
          })
          ..forward();
  }

  Future<void> _goToTermsScreen() async {
    if (_didNavigate) {
      return;
    }
    _didNavigate = true;

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _kScreenFadeDuration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: const TermsScreen(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fillController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _backgroundController,
        contentBuilder: (context, metrics) {
          final ringSize = (250 * metrics.designScale).clamp(180.0, 340.0);
          final innerSize = ringSize * 0.82;
          final ringTop = (metrics.height * 0.5) - (ringSize / 2);
          final strokeWidth = (1 * metrics.designScale).clamp(0.8, 1.4);
          final fillProgress = Curves.easeInOut.transform(
            _fillController.value,
          );
          final loadingTextColor = Color.lerp(
            Colors.white,
            const Color(0xFFE88C95),
            fillProgress * 0.92,
          )!;

          return Positioned(
            left: (metrics.width - ringSize) / 2,
            top: ringTop,
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x33FFDADC),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xB3FFFFFF),
                        width: strokeWidth,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: innerSize,
                    height: innerSize,
                    child: ClipOval(
                      child: Stack(
                        children: [
                          ColoredBox(color: metrics.baseColor),
                          Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: fillProgress,
                            child: const ColoredBox(
                              color: Colors.white,
                              child: SizedBox.expand(),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x99FFFFFF),
                                width: strokeWidth,
                              ),
                            ),
                          ),
                          Center(
                            child: Transform.translate(
                              offset: Offset(0, 8 * metrics.designScale),
                              child: Text(
                                'Loading...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Borel',
                                  color: loadingTextColor,
                                  fontSize: (16 * metrics.designScale).clamp(
                                    14.0,
                                    22.0,
                                  ),
                                  height: 0.99,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final contentWidth = math.min(
            358 * metrics.designScale,
            metrics.width - (32 * metrics.designScale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = math.max(
            88 * metrics.designScale,
            metrics.padding.top + (42 * metrics.designScale),
          );
          final topCardStart = titleTop + (84 * metrics.designScale);
          final bottomGroupBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );
          final linkGap = 32 * metrics.designScale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Terms',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * metrics.designScale).clamp(24.0, 44.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: topCardStart,
                left: contentLeft,
                width: contentWidth,
                child: Column(
                  children: [
                    _TermsLinkTile(
                      label: 'Terms and Conditions',
                      scale: metrics.designScale,
                    ),
                    SizedBox(height: linkGap),
                    _TermsLinkTile(
                      label: 'Privacy Policy',
                      scale: metrics.designScale,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: contentLeft,
                bottom: bottomGroupBottom,
                width: contentWidth,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16 * metrics.designScale),
                      decoration: BoxDecoration(
                        color: const Color(0x52FFFFFF),
                        borderRadius: BorderRadius.circular(
                          16 * metrics.designScale,
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: (16 * metrics.designScale).clamp(
                              14.0,
                              21.0,
                            ),
                            color: Colors.black,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms',
                              style: TextStyle(color: Color(0xFF0C8CE9)),
                            ),
                            TextSpan(
                              text:
                                  ' and confirm that I am at least 18 years old or using the service under parental control.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * metrics.designScale),
                    _GlassNextButton(scale: metrics.designScale),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TermsLinkTile extends StatelessWidget {
  const _TermsLinkTile({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 * scale,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: BorderRadius.circular(32 * scale),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: (16 * scale).clamp(14.0, 20.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.open_in_new,
            size: (20 * scale).clamp(16.0, 24.0),
            color: const Color(0xFF0C8CE9),
          ),
        ],
      ),
    );
  }
}

class _GlassNextButton extends StatefulWidget {
  const _GlassNextButton({required this.scale});

  final double scale;

  @override
  State<_GlassNextButton> createState() => _GlassNextButtonState();
}

class _GlassNextButtonState extends State<_GlassNextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lightController;

  @override
  void initState() {
    super.initState();
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _lightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final radius = 32 * scale;
    final height = 56 * scale;
    final borderStroke = (2 * scale).clamp(1.2, 2.8);
    final rotatingLightStroke = (borderStroke * 0.5).clamp(0.6, 1.4);

    return AnimatedBuilder(
      animation: _lightController,
      builder: (context, child) {
        final rotatingAngle =
            (math.pi / 4) + (_lightController.value * math.pi * 2);

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 40 * scale,
                    sigmaY: 40 * scale,
                  ),
                  child: Container(
                    height: height,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0x8FFFD206), // #FFD206 at 56%
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: Colors.white24,
                        width: borderStroke,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RotatingBorderLightPainter(
                      angle: rotatingAngle,
                      borderRadius: radius,
                      strokeWidth: rotatingLightStroke,
                      glowWidth: (2 * scale).clamp(1.2, 2.8),
                      borderStroke: borderStroke,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RotatingBorderLightPainter extends CustomPainter {
  const _RotatingBorderLightPainter({
    required this.angle,
    required this.borderRadius,
    required this.strokeWidth,
    required this.glowWidth,
    required this.borderStroke,
  });

  final double angle;
  final double borderRadius;
  final double strokeWidth;
  final double glowWidth;
  final double borderStroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Keep the rotating highlight exactly on the button's border edge.
    final drawRect = Rect.fromLTWH(
      borderStroke * 0.5,
      borderStroke * 0.5,
      size.width - borderStroke,
      size.height - borderStroke,
    );
    final rrect = RRect.fromRectAndRadius(
      drawRect,
      Radius.circular((borderRadius - (borderStroke * 0.5)).clamp(0.0, 1000.0)),
    );
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(angle),
      colors: const [
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0x66FFFFFF),
        Color(0xFFFFFFFF), // light 1 peak
        Color(0x66FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0x66FFFFFF),
        Color(0xFFFFFFFF), // light 2 peak
        Color(0x66FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
      ],
      // Two identical highlight profiles, 180 degrees apart.
      stops: const [
        0.0,
        0.08,
        0.1,
        0.12,
        0.14,
        0.16,
        0.58,
        0.6,
        0.62,
        0.64,
        0.66,
        1.0,
      ],
    ).createShader(drawRect);

    final glowPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final strokePaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RotatingBorderLightPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glowWidth != glowWidth ||
        oldDelegate.borderStroke != borderStroke;
  }
}

typedef _SceneContentBuilder =
    Widget Function(BuildContext context, _SceneMetrics metrics);

class _SceneMetrics {
  const _SceneMetrics({
    required this.width,
    required this.height,
    required this.designScale,
    required this.baseColor,
    required this.padding,
  });

  final double width;
  final double height;
  final double designScale;
  final Color baseColor;
  final EdgeInsets padding;
}

class _AnimatedGradientScene extends StatelessWidget {
  const _AnimatedGradientScene({
    required this.animation,
    required this.contentBuilder,
  });

  final Animation<double> animation;
  final _SceneContentBuilder contentBuilder;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final designScale = math.min(width / 390, height / 844).clamp(0.7, 2.4);
        final yellowBlobWidth = 390 * designScale;
        final yellowBlobLeft = (width - yellowBlobWidth) / 2;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value * 2 * math.pi;
            final baseColor = Color.lerp(
              const Color(0xFFFF9596),
              const Color(0xFFFF8890),
              (math.sin(t * 0.9) + 1) / 2,
            )!;

            final metrics = _SceneMetrics(
              width: width,
              height: height,
              designScale: designScale,
              baseColor: baseColor,
              padding: mediaQuery.padding,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: baseColor),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(
                          -0.22 + (math.sin(t * 0.8) * 0.22),
                          -1,
                        ),
                        end: Alignment(0.2 + (math.cos(t * 0.75) * 0.2), 1),
                        colors: const [
                          Color(0x00FFFFFF),
                          Color(0x1AFFFFFF),
                          Color(0x50FFDC92),
                        ],
                        stops: [0.15, 0.66, 1],
                      ),
                    ),
                  ),
                ),
                _GlowBlob(
                  left: -113 * designScale,
                  top: 71 * designScale,
                  width: 195 * designScale,
                  height: 244 * designScale,
                  color: const Color(0xFF92EBFF),
                  blurSigma: 50 * designScale,
                  dx: math.sin(t * 0.95) * (24 * designScale),
                  dy: math.cos(t * 0.85) * (18 * designScale),
                ),
                _GlowBlob(
                  left: width - (104 * designScale),
                  top: 300 * designScale,
                  width: 195 * designScale,
                  height: 244 * designScale,
                  color: const Color(0xFFFF7375),
                  blurSigma: 30 * designScale,
                  dx: math.cos(t * 1.05) * (19 * designScale),
                  dy: math.sin(t * 0.9) * (16 * designScale),
                ),
                _GlowBlob(
                  left: yellowBlobLeft,
                  top: height - (65 * designScale),
                  width: yellowBlobWidth,
                  height: 244 * designScale,
                  color: const Color(0xFFFFDC92),
                  blurSigma: 55 * designScale,
                  borderRadius: BorderRadius.zero,
                  dx: math.sin(t * 0.7) * (14 * designScale),
                  dy: math.cos(t * 0.65) * (12 * designScale),
                ),
                contentBuilder(context, metrics),
                _HomeIndicator(
                  width: width,
                  designScale: designScale,
                  padding: mediaQuery.padding,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    required this.blurSigma,
    this.borderRadius,
    this.dx = 0,
    this.dy = 0,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;
  final double blurSigma;
  final BorderRadius? borderRadius;
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left + dx,
      top: top + dy,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                borderRadius ?? BorderRadius.circular(math.max(width, height)),
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator({
    required this.width,
    required this.designScale,
    required this.padding,
  });

  final double width;
  final double designScale;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (width - (134 * designScale)) / 2,
      bottom: math.max(
        8 * designScale,
        padding.bottom * 0.2 + (8 * designScale),
      ),
      child: Container(
        width: 134 * designScale,
        height: 5 * designScale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

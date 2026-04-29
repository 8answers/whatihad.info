import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Duration _kScreenFadeDuration = Duration(milliseconds: 500);
const Duration _kSplashDuration = Duration(milliseconds: 2500);
const Duration _kLoadingFillDuration = Duration(milliseconds: 2600);
const Duration _kBackgroundMotionDuration = Duration(seconds: 10);

const String _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://fkvzaicxqnlmnsfpbqyn.supabase.co',
);
const String _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrdnphaWN4cW5sbW5zZnBicXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNzE2OTMsImV4cCI6MjA5Mjk0NzY5M30.PgIQK6aVAHIr6CeAMDTG7_OBnDKoZvlFbOOY122yKV0',
);
const String _authCallbackScheme = 'com.example.whatihad';
const String _authCallbackHost = 'login-callback';
const String _authCallbackUrl = '$_authCallbackScheme://$_authCallbackHost/';
const String _goalLoseWeightImageUrl = 'assets/Lose_weight.png';
const String _goalGainWeightImageUrl = 'assets/Gain_weight.png';
const String _goalGainMuscleImageUrl = 'assets/Gain_muscle.png';
const String _goalMaintainImageUrl = 'assets/Maintain.png';

PageRouteBuilder<void> _buildSwipeRoute({
  required Widget screen,
  bool fromLeft = false,
}) {
  final beginOffset = fromLeft ? const Offset(-1, 0) : const Offset(1, 0);
  return PageRouteBuilder<void>(
    transitionDuration: _kScreenFadeDuration,
    reverseTransitionDuration: _kScreenFadeDuration,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: slideAnimation, child: child);
    },
  );
}

PageRouteBuilder<void> _buildFadeRoute({required Widget screen}) {
  return PageRouteBuilder<void>(
    transitionDuration: _kScreenFadeDuration,
    reverseTransitionDuration: _kScreenFadeDuration,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const WhatIHadApp());
}

final SupabaseClient supabase = Supabase.instance.client;

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
      duration: _kBackgroundMotionDuration,
    )..repeat();

    _nextScreenTimer = Timer(_kSplashDuration, () {
      if (!mounted) {
        return;
      }
      _replaceScreen(const LoadingScreen());
    });
  }

  void _replaceScreen(Widget screen) {
    Navigator.of(context).pushReplacement(_buildFadeRoute(screen: screen));
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
      duration: _kBackgroundMotionDuration,
    )..repeat();

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

    Navigator.of(
      context,
    ).pushReplacement(_buildFadeRoute(screen: const TermsScreen()));
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
          final innerRatio = innerSize / ringSize;
          final ringTop = (metrics.height * 0.5) - (ringSize / 2);
          final strokeWidth = (1 * metrics.designScale).clamp(0.8, 1.4);
          final fillProgress = Curves.easeInOut.transform(
            _fillController.value,
          );
          final rotatingAngle = (math.pi / 4) + (fillProgress * math.pi * 3);
          final rotatingLightStroke = (strokeWidth * 0.5).clamp(0.6, 1.4);

          return Positioned(
            left: (metrics.width - ringSize) / 2,
            top: ringTop,
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RingGapFillPainter(
                          innerDiameterRatio: innerRatio,
                          color: const Color(0x33FFDADC),
                        ),
                      ),
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RotatingCircleLightPainter(
                          angle: rotatingAngle,
                          strokeWidth: rotatingLightStroke,
                          glowWidth: (2 * metrics.designScale).clamp(1.2, 2.8),
                          borderStroke: strokeWidth,
                          innerDiameterRatio: innerRatio,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: innerSize,
                    height: innerSize,
                    child: ClipOval(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xB3FFFFFF),
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
                                  color: Colors.white,
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
  bool _didNavigateForward = false;
  bool _isTermsAccepted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToBellyoIntroScreen() {
    if (!_isTermsAccepted || _didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;

    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const BellyoIntroScreen()));
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
                    _RotatingGlassPanel(
                      scale: metrics.designScale,
                      borderRadius: 16 * metrics.designScale,
                      fillColor: const Color(0x52FFFFFF),
                      padding: EdgeInsets.all(16 * metrics.designScale),
                      onTap: () {
                        setState(() {
                          _isTermsAccepted = !_isTermsAccepted;
                        });
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: (24 * metrics.designScale).clamp(19.5, 30.0),
                            height: (24 * metrics.designScale).clamp(
                              19.5,
                              30.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                4.5 * metrics.designScale,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: (1.2 * metrics.designScale).clamp(
                                  1.0,
                                  1.8,
                                ),
                              ),
                            ),
                            child: _isTermsAccepted
                                ? SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: (22.5 * metrics.designScale)
                                              .clamp(18.0, 30.0),
                                        ),
                                        Transform.translate(
                                          offset: const Offset(0.6, 0),
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: (22.5 * metrics.designScale)
                                                .clamp(18.0, 30.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 12 * metrics.designScale),
                          Expanded(
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
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * metrics.designScale),
                    _GlassNextButton(
                      scale: metrics.designScale,
                      enabled: _isTermsAccepted,
                      onTap: _goToBellyoIntroScreen,
                    ),
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

class BellyoIntroScreen extends StatefulWidget {
  const BellyoIntroScreen({super.key});

  @override
  State<BellyoIntroScreen> createState() => _BellyoIntroScreenState();
}

enum _AuthProviderSelection { google, apple }

class _BellyoIntroScreenState extends State<BellyoIntroScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isGoogleSigningIn = false;
  bool _didNavigateToWelcome = false;
  _AuthProviderSelection? _selectedAuthProvider;
  Timer? _authSelectionResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();

    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      if (!mounted) {
        return;
      }
      if (authState.event == AuthChangeEvent.signedIn) {
        setState(() => _isGoogleSigningIn = false);
        _goToWelcomeScreen();
        return;
      }
      if (authState.event == AuthChangeEvent.signedOut) {
        setState(() => _isGoogleSigningIn = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAuthSelectionResetTimer();
    _authSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleAuthSelectionResetIfNeeded();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cancelAuthSelectionResetTimer();
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleSigningIn) {
      return;
    }

    setState(() => _isGoogleSigningIn = true);

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : _authCallbackUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isGoogleSigningIn = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $error')));
    }
  }

  void _cancelAuthSelectionResetTimer() {
    _authSelectionResetTimer?.cancel();
    _authSelectionResetTimer = null;
  }

  void _scheduleAuthSelectionResetIfNeeded() {
    _cancelAuthSelectionResetTimer();
    if (_selectedAuthProvider == null) {
      return;
    }
    _authSelectionResetTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAuthProvider = null;
        _isGoogleSigningIn = false;
      });
    });
  }

  void _clearAuthSelection({bool clearGoogleProgress = false}) {
    _cancelAuthSelectionResetTimer();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAuthProvider = null;
      if (clearGoogleProgress) {
        _isGoogleSigningIn = false;
      }
    });
  }

  void _onGoogleButtonTap() {
    if (_selectedAuthProvider == _AuthProviderSelection.apple) {
      return;
    }
    if (_selectedAuthProvider == _AuthProviderSelection.google) {
      _clearAuthSelection(clearGoogleProgress: true);
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAuthProvider = _AuthProviderSelection.google;
    });
    _cancelAuthSelectionResetTimer();
    unawaited(_signInWithGoogle());
  }

  void _onAppleButtonTap() {
    if (_selectedAuthProvider == _AuthProviderSelection.google) {
      return;
    }
    if (_selectedAuthProvider == _AuthProviderSelection.apple) {
      _clearAuthSelection();
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAuthProvider = _AuthProviderSelection.apple;
    });
    _cancelAuthSelectionResetTimer();
  }

  void _goToWelcomeScreen() {
    if (_didNavigateToWelcome || !mounted) {
      return;
    }
    _didNavigateToWelcome = true;

    Navigator.of(
      context,
    ).pushReplacement(_buildFadeRoute(screen: const WelcomeScreen()));
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
          final heroTop = metrics.padding.top + 48;
          final bottomGroupBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );

          return Stack(
            children: [
              Positioned(
                top: heroTop,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 243,
                      child: Image.asset(
                        'assets/Smart 1 (1).png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Hey! I’m Bellyo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: (32 * metrics.designScale).clamp(24.0, 42.0),
                        color: Colors.white,
                        height: 0.99,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Eat better. Spend smarter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: (24 * metrics.designScale).clamp(20.0, 30.0),
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'I’ll help you eat smarter, stay on budget,\nand hit your health goals',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: (16 * metrics.designScale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: bottomGroupBottom,
                child: Column(
                  children: [
                    _GlassActionButton(
                      scale: metrics.designScale,
                      label: _isGoogleSigningIn
                          ? 'Connecting to Google...'
                          : 'Continue with Google',
                      icon: SvgPicture.asset(
                        'assets/Google Logo (1).svg',
                        fit: BoxFit.contain,
                      ),
                      isSelected:
                          _selectedAuthProvider ==
                          _AuthProviderSelection.google,
                      isDisabled:
                          _selectedAuthProvider == _AuthProviderSelection.apple,
                      onTap: _onGoogleButtonTap,
                    ),
                    SizedBox(height: 32 * metrics.designScale),
                    _GlassActionButton(
                      scale: metrics.designScale,
                      label: 'Continue with Apple',
                      icon: SvgPicture.asset(
                        'assets/Apple.svg',
                        fit: BoxFit.contain,
                      ),
                      isSelected:
                          _selectedAuthProvider == _AuthProviderSelection.apple,
                      isDisabled:
                          _selectedAuthProvider ==
                          _AuthProviderSelection.google,
                      onTap: _onAppleButtonTap,
                    ),
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

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _didNavigateForward = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNameScreen() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;

    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const NameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final topGroupTop = metrics.padding.top + (44 * metrics.designScale);
          final centerGap = 58 * metrics.designScale;
          final buttonWidth = math.min(
            358 * metrics.designScale,
            metrics.width - (32 * metrics.designScale),
          );
          final buttonLeft = (metrics.width - buttonWidth) / 2;
          final buttonBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );

          return Stack(
            children: [
              Positioned(
                top: topGroupTop,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 243,
                      child: Image.asset('assets/Pray 1.png', fit: BoxFit.fill),
                    ),
                    SizedBox(height: 32 * metrics.designScale),
                    Text(
                      'Welcome',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: (32 * metrics.designScale).clamp(24.0, 42.0),
                        color: Colors.white,
                        height: 0.99,
                      ),
                    ),
                    SizedBox(height: centerGap),
                    Text(
                      'Let’s get to know you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: (24 * metrics.designScale).clamp(20.0, 30.0),
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: centerGap),
                    SizedBox(
                      width: 264 * metrics.designScale,
                      child: Text(
                        'Let’s start with some basic details\nto fuel your journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (16 * metrics.designScale).clamp(
                            14.0,
                            20.0,
                          ),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: buttonLeft,
                width: buttonWidth,
                bottom: buttonBottom,
                child: _RotatingGlassButton(
                  scale: metrics.designScale,
                  height: 56 * metrics.designScale,
                  borderRadius: 32 * metrics.designScale,
                  fillColor: const Color(0x8FFFD206),
                  enablePressShadeFeedback: true,
                  onTap: _goToNameScreen,
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (34 * metrics.designScale / 1.7).clamp(
                        18.0,
                        28.0,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isNameLongPressed = false;
  bool _isNameClicked = false;
  bool _didNavigateForward = false;

  void _setNameDefaultState() {
    _isNameLongPressed = false;
    _isNameClicked = false;
  }

  void _handleNameTap() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isNameClicked = true;
      _isNameLongPressed = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
    _nameFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goBackToWelcome() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const WelcomeScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;
    FocusScope.of(context).unfocus();

    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const GoalScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final titleTop =
              metrics.padding.top +
              (15 * metrics.designScale) +
              (30 * metrics.designScale);
          final contentWidth = math.min(
            358 * metrics.designScale,
            metrics.width - (32 * metrics.designScale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final controlsBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;
          final controlsGap = 16 * metrics.designScale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: contentLeft,
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'What’s your Name?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: (32 * metrics.designScale).clamp(24.0, 42.0),
                        color: Colors.white,
                        height: 0.99,
                      ),
                    ),
                    SizedBox(height: 32 * metrics.designScale),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressDown: (_) {
                        if (mounted) {
                          setState(() {
                            _isNameLongPressed = true;
                            _isNameClicked = false;
                          });
                        }
                      },
                      onLongPressStart: (_) {
                        if (mounted) {
                          setState(() {
                            _isNameLongPressed = true;
                            _isNameClicked = false;
                          });
                        }
                      },
                      onLongPressEnd: (_) {
                        if (mounted) {
                          setState(() {
                            _isNameLongPressed = false;
                          });
                        }
                      },
                      onLongPressCancel: () {
                        if (mounted) {
                          setState(() {
                            _isNameLongPressed = false;
                          });
                        }
                      },
                      onTap: () {
                        _handleNameTap();
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 56 * metrics.designScale,
                        child: _RotatingGlassPanel(
                          scale: metrics.designScale,
                          borderRadius: 16 * metrics.designScale,
                          fillColor: _isNameLongPressed
                              ? Colors.transparent
                              : (_isNameClicked
                                    ? Colors.white
                                    : const Color(0x52FFFFFF)),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * metrics.designScale,
                          ),
                          expandToBounds: true,
                          boxShadow: (_isNameLongPressed || _isNameClicked)
                              ? const [
                                  BoxShadow(
                                    color: Color(0xFFFF0000),
                                    blurRadius: 4,
                                    blurStyle: BlurStyle.outer,
                                  ),
                                ]
                              : const <BoxShadow>[],
                          enableBlur: !(_isNameLongPressed || _isNameClicked),
                          child: Align(
                            alignment: Alignment.center,
                            child: TextField(
                              focusNode: _nameFocusNode,
                              onTap: _handleNameTap,
                              onChanged: (_) {
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              onEditingComplete: () {
                                FocusScope.of(context).unfocus();
                                if (mounted) {
                                  setState(() {
                                    _setNameDefaultState();
                                  });
                                }
                              },
                              onSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                                if (mounted) {
                                  setState(() {
                                    _setNameDefaultState();
                                  });
                                }
                              },
                              controller: _nameController,
                              textInputAction: TextInputAction.done,
                              enableInteractiveSelection: false,
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              cursorColor: _isNameClicked
                                  ? Colors.black
                                  : Colors.white,
                              style: TextStyle(
                                color: _isNameClicked
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: (18 * metrics.designScale).clamp(
                                  16.0,
                                  22.0,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: '',
                                hintStyle: TextStyle(
                                  color: _isNameClicked
                                      ? const Color(0x80000000)
                                      : const Color(0xB3FFFFFF),
                                  fontSize: (16 * metrics.designScale).clamp(
                                    14.0,
                                    20.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    SizedBox(
                      width: backButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBackToWelcome,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * metrics.designScale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: controlsGap),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: const Color(0x8FFFD206),
                        enablePressShadeFeedback: true,
                        onTap: _goNext,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * metrics.designScale / 1.7)
                                    .clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * metrics.designScale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * metrics.designScale).clamp(
                                20.0,
                                28.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedGoalIndex = -1;
  bool _didNavigateForward = false;

  static const List<_GoalOption> _goalOptions = [
    _GoalOption(label: 'Lose Weight', imageUrl: _goalLoseWeightImageUrl),
    _GoalOption(label: 'Gain Weight', imageUrl: _goalGainWeightImageUrl),
    _GoalOption(label: 'Gain Muscle', imageUrl: _goalGainMuscleImageUrl),
    _GoalOption(label: 'Maintain', imageUrl: _goalMaintainImageUrl),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goBackToName() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const NameScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const AgeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final titleTop = metrics.padding.top + (15 * metrics.designScale);
          final questionTop = titleTop + (30 * metrics.designScale);
          final contentWidth = math.min(
            358 * metrics.designScale,
            metrics.width - (32 * metrics.designScale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final cardGap = 16 * metrics.designScale;
          final cardWidth = (contentWidth - cardGap) / 2;
          final cardsTop = titleTop + (100 * metrics.designScale);
          final controlsBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;

          return Stack(
            children: [
              Positioned(
                top: questionTop,
                left: 0,
                right: 0,
                child: Text(
                  'What’s your goal?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * metrics.designScale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                child: Wrap(
                  spacing: cardGap,
                  runSpacing: cardGap,
                  children: List<Widget>.generate(_goalOptions.length, (index) {
                    final option = _goalOptions[index];
                    return SizedBox(
                      width: cardWidth,
                      child: _GoalCard(
                        scale: metrics.designScale,
                        label: option.label,
                        imageUrl: option.imageUrl,
                        isSelected: _selectedGoalIndex == index,
                        onTap: () {
                          setState(() => _selectedGoalIndex = index);
                        },
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    SizedBox(
                      width: backButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBackToName,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * metrics.designScale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * metrics.designScale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: const Color(0x8FFFD206),
                        enablePressShadeFeedback: true,
                        onTap: _goNext,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * metrics.designScale / 1.7)
                                    .clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * metrics.designScale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * metrics.designScale).clamp(
                                20.0,
                                28.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final FixedExtentScrollController _ageScrollController;
  int _selectedAge = 18;
  bool _didNavigateForward = false;

  static final List<int> _ages = List<int>.generate(85, (index) => 13 + index);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
    final initialIndex = _ages.indexOf(_selectedAge);
    _ageScrollController = FixedExtentScrollController(
      initialItem: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  @override
  void dispose() {
    _ageScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goBackToGoal() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const GoalScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const WeightScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final titleTop = metrics.padding.top + (15 * metrics.designScale);
          final questionTop = titleTop + (30 * metrics.designScale);
          final contentWidth = math.min(
            358 * metrics.designScale,
            metrics.width - (32 * metrics.designScale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final agesTop = titleTop + (116 * metrics.designScale);
          final wheelHeight = (420 * metrics.designScale).clamp(320.0, 500.0);
          final itemExtent = (108 * metrics.designScale).clamp(86.0, 130.0);
          final selectedCardHeight = (142 * metrics.designScale).clamp(
            110.0,
            170.0,
          );
          final controlsBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;

          return Stack(
            children: [
              Positioned(
                top: questionTop,
                left: 0,
                right: 0,
                child: Text(
                  'What’s your Age?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * metrics.designScale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: agesTop,
                left: contentLeft,
                width: contentWidth,
                child: SizedBox(
                  height: wheelHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        child: Container(
                          width: double.infinity,
                          height: selectedCardHeight,
                          decoration: BoxDecoration(
                            color: const Color(0x52FFFFFF),
                            borderRadius: BorderRadius.circular(
                              16 * metrics.designScale,
                            ),
                            border: Border.all(
                              color: const Color(0x80FFFFFF),
                              width: (1 * metrics.designScale).clamp(0.8, 1.4),
                            ),
                          ),
                        ),
                      ),
                      ListWheelScrollView.useDelegate(
                        controller: _ageScrollController,
                        physics: const FixedExtentScrollPhysics(),
                        itemExtent: itemExtent,
                        perspective: 0.0025,
                        diameterRatio: 3.0,
                        squeeze: 1.0,
                        overAndUnderCenterOpacity: 0.8,
                        onSelectedItemChanged: (index) {
                          if (mounted) {
                            setState(() => _selectedAge = _ages[index]);
                          }
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _ages.length,
                          builder: (context, index) {
                            final age = _ages[index];
                            final distance = (age - _selectedAge).abs();
                            final isSelected = distance == 0;
                            final isNear = distance == 1;
                            final fontSize = isSelected
                                ? (96 * metrics.designScale).clamp(72.0, 112.0)
                                : (isNear
                                      ? (64 * metrics.designScale).clamp(
                                          48.0,
                                          80.0,
                                        )
                                      : (32 * metrics.designScale).clamp(
                                          24.0,
                                          42.0,
                                        ));
                            final color = isSelected
                                ? Colors.black
                                : (distance >= 2
                                      ? const Color(0x80000000)
                                      : Colors.black);

                            return Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 130),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                                child: Text('$age'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    SizedBox(
                      width: backButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBackToGoal,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * metrics.designScale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * metrics.designScale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: const Color(0x8FFFD206),
                        enablePressShadeFeedback: true,
                        onTap: _goNext,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * metrics.designScale / 1.7)
                                    .clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * metrics.designScale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * metrics.designScale).clamp(
                                20.0,
                                28.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedWeight = 60;
  bool _didNavigateForward = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goBackToAge() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const AgeScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final titleTop = metrics.padding.top + (15 * metrics.designScale);
          final questionTop = titleTop + (30 * metrics.designScale);
          final contentWidth = math.min(
            358 * metrics.designScale,
            metrics.width - (32 * metrics.designScale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final cardTop = titleTop + (170 * metrics.designScale);
          final rulerTop = cardTop + (205 * metrics.designScale);
          final controlsBottom = math.max(
            66 * metrics.designScale,
            metrics.padding.bottom + (26 * metrics.designScale),
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;

          return Stack(
            children: [
              Positioned(
                top: questionTop,
                left: 0,
                right: 0,
                child: Text(
                  'What’s your Weight?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * metrics.designScale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: cardTop,
                left: contentLeft,
                width: contentWidth,
                child: Container(
                  height: (140 * metrics.designScale).clamp(110.0, 170.0),
                  decoration: BoxDecoration(
                    color: const Color(0x52FFFFFF),
                    borderRadius: BorderRadius.circular(
                      16 * metrics.designScale,
                    ),
                    border: Border.all(
                      color: const Color(0x80FFFFFF),
                      width: (1 * metrics.designScale).clamp(0.8, 1.4),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_selectedWeight',
                          style: TextStyle(
                            fontSize: (96 * metrics.designScale).clamp(
                              72.0,
                              112.0,
                            ),
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 16 * metrics.designScale),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 12 * metrics.designScale,
                          ),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              fontSize: (32 * metrics.designScale).clamp(
                                24.0,
                                42.0,
                              ),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: rulerTop,
                left: contentLeft,
                width: contentWidth,
                child: _WeightRuler(
                  scale: metrics.designScale,
                  value: _selectedWeight,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _selectedWeight = value);
                    }
                  },
                ),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    SizedBox(
                      width: backButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBackToAge,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * metrics.designScale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * metrics.designScale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: metrics.designScale,
                        height: 56 * metrics.designScale,
                        borderRadius: 32 * metrics.designScale,
                        fillColor: const Color(0x8FFFD206),
                        enablePressShadeFeedback: true,
                        onTap: _goNext,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * metrics.designScale / 1.7)
                                    .clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * metrics.designScale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * metrics.designScale).clamp(
                                20.0,
                                28.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _WeightRuler extends StatefulWidget {
  const _WeightRuler({
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final int value;
  final ValueChanged<int> onChanged;

  static const int _minWeight = 30;
  static const int _maxWeight = 150;

  @override
  State<_WeightRuler> createState() => _WeightRulerState();
}

class _WeightRulerState extends State<_WeightRuler> {
  double _dragRemainderPx = 0;

  void _applyDeltaPx(double deltaPx) {
    final pixelsPerKg = (20 * widget.scale).clamp(14.0, 26.0);
    // Inverted mapping: drag right decreases, drag left increases.
    _dragRemainderPx -= deltaPx;
    final deltaKg = (_dragRemainderPx / pixelsPerKg).truncate();

    if (deltaKg != 0) {
      final next = (widget.value + deltaKg).clamp(
        _WeightRuler._minWeight,
        _WeightRuler._maxWeight,
      );
      if (next != widget.value) {
        widget.onChanged(next);
      }
      _dragRemainderPx -= deltaKg * pixelsPerKg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final rulerHeight = (88 * scale).clamp(70.0, 110.0);
    final markerSize = (18 * scale).clamp(14.0, 24.0);

    return SizedBox(
      height: rulerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              // Right drag increases, left drag decreases.
              _applyDeltaPx(details.delta.dx);
            },
            onHorizontalDragEnd: (_) {
              _dragRemainderPx = 0;
            },
            onTapDown: (details) {
              final pixelsPerKg = (20 * scale).clamp(14.0, 26.0);
              final dxFromCenter =
                  details.localPosition.dx - (constraints.maxWidth / 2);
              final jumpKg = (dxFromCenter / pixelsPerKg).round();
              if (jumpKg == 0) {
                return;
              }
              final next = (widget.value - jumpKg).clamp(
                _WeightRuler._minWeight,
                _WeightRuler._maxWeight,
              );
              if (next != widget.value) {
                widget.onChanged(next);
              }
            },
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WeightTicksPainter(
                      scale: scale,
                      value: widget.value,
                      minWeight: _WeightRuler._minWeight,
                      maxWeight: _WeightRuler._maxWeight,
                      baselineBottomInset: markerSize,
                    ),
                  ),
                ),
                Positioned(
                  top: rulerHeight - markerSize,
                  child: Icon(
                    Icons.arrow_drop_up,
                    color: Colors.white,
                    size: markerSize,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeightTicksPainter extends CustomPainter {
  const _WeightTicksPainter({
    required this.scale,
    required this.value,
    required this.minWeight,
    required this.maxWeight,
    required this.baselineBottomInset,
  });

  final double scale;
  final int value;
  final int minWeight;
  final int maxWeight;
  final double baselineBottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height - baselineBottomInset;
    final spacing = (20 * scale).clamp(14.0, 26.0);
    final strokeWidth = (2 * scale).clamp(1.2, 2.4);
    final centerIndex = value;
    final visibleTicks = (size.width / spacing).ceil() + 6;
    final minTick = math.max(minWeight, centerIndex - visibleTicks);
    final maxTick = math.min(maxWeight, centerIndex + visibleTicks);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int tick = minTick; tick <= maxTick; tick++) {
      final x = centerX + ((tick - centerIndex) * spacing);
      if (x < -4 || x > size.width + 4) {
        continue;
      }

      final isCenter = tick == centerIndex;
      final isMajor = tick % 5 == 0;
      final lineHeight = isCenter
          ? (70 * scale).clamp(54.0, 84.0)
          : (isMajor ? (56 * scale) : (50 * scale)).clamp(36.0, 70.0);
      final distanceRatio = ((x - centerX).abs() / (size.width / 2)).clamp(
        0.0,
        1.0,
      );
      final opacity = (1.0 - (distanceRatio * 0.45)).clamp(0.45, 1.0);

      paint.color = isCenter
          ? Colors.white
          : Colors.black.withValues(alpha: opacity);
      canvas.drawLine(Offset(x, baseY - lineHeight), Offset(x, baseY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightTicksPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.value != value ||
        oldDelegate.minWeight != minWeight ||
        oldDelegate.maxWeight != maxWeight ||
        oldDelegate.baselineBottomInset != baselineBottomInset;
  }
}

class _GoalOption {
  const _GoalOption({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({
    required this.scale,
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  void didUpdateWidget(covariant _GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && _isClicked && !_isLongPressed) {
      setState(() {
        _isClicked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isActive = _isClicked || widget.isSelected;
    final fillColor = _isLongPressed
        ? Colors.transparent
        : (isActive ? Colors.white : const Color(0x52FFFFFF));
    final hasShadow = _isLongPressed || isActive;
    final shadows = hasShadow
        ? const [
            BoxShadow(
              color: Color(0xFFFF0000),
              blurRadius: 4,
              blurStyle: BlurStyle.outer,
            ),
          ]
        : const <BoxShadow>[];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressDown: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLongPressed = true;
          _isClicked = false;
        });
      },
      onLongPressStart: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLongPressed = true;
          _isClicked = false;
        });
      },
      onLongPressEnd: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLongPressed = false;
        });
      },
      onLongPressCancel: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLongPressed = false;
        });
      },
      onTap: () {
        if (mounted) {
          setState(() {
            _isClicked = true;
            _isLongPressed = false;
          });
        }
        widget.onTap();
      },
      child: SizedBox(
        width: double.infinity,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.all(16 * scale),
          expandToBounds: false,
          boxShadow: shadows,
          enableBlur: !(_isLongPressed || isActive),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80 * scale,
                height: 80 * scale,
                child: Image.asset(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported_outlined,
                      color: const Color(0x80000000),
                      size: 30 * scale,
                    );
                  },
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsLinkTile extends StatefulWidget {
  const _TermsLinkTile({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  State<_TermsLinkTile> createState() => _TermsLinkTileState();
}

class _TermsLinkTileState extends State<_TermsLinkTile> {
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final fillColor = _isLongPressed
        ? Colors.transparent
        : (_isClicked ? Colors.white : const Color(0x52FFFFFF));
    final hasShadow = _isLongPressed || _isClicked;
    final shadows = hasShadow
        ? const [
            BoxShadow(
              color: Color(0xFFFF0000),
              blurRadius: 4,
              blurStyle: BlurStyle.outer,
            ),
          ]
        : const <BoxShadow>[];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressDown: (_) {
        setState(() {
          _isLongPressed = true;
          _isClicked = false;
        });
      },
      onLongPressStart: (_) {
        setState(() {
          _isLongPressed = true;
          _isClicked = false;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          _isLongPressed = false;
        });
      },
      onLongPressCancel: () {
        setState(() {
          _isLongPressed = false;
        });
      },
      onTap: () {
        setState(() {
          _isClicked = true;
          _isLongPressed = false;
        });
      },
      child: SizedBox(
        height: 56 * scale,
        width: double.infinity,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 32 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
          expandToBounds: true,
          boxShadow: shadows,
          enableBlur: !(_isLongPressed || _isClicked),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: (16 * scale).clamp(14.0, 20.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: (20 * scale).clamp(16.0, 24.0),
                height: (20 * scale).clamp(16.0, 24.0),
                child: SvgPicture.asset(
                  'assets/t_and_c.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotatingGlassPanel extends StatefulWidget {
  const _RotatingGlassPanel({
    required this.scale,
    required this.borderRadius,
    required this.fillColor,
    required this.child,
    this.padding,
    this.onTap,
    this.expandToBounds = false,
    this.boxShadow,
    this.enableBlur = true,
  });

  final double scale;
  final double borderRadius;
  final Color fillColor;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool expandToBounds;
  final List<BoxShadow>? boxShadow;
  final bool enableBlur;

  @override
  State<_RotatingGlassPanel> createState() => _RotatingGlassPanelState();
}

class _RotatingGlassPanelState extends State<_RotatingGlassPanel>
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
    final radius = widget.borderRadius;
    final borderStroke = (2 * scale).clamp(1.2, 2.8);
    final rotatingLightStroke = (borderStroke * 0.5).clamp(0.6, 1.4);

    return AnimatedBuilder(
      animation: _lightController,
      builder: (context, child) {
        final rotatingAngle =
            (math.pi / 4) + (_lightController.value * math.pi * 2);
        final panelContent = Container(
          width: double.infinity,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: widget.child,
        );
        final panel = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: widget.boxShadow,
          ),
          child: Stack(
            fit: widget.expandToBounds ? StackFit.expand : StackFit.loose,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: widget.enableBlur
                    ? BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 40 * scale,
                          sigmaY: 40 * scale,
                        ),
                        child: panelContent,
                      )
                    : panelContent,
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

        if (widget.onTap == null) {
          return panel;
        }

        return GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: panel,
        );
      },
    );
  }
}

class _GlassNextButton extends StatefulWidget {
  const _GlassNextButton({
    required this.scale,
    required this.onTap,
    this.enabled = true,
  });

  final double scale;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_GlassNextButton> createState() => _GlassNextButtonState();
}

class _GlassNextButtonState extends State<_GlassNextButton>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return _RotatingGlassButton(
      scale: scale,
      height: 56 * scale,
      borderRadius: 32 * scale,
      fillColor: widget.enabled
          ? const Color(0x8FFFD206)
          : const Color(0x14FFD206),
      enablePressShadeFeedback: widget.enabled,
      onTap: widget.enabled ? widget.onTap : () {},
      child: Text(
        'Next',
        style: TextStyle(
          color: Colors.white,
          fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatefulWidget {
  const _GlassActionButton({
    required this.scale,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
  });

  final double scale;
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isDisabled;

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton> {
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  void didUpdateWidget(covariant _GlassActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && _isClicked && !_isLongPressed) {
      setState(() {
        _isClicked = false;
      });
    }
    if (widget.isDisabled && (_isLongPressed || _isClicked)) {
      setState(() {
        _isLongPressed = false;
        _isClicked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isActive = _isClicked || widget.isSelected;
    final fillColor = _isLongPressed
        ? Colors.transparent
        : (isActive ? Colors.white : const Color(0x52FFFFFF));
    final hasShadow = _isLongPressed || isActive;
    final shadows = hasShadow
        ? const [
            BoxShadow(
              color: Color(0xFFFF0000),
              blurRadius: 4,
              blurStyle: BlurStyle.outer,
            ),
          ]
        : const <BoxShadow>[];

    return IgnorePointer(
      ignoring: widget.isDisabled,
      child: Opacity(
        opacity: widget.isDisabled ? 0.5 : 1.0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressDown: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLongPressed = true;
              _isClicked = false;
            });
          },
          onLongPressStart: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLongPressed = true;
              _isClicked = false;
            });
          },
          onLongPressEnd: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLongPressed = false;
            });
          },
          onLongPressCancel: () {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLongPressed = false;
            });
          },
          onTap: () {
            if (mounted) {
              setState(() {
                _isLongPressed = false;
                _isClicked = !widget.isSelected;
              });
            }
            widget.onTap();
          },
          child: SizedBox(
            height: 56 * scale,
            width: double.infinity,
            child: _RotatingGlassPanel(
              scale: scale,
              borderRadius: 32 * scale,
              fillColor: fillColor,
              padding: EdgeInsets.symmetric(horizontal: 24 * scale),
              expandToBounds: true,
              boxShadow: shadows,
              enableBlur: !(_isLongPressed || isActive),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24 * scale,
                    height: 24 * scale,
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          size: 24 * scale,
                          color: Colors.black,
                        ),
                        child: widget.icon,
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * scale),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: (16 * scale).clamp(14.0, 20.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotatingGlassButton extends StatefulWidget {
  const _RotatingGlassButton({
    required this.scale,
    required this.height,
    required this.borderRadius,
    required this.fillColor,
    required this.onTap,
    required this.child,
    this.enablePressShadeFeedback = false,
  });

  final double scale;
  final double height;
  final double borderRadius;
  final Color fillColor;
  final VoidCallback onTap;
  final Widget child;
  final bool enablePressShadeFeedback;

  @override
  State<_RotatingGlassButton> createState() => _RotatingGlassButtonState();
}

class _RotatingGlassButtonState extends State<_RotatingGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lightController;
  bool _isTapPressed = false;
  bool _isLongPressed = false;

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
    final radius = widget.borderRadius;
    final height = widget.height;
    final borderStroke = (2 * scale).clamp(1.2, 2.8);
    final rotatingLightStroke = (borderStroke * 0.5).clamp(0.6, 1.4);

    final baseOpacity = widget.fillColor.a.clamp(0.0, 1.0);
    final targetOpacity = _isLongPressed
        ? 0.28
        : (_isTapPressed ? 1.0 : baseOpacity);
    final alpha = (targetOpacity * 255).round();
    final safeAlpha = alpha < 0 ? 0 : (alpha > 255 ? 255 : alpha);
    final fillColor = widget.fillColor.withAlpha(safeAlpha);

    return AnimatedBuilder(
      animation: _lightController,
      builder: (context, child) {
        final rotatingAngle =
            (math.pi / 4) + (_lightController.value * math.pi * 2);

        return SizedBox(
          height: height,
          child: GestureDetector(
            onLongPressDown: widget.enablePressShadeFeedback
                ? (_) {
                    if (mounted) {
                      setState(() {
                        _isLongPressed = true;
                        _isTapPressed = false;
                      });
                    }
                  }
                : null,
            onLongPressStart: widget.enablePressShadeFeedback
                ? (_) {
                    if (mounted) {
                      setState(() {
                        _isLongPressed = true;
                        _isTapPressed = false;
                      });
                    }
                  }
                : null,
            onLongPressEnd: widget.enablePressShadeFeedback
                ? (_) {
                    if (mounted) {
                      setState(() {
                        _isLongPressed = false;
                        _isTapPressed = false;
                      });
                    }
                  }
                : null,
            onTapCancel: widget.enablePressShadeFeedback
                ? () {
                    if (mounted) {
                      setState(() {
                        _isTapPressed = false;
                        _isLongPressed = false;
                      });
                    }
                  }
                : null,
            onTap: () {
              if (widget.enablePressShadeFeedback) {
                if (mounted) {
                  setState(() {
                    _isTapPressed = true;
                    _isLongPressed = false;
                  });
                }
                Future<void>.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      _isTapPressed = false;
                      _isLongPressed = false;
                    });
                  }
                });
              }
              widget.onTap();
            },
            behavior: HitTestBehavior.opaque,
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
                        color: fillColor,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      alignment: Alignment.center,
                      child: widget.child,
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
        Color(0x20FFFFFF),
        Color(0x4DFFFFFF),
        Color(0x73FFFFFF), // light 1 blended peak
        Color(0x4DFFFFFF),
        Color(0x20FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0x20FFFFFF),
        Color(0x4DFFFFFF),
        Color(0x73FFFFFF), // light 2 blended peak
        Color(0x4DFFFFFF),
        Color(0x20FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
      ],
      // Two identical, softer profiles that blend into the border.
      stops: const [
        0.0,
        0.062,
        0.086,
        0.104,
        0.122,
        0.14,
        0.166,
        0.5,
        0.56,
        0.586,
        0.604,
        0.622,
        0.64,
        0.666,
        0.69,
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

class _RotatingCircleLightPainter extends CustomPainter {
  const _RotatingCircleLightPainter({
    required this.angle,
    required this.strokeWidth,
    required this.glowWidth,
    required this.borderStroke,
    required this.innerDiameterRatio,
  });

  final double angle;
  final double strokeWidth;
  final double glowWidth;
  final double borderStroke;
  final double innerDiameterRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final drawRect = Rect.fromLTWH(
      borderStroke * 0.5,
      borderStroke * 0.5,
      size.width - borderStroke,
      size.height - borderStroke,
    );
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(angle),
      colors: const [
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0x20FFFFFF),
        Color(0x4DFFFFFF),
        Color(0x73FFFFFF),
        Color(0x4DFFFFFF),
        Color(0x20FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0x20FFFFFF),
        Color(0x4DFFFFFF),
        Color(0x73FFFFFF),
        Color(0x4DFFFFFF),
        Color(0x20FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: const [
        0.0,
        0.062,
        0.086,
        0.104,
        0.122,
        0.14,
        0.166,
        0.5,
        0.56,
        0.586,
        0.604,
        0.622,
        0.64,
        0.666,
        0.69,
        1.0,
      ],
    ).createShader(drawRect);

    final minSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final outerBorderCenterRadius = (minSide - borderStroke) / 2;
    final outerInsideEdgeRadius =
        (outerBorderCenterRadius - (borderStroke * 0.5)).clamp(0.0, minSide);
    final innerOutsideEdgeRadius = ((minSide * innerDiameterRatio) / 2).clamp(
      0.0,
      minSide,
    );
    final edgeStrokeWidth = math.max(strokeWidth, 0.8) * 2;
    final edgeGlowWidth = math.max(glowWidth, 1.2) * 2;

    final glowPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeGlowWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final strokePaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeStrokeWidth;

    // Keep the rotating effect only in the ring gap so it does not tint
    // the inner circle area.
    final gapPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: outerInsideEdgeRadius))
      ..addOval(
        Rect.fromCircle(center: center, radius: innerOutsideEdgeRadius),
      );

    canvas.save();
    canvas.clipPath(gapPath);
    canvas.drawCircle(center, outerInsideEdgeRadius, glowPaint);
    canvas.drawCircle(center, outerInsideEdgeRadius, strokePaint);
    canvas.drawCircle(center, innerOutsideEdgeRadius, glowPaint);
    canvas.drawCircle(center, innerOutsideEdgeRadius, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RotatingCircleLightPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glowWidth != glowWidth ||
        oldDelegate.borderStroke != borderStroke ||
        oldDelegate.innerDiameterRatio != innerDiameterRatio;
  }
}

class _RingGapFillPainter extends CustomPainter {
  const _RingGapFillPainter({
    required this.innerDiameterRatio,
    required this.color,
  });

  final double innerDiameterRatio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = minSide / 2;
    final innerRadius = ((minSide * innerDiameterRatio) / 2).clamp(
      0.0,
      minSide,
    );

    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawPath(ringPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingGapFillPainter oldDelegate) {
    return oldDelegate.innerDiameterRatio != innerDiameterRatio ||
        oldDelegate.color != color;
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
        final blueBlobWidth = 195 * designScale;
        final blueBlobHeight = 244 * designScale;
        final redBlobWidth = 195 * designScale;
        final redBlobHeight = 244 * designScale;
        final yellowBlobWidth = 390 * designScale;
        final yellowBlobHeight = 244 * designScale;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final blueLeft = -113 * designScale;
            final blueTop = 71 * designScale;
            final redLeft = width - (104 * designScale);
            final redTop = 300 * designScale;
            final yellowLeft = (width - yellowBlobWidth) / 2;
            final yellowTop = height - (65 * designScale);
            const baseColor = Color(0xFFFF9596);

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
                        begin: Alignment(-0.22, -1),
                        end: Alignment(0.2, 1),
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
                  left: blueLeft,
                  top: blueTop,
                  width: blueBlobWidth,
                  height: blueBlobHeight,
                  color: const Color(0xFF92EBFF),
                  blurSigma: 50 * designScale,
                ),
                _GlowBlob(
                  left: redLeft,
                  top: redTop,
                  width: redBlobWidth,
                  height: redBlobHeight,
                  color: const Color(0xFFFF7375),
                  blurSigma: 30 * designScale,
                ),
                _GlowBlob(
                  left: yellowLeft,
                  top: yellowTop,
                  width: yellowBlobWidth,
                  height: yellowBlobHeight,
                  color: const Color(0xFFFFDC92),
                  blurSigma: 55 * designScale,
                  borderRadius: BorderRadius.zero,
                ),
                contentBuilder(context, metrics),
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
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;
  final double blurSigma;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
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

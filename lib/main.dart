import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const Duration _kScreenFadeDuration = Duration(milliseconds: 380);
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
const String _defaultNonBorelFontFamily = 'Nata Sans';
const Color _menuBarBlockFillColor = Color(0x04FFFFFF);
const Color _bottomNavActiveIconColor = Color(0xFFFF7375);
const double _bottomBlurLayerCount = 8;
const double _bottomBlurTopSigma = 0.25;
const double _bottomBlurBottomSigma = 2.0;
const double _dailyProgressMenuBarBlurSigma = 40.0;
const double _currencyDropdownBlurSigma = 32.0;
const double _currencyDropdownOptionBlurSigma = 58.0;
const ColorFilter _halfOpacityBackdropColorFilter = ColorFilter.matrix(<double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0.5,
  0,
]);
final Map<String, String> _defaultNutritionGoalValues =
    _computeNutritionRecommendation(
      goalIndex: 2,
      ageYears: 21,
      weightKg: 66,
      heightCm: 160,
      activityIndex: 1,
    ).goalValues;
final Map<String, String> _defaultAdvancedNutritionGoalValues =
    _computeNutritionRecommendation(
      goalIndex: 2,
      ageYears: 21,
      weightKg: 66,
      heightCm: 160,
      activityIndex: 1,
    ).advancedGoalValues;
const Map<String, String> _budgetCurrencyGlyphByCode = <String, String>{
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
  'CNY': '¥',
  'BRL': r'R$',
  'JPY': '¥',
  'AUD': r'A$',
  'CAD': r'C$',
  'SGD': r'S$',
  'AED': 'د.إ',
  'SAR': '﷼',
};
const int _defaultDietPreferenceIndex = 1;
const List<_DietPreferenceOption> _dietPreferenceOptions =
    <_DietPreferenceOption>[
      _DietPreferenceOption(label: 'Vegetarian', imagePath: 'assets/Veg.png'),
      _DietPreferenceOption(
        label: 'Non-vegetarian',
        imagePath: 'assets/Non-veg.png',
      ),
      _DietPreferenceOption(
        label: 'Eggetarian',
        imagePath: 'assets/Eggiterian.png',
      ),
      _DietPreferenceOption(label: 'Vegan', imagePath: 'assets/Vegan.png'),
    ];
const List<String> _onboardingGenderLabels = <String>[
  'Male',
  'Female',
  'Transgender',
  'Other',
  'Prefer not to respond',
];
const Map<String, String> _countryNameByIso2Code = <String, String>{
  'IN': 'India',
  'US': 'United States',
  'GB': 'United Kingdom',
  'AE': 'United Arab Emirates',
  'SA': 'Saudi Arabia',
  'CN': 'China',
  'JP': 'Japan',
  'BR': 'Brazil',
  'CA': 'Canada',
  'AU': 'Australia',
  'SG': 'Singapore',
  'DE': 'Germany',
  'FR': 'France',
  'IT': 'Italy',
  'ES': 'Spain',
  'MX': 'Mexico',
  'ID': 'Indonesia',
  'MY': 'Malaysia',
  'TH': 'Thailand',
  'PH': 'Philippines',
  'KR': 'South Korea',
  'TR': 'Turkey',
  'ZA': 'South Africa',
};

class _BellyoQuickPrompt {
  const _BellyoQuickPrompt({required this.label, required this.prompt});

  final String label;
  final String prompt;
}

const List<_BellyoQuickPrompt>
_bellyoAssistantPromptSuggestions = <_BellyoQuickPrompt>[
  _BellyoQuickPrompt(
    label: 'Suggest meal under ₹150',
    prompt: 'Suggest meal under ₹150',
  ),
  _BellyoQuickPrompt(label: 'High protein food', prompt: 'High protein food'),
  _BellyoQuickPrompt(
    label: 'What should I eat today?',
    prompt: 'What should I eat today?',
  ),
  _BellyoQuickPrompt(label: 'Recovery foods', prompt: 'Recovery foods'),
  _BellyoQuickPrompt(label: 'Quick meal idea', prompt: 'Quick meal idea'),
  _BellyoQuickPrompt(label: 'Low calorie dinner', prompt: 'Low calorie dinner'),
  _BellyoQuickPrompt(label: 'Cheap muscle meal', prompt: 'Cheap muscle meal'),
  _BellyoQuickPrompt(
    label: 'Quick healthy snack',
    prompt: 'Quick healthy snack',
  ),
  _BellyoQuickPrompt(label: 'Breakfast Ideas', prompt: 'Breakfast Ideas'),
  _BellyoQuickPrompt(label: 'Lunch Ideas', prompt: 'Lunch Ideas'),
  _BellyoQuickPrompt(label: 'Dinner Ideas', prompt: 'Dinner Ideas'),
];
const String _bellyoAssistantOllamaEndpoint = String.fromEnvironment(
  'BELLYO_OLLAMA_ENDPOINT',
  defaultValue: '',
);
const String _bellyoAssistantOllamaModel = String.fromEnvironment(
  'BELLYO_OLLAMA_MODEL',
  defaultValue: 'llama3.2',
);
const int _bellyoAssistantHistoryLimit = 12;
const bool _bellyoAssistantEnableOfflineFallback = bool.fromEnvironment(
  'BELLYO_ENABLE_OFFLINE_FALLBACK',
  defaultValue: false,
);

enum _BellyoAssistantRole { user, assistant }

class _BellyoAssistantMessage {
  const _BellyoAssistantMessage({required this.role, required this.text});

  final _BellyoAssistantRole role;
  final String text;

  bool get isUser => role == _BellyoAssistantRole.user;
}

const int _maleGenderIndex = 0;
const int _unselectedGenderIndex = -1;

enum _NutritionGoalType { loseWeight, maintain, gainWeight, gainMuscle }

class _NutritionGoalRule {
  const _NutritionGoalRule({
    required this.calorieAdjustment,
    required this.proteinPerKg,
    required this.fatPercent,
    required this.fiberPer1000Kcal,
    required this.sugarPercent,
    required this.sodiumMg,
  });

  final int calorieAdjustment;
  final double proteinPerKg;
  final double fatPercent;
  final double fiberPer1000Kcal;
  final double sugarPercent;
  final int sodiumMg;
}

class _NutritionRecommendation {
  const _NutritionRecommendation({
    required this.bmr,
    required this.tdee,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbohydratesG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
  });

  final double bmr;
  final double tdee;
  final int caloriesKcal;
  final int proteinG;
  final int carbohydratesG;
  final int fatG;
  final int fiberG;
  final int sugarG;
  final int sodiumMg;

  Map<String, String> get goalValues => <String, String>{
    'Calories': _formatGroupedWholeNumber(caloriesKcal),
    'Protein': _formatGroupedWholeNumber(proteinG),
    'Carbohydrates': _formatGroupedWholeNumber(carbohydratesG),
    'Fat': _formatGroupedWholeNumber(fatG),
  };

  Map<String, String> get advancedGoalValues => <String, String>{
    'Fiber': _formatGroupedWholeNumber(fiberG),
    'Sugar': _formatGroupedWholeNumber(sugarG),
    'Sodium': _formatGroupedWholeNumber(sodiumMg),
  };
}

const List<double> _activityFactors = <double>[1.2, 1.375, 1.55, 1.725, 1.9];
const double _mifflinStJeorMaleOffset = 5.0;
const double _mifflinStJeorNonMaleOffset = -161.0;
const _NutritionGoalRule _loseWeightNutritionRule = _NutritionGoalRule(
  calorieAdjustment: -400,
  proteinPerKg: 1.8,
  fatPercent: 0.22,
  fiberPer1000Kcal: 18,
  sugarPercent: 0.05,
  sodiumMg: 1800,
);
const _NutritionGoalRule _maintainNutritionRule = _NutritionGoalRule(
  calorieAdjustment: 0,
  proteinPerKg: 1.1,
  fatPercent: 0.27,
  fiberPer1000Kcal: 15,
  sugarPercent: 0.08,
  sodiumMg: 2000,
);
const _NutritionGoalRule _gainWeightNutritionRule = _NutritionGoalRule(
  calorieAdjustment: 550,
  proteinPerKg: 1.5,
  fatPercent: 0.28,
  fiberPer1000Kcal: 14,
  sugarPercent: 0.15,
  sodiumMg: 2400,
);
const _NutritionGoalRule _gainMuscleNutritionRule = _NutritionGoalRule(
  calorieAdjustment: 300,
  proteinPerKg: 1.9,
  fatPercent: 0.22,
  fiberPer1000Kcal: 16,
  sugarPercent: 0.09,
  sodiumMg: 2100,
);

_NutritionGoalType _nutritionGoalTypeFromIndex(int goalIndex) {
  switch (goalIndex) {
    case 0:
      return _NutritionGoalType.loseWeight;
    case 1:
      return _NutritionGoalType.gainWeight;
    case 2:
      return _NutritionGoalType.gainMuscle;
    case 3:
      return _NutritionGoalType.maintain;
    default:
      return _NutritionGoalType.maintain;
  }
}

_NutritionGoalRule _nutritionRuleForType(_NutritionGoalType goalType) {
  switch (goalType) {
    case _NutritionGoalType.loseWeight:
      return _loseWeightNutritionRule;
    case _NutritionGoalType.maintain:
      return _maintainNutritionRule;
    case _NutritionGoalType.gainWeight:
      return _gainWeightNutritionRule;
    case _NutritionGoalType.gainMuscle:
      return _gainMuscleNutritionRule;
  }
}

double _activityFactorFromIndex(int activityIndex) {
  final safeIndex = activityIndex.clamp(0, _activityFactors.length - 1).toInt();
  return _activityFactors[safeIndex];
}

double _mifflinStJeorOffsetFromGenderIndex(int genderIndex) {
  return genderIndex == _maleGenderIndex
      ? _mifflinStJeorMaleOffset
      : _mifflinStJeorNonMaleOffset;
}

int _roundToNearestTen(double value) {
  if (value.isNaN || value.isInfinite) {
    return 0;
  }
  return (value / 10).round() * 10;
}

String _formatGroupedWholeNumber(int value) {
  final absoluteDigits = value.abs().toString();
  final grouped = absoluteDigits.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return value < 0 ? '-$grouped' : grouped;
}

_NutritionRecommendation _computeNutritionRecommendation({
  required int goalIndex,
  required int ageYears,
  required int weightKg,
  required int heightCm,
  required int activityIndex,
  int genderIndex = _unselectedGenderIndex,
}) {
  final goalType = _nutritionGoalTypeFromIndex(goalIndex);
  final goalRule = _nutritionRuleForType(goalType);
  final safeAge = ageYears.clamp(10, 110).toInt();
  final safeWeight = weightKg.clamp(20, 300).toInt();
  final safeHeight = heightCm.clamp(100, 240).toInt();
  final activityFactor = _activityFactorFromIndex(activityIndex);
  final bmrSexOffset = _mifflinStJeorOffsetFromGenderIndex(genderIndex);

  final bmr =
      (10 * safeWeight) + (6.25 * safeHeight) - (5 * safeAge) + bmrSexOffset;
  final safeBmr = math.max(0.0, bmr);
  final tdee = safeBmr * activityFactor;
  final calories = _roundToNearestTen(
    math.max(0.0, tdee + goalRule.calorieAdjustment),
  );

  final proteinG = math
      .max(0, (safeWeight * goalRule.proteinPerKg).round())
      .toInt();
  final fatG = math
      .max(0, ((calories * goalRule.fatPercent) / 9).round())
      .toInt();
  final carbsEnergy = calories - ((proteinG * 4) + (fatG * 9));
  final carbohydratesG = math.max(0, (carbsEnergy / 4).round()).toInt();
  final fiberG = math
      .max(0, ((calories * goalRule.fiberPer1000Kcal) / 1000).round())
      .toInt();
  final sugarG = math
      .max(0, ((calories * goalRule.sugarPercent) / 4).round())
      .toInt();
  final sodiumMg = goalRule.sodiumMg;

  return _NutritionRecommendation(
    bmr: safeBmr,
    tdee: tdee,
    caloriesKcal: calories,
    proteinG: proteinG,
    carbohydratesG: carbohydratesG,
    fatG: fatG,
    fiberG: fiberG,
    sugarG: sugarG,
    sodiumMg: sodiumMg,
  );
}

_NutritionRecommendation _computeNutritionRecommendationFromProfile({
  int? goalIndex,
  int? ageYears,
  int? weightKg,
  int? heightCm,
  int? activityIndex,
  int? genderIndex,
}) {
  return _computeNutritionRecommendation(
    goalIndex: goalIndex ?? _OnboardingProfileState.selectedGoalIndex,
    ageYears: ageYears ?? _OnboardingProfileState.selectedAge,
    weightKg: weightKg ?? _OnboardingProfileState.selectedWeightKg,
    heightCm: heightCm ?? _OnboardingProfileState.selectedHeightCm,
    activityIndex:
        activityIndex ?? _OnboardingProfileState.selectedActivityIndex,
    genderIndex: genderIndex ?? _OnboardingProfileState.selectedGenderIndex,
  );
}

void _applyRecommendedNutritionToOnboardingProfile({
  int? goalIndex,
  int? ageYears,
  int? weightKg,
  int? heightCm,
  int? activityIndex,
  int? genderIndex,
}) {
  final recommendation = _computeNutritionRecommendationFromProfile(
    goalIndex: goalIndex,
    ageYears: ageYears,
    weightKg: weightKg,
    heightCm: heightCm,
    activityIndex: activityIndex,
    genderIndex: genderIndex,
  );
  _OnboardingProfileState.nutritionGoalValues = Map<String, String>.from(
    recommendation.goalValues,
  );
  _OnboardingProfileState.advancedNutritionGoalValues =
      Map<String, String>.from(recommendation.advancedGoalValues);
}

const int _hydrationBaseMlPerKg = 35;
const double _ouncesPerLiter = 33.8140227018;
const List<int> _hydrationActivityExtraMlByIndex = <int>[
  0, // Low
  250, // Light
  500, // Moderate
  750, // Active
  1000, // Athlete
];
const List<int> _hydrationGoalExtraMlByGoalIndex = <int>[
  300, // Lose Weight
  200, // Gain Weight
  300, // Gain Muscle
  0, // Maintain
];

double _computeHydrationRecommendationLiters({
  required int weightKg,
  required int activityIndex,
  required int goalIndex,
}) {
  final safeWeight = weightKg.clamp(20, 300).toInt();
  final safeActivityIndex = activityIndex
      .clamp(0, _hydrationActivityExtraMlByIndex.length - 1)
      .toInt();
  final safeGoalIndex = goalIndex
      .clamp(0, _hydrationGoalExtraMlByGoalIndex.length - 1)
      .toInt();

  final baseMl = safeWeight * _hydrationBaseMlPerKg;
  final activityExtraMl = _hydrationActivityExtraMlByIndex[safeActivityIndex];
  final goalExtraMl = _hydrationGoalExtraMlByGoalIndex[safeGoalIndex];
  final totalMl = baseMl + activityExtraMl + goalExtraMl;
  final liters = totalMl / 1000;
  return math.max(0.1, liters);
}

String _formatHydrationGoalTextFromLiters(double liters) {
  final roundedToOneDecimal = ((liters * 10).round() / 10);
  final oneDecimalText = roundedToOneDecimal.toStringAsFixed(1);
  if (oneDecimalText.endsWith('.0')) {
    return oneDecimalText.substring(0, oneDecimalText.length - 2);
  }
  return oneDecimalText;
}

String _computeHydrationGoalTextFromProfile({
  int? goalIndex,
  int? weightKg,
  int? activityIndex,
  bool? outputInLiters,
}) {
  final liters = _computeHydrationRecommendationLiters(
    goalIndex: goalIndex ?? _OnboardingProfileState.selectedGoalIndex,
    weightKg: weightKg ?? _OnboardingProfileState.selectedWeightKg,
    activityIndex:
        activityIndex ?? _OnboardingProfileState.selectedActivityIndex,
  );
  final shouldOutputLiters = outputInLiters ?? true;
  final displayedValue = shouldOutputLiters
      ? liters
      : (liters * _ouncesPerLiter);
  return _formatHydrationGoalTextFromLiters(displayedValue);
}

void _applyRecommendedHydrationToOnboardingProfile({
  int? goalIndex,
  int? weightKg,
  int? activityIndex,
}) {
  _OnboardingProfileState.hydrationGoalText =
      _computeHydrationGoalTextFromProfile(
        goalIndex: goalIndex,
        weightKg: weightKg,
        activityIndex: activityIndex,
        outputInLiters: _OnboardingProfileState.isHydrationInLiters,
      );
}

Widget _buildBottomBlurFadeOverlay() {
  // Progressive blur + 50% backdrop opacity, without extra overlay layer.
  return ClipRect(
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final panelHeight = constraints.maxHeight;
        if (panelHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            for (int index = 0; index < _bottomBlurLayerCount; index++)
              _buildProgressiveBottomBlurSlice(
                panelHeight: panelHeight,
                layerIndex: index,
              ),
          ],
        );
      },
    ),
  );
}

Widget _buildProgressiveBottomBlurSlice({
  required double panelHeight,
  required int layerIndex,
}) {
  final sliceTop = panelHeight * (layerIndex / _bottomBlurLayerCount);
  final sliceHeight = (panelHeight / _bottomBlurLayerCount) + 2;
  final blurProgress = _bottomBlurLayerCount <= 1
      ? 1.0
      : layerIndex / (_bottomBlurLayerCount - 1);
  final sigma =
      _bottomBlurTopSigma +
      ((_bottomBlurBottomSigma - _bottomBlurTopSigma) * blurProgress);
  final filteredBackdrop = ImageFilter.compose(
    inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    outer: _halfOpacityBackdropColorFilter,
  );

  return Positioned(
    top: sliceTop,
    left: 0,
    right: 0,
    height: sliceHeight,
    child: BackdropFilter(
      filter: filteredBackdrop,
      child: const ColoredBox(color: Colors.transparent),
    ),
  );
}

bool _isCompactIPhoneLayout(_SceneMetrics metrics) {
  return !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      math.min(metrics.width, metrics.height) < 600;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

TimeOfDay _currentLocalTimeOfDay() {
  final now = DateTime.now();
  return TimeOfDay(hour: now.hour, minute: now.minute);
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const List<String> _historyMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _daySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

String _formatHistoryDateLabel(DateTime date) {
  final safeMonth = date.month.clamp(1, 12).toInt() - 1;
  final monthName = _historyMonthNames[safeMonth];
  final day = date.day;
  return '$day${_daySuffix(day)} $monthName, ${date.year}';
}

double _actionControlsBottomInset({
  required _SceneMetrics metrics,
  required double scale,
}) {
  if (_isCompactIPhoneLayout(metrics)) {
    // Keep action rows just above iPhone safe area.
    return metrics.padding.bottom + (8 * scale);
  }
  return math.max(66 * scale, metrics.padding.bottom + (26 * scale));
}

class _OnboardingSkipFlags {
  static bool skippedBudgetSection = false;
  static bool skippedWaterSection = false;

  static void reset() {
    skippedBudgetSection = false;
    skippedWaterSection = false;
  }
}

class _OnboardingProfileState {
  static String selectedName = '';
  static int selectedGenderIndex = _unselectedGenderIndex;
  static int selectedGoalIndex = 2;
  static int selectedAge = 21;
  static int selectedWeightKg = 66;
  static bool isWeightInKg = true;
  static int selectedHeightCm = 160;
  static bool isHeightInCm = true;
  static int selectedActivityIndex = 1;
  static bool budgetEnabled = true;
  static String budgetCurrencyCode = 'INR';
  static int? selectedBudgetPerMeal = 200;
  static String customBudgetPerMeal = '';
  static bool isCustomBudgetPerMeal = false;
  static Map<String, String> nutritionGoalValues =
      _computeNutritionRecommendation(
        goalIndex: selectedGoalIndex,
        ageYears: selectedAge,
        weightKg: selectedWeightKg,
        heightCm: selectedHeightCm,
        activityIndex: selectedActivityIndex,
        genderIndex: selectedGenderIndex,
      ).goalValues;
  static Map<String, String> advancedNutritionGoalValues =
      _computeNutritionRecommendation(
        goalIndex: selectedGoalIndex,
        ageYears: selectedAge,
        weightKg: selectedWeightKg,
        heightCm: selectedHeightCm,
        activityIndex: selectedActivityIndex,
        genderIndex: selectedGenderIndex,
      ).advancedGoalValues;
  static bool hydrationEnabled = true;
  static String hydrationGoalText = _computeHydrationGoalTextFromProfile(
    weightKg: selectedWeightKg,
    activityIndex: selectedActivityIndex,
  );
  static bool isHydrationInLiters = true;
  static int selectedDietPreferenceIndex = _defaultDietPreferenceIndex;
  static String selectedCountryName = '';

  static void reset() {
    selectedName = '';
    selectedGenderIndex = _unselectedGenderIndex;
    selectedGoalIndex = 2;
    selectedAge = 21;
    selectedWeightKg = 66;
    isWeightInKg = true;
    selectedHeightCm = 160;
    isHeightInCm = true;
    selectedActivityIndex = 1;
    budgetEnabled = true;
    budgetCurrencyCode = 'INR';
    selectedBudgetPerMeal = 200;
    customBudgetPerMeal = '';
    isCustomBudgetPerMeal = false;
    final recommendation = _computeNutritionRecommendation(
      goalIndex: selectedGoalIndex,
      ageYears: selectedAge,
      weightKg: selectedWeightKg,
      heightCm: selectedHeightCm,
      activityIndex: selectedActivityIndex,
      genderIndex: selectedGenderIndex,
    );
    nutritionGoalValues = Map<String, String>.from(recommendation.goalValues);
    advancedNutritionGoalValues = Map<String, String>.from(
      recommendation.advancedGoalValues,
    );
    hydrationEnabled = true;
    hydrationGoalText = _computeHydrationGoalTextFromProfile(
      weightKg: selectedWeightKg,
      activityIndex: selectedActivityIndex,
    );
    isHydrationInLiters = true;
    selectedDietPreferenceIndex = _defaultDietPreferenceIndex;
    selectedCountryName = '';
  }
}

class _CustomFoodEntry {
  const _CustomFoodEntry({
    required this.id,
    required this.name,
    required this.caloriesText,
    required this.timeText,
    this.budgetAmountText = '0',
    required this.proteinText,
    required this.carbohydratesText,
    required this.fatText,
    required this.fiberText,
    required this.sugarText,
    required this.sodiumText,
    this.isFavorite = false,
  });

  final int id;
  final String name;
  final String caloriesText;
  final String timeText;
  final String budgetAmountText;
  final String proteinText;
  final String carbohydratesText;
  final String fatText;
  final String fiberText;
  final String sugarText;
  final String sodiumText;
  final bool isFavorite;

  _CustomFoodEntry copyWith({bool? isFavorite}) {
    return _CustomFoodEntry(
      id: id,
      name: name,
      caloriesText: caloriesText,
      timeText: timeText,
      budgetAmountText: budgetAmountText,
      proteinText: proteinText,
      carbohydratesText: carbohydratesText,
      fatText: fatText,
      fiberText: fiberText,
      sugarText: sugarText,
      sodiumText: sodiumText,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class _CustomFoodEntryStore {
  static int _nextId = 1;
  static final List<_CustomFoodEntry> _entries = <_CustomFoodEntry>[];

  static List<_CustomFoodEntry> get entries =>
      List<_CustomFoodEntry>.unmodifiable(_entries);

  static _CustomFoodEntry create({
    required String name,
    required String caloriesText,
    required String timeText,
    String budgetAmountText = '0',
    required String proteinText,
    required String carbohydratesText,
    required String fatText,
    required String fiberText,
    required String sugarText,
    required String sodiumText,
    bool isFavorite = false,
  }) {
    return _CustomFoodEntry(
      id: _nextId++,
      name: name,
      caloriesText: caloriesText,
      timeText: timeText,
      budgetAmountText: budgetAmountText,
      proteinText: proteinText,
      carbohydratesText: carbohydratesText,
      fatText: fatText,
      fiberText: fiberText,
      sugarText: sugarText,
      sodiumText: sodiumText,
      isFavorite: isFavorite,
    );
  }

  static void add(_CustomFoodEntry entry) {
    _entries.insert(0, entry);
  }

  static void removeById(int id) {
    _entries.removeWhere((entry) => entry.id == id);
  }

  static void setFavoriteById(int id, bool isFavorite) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return;
    }
    _entries[index] = _entries[index].copyWith(isFavorite: isFavorite);
  }
}

class _MealTimelineEntry {
  const _MealTimelineEntry({
    required this.id,
    required this.entryDate,
    required this.timeText,
    required this.itemName,
    required this.caloriesText,
    this.proteinText = '0',
    this.carbohydratesText = '0',
    this.fatText = '0',
    this.fiberText = '0',
    this.sugarText = '0',
    this.sodiumText = '0',
    this.waterLitersText = '0',
    this.budgetAmountText = '0',
  });

  final int id;
  final DateTime entryDate;
  final String timeText;
  final String itemName;
  final String caloriesText;
  final String proteinText;
  final String carbohydratesText;
  final String fatText;
  final String fiberText;
  final String sugarText;
  final String sodiumText;
  final String waterLitersText;
  final String budgetAmountText;
}

class _MealsTimelineStore {
  static int _nextId = 1;
  static final List<_MealTimelineEntry> _entries = <_MealTimelineEntry>[];

  static DateTime get today => _dateOnly(DateTime.now());

  static List<_MealTimelineEntry> get entries =>
      List<_MealTimelineEntry>.unmodifiable(_entries);

  static List<_MealTimelineEntry> entriesForDate(DateTime date) {
    final normalizedDate = _dateOnly(date);
    return List<_MealTimelineEntry>.unmodifiable(
      _entries.where(
        (entry) => _isSameDate(_dateOnly(entry.entryDate), normalizedDate),
      ),
    );
  }

  static String normalizeTimeText(String raw) {
    final match = RegExp(
      r'^\s*(\d{1,2})\s*:\s*(\d{1,2})\s*([AaPp][Mm])\s*$',
    ).firstMatch(raw);
    if (match == null) {
      return raw.trim();
    }
    var hour = int.tryParse(match.group(1) ?? '') ?? 12;
    final minute = (int.tryParse(match.group(2) ?? '') ?? 0).clamp(0, 59);
    final meridiem = (match.group(3) ?? 'AM').toUpperCase();
    if (hour <= 0) {
      hour = 12;
    }
    if (hour > 12) {
      hour = ((hour - 1) % 12) + 1;
    }
    return '$hour:${minute.toString().padLeft(2, '0')} $meridiem';
  }

  static String timeTextFromTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final meridiem = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $meridiem';
  }

  static String _normalizedAmountText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '0';
    }
    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) {
      return '0';
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static void add({
    required String timeText,
    required String itemName,
    required String caloriesText,
    DateTime? entryDate,
    String proteinText = '0',
    String carbohydratesText = '0',
    String fatText = '0',
    String fiberText = '0',
    String sugarText = '0',
    String sodiumText = '0',
    String waterLitersText = '0',
    String budgetAmountText = '0',
  }) {
    final normalizedName = itemName.trim().isEmpty ? 'Meal' : itemName.trim();
    _entries.add(
      _MealTimelineEntry(
        id: _nextId++,
        entryDate: _dateOnly(entryDate ?? DateTime.now()),
        timeText: normalizeTimeText(timeText),
        itemName: normalizedName,
        caloriesText: _normalizedAmountText(caloriesText),
        proteinText: _normalizedAmountText(proteinText),
        carbohydratesText: _normalizedAmountText(carbohydratesText),
        fatText: _normalizedAmountText(fatText),
        fiberText: _normalizedAmountText(fiberText),
        sugarText: _normalizedAmountText(sugarText),
        sodiumText: _normalizedAmountText(sodiumText),
        waterLitersText: _normalizedAmountText(waterLitersText),
        budgetAmountText: _normalizedAmountText(budgetAmountText),
      ),
    );
  }

  static bool replaceById({
    required int id,
    required String timeText,
    required String itemName,
    required String caloriesText,
    bool preserveExistingTimeText = false,
    DateTime? entryDate,
    String proteinText = '0',
    String carbohydratesText = '0',
    String fatText = '0',
    String fiberText = '0',
    String sugarText = '0',
    String sodiumText = '0',
    String waterLitersText = '0',
    String budgetAmountText = '0',
  }) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return false;
    }
    final normalizedName = itemName.trim().isEmpty ? 'Meal' : itemName.trim();
    final existingEntry = _entries[index];
    _entries[index] = _MealTimelineEntry(
      id: id,
      entryDate: _dateOnly(entryDate ?? existingEntry.entryDate),
      timeText: preserveExistingTimeText
          ? existingEntry.timeText
          : normalizeTimeText(timeText),
      itemName: normalizedName,
      caloriesText: _normalizedAmountText(caloriesText),
      proteinText: _normalizedAmountText(proteinText),
      carbohydratesText: _normalizedAmountText(carbohydratesText),
      fatText: _normalizedAmountText(fatText),
      fiberText: _normalizedAmountText(fiberText),
      sugarText: _normalizedAmountText(sugarText),
      sodiumText: _normalizedAmountText(sodiumText),
      waterLitersText: _normalizedAmountText(waterLitersText),
      budgetAmountText: _normalizedAmountText(budgetAmountText),
    );
    return true;
  }

  static void addOrReplace({
    int? entryId,
    required String timeText,
    required String itemName,
    required String caloriesText,
    bool preserveExistingTimeText = false,
    DateTime? entryDate,
    String proteinText = '0',
    String carbohydratesText = '0',
    String fatText = '0',
    String fiberText = '0',
    String sugarText = '0',
    String sodiumText = '0',
    String waterLitersText = '0',
    String budgetAmountText = '0',
  }) {
    if (entryId != null) {
      final wasReplaced = replaceById(
        id: entryId,
        timeText: timeText,
        itemName: itemName,
        caloriesText: caloriesText,
        preserveExistingTimeText: preserveExistingTimeText,
        entryDate: entryDate,
        proteinText: proteinText,
        carbohydratesText: carbohydratesText,
        fatText: fatText,
        fiberText: fiberText,
        sugarText: sugarText,
        sodiumText: sodiumText,
        waterLitersText: waterLitersText,
        budgetAmountText: budgetAmountText,
      );
      if (wasReplaced) {
        return;
      }
    }
    add(
      timeText: timeText,
      itemName: itemName,
      caloriesText: caloriesText,
      entryDate: entryDate,
      proteinText: proteinText,
      carbohydratesText: carbohydratesText,
      fatText: fatText,
      fiberText: fiberText,
      sugarText: sugarText,
      sodiumText: sodiumText,
      waterLitersText: waterLitersText,
      budgetAmountText: budgetAmountText,
    );
  }

  static void removeById(int id) {
    _entries.removeWhere((entry) => entry.id == id);
  }
}

class _DailyFoodCatalogItem {
  const _DailyFoodCatalogItem({
    required this.id,
    required this.name,
    required this.caloriesKcal,
    this.caloriesText = '0',
    this.proteinText = '0',
    this.carbohydratesText = '0',
    this.fatText = '0',
    this.fiberText = '0',
    this.sugarText = '0',
    this.sodiumText = '0',
    this.quantityType = '',
    this.quantityAmountText = '',
    this.priceByCurrency = const <String, double>{},
    this.countryName = '',
    this.isVegetarian = false,
    this.isNonVegetarian = false,
    this.isEggFriendly = false,
    this.isVegan = false,
    this.isFavorite = false,
  });

  final int id;
  final String name;
  final int caloriesKcal;
  final String caloriesText;
  final String proteinText;
  final String carbohydratesText;
  final String fatText;
  final String fiberText;
  final String sugarText;
  final String sodiumText;
  final String quantityType;
  final String quantityAmountText;
  final Map<String, double> priceByCurrency;
  final String countryName;
  final bool isVegetarian;
  final bool isNonVegetarian;
  final bool isEggFriendly;
  final bool isVegan;
  final bool isFavorite;

  _DailyFoodCatalogItem copyWith({bool? isFavorite}) {
    return _DailyFoodCatalogItem(
      id: id,
      name: name,
      caloriesKcal: caloriesKcal,
      caloriesText: caloriesText,
      proteinText: proteinText,
      carbohydratesText: carbohydratesText,
      fatText: fatText,
      fiberText: fiberText,
      sugarText: sugarText,
      sodiumText: sodiumText,
      quantityType: quantityType,
      quantityAmountText: quantityAmountText,
      priceByCurrency: priceByCurrency,
      countryName: countryName,
      isVegetarian: isVegetarian,
      isNonVegetarian: isNonVegetarian,
      isEggFriendly: isEggFriendly,
      isVegan: isVegan,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get quantityTypeLabel {
    final normalized = quantityType.trim().toLowerCase();
    switch (normalized) {
      case 'unit':
        return 'unit';
      case 'g':
      case 'gram':
      case 'grams':
        return 'g';
      case 'mg':
      case 'milligram':
      case 'milligrams':
        return 'mg';
      case 'ml':
      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
        return 'ml';
      case 'l':
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return 'l';
      default:
        return quantityType.trim();
    }
  }

  String get quantityDisplayText {
    final amount = quantityAmountText.trim();
    final type = quantityTypeLabel.trim();
    if (amount.isEmpty && type.isEmpty) {
      return '';
    }
    if (amount.isEmpty) {
      return type;
    }
    if (type.isEmpty) {
      return amount;
    }
    return '$amount $type';
  }

  String budgetTextForCurrency(String currencyCode) {
    final value = priceByCurrency[currencyCode];
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return '';
    }
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.round().toString();
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _DailyFoodDatabase {
  static const String _mainFoodCsvAssetPath =
      'lib/realistic_country_specific_food_prices.csv';
  static const List<String> _mainFoodCurrencyColumns = <String>[
    'USD',
    'EUR',
    'GBP',
    'INR',
    'CNY',
    'BRL',
    'JPY',
    'AUD',
    'CAD',
    'SGD',
    'AED',
    'SAR',
  ];

  static final Set<int> _favoriteFoodIds = <int>{};
  static bool _triedRemoteSearch = false;
  static bool _remoteSearchAvailable = true;
  static bool _csvFoodsLoaded = false;
  static Future<void>? _csvLoadFuture;
  static List<_DailyFoodCatalogItem> _csvFoods = <_DailyFoodCatalogItem>[];

  static final List<_DailyFoodCatalogItem>
  _localFoods = <_DailyFoodCatalogItem>[
    _DailyFoodCatalogItem(id: 1001, name: 'Water', caloriesKcal: 0),
    _DailyFoodCatalogItem(id: 1002, name: 'Mineral Water', caloriesKcal: 0),
    _DailyFoodCatalogItem(id: 1003, name: 'Sparkling Water', caloriesKcal: 0),
    _DailyFoodCatalogItem(id: 1004, name: 'Coconut Water', caloriesKcal: 45),
    _DailyFoodCatalogItem(id: 1005, name: 'Lemon Water', caloriesKcal: 5),
    _DailyFoodCatalogItem(id: 1006, name: 'Black Coffee', caloriesKcal: 2),
    _DailyFoodCatalogItem(id: 1007, name: 'Espresso', caloriesKcal: 5),
    _DailyFoodCatalogItem(id: 1008, name: 'Cappuccino', caloriesKcal: 90),
    _DailyFoodCatalogItem(id: 1009, name: 'Cafe Latte', caloriesKcal: 130),
    _DailyFoodCatalogItem(id: 1010, name: 'Green Tea', caloriesKcal: 2),
    _DailyFoodCatalogItem(id: 1011, name: 'Black Tea', caloriesKcal: 2),
    _DailyFoodCatalogItem(id: 1012, name: 'Milk Tea', caloriesKcal: 85),
    _DailyFoodCatalogItem(id: 1013, name: 'Masala Chai', caloriesKcal: 95),
    _DailyFoodCatalogItem(id: 1014, name: 'Whole Milk', caloriesKcal: 149),
    _DailyFoodCatalogItem(id: 1015, name: 'Toned Milk', caloriesKcal: 122),
    _DailyFoodCatalogItem(id: 1016, name: 'Skim Milk', caloriesKcal: 83),
    _DailyFoodCatalogItem(id: 1017, name: 'Chocolate Milk', caloriesKcal: 190),
    _DailyFoodCatalogItem(id: 1018, name: 'Almond Milk', caloriesKcal: 60),
    _DailyFoodCatalogItem(id: 1019, name: 'Soy Milk', caloriesKcal: 105),
    _DailyFoodCatalogItem(id: 1020, name: 'Oat Milk', caloriesKcal: 120),
    _DailyFoodCatalogItem(id: 1021, name: 'Buttermilk', caloriesKcal: 60),
    _DailyFoodCatalogItem(id: 1022, name: 'Sweet Lassi', caloriesKcal: 180),
    _DailyFoodCatalogItem(id: 1023, name: 'Salted Lassi', caloriesKcal: 130),
    _DailyFoodCatalogItem(id: 1024, name: 'Orange Juice', caloriesKcal: 112),
    _DailyFoodCatalogItem(id: 1025, name: 'Apple Juice', caloriesKcal: 114),
    _DailyFoodCatalogItem(
      id: 1026,
      name: 'Pomegranate Juice',
      caloriesKcal: 135,
    ),
    _DailyFoodCatalogItem(id: 1027, name: 'Mango Juice', caloriesKcal: 128),
    _DailyFoodCatalogItem(id: 1028, name: 'Protein Shake', caloriesKcal: 180),
    _DailyFoodCatalogItem(id: 1029, name: 'Curd', caloriesKcal: 98),
    _DailyFoodCatalogItem(id: 1030, name: 'Greek Yogurt', caloriesKcal: 130),
    _DailyFoodCatalogItem(id: 1031, name: 'Paneer', caloriesKcal: 265),
    _DailyFoodCatalogItem(id: 1032, name: 'Cottage Cheese', caloriesKcal: 206),
    _DailyFoodCatalogItem(id: 1033, name: 'Cheddar Cheese', caloriesKcal: 113),
    _DailyFoodCatalogItem(
      id: 1034,
      name: 'Mozzarella Cheese',
      caloriesKcal: 85,
    ),
    _DailyFoodCatalogItem(id: 1035, name: 'Parmesan Cheese', caloriesKcal: 111),
    _DailyFoodCatalogItem(id: 1036, name: 'Butter', caloriesKcal: 102),
    _DailyFoodCatalogItem(id: 1037, name: 'Ghee', caloriesKcal: 112),
    _DailyFoodCatalogItem(id: 1038, name: 'Boiled Egg', caloriesKcal: 78),
    _DailyFoodCatalogItem(id: 1039, name: 'Omelette', caloriesKcal: 155),
    _DailyFoodCatalogItem(
      id: 1040,
      name: 'Egg White Omelette',
      caloriesKcal: 95,
    ),
    _DailyFoodCatalogItem(id: 1041, name: 'Scrambled Eggs', caloriesKcal: 182),
    _DailyFoodCatalogItem(id: 1042, name: 'Apple', caloriesKcal: 95),
    _DailyFoodCatalogItem(id: 1043, name: 'Banana', caloriesKcal: 105),
    _DailyFoodCatalogItem(id: 1044, name: 'Orange', caloriesKcal: 62),
    _DailyFoodCatalogItem(id: 1045, name: 'Mango', caloriesKcal: 99),
    _DailyFoodCatalogItem(id: 1046, name: 'Pineapple', caloriesKcal: 83),
    _DailyFoodCatalogItem(id: 1047, name: 'Papaya', caloriesKcal: 55),
    _DailyFoodCatalogItem(id: 1048, name: 'Watermelon', caloriesKcal: 46),
    _DailyFoodCatalogItem(id: 1049, name: 'Grapes', caloriesKcal: 104),
    _DailyFoodCatalogItem(id: 1050, name: 'Guava', caloriesKcal: 68),
    _DailyFoodCatalogItem(id: 1051, name: 'Kiwi', caloriesKcal: 42),
    _DailyFoodCatalogItem(id: 1052, name: 'Strawberries', caloriesKcal: 49),
    _DailyFoodCatalogItem(id: 1053, name: 'Blueberries', caloriesKcal: 57),
    _DailyFoodCatalogItem(id: 1054, name: 'Fruit Salad', caloriesKcal: 160),
    _DailyFoodCatalogItem(id: 1055, name: 'Almonds', caloriesKcal: 170),
    _DailyFoodCatalogItem(id: 1056, name: 'Cashews', caloriesKcal: 157),
    _DailyFoodCatalogItem(id: 1057, name: 'Pistachios', caloriesKcal: 159),
    _DailyFoodCatalogItem(id: 1058, name: 'Walnuts', caloriesKcal: 185),
    _DailyFoodCatalogItem(id: 1059, name: 'Peanuts', caloriesKcal: 166),
    _DailyFoodCatalogItem(id: 1060, name: 'Peanut Butter', caloriesKcal: 188),
    _DailyFoodCatalogItem(id: 1061, name: 'Chia Seeds', caloriesKcal: 138),
    _DailyFoodCatalogItem(id: 1062, name: 'Flax Seeds', caloriesKcal: 150),
    _DailyFoodCatalogItem(id: 1063, name: 'Potato Chips', caloriesKcal: 152),
    _DailyFoodCatalogItem(id: 1064, name: 'Banana Chips', caloriesKcal: 165),
    _DailyFoodCatalogItem(id: 1065, name: 'Tortilla Chips', caloriesKcal: 140),
    _DailyFoodCatalogItem(id: 1066, name: 'Nachos', caloriesKcal: 220),
    _DailyFoodCatalogItem(id: 1067, name: 'French Fries', caloriesKcal: 312),
    _DailyFoodCatalogItem(id: 1068, name: 'Popcorn', caloriesKcal: 106),
    _DailyFoodCatalogItem(id: 1069, name: 'Salted Crackers', caloriesKcal: 120),
    _DailyFoodCatalogItem(
      id: 1070,
      name: 'Digestive Biscuit',
      caloriesKcal: 84,
    ),
    _DailyFoodCatalogItem(
      id: 1071,
      name: 'Chocolate Cookie',
      caloriesKcal: 160,
    ),
    _DailyFoodCatalogItem(id: 1072, name: 'Granola Bar', caloriesKcal: 130),
    _DailyFoodCatalogItem(id: 1073, name: 'Trail Mix', caloriesKcal: 173),
    _DailyFoodCatalogItem(id: 1074, name: 'Masala Dosa', caloriesKcal: 126),
    _DailyFoodCatalogItem(
      id: 1075,
      name: 'Masala Pudi Dosa',
      caloriesKcal: 226,
    ),
    _DailyFoodCatalogItem(
      id: 1076,
      name: 'Masala Ghee Dosa',
      caloriesKcal: 226,
    ),
    _DailyFoodCatalogItem(
      id: 1077,
      name: 'Masala Rava Dosa',
      caloriesKcal: 226,
    ),
    _DailyFoodCatalogItem(id: 1078, name: 'Plain Dosa', caloriesKcal: 133),
    _DailyFoodCatalogItem(id: 1079, name: 'Idli', caloriesKcal: 120),
    _DailyFoodCatalogItem(id: 1080, name: 'Medu Vada', caloriesKcal: 97),
    _DailyFoodCatalogItem(id: 1081, name: 'Uttapam', caloriesKcal: 180),
    _DailyFoodCatalogItem(id: 1082, name: 'Poha', caloriesKcal: 200),
    _DailyFoodCatalogItem(id: 1083, name: 'Upma', caloriesKcal: 230),
    _DailyFoodCatalogItem(id: 1084, name: 'Rava Upma', caloriesKcal: 220),
    _DailyFoodCatalogItem(id: 1085, name: 'Pongal', caloriesKcal: 240),
    _DailyFoodCatalogItem(id: 1086, name: 'Aloo Paratha', caloriesKcal: 290),
    _DailyFoodCatalogItem(id: 1087, name: 'Paratha', caloriesKcal: 200),
    _DailyFoodCatalogItem(id: 1088, name: 'Chapati', caloriesKcal: 104),
    _DailyFoodCatalogItem(id: 1089, name: 'Roti', caloriesKcal: 85),
    _DailyFoodCatalogItem(id: 1090, name: 'Steamed Rice', caloriesKcal: 205),
    _DailyFoodCatalogItem(id: 1091, name: 'Brown Rice', caloriesKcal: 216),
    _DailyFoodCatalogItem(id: 1092, name: 'Jeera Rice', caloriesKcal: 290),
    _DailyFoodCatalogItem(id: 1093, name: 'Lemon Rice', caloriesKcal: 280),
    _DailyFoodCatalogItem(id: 1094, name: 'Tomato Rice', caloriesKcal: 300),
    _DailyFoodCatalogItem(id: 1095, name: 'Curd Rice', caloriesKcal: 250),
    _DailyFoodCatalogItem(id: 1096, name: 'Vegetable Pulao', caloriesKcal: 310),
    _DailyFoodCatalogItem(id: 1097, name: 'Veg Biryani', caloriesKcal: 345),
    _DailyFoodCatalogItem(id: 1098, name: 'Chicken Biryani', caloriesKcal: 380),
    _DailyFoodCatalogItem(id: 1099, name: 'Egg Fried Rice', caloriesKcal: 356),
    _DailyFoodCatalogItem(id: 1100, name: 'Veg Fried Rice', caloriesKcal: 330),
    _DailyFoodCatalogItem(
      id: 1101,
      name: 'Chicken Fried Rice',
      caloriesKcal: 410,
    ),
    _DailyFoodCatalogItem(id: 1102, name: 'Dal Tadka', caloriesKcal: 210),
    _DailyFoodCatalogItem(id: 1103, name: 'Rajma', caloriesKcal: 230),
    _DailyFoodCatalogItem(id: 1104, name: 'Chole', caloriesKcal: 240),
    _DailyFoodCatalogItem(id: 1105, name: 'Sambar', caloriesKcal: 95),
    _DailyFoodCatalogItem(id: 1106, name: 'Rasam', caloriesKcal: 45),
    _DailyFoodCatalogItem(
      id: 1107,
      name: 'Paneer Butter Masala',
      caloriesKcal: 325,
    ),
    _DailyFoodCatalogItem(id: 1108, name: 'Palak Paneer', caloriesKcal: 310),
    _DailyFoodCatalogItem(id: 1109, name: 'Mix Veg Curry', caloriesKcal: 190),
    _DailyFoodCatalogItem(id: 1110, name: 'Chicken Curry', caloriesKcal: 320),
    _DailyFoodCatalogItem(id: 1111, name: 'Fish Curry', caloriesKcal: 280),
    _DailyFoodCatalogItem(id: 1112, name: 'Mutton Curry', caloriesKcal: 350),
    _DailyFoodCatalogItem(id: 1113, name: 'Khichdi', caloriesKcal: 260),
    _DailyFoodCatalogItem(id: 1114, name: 'Oats Porridge', caloriesKcal: 180),
    _DailyFoodCatalogItem(id: 1115, name: 'Avocado Toast', caloriesKcal: 240),
    _DailyFoodCatalogItem(
      id: 1116,
      name: 'Peanut Butter Sandwich',
      caloriesKcal: 270,
    ),
    _DailyFoodCatalogItem(
      id: 1117,
      name: 'Chicken Sandwich',
      caloriesKcal: 456,
    ),
    _DailyFoodCatalogItem(
      id: 1118,
      name: 'Vegetable Sandwich',
      caloriesKcal: 320,
    ),
    _DailyFoodCatalogItem(id: 1119, name: 'Tofu Stir Fry', caloriesKcal: 220),
    _DailyFoodCatalogItem(id: 1120, name: 'Grilled Chicken', caloriesKcal: 220),
    _DailyFoodCatalogItem(id: 1121, name: 'Grilled Fish', caloriesKcal: 210),
    _DailyFoodCatalogItem(id: 1122, name: 'Salmon Fillet', caloriesKcal: 280),
    _DailyFoodCatalogItem(id: 1123, name: 'Tuna Salad', caloriesKcal: 240),
    _DailyFoodCatalogItem(id: 1124, name: 'Mixed Salad', caloriesKcal: 140),
    _DailyFoodCatalogItem(id: 1125, name: 'Caesar Salad', caloriesKcal: 190),
    _DailyFoodCatalogItem(
      id: 1126,
      name: 'Broccoli Stir Fry',
      caloriesKcal: 90,
    ),
    _DailyFoodCatalogItem(id: 1127, name: 'Sauteed Spinach', caloriesKcal: 75),
    _DailyFoodCatalogItem(
      id: 1128,
      name: 'Boiled Chickpeas',
      caloriesKcal: 269,
    ),
    _DailyFoodCatalogItem(id: 1129, name: 'Lentil Soup', caloriesKcal: 170),
    _DailyFoodCatalogItem(id: 1130, name: 'Quinoa Bowl', caloriesKcal: 260),
    _DailyFoodCatalogItem(id: 1131, name: 'Veg Burger', caloriesKcal: 290),
    _DailyFoodCatalogItem(id: 1132, name: 'Chicken Burger', caloriesKcal: 370),
    _DailyFoodCatalogItem(
      id: 1133,
      name: 'Pizza Margherita Slice',
      caloriesKcal: 285,
    ),
    _DailyFoodCatalogItem(
      id: 1134,
      name: 'Pizza Pepperoni Slice',
      caloriesKcal: 313,
    ),
    _DailyFoodCatalogItem(id: 1135, name: 'Chicken Nuggets', caloriesKcal: 300),
    _DailyFoodCatalogItem(id: 1136, name: 'Samosa', caloriesKcal: 262),
    _DailyFoodCatalogItem(id: 1137, name: 'Veg Puff', caloriesKcal: 290),
    _DailyFoodCatalogItem(
      id: 1138,
      name: 'Chocolate Brownie',
      caloriesKcal: 311,
    ),
    _DailyFoodCatalogItem(
      id: 1139,
      name: 'Vanilla Ice Cream',
      caloriesKcal: 207,
    ),
    _DailyFoodCatalogItem(id: 1140, name: 'Gulab Jamun', caloriesKcal: 175),
  ];

  static List<String> _parseCsvRow(String row) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < row.length; i++) {
      final char = row[i];
      if (char == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    fields.add(buffer.toString());
    return fields;
  }

  static double _parseCsvNumber(String raw) {
    final normalized = raw.trim().replaceAll(' ', '');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  static bool _parseCsvFlag(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'y';
  }

  static String _formatCsvNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.round().toString();
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _normalizeCsvQuantityAmount(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return '';
    }
    final parsed = _parseCsvNumber(cleaned);
    if (parsed <= 0) {
      return cleaned;
    }
    return _formatCsvNumber(parsed);
  }

  static Future<void> _ensureCsvFoodsLoaded() async {
    if (_csvFoodsLoaded) {
      return;
    }
    if (_csvLoadFuture != null) {
      return _csvLoadFuture!;
    }
    _csvLoadFuture = _loadCsvFoods();
    await _csvLoadFuture;
  }

  static Future<void> _loadCsvFoods() async {
    try {
      final rawCsv = await rootBundle.loadString(_mainFoodCsvAssetPath);
      final rows = const LineSplitter()
          .convert(rawCsv)
          .where((row) => row.trim().isNotEmpty)
          .toList(growable: false);
      if (rows.length < 2) {
        _csvFoodsLoaded = true;
        _csvFoods = <_DailyFoodCatalogItem>[];
        return;
      }

      final header = _parseCsvRow(rows.first)
          .map((value) => value.trim().replaceFirst('\uFEFF', ''))
          .toList(growable: false);
      final indexByColumn = <String, int>{};
      for (int i = 0; i < header.length; i++) {
        indexByColumn[header[i]] = i;
      }

      String readAt(List<String> fields, String key) {
        final idx = indexByColumn[key];
        if (idx == null || idx < 0 || idx >= fields.length) {
          return '';
        }
        return fields[idx].trim();
      }

      final parsedFoods = <_DailyFoodCatalogItem>[];
      for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final fields = _parseCsvRow(rows[rowIndex]);
        final itemName = readAt(fields, 'item_name');
        if (itemName.isEmpty) {
          continue;
        }
        final country = readAt(fields, 'country');
        final quantityType = readAt(fields, 'quantity_type');
        final quantityAmountText = _normalizeCsvQuantityAmount(
          readAt(fields, 'quantity'),
        );

        final calories = _parseCsvNumber(readAt(fields, 'calories_kcal'));
        final protein = _parseCsvNumber(readAt(fields, 'protein_g'));
        final fat = _parseCsvNumber(readAt(fields, 'fat_g'));
        final carbs = _parseCsvNumber(readAt(fields, 'carbohydrates_g'));
        final fiber = _parseCsvNumber(readAt(fields, 'fiber_g'));
        final sugar = _parseCsvNumber(readAt(fields, 'sugar_g'));
        final sodium = _parseCsvNumber(readAt(fields, 'sodium_mg'));
        final isVegetarian = _parseCsvFlag(readAt(fields, 'veg'));
        final isNonVegetarian = _parseCsvFlag(readAt(fields, 'non_veg'));
        final isEggFriendly = _parseCsvFlag(readAt(fields, 'egg'));
        final isVegan = _parseCsvFlag(readAt(fields, 'vegan'));

        final priceByCurrency = <String, double>{};
        for (final code in _mainFoodCurrencyColumns) {
          priceByCurrency[code] = _parseCsvNumber(readAt(fields, code));
        }

        parsedFoods.add(
          _DailyFoodCatalogItem(
            id: 200000 + rowIndex,
            name: itemName,
            caloriesKcal: calories.round(),
            caloriesText: _formatCsvNumber(calories),
            proteinText: _formatCsvNumber(protein),
            carbohydratesText: _formatCsvNumber(carbs),
            fatText: _formatCsvNumber(fat),
            fiberText: _formatCsvNumber(fiber),
            sugarText: _formatCsvNumber(sugar),
            sodiumText: _formatCsvNumber(sodium),
            quantityType: quantityType,
            quantityAmountText: quantityAmountText,
            priceByCurrency: priceByCurrency,
            countryName: country,
            isVegetarian: isVegetarian,
            isNonVegetarian: isNonVegetarian,
            isEggFriendly: isEggFriendly,
            isVegan: isVegan,
          ),
        );
      }

      parsedFoods.sort((a, b) => a.name.compareTo(b.name));
      _csvFoods = parsedFoods;
      _csvFoodsLoaded = true;
    } catch (_) {
      _csvFoodsLoaded = true;
      _csvFoods = <_DailyFoodCatalogItem>[];
    }
  }

  static List<_DailyFoodCatalogItem> _applyFavoriteFlags(
    List<_DailyFoodCatalogItem> foods,
  ) {
    return foods
        .map(
          (food) =>
              food.copyWith(isFavorite: _favoriteFoodIds.contains(food.id)),
        )
        .toList(growable: false);
  }

  static Future<List<_DailyFoodCatalogItem>?> _searchRemoteFoods(
    String query,
  ) async {
    if (_triedRemoteSearch && !_remoteSearchAvailable) {
      return null;
    }
    _triedRemoteSearch = true;
    try {
      final response = await Supabase.instance.client
          .from('daily_food_catalog')
          .select('id,name,calories_kcal')
          .ilike('name', '%$query%')
          .limit(120);

      final foods = <_DailyFoodCatalogItem>[];
      for (int i = 0; i < response.length; i++) {
        final row = response[i];
        final dynamic idRaw = row['id'];
        final dynamic nameRaw = row['name'];
        final dynamic caloriesRaw = row['calories_kcal'] ?? row['calories'];
        final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? (2000 + i);
        final name = '$nameRaw'.trim();
        final calories = caloriesRaw is int
            ? caloriesRaw
            : int.tryParse('$caloriesRaw') ?? 0;
        if (name.isEmpty) {
          continue;
        }
        foods.add(
          _DailyFoodCatalogItem(id: id, name: name, caloriesKcal: calories),
        );
      }

      if (foods.isEmpty) {
        return <_DailyFoodCatalogItem>[];
      }

      foods.sort((a, b) => a.name.compareTo(b.name));
      _remoteSearchAvailable = true;
      return _applyFavoriteFlags(foods);
    } catch (_) {
      _remoteSearchAvailable = false;
      return null;
    }
  }

  static List<_DailyFoodCatalogItem> _searchFoodsFromList(
    String query,
    List<_DailyFoodCatalogItem> sourceFoods,
  ) {
    final normalized = query.trim().toLowerCase();
    final foods = sourceFoods
        .where((food) => food.name.toLowerCase().contains(normalized))
        .toList(growable: false);
    final sorted = [...foods]..sort((a, b) => a.name.compareTo(b.name));
    return _applyFavoriteFlags(sorted);
  }

  static Future<List<_DailyFoodCatalogItem>> searchFoods(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return <_DailyFoodCatalogItem>[];
    }

    await _ensureCsvFoodsLoaded();
    if (_csvFoods.isNotEmpty) {
      return _searchFoodsFromList(normalized, _csvFoods);
    }

    final remoteResults = await _searchRemoteFoods(normalized);
    if (remoteResults != null && remoteResults.isNotEmpty) {
      return remoteResults;
    }

    return _searchFoodsFromList(normalized, _localFoods);
  }

  static String _normalizedCountry(String value) {
    return value.trim().toLowerCase();
  }

  static bool _countryMatches(String itemCountry, String preferredCountry) {
    final normalizedItemCountry = _normalizedCountry(itemCountry);
    final normalizedPreferredCountry = _normalizedCountry(preferredCountry);
    if (normalizedItemCountry.isEmpty || normalizedPreferredCountry.isEmpty) {
      return false;
    }
    if (normalizedItemCountry == normalizedPreferredCountry) {
      return true;
    }
    return normalizedItemCountry.contains(normalizedPreferredCountry) ||
        normalizedPreferredCountry.contains(normalizedItemCountry);
  }

  static int _dietCompatibilityScore(
    _DailyFoodCatalogItem food,
    int selectedDietPreferenceIndex,
  ) {
    switch (selectedDietPreferenceIndex) {
      case 0:
        if (food.isVegan) {
          return 3;
        }
        if (food.isVegetarian && !food.isNonVegetarian && !food.isEggFriendly) {
          return 2;
        }
        return 0;
      case 1:
        if (food.isNonVegetarian) {
          return 4;
        }
        if (food.isEggFriendly) {
          return 3;
        }
        if (food.isVegetarian) {
          return 2;
        }
        if (food.isVegan) {
          return 1;
        }
        return 0;
      case 2:
        if (food.isEggFriendly) {
          return 4;
        }
        if (food.isVegetarian) {
          return 3;
        }
        if (food.isVegan) {
          return 2;
        }
        return 0;
      case 3:
        return food.isVegan ? 4 : 0;
      default:
        return 1;
    }
  }

  static Future<String> buildAssistantFoodContext({
    required int selectedDietPreferenceIndex,
    required String preferredCountry,
  }) async {
    await _ensureCsvFoodsLoaded();
    final sourceFoods = _csvFoods.isNotEmpty ? _csvFoods : _localFoods;

    final scoredFoods = sourceFoods
        .map(
          (food) => (
            food: food,
            score: _dietCompatibilityScore(food, selectedDietPreferenceIndex),
          ),
        )
        .where((entry) => entry.score > 0)
        .toList(growable: false);
    scoredFoods.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      return a.food.name.compareTo(b.food.name);
    });
    final compatibleFoods = scoredFoods
        .map((entry) => entry.food)
        .toList(growable: false);

    if (compatibleFoods.isEmpty) {
      return '';
    }

    final prioritizedFoods = preferredCountry.trim().isEmpty
        ? const <_DailyFoodCatalogItem>[]
        : compatibleFoods
              .where(
                (food) => _countryMatches(food.countryName, preferredCountry),
              )
              .toList(growable: false);

    final priorityNames = prioritizedFoods
        .map((food) => food.name)
        .toSet()
        .take(18)
        .join(', ');
    final compatibleNames = compatibleFoods
        .map((food) => food.name)
        .toSet()
        .take(18)
        .join(', ');

    final contextParts = <String>[];
    if (preferredCountry.trim().isNotEmpty) {
      contextParts.add('Preferred country: ${preferredCountry.trim()}.');
    }
    if (priorityNames.isNotEmpty) {
      contextParts.add(
        'Prioritize these country dishes first when relevant: $priorityNames.',
      );
    }
    contextParts.add(
      'Compatible dishes based on profile diet preference: $compatibleNames.',
    );
    return contextParts.join(' ');
  }

  static void setFavorite(int foodId, bool isFavorite) {
    if (isFavorite) {
      _favoriteFoodIds.add(foodId);
      return;
    }
    _favoriteFoodIds.remove(foodId);
  }

  static bool isFavorite(int foodId) => _favoriteFoodIds.contains(foodId);
}

class _AccountWeightSelection {
  const _AccountWeightSelection({
    required this.weightKg,
    required this.isWeightInKg,
  });

  final int weightKg;
  final bool isWeightInKg;
}

class _AccountHeightSelection {
  const _AccountHeightSelection({
    required this.heightCm,
    required this.isHeightInCm,
  });

  final int heightCm;
  final bool isHeightInCm;
}

class _AccountBudgetSelection {
  const _AccountBudgetSelection({
    required this.budgetEnabled,
    required this.skippedBudgetSection,
    required this.currencyCode,
    required this.selectedBudgetPerMeal,
    required this.customBudgetPerMeal,
    required this.isCustomBudgetPerMeal,
  });

  final bool budgetEnabled;
  final bool skippedBudgetSection;
  final String currencyCode;
  final int? selectedBudgetPerMeal;
  final String customBudgetPerMeal;
  final bool isCustomBudgetPerMeal;
}

class _AccountNutritionSelection {
  const _AccountNutritionSelection({
    required this.goalValues,
    required this.advancedGoalValues,
  });

  final Map<String, String> goalValues;
  final Map<String, String> advancedGoalValues;
}

class _AccountHydrationSelection {
  const _AccountHydrationSelection({
    required this.hydrationEnabled,
    required this.skippedHydrationSection,
    required this.hydrationGoalText,
    required this.isHydrationInLiters,
  });

  final bool hydrationEnabled;
  final bool skippedHydrationSection;
  final String hydrationGoalText;
  final bool isHydrationInLiters;
}

class _IndianNumberInputFormatter extends TextInputFormatter {
  const _IndianNumberInputFormatter({this.allowDecimal = true});

  final bool allowDecimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    final beforeCursorRaw = rawText.substring(
      0,
      newValue.selection.baseOffset.clamp(0, rawText.length),
    );

    String normalized = rawText.replaceAll(',', '');
    String beforeCursorNormalized = beforeCursorRaw.replaceAll(',', '');

    bool hasDecimal = false;
    if (allowDecimal) {
      final firstDotIndex = normalized.indexOf('.');
      if (firstDotIndex != -1) {
        hasDecimal = true;
        normalized =
            '${normalized.substring(0, firstDotIndex + 1)}${normalized.substring(firstDotIndex + 1).replaceAll('.', '')}';
      }
      final firstDotBeforeCursor = beforeCursorNormalized.indexOf('.');
      if (firstDotBeforeCursor != -1) {
        beforeCursorNormalized =
            '${beforeCursorNormalized.substring(0, firstDotBeforeCursor + 1)}${beforeCursorNormalized.substring(firstDotBeforeCursor + 1).replaceAll('.', '')}';
      }
    } else {
      normalized = normalized.replaceAll('.', '');
      beforeCursorNormalized = beforeCursorNormalized.replaceAll('.', '');
    }

    final normalizedChars = normalized.split('');
    final filteredBuffer = StringBuffer();
    for (final ch in normalizedChars) {
      if (_isDigit(ch)) {
        filteredBuffer.write(ch);
      } else if (allowDecimal &&
          ch == '.' &&
          !filteredBuffer.toString().contains('.')) {
        filteredBuffer.write(ch);
      }
    }

    final filtered = filteredBuffer.toString();
    if (filtered.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final split = filtered.split('.');
    final integerDigits = split.first.replaceAll(RegExp(r'[^0-9]'), '');
    final fractionDigits = split.length > 1
        ? split.sublist(1).join('').replaceAll(RegExp(r'[^0-9]'), '')
        : '';
    final showDecimal = allowDecimal && (hasDecimal || split.length > 1);

    final formattedInt = _formatIndianInteger(integerDigits);
    final formattedText = showDecimal
        ? '$formattedInt.$fractionDigits'
        : formattedInt;

    int intDigitsBeforeCursor = 0;
    int fracDigitsBeforeCursor = 0;
    bool cursorAfterDecimal = false;
    for (final ch in beforeCursorNormalized.split('')) {
      if (_isDigit(ch)) {
        if (cursorAfterDecimal) {
          fracDigitsBeforeCursor++;
        } else {
          intDigitsBeforeCursor++;
        }
      } else if (allowDecimal && ch == '.' && !cursorAfterDecimal) {
        cursorAfterDecimal = true;
      }
    }

    final clampedIntCount = intDigitsBeforeCursor.clamp(
      0,
      integerDigits.length,
    );
    int selectionOffset = _positionAfterDigits(formattedInt, clampedIntCount);

    if (showDecimal && cursorAfterDecimal) {
      final clampedFracCount = fracDigitsBeforeCursor.clamp(
        0,
        fractionDigits.length,
      );
      selectionOffset = (formattedInt.length + 1 + clampedFracCount).clamp(
        0,
        formattedText.length,
      );
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  static bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  static int _positionAfterDigits(String text, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }
    int seen = 0;
    for (int i = 0; i < text.length; i++) {
      if (_isDigit(text[i])) {
        seen++;
        if (seen == digitCount) {
          return i + 1;
        }
      }
    }
    return text.length;
  }

  static String _formatIndianInteger(String digits) {
    if (digits.isEmpty) {
      return '';
    }
    if (digits.length <= 3) {
      return digits;
    }
    final last3 = digits.substring(digits.length - 3);
    var prefix = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (prefix.length > 2) {
      groups.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    if (prefix.isNotEmpty) {
      groups.insert(0, prefix);
    }
    return '${groups.join(',')},$last3';
  }
}

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
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(curvedAnimation);
      return RepaintBoundary(
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}

PageRouteBuilder<void> _buildFadeRoute({required Widget screen}) {
  return PageRouteBuilder<void>(
    transitionDuration: _kScreenFadeDuration,
    reverseTransitionDuration: _kScreenFadeDuration,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return RepaintBoundary(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
  );
}

PageRouteBuilder<void> _buildNoTransitionRoute({required Widget screen}) {
  return PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  rendering.debugPaintBaselinesEnabled = false;
  rendering.debugPaintSizeEnabled = false;
  rendering.debugPaintPointersEnabled = false;
  rendering.debugPaintLayerBordersEnabled = false;
  rendering.debugRepaintRainbowEnabled = false;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const WhatIHadApp());
}

final SupabaseClient supabase = Supabase.instance.client;

class WhatIHadApp extends StatelessWidget {
  const WhatIHadApp({super.key});

  @override
  Widget build(BuildContext context) {
    assert(() {
      rendering.debugPaintBaselinesEnabled = false;
      rendering.debugPaintSizeEnabled = false;
      rendering.debugPaintPointersEnabled = false;
      rendering.debugPaintLayerBordersEnabled = false;
      rendering.debugRepaintRainbowEnabled = false;
      return true;
    }());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _defaultNonBorelFontFamily),
      home: const FirstScreen(),
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

  String _countryFromDeviceLocale() {
    final countryCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .countryCode
        ?.trim()
        .toUpperCase();
    if (countryCode == null || countryCode.isEmpty) {
      return '';
    }
    return _countryNameByIso2Code[countryCode] ?? countryCode;
  }

  Future<void> _captureCountryFromPermissionFlow() async {
    final fallbackCountry = _countryFromDeviceLocale();
    if (fallbackCountry.isNotEmpty) {
      _OnboardingProfileState.selectedCountryName = fallbackCountry;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return;
      }
      final country = placemarks.first.country?.trim();
      if (country == null || country.isEmpty) {
        return;
      }
      _OnboardingProfileState.selectedCountryName = country;
    } catch (_) {
      // Keep locale fallback when geolocation is unavailable or denied.
    }
  }

  @override
  void initState() {
    super.initState();
    _OnboardingSkipFlags.reset();
    _OnboardingProfileState.reset();
    unawaited(_captureCountryFromPermissionFlow());
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
      resizeToAvoidBottomInset: false,
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
      resizeToAvoidBottomInset: false,
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

class AccountTermsScreen extends StatefulWidget {
  const AccountTermsScreen({super.key});

  @override
  State<AccountTermsScreen> createState() => _AccountTermsScreenState();
}

class _AccountTermsScreenState extends State<AccountTermsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (52 * scale);
          final linksTop = titleTop + (84 * scale);
          final bottomButtonBottom = math.max(
            66 * scale,
            metrics.padding.bottom + (26 * scale),
          );

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
                    fontSize: (32 * scale).clamp(24.0, 44.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: linksTop,
                left: contentLeft,
                width: contentWidth,
                child: Column(
                  children: [
                    _TermsLinkTile(label: 'Terms and Conditions', scale: scale),
                    SizedBox(height: 32 * scale),
                    _TermsLinkTile(label: 'Privacy Policy', scale: scale),
                  ],
                ),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: bottomButtonBottom,
                child: _RotatingGlassButton(
                  scale: scale,
                  height: 56 * scale,
                  borderRadius: 32 * scale,
                  fillColor: Colors.white,
                  enablePressShadeFeedback: true,
                  onTap: _goBack,
                  child: Icon(
                    Icons.arrow_back,
                    color: const Color(0xFFFFD206),
                    size: (24 * scale).clamp(20.0, 28.0),
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

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;
  static const int _resendCooldownDefaultSeconds = 60;
  static const int _tryAgainLockSeconds = 90 * 60;

  late final AnimationController _controller;
  late final TextEditingController _otpHiddenController;
  late final FocusNode _otpHiddenFocusNode;
  Timer? _otpTimer;
  Timer? _otpAutoVerifyTimer;

  bool _isRequestInProgress = false;
  bool _isVerifyInProgress = false;
  bool _isOtpVerified = false;
  bool _didRequestOtp = false;
  bool _showOtpError = false;
  int _resendAttempts = 0;
  int _resendCooldownSeconds = 0;
  int _tryAgainSeconds = 0;
  int _otpVerifyGeneration = 0;
  String _otpValue = '';

  String? get _registeredEmail {
    final email = supabase.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email;
  }

  bool get _hasRegisteredEmail => _registeredEmail != null;

  bool get _canTapOtpAction {
    if (_isRequestInProgress || _isVerifyInProgress) {
      return false;
    }
    if (!_hasRegisteredEmail) {
      return false;
    }
    if (_tryAgainSeconds > 0) {
      return false;
    }
    if (!_didRequestOtp) {
      return true;
    }
    return _resendCooldownSeconds == 0 && _resendAttempts < 3;
  }

  bool get _canTapDeleteAccount =>
      _didRequestOtp &&
      _tryAgainSeconds == 0 &&
      !_isVerifyInProgress &&
      _otpValue.length == _otpLength &&
      _isOtpVerified;

  @override
  void initState() {
    super.initState();
    _otpHiddenController = TextEditingController();
    _otpHiddenFocusNode = FocusNode();
    _otpHiddenController.addListener(_syncOtpValueFromField);
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _otpAutoVerifyTimer?.cancel();
    _otpHiddenController.removeListener(_syncOtpValueFromField);
    _otpHiddenController.dispose();
    _otpHiddenFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _ensureOtpTimerRunning() {
    if (_otpTimer != null) {
      return;
    }
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_resendCooldownSeconds > 0) {
          _resendCooldownSeconds--;
        }
        if (_tryAgainSeconds > 0) {
          _tryAgainSeconds--;
          if (_tryAgainSeconds == 0) {
            _didRequestOtp = false;
            _resendAttempts = 0;
            _resendCooldownSeconds = 0;
            _resetOtpValidationState();
            _setOtpValue('', updateField: true);
          }
        }
      });
      _stopOtpTimerIfIdle();
    });
  }

  void _stopOtpTimerIfIdle() {
    if (_resendCooldownSeconds > 0 || _tryAgainSeconds > 0) {
      return;
    }
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  String _formatCountdownLabel(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _otpActionLabel {
    if (!_hasRegisteredEmail) {
      return 'No registered email';
    }
    if (_isRequestInProgress) {
      return _didRequestOtp ? 'Sending OTP...' : 'Getting OTP...';
    }
    if (_tryAgainSeconds > 0) {
      return 'Try After (${_formatCountdownLabel(_tryAgainSeconds)})';
    }
    if (!_didRequestOtp) {
      return 'Get OTP';
    }
    if (_resendCooldownSeconds > 0) {
      return 'Resend OTP (${_formatCountdownLabel(_resendCooldownSeconds)}) [$_resendAttempts/3]';
    }
    return 'Resend OTP [$_resendAttempts/3]';
  }

  String _sanitizeOtp(String input) {
    final filtered = input
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '')
        .toUpperCase();
    if (filtered.length <= _otpLength) {
      return filtered;
    }
    return filtered.substring(0, _otpLength);
  }

  void _setOtpValue(String value, {required bool updateField}) {
    final normalized = _sanitizeOtp(value);
    _otpValue = normalized;
    if (updateField && _otpHiddenController.text != normalized) {
      _otpHiddenController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
  }

  void _resetOtpValidationState({bool clearError = true}) {
    _otpVerifyGeneration++;
    _otpAutoVerifyTimer?.cancel();
    _otpAutoVerifyTimer = null;
    _isOtpVerified = false;
    if (clearError) {
      _showOtpError = false;
    }
  }

  Future<bool> _verifyOtpWithFallback(String token) async {
    final email = _registeredEmail;
    if (email == null) {
      return false;
    }
    final otpTypes = <OtpType>[
      OtpType.email,
      OtpType.magiclink,
      OtpType.signup,
    ];
    for (final otpType in otpTypes) {
      try {
        await supabase.auth.verifyOTP(
          type: otpType,
          token: token,
          email: email,
        );
        return true;
      } on AuthException {
        continue;
      }
    }
    return false;
  }

  void _scheduleAutoOtpVerification() {
    _otpAutoVerifyTimer?.cancel();
    if (!_didRequestOtp ||
        _tryAgainSeconds > 0 ||
        _otpValue.length != _otpLength) {
      return;
    }
    final generation = ++_otpVerifyGeneration;
    _otpAutoVerifyTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted ||
          generation != _otpVerifyGeneration ||
          _isVerifyInProgress) {
        return;
      }
      final token = _otpValue;
      if (token.length != _otpLength) {
        return;
      }
      setState(() {
        _isVerifyInProgress = true;
      });
      final verified = await _verifyOtpWithFallback(token);
      if (!mounted || generation != _otpVerifyGeneration) {
        return;
      }
      setState(() {
        _isVerifyInProgress = false;
        _isOtpVerified = verified;
        _showOtpError = !verified;
      });
    });
  }

  void _syncOtpValueFromField() {
    if (!mounted) {
      return;
    }
    final nextValue = _sanitizeOtp(_otpHiddenController.text);
    if (_otpHiddenController.text != nextValue) {
      _otpHiddenController.value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
      );
    }
    if (_otpValue == nextValue) {
      return;
    }
    setState(() {
      _otpValue = nextValue;
      _resetOtpValidationState();
    });
    _scheduleAutoOtpVerification();
  }

  void _focusOtpInput() {
    if (!mounted) {
      return;
    }
    _otpHiddenFocusNode.requestFocus();
    _otpHiddenController.selection = TextSelection.collapsed(
      offset: _otpHiddenController.text.length,
    );
  }

  String _otpDisplayCharacter(int index) {
    if (_showOtpError) {
      const wrongPattern = <String>['0', 'X', '0', '0', '0', '0'];
      return wrongPattern[index];
    }
    if (index >= _otpValue.length) {
      return '';
    }
    return _otpValue[index];
  }

  String get _otpStatusLabel {
    if (!_didRequestOtp || _otpValue.length != _otpLength) {
      return '';
    }
    if (_isVerifyInProgress) {
      return 'Checking OTP...';
    }
    if (_isOtpVerified) {
      return 'OTP is correct';
    }
    if (_showOtpError) {
      return 'OTP is wrong';
    }
    return '';
  }

  Color get _otpStatusColor {
    if (_isOtpVerified) {
      return const Color(0xFF31E68B);
    }
    if (_showOtpError) {
      return const Color(0xFFFF6B6B);
    }
    return Colors.white;
  }

  Future<void> _requestOrResendOtp() async {
    if (!_canTapOtpAction || !mounted) {
      return;
    }
    final email = _registeredEmail;
    if (email == null) {
      return;
    }

    setState(() {
      _isRequestInProgress = true;
      _resetOtpValidationState();
      _setOtpValue('', updateField: true);
    });

    try {
      await supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      if (!mounted) {
        return;
      }
      setState(() {
        if (!_didRequestOtp) {
          _didRequestOtp = true;
          _resendAttempts = 1;
          _resendCooldownSeconds = _resendCooldownDefaultSeconds;
        } else {
          _resendAttempts += 1;
          if (_resendAttempts >= 3) {
            _resendAttempts = 3;
            _tryAgainSeconds = _tryAgainLockSeconds;
            _resendCooldownSeconds = 0;
          } else {
            _resendCooldownSeconds = _resendCooldownDefaultSeconds;
          }
        }
      });
      _ensureOtpTimerRunning();
      _focusOtpInput();
    } on AuthException catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resetOtpValidationState();
        _showOtpError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequestInProgress = false;
        });
      }
    }
  }

  Future<void> _validateOtpAndDelete() async {
    if (!_canTapDeleteAccount || !mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    // OTP is already verified before this point; now only execute delete flow.
    setState(() {
      _resetOtpValidationState();
      _resendAttempts = _resendAttempts <= 0 ? 1 : _resendAttempts;
      _resendCooldownSeconds = _resendCooldownDefaultSeconds;
      _setOtpValue('', updateField: true);
    });
    _ensureOtpTimerRunning();
  }

  Widget _buildOtpDigitCell({required int index, required double scale}) {
    final canEdit = _didRequestOtp && _tryAgainSeconds == 0;
    final fillColor = _showOtpError
        ? const Color(0x29FF0000)
        : (_didRequestOtp ? const Color(0x52FFFFFF) : const Color(0x3DFFFFFF));
    final textColor = _showOtpError
        ? Colors.black
        : (_didRequestOtp ? Colors.black : const Color(0x29000000));

    return SizedBox(
      width: 50 * scale,
      height: 50 * scale,
      child: _RotatingGlassPanel(
        scale: scale,
        borderRadius: 15 * scale,
        fillColor: fillColor,
        padding: EdgeInsets.zero,
        expandToBounds: true,
        boxShadow: _showOtpError
            ? const [
                BoxShadow(
                  color: Color(0xFFFF0000),
                  blurRadius: 2,
                  blurStyle: BlurStyle.outer,
                ),
              ]
            : const <BoxShadow>[],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canEdit ? _focusOtpInput : null,
          child: Center(
            child: Text(
              _otpDisplayCharacter(index),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (24 * scale).clamp(18.0, 30.0),
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSupportCard(double scale) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      padding: EdgeInsets.all(16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Having trouble with OTP verification?',
            style: TextStyle(
              fontSize: (16 * scale).clamp(14.0, 20.0),
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'You can request account deletion by\nemailing us at',
            style: TextStyle(
              fontSize: (14 * scale).clamp(12.0, 18.0),
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'whatihad.info@gmail.com',
            style: TextStyle(
              fontSize: (14 * scale).clamp(12.0, 18.0),
              color: const Color(0xFFFF0000),
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFFF0000),
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'from your registered email address.\nWe’ll verify your request and process it\nshortly.',
            style: TextStyle(
              fontSize: (14 * scale).clamp(12.0, 18.0),
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Requests are usually processed within\n24–48 hours.',
            style: TextStyle(
              fontSize: (14 * scale).clamp(12.0, 18.0),
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: _AnimatedGradientScene(
          animation: _controller,
          contentBuilder: (context, metrics) {
            final scale = metrics.designScale;
            final contentWidth = math.min(
              358 * scale,
              metrics.width - (32 * scale),
            );
            final contentLeft = (metrics.width - contentWidth) / 2;
            final titleTop = metrics.padding.top + (15 * scale) + (30 * scale);
            final contentTop = titleTop + (72 * scale);
            final controlsBottom = _actionControlsBottomInset(
              metrics: metrics,
              scale: scale,
            );
            final scrollBottomPadding = controlsBottom + (72 * scale);
            final backButtonWidth = 79 * scale;
            final deleteButtonWidth = 263 * scale;

            return Stack(
              children: [
                Positioned(
                  top: titleTop,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Account Deletion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Borel',
                      fontSize: (32 * scale).clamp(24.0, 42.0),
                      color: Colors.white,
                      height: 0.99,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      contentLeft,
                      contentTop,
                      contentLeft,
                      scrollBottomPadding,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: contentWidth,
                          height: 56 * scale,
                          child: _RotatingGlassPanel(
                            scale: scale,
                            borderRadius: 16 * scale,
                            fillColor: const Color(0x52FFFFFF),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale,
                            ),
                            expandToBounds: true,
                            child: Center(
                              child: Text(
                                _registeredEmail ?? 'No registered email found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: (16 * scale).clamp(14.0, 20.0),
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24 * scale),
                        SizedBox(
                          width: deleteButtonWidth,
                          child: _RotatingGlassButton(
                            scale: scale,
                            height: 56 * scale,
                            borderRadius: 32 * scale,
                            fillColor: _canTapOtpAction
                                ? const Color(0xCC00B2FF)
                                : const Color(0x6600B2FF),
                            enablePressShadeFeedback: _canTapOtpAction,
                            onTap: _canTapOtpAction
                                ? _requestOrResendOtp
                                : () {},
                            child: Text(
                              _otpActionLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24 * scale),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List<Widget>.generate(
                            _otpLength,
                            (index) =>
                                _buildOtpDigitCell(index: index, scale: scale),
                          ),
                        ),
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _otpHiddenController,
                              focusNode: _otpHiddenFocusNode,
                              autofocus: false,
                              enabled: _didRequestOtp && _tryAgainSeconds == 0,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: _otpLength,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9A-Za-z]'),
                                ),
                                LengthLimitingTextInputFormatter(_otpLength),
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        SizedBox(
                          height: 20 * scale,
                          child: Text(
                            _otpStatusLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: (14 * scale).clamp(12.0, 18.0),
                              color: _otpStatusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                        _buildOtpSupportCard(scale),
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
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: Colors.white,
                          enablePressShadeFeedback: true,
                          onTap: _goBack,
                          child: Icon(
                            Icons.arrow_back,
                            color: const Color(0xFFFFD206),
                            size: (24 * scale).clamp(20.0, 28.0),
                          ),
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      SizedBox(
                        width: deleteButtonWidth,
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: _canTapDeleteAccount
                              ? const Color(0x52FF0606)
                              : const Color(0x24FF0606),
                          enablePressShadeFeedback: _canTapDeleteAccount,
                          onTap: _canTapDeleteAccount
                              ? _validateOtpAndDelete
                              : () {},
                          child: Text(
                            _isVerifyInProgress
                                ? 'Verifying...'
                                : 'Delete Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                              fontWeight: FontWeight.w700,
                            ),
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
        queryParams: const <String, String>{'prompt': 'select_account'},
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
      resizeToAvoidBottomInset: false,
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
      resizeToAvoidBottomInset: false,
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
  const NameScreen({super.key, this.isAccountEdit = false});

  final bool isAccountEdit;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  int _selectedGenderIndex = _OnboardingProfileState.selectedGenderIndex;
  bool _isNameLongPressed = false;
  bool _isNameClicked = false;
  bool _didNavigateForward = false;

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _selectedGenderIndex >= 0 &&
      _selectedGenderIndex < _onboardingGenderLabels.length;

  void _setNameDefaultState() {
    _isNameLongPressed = false;
    _isNameClicked = false;
  }

  void _setNameLongPressedState() {
    _nameFocusNode.unfocus();
    if (!mounted) {
      return;
    }
    setState(() {
      _isNameLongPressed = true;
      _isNameClicked = false;
    });
  }

  void _resetNameLongPressState() {
    if (!mounted || !_isNameLongPressed) {
      return;
    }
    _nameFocusNode.unfocus();
    setState(() {
      _setNameDefaultState();
    });
  }

  void _handleNameTap() {
    if (!mounted) {
      return;
    }
    if (_isNameClicked && !_isNameLongPressed) {
      if (!_nameFocusNode.hasFocus) {
        _nameFocusNode.requestFocus();
      }
      return;
    }
    setState(() {
      _isNameClicked = true;
      _isNameLongPressed = false;
    });
    if (!_nameFocusNode.hasFocus) {
      _nameFocusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = _OnboardingProfileState.selectedName;
    _selectedGenderIndex = _OnboardingProfileState.selectedGenderIndex;
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
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
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const WelcomeScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (!_isFormValid || _didNavigateForward || !mounted) {
      return;
    }
    _OnboardingProfileState.selectedName = _nameController.text.trim();
    _OnboardingProfileState.selectedGenderIndex = _selectedGenderIndex;
    _applyRecommendedNutritionToOnboardingProfile(
      genderIndex: _selectedGenderIndex,
    );
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
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
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;
          final controlsGap = 16 * metrics.designScale;
          final optionGap = 16 * metrics.designScale;
          final optionWidth = (contentWidth - optionGap) / 2;
          final optionHeight = 80 * metrics.designScale;
          final isNameValid = _isFormValid;

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
                    SizedBox(height: 24 * metrics.designScale),
                    Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerUp: (_) => _resetNameLongPressState(),
                      onPointerCancel: (_) => _resetNameLongPressState(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPressDown: (_) => _setNameLongPressedState(),
                        onLongPressStart: (_) => _setNameLongPressedState(),
                        onLongPressUp: _resetNameLongPressState,
                        onLongPressEnd: (_) => _resetNameLongPressState(),
                        onLongPressCancel: _resetNameLongPressState,
                        onTap: _handleNameTap,
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
                            enableBlur: false,
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
                                cursorColor: Colors.black,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: (40 * metrics.designScale).clamp(
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
                                    color: const Color(0x80000000),
                                    fontFamily: 'Borel',
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
                    ),
                    SizedBox(height: 24 * metrics.designScale),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gender',
                        style: TextStyle(
                          fontFamily: 'Borel',
                          fontSize: (24 * metrics.designScale).clamp(
                            18.0,
                            30.0,
                          ),
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * metrics.designScale),
                    Row(
                      children: [
                        SizedBox(
                          width: optionWidth,
                          child: _NameGenderCard(
                            scale: metrics.designScale,
                            label: _onboardingGenderLabels[0],
                            isSelected: _selectedGenderIndex == 0,
                            height: optionHeight,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _selectedGenderIndex = 0;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: optionGap),
                        SizedBox(
                          width: optionWidth,
                          child: _NameGenderCard(
                            scale: metrics.designScale,
                            label: _onboardingGenderLabels[1],
                            isSelected: _selectedGenderIndex == 1,
                            height: optionHeight,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _selectedGenderIndex = 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: optionGap),
                    Row(
                      children: [
                        SizedBox(
                          width: optionWidth,
                          child: _NameGenderCard(
                            scale: metrics.designScale,
                            label: _onboardingGenderLabels[2],
                            isSelected: _selectedGenderIndex == 2,
                            height: optionHeight,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _selectedGenderIndex = 2;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: optionGap),
                        SizedBox(
                          width: optionWidth,
                          child: _NameGenderCard(
                            scale: metrics.designScale,
                            label: _onboardingGenderLabels[3],
                            isSelected: _selectedGenderIndex == 3,
                            height: optionHeight,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _selectedGenderIndex = 3;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: optionGap),
                    SizedBox(
                      width: double.infinity,
                      child: _NameGenderCard(
                        scale: metrics.designScale,
                        label: _onboardingGenderLabels[4],
                        isSelected: _selectedGenderIndex == 4,
                        height: optionHeight,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedGenderIndex = 4;
                          });
                        },
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
                        fillColor: isNameValid
                            ? const Color(0x8FFFD206)
                            : const Color(0x14FFD206),
                        enablePressShadeFeedback: isNameValid,
                        onTap: isNameValid ? _goNext : () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isAccountEdit ? 'Save' : 'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * metrics.designScale / 1.7)
                                    .clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!widget.isAccountEdit) ...[
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

class _NameGenderCard extends StatefulWidget {
  const _NameGenderCard({
    required this.scale,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.height,
  });

  final double scale;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;

  @override
  State<_NameGenderCard> createState() => _NameGenderCardState();
}

class _NameGenderCardState extends State<_NameGenderCard> {
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  void didUpdateWidget(covariant _NameGenderCard oldWidget) {
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
        height: widget.height,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          expandToBounds: true,
          boxShadow: shadows,
          enableBlur: false,
          child: Center(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: (16 * scale).clamp(14.0, 20.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ),
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
    if (_selectedGoalIndex < 0 || _didNavigateForward || !mounted) {
      return;
    }
    _OnboardingProfileState.selectedGoalIndex = _selectedGoalIndex;
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
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;
          final isGoalSelected = _selectedGoalIndex >= 0;

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
                        fillColor: isGoalSelected
                            ? const Color(0x8FFFD206)
                            : const Color(0x14FFD206),
                        enablePressShadeFeedback: isGoalSelected,
                        onTap: isGoalSelected ? _goNext : () {},
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

class AccountGoalScreen extends StatefulWidget {
  const AccountGoalScreen({super.key, required this.initialSelectedGoalIndex});

  final int initialSelectedGoalIndex;

  @override
  State<AccountGoalScreen> createState() => _AccountGoalScreenState();
}

class _AccountGoalScreenState extends State<AccountGoalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _selectedGoalIndex;
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
    _selectedGoalIndex = widget.initialSelectedGoalIndex.clamp(
      0,
      _goalOptions.length - 1,
    );
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _saveGoal() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;
    Navigator.of(context).pop(_selectedGoalIndex);
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
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
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
                  'Change of goal?',
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
                        onTap: _goBack,
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
                        onTap: _saveGoal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Save',
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

class AccountDietPreferenceScreen extends StatefulWidget {
  const AccountDietPreferenceScreen({
    super.key,
    required this.initialSelectedIndex,
  });

  final int initialSelectedIndex;

  @override
  State<AccountDietPreferenceScreen> createState() =>
      _AccountDietPreferenceScreenState();
}

class _AccountDietPreferenceScreenState
    extends State<AccountDietPreferenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _selectedIndex;
  bool _didNavigateForward = false;

  bool get _hasChanged => _selectedIndex != widget.initialSelectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex
        .clamp(0, _dietPreferenceOptions.length - 1)
        .toInt();
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _savePreference() {
    if (!_hasChanged || _didNavigateForward || !mounted) {
      return;
    }
    _didNavigateForward = true;
    Navigator.of(context).pop(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (18 * scale);
          final cardsTop = titleTop + (94 * scale);
          final cardWidth = 171 * scale;
          final cardHeight = 141 * scale;
          final bottomPanelHeight = (190 * scale).clamp(162.0, 220.0);
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final backButtonWidth = 79 * scale;
          final saveButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Diet Preference?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * scale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Wrap(
                    spacing: 16 * scale,
                    runSpacing: 16 * scale,
                    children: List<Widget>.generate(
                      _dietPreferenceOptions.length,
                      (index) {
                        final option = _dietPreferenceOptions[index];
                        return _DietPreferenceCard(
                          scale: scale,
                          width: cardWidth,
                          height: cardHeight,
                          label: option.label,
                          imagePath: option.imagePath,
                          isSelected: _selectedIndex == index,
                          showSelectionGlow: false,
                          onTap: () {
                            if (!mounted) {
                              return;
                            }
                            setState(() => _selectedIndex = index);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
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
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    SizedBox(
                      width: saveButtonWidth,
                      child: _RotatingGlassButton(
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: _hasChanged
                            ? const Color(0x8FFFD206)
                            : const Color(0x52FFD206),
                        enablePressShadeFeedback: _hasChanged,
                        onTap: _hasChanged ? _savePreference : () {},
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                            fontWeight: FontWeight.w700,
                          ),
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

class AccountNutritionCalculatingScreen extends StatefulWidget {
  const AccountNutritionCalculatingScreen({super.key});

  @override
  State<AccountNutritionCalculatingScreen> createState() =>
      _AccountNutritionCalculatingScreenState();
}

class _AccountNutritionCalculatingScreenState
    extends State<AccountNutritionCalculatingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _fillController;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _applyRecommendedNutritionToOnboardingProfile();
    _applyRecommendedHydrationToOnboardingProfile();
    _backgroundController = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
    _fillController = AnimationController(
      vsync: this,
      duration: _kLoadingFillDuration,
    )..repeat(reverse: true);
    _closeTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
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
          final scale = metrics.designScale;
          final ringSize = (250 * scale).clamp(190.0, 320.0);
          final innerSize = ringSize * 0.82;
          final innerRatio = innerSize / ringSize;
          final ringTop = (296.5 * scale).clamp(
            metrics.padding.top + (140 * scale),
            metrics.height * 0.48,
          );
          final descriptionTop = ringTop + ringSize + (64 * scale);
          final strokeWidth = (1 * scale).clamp(0.8, 1.4);
          final fillProgress = Curves.easeInOut.transform(
            _fillController.value,
          );
          final rotatingAngle = (math.pi / 4) + (fillProgress * math.pi * 3);
          final rotatingLightStroke = (strokeWidth * 0.5).clamp(0.6, 1.4);

          return Stack(
            children: [
              Positioned(
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
                              glowWidth: (2 * scale).clamp(1.2, 2.8),
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
                                child: Text(
                                  'Calculating...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Borel',
                                    color: Colors.white,
                                    fontSize: (16 * scale).clamp(14.0, 22.0),
                                    height: 0.99,
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
              ),
              Positioned(
                left: (metrics.width - (358 * scale)) / 2,
                top: descriptionTop,
                width: 358 * scale,
                child: Text(
                  'Setting your goals based on standard\nrequirements, adjust them if needed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (16 * scale).clamp(14.0, 20.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                    height: 1.98,
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

class AccountDailyNutritionGoalsScreen extends StatefulWidget {
  const AccountDailyNutritionGoalsScreen({
    super.key,
    required this.initialGoalValues,
    required this.initialAdvancedGoalValues,
  });

  final Map<String, String> initialGoalValues;
  final Map<String, String> initialAdvancedGoalValues;

  @override
  State<AccountDailyNutritionGoalsScreen> createState() =>
      _AccountDailyNutritionGoalsScreenState();
}

class _AccountDailyNutritionGoalsScreenState
    extends State<AccountDailyNutritionGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Map<String, TextEditingController> _goalValueControllers;
  late final Map<String, String> _savedGoalValues;
  late final Map<String, String> _savedAdvancedGoalValues;

  bool _isAdvanceOpen = false;
  bool _isShowingRecommended = false;
  bool _didComplete = false;

  static const List<_NutritionGoalItem> _goalItems = <_NutritionGoalItem>[
    _NutritionGoalItem(label: 'Calories', value: '2,330', unit: 'kcal'),
    _NutritionGoalItem(label: 'Protein', value: '100', unit: 'g'),
    _NutritionGoalItem(label: 'Carbohydrates', value: '100', unit: 'g'),
    _NutritionGoalItem(label: 'Fat', value: '100', unit: 'g'),
  ];
  static const List<_NutritionGoalItem> _advancedGoalItems =
      <_NutritionGoalItem>[
        _NutritionGoalItem(label: 'Fiber', value: '2,330', unit: 'g'),
        _NutritionGoalItem(label: 'Sugar', value: '100', unit: 'g'),
        _NutritionGoalItem(label: 'Sodium', value: '100', unit: 'mg'),
      ];

  @override
  void initState() {
    super.initState();
    final recommended = _computeNutritionRecommendationFromProfile();
    _savedGoalValues = <String, String>{
      for (final item in _goalItems)
        item.label:
            widget.initialGoalValues[item.label] ??
            recommended.goalValues[item.label] ??
            '0',
    };
    _savedAdvancedGoalValues = <String, String>{
      for (final item in _advancedGoalItems)
        item.label:
            widget.initialAdvancedGoalValues[item.label] ??
            recommended.advancedGoalValues[item.label] ??
            '0',
    };
    _goalValueControllers = <String, TextEditingController>{
      for (final item in [..._goalItems, ..._advancedGoalItems])
        item.label: TextEditingController(
          text:
              _savedGoalValues[item.label] ??
              _savedAdvancedGoalValues[item.label] ??
              item.value,
        ),
    };
    for (final controller in _goalValueControllers.values) {
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    for (final controller in _goalValueControllers.values) {
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Map<String, String> _collectGoalValues() {
    return <String, String>{
      for (final item in _goalItems)
        item.label: _goalValueControllers[item.label]!.text.trim(),
    };
  }

  Map<String, String> _collectAdvancedGoalValues() {
    return <String, String>{
      for (final item in _advancedGoalItems)
        item.label: _goalValueControllers[item.label]!.text.trim(),
    };
  }

  bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if ((right[entry.key] ?? '').trim() != entry.value.trim()) {
        return false;
      }
    }
    return true;
  }

  bool get _hasChanges {
    return !_mapsEqual(_collectGoalValues(), _savedGoalValues) ||
        !_mapsEqual(_collectAdvancedGoalValues(), _savedAdvancedGoalValues);
  }

  bool get _showRecommendedAction => !_isShowingRecommended && _hasChanges;

  void _toggleAdvance() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdvanceOpen = !_isAdvanceOpen;
    });
  }

  void _applyValues({
    required Map<String, String> goalValues,
    required Map<String, String> advancedGoalValues,
  }) {
    final recommended = _computeNutritionRecommendationFromProfile();
    for (final item in _goalItems) {
      _goalValueControllers[item.label]!.text =
          goalValues[item.label] ?? recommended.goalValues[item.label] ?? '0';
    }
    for (final item in _advancedGoalItems) {
      _goalValueControllers[item.label]!.text =
          advancedGoalValues[item.label] ??
          recommended.advancedGoalValues[item.label] ??
          '0';
    }
  }

  Future<void> _showRecommendedFlow() async {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    await Navigator.of(
      context,
    ).push(_buildFadeRoute(screen: const AccountNutritionCalculatingScreen()));
    if (!mounted) {
      return;
    }
    final recommendation = _computeNutritionRecommendationFromProfile();
    _applyValues(
      goalValues: recommendation.goalValues,
      advancedGoalValues: recommendation.advancedGoalValues,
    );
    setState(() {
      _isShowingRecommended = true;
    });
  }

  void _revertRecommended() {
    if (!mounted) {
      return;
    }
    _applyValues(
      goalValues: _savedGoalValues,
      advancedGoalValues: _savedAdvancedGoalValues,
    );
    setState(() {
      _isShowingRecommended = false;
    });
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _saveAndClose() {
    if (_didComplete || !mounted) {
      return;
    }
    if (_hasChanges && !_isShowingRecommended) {
      _showRecommendedFlow();
      return;
    }
    _didComplete = true;
    Navigator.of(context).pop(
      _AccountNutritionSelection(
        goalValues: _collectGoalValues(),
        advancedGoalValues: _collectAdvancedGoalValues(),
      ),
    );
  }

  Widget _buildNutritionGoalCard({
    required _NutritionGoalItem item,
    required double scale,
    required double contentWidth,
    required double cardHeight,
  }) {
    return SizedBox(
      width: contentWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          color: const Color(0x2EFFFFFF),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (16 * scale).clamp(12.0, 20.0).toDouble(),
          vertical: (12 * scale).clamp(8.0, 16.0).toDouble(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: (140 * scale).clamp(130.0, 170.0).toDouble(),
              height: (56 * scale).clamp(48.0, 60.0).toDouble(),
              child: _EditableNutritionValueField(
                scale: scale,
                controller: _goalValueControllers[item.label]!,
                fontSize: (24 * scale).clamp(18.0, 30.0),
              ),
            ),
            SizedBox(width: 8 * scale),
            SizedBox(
              width: 27 * scale,
              height: 25 * scale,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  item.unit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 18.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (15 * scale) + (30 * scale);
          final recommendedTop = titleTop + (50 * scale);
          final cardsTop = titleTop + (60 * scale);
          final cardHeight = (80 * scale).clamp(68.0, 96.0);
          final cardGap = 16 * scale;
          final controlsRowHeight = 56 * scale;
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final bottomPanelHeight = controlsBottom + controlsRowHeight;
          final backButtonWidth = 79 * scale;
          final nextButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Daily Nutrition Goals?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * scale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              if (_isShowingRecommended)
                Positioned(
                  top: recommendedTop,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Recommended',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (20 * scale).clamp(16.0, 26.0),
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Column(
                    children: [
                      ..._goalItems.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(
                            bottom: item == _goalItems.last ? 0 : cardGap,
                          ),
                          child: _buildNutritionGoalCard(
                            item: item,
                            scale: scale,
                            contentWidth: contentWidth,
                            cardHeight: cardHeight,
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleAdvance,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Advance',
                              style: TextStyle(
                                fontSize: (32 * scale / 1.7).clamp(18.0, 28.0),
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(
                              _isAdvanceOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: (24 * scale).clamp(20.0, 30.0),
                            ),
                          ],
                        ),
                      ),
                      if (_isAdvanceOpen) ...[
                        SizedBox(height: 16 * scale),
                        ..._advancedGoalItems.map(
                          (item) => Padding(
                            padding: EdgeInsets.only(
                              bottom: item == _advancedGoalItems.last
                                  ? 0
                                  : cardGap,
                            ),
                            child: _buildNutritionGoalCard(
                              item: item,
                              scale: scale,
                              contentWidth: contentWidth,
                              cardHeight: cardHeight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom + controlsRowHeight + (10 * scale),
                child: Row(
                  children: [
                    SizedBox(width: backButtonWidth + (16 * scale)),
                    SizedBox(
                      width: nextButtonWidth,
                      child: Align(
                        alignment: Alignment.center,
                        child: _showRecommendedAction
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12 * scale,
                                  vertical: 2 * scale,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Recommended',
                                      style: TextStyle(
                                        fontSize: (20 * scale).clamp(
                                          16.0,
                                          24.0,
                                        ),
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10 * scale),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: (24 * scale).clamp(20.0, 30.0),
                                    ),
                                  ],
                                ),
                              )
                            : (_isShowingRecommended
                                  ? GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _revertRecommended,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12 * scale,
                                          vertical: 2 * scale,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Revert',
                                              style: TextStyle(
                                                fontSize: (20 * scale).clamp(
                                                  16.0,
                                                  24.0,
                                                ),
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 10 * scale),
                                            Icon(
                                              Icons.undo,
                                              color: Colors.white,
                                              size: (22 * scale).clamp(
                                                18.0,
                                                28.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
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
                        scale: scale,
                        height: controlsRowHeight,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: scale,
                        height: controlsRowHeight,
                        borderRadius: 32 * scale,
                        fillColor: const Color(0x8FFFD206),
                        enablePressShadeFeedback: true,
                        onTap: _saveAndClose,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
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

class AccountDailyHydrationGoalsScreen extends StatefulWidget {
  const AccountDailyHydrationGoalsScreen({
    super.key,
    required this.initiallySkippedHydrationSection,
    required this.initialHydrationEnabled,
    required this.initialHydrationGoalText,
    required this.initialHydrationInLiters,
  });

  final bool initiallySkippedHydrationSection;
  final bool initialHydrationEnabled;
  final String initialHydrationGoalText;
  final bool initialHydrationInLiters;

  @override
  State<AccountDailyHydrationGoalsScreen> createState() =>
      _AccountDailyHydrationGoalsScreenState();
}

class _AccountDailyHydrationGoalsScreenState
    extends State<AccountDailyHydrationGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _waterController;

  late final bool _savedHydrationEnabled;
  late final bool _savedSkippedHydrationSection;
  late final bool _savedIsHydrationInLiters;
  late final String _savedHydrationGoalText;

  late bool _isHydrationEnabled;
  late bool _skippedHydrationSection;
  late bool _isHydrationInLiters;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    final initialParsed = _parseFormattedNumber(
      widget.initialHydrationGoalText,
    );
    final hasInitialHydrationValue = initialParsed != null && initialParsed > 0;
    _savedHydrationEnabled =
        widget.initialHydrationEnabled &&
        !widget.initiallySkippedHydrationSection &&
        hasInitialHydrationValue;
    _savedSkippedHydrationSection = !_savedHydrationEnabled;
    _savedIsHydrationInLiters = widget.initialHydrationInLiters;
    _savedHydrationGoalText = _savedHydrationEnabled
        ? _normalizeHydrationText(widget.initialHydrationGoalText)
        : '0';

    _isHydrationEnabled = _savedHydrationEnabled;
    _skippedHydrationSection = _savedSkippedHydrationSection;
    _isHydrationInLiters = _savedIsHydrationInLiters;
    _waterController = TextEditingController(text: _savedHydrationGoalText)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _waterController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _isSkippedMode => !_isHydrationEnabled || _skippedHydrationSection;

  bool get _showRevertAction => !_isSkippedMode && _hasChanges;

  bool get _canSave {
    if (_isSkippedMode) {
      return true;
    }
    final parsedValue = _parseFormattedNumber(_waterController.text);
    return parsedValue != null && parsedValue > 0;
  }

  bool get _hasChanges {
    return _isHydrationEnabled != _savedHydrationEnabled ||
        _skippedHydrationSection != _savedSkippedHydrationSection ||
        _isHydrationInLiters != _savedIsHydrationInLiters ||
        _normalizeHydrationText(_waterController.text) !=
            _savedHydrationGoalText;
  }

  double? _parseFormattedNumber(String input) {
    final normalized = input.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _formatNumberForField(double value) {
    final isNegative = value < 0;
    final absValue = value.abs();
    final whole = absValue.truncate();
    final decimal = absValue - whole;
    final formattedWhole = _IndianNumberInputFormatter._formatIndianInteger(
      whole.toString(),
    );

    if (decimal < 0.0001) {
      return isNegative ? '-$formattedWhole' : formattedWhole;
    }

    String frac = absValue.toStringAsFixed(2).split('.').last;
    frac = frac.replaceFirst(RegExp(r'0+$'), '');
    final combined = '$formattedWhole.$frac';
    return isNegative ? '-$combined' : combined;
  }

  String _normalizeHydrationText(String input) {
    final parsed = _parseFormattedNumber(input);
    if (parsed == null || parsed <= 0) {
      return '0';
    }
    return _formatNumberForField(parsed);
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _setHydrationUnit(bool isLiters) {
    if (_isHydrationInLiters == isLiters || !mounted) {
      return;
    }
    final currentValue = _parseFormattedNumber(_waterController.text);
    setState(() {
      _isHydrationInLiters = isLiters;
      if (currentValue != null) {
        final converted = isLiters
            ? currentValue / _ouncesPerLiter
            : currentValue * _ouncesPerLiter;
        final nextText = _formatNumberForField(converted);
        _waterController.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      }
    });
  }

  void _disableHydration() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isHydrationEnabled = false;
      _skippedHydrationSection = true;
      _waterController.value = const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    });
  }

  void _revertChanges() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isHydrationEnabled = _savedHydrationEnabled;
      _skippedHydrationSection = _savedSkippedHydrationSection;
      _isHydrationInLiters = _savedIsHydrationInLiters;
      _waterController.value = TextEditingValue(
        text: _savedHydrationGoalText,
        selection: TextSelection.collapsed(
          offset: _savedHydrationGoalText.length,
        ),
      );
    });
  }

  void _saveAndClose() {
    if (_didComplete || !_canSave || !mounted) {
      return;
    }
    _didComplete = true;
    final parsedGoal = _parseFormattedNumber(_waterController.text);
    final hasHydrationValue = parsedGoal != null && parsedGoal > 0;
    final shouldEnableHydration = _isHydrationEnabled || hasHydrationValue;
    final isSkippedMode = !shouldEnableHydration;
    Navigator.of(context).pop(
      _AccountHydrationSelection(
        hydrationEnabled: shouldEnableHydration,
        skippedHydrationSection: isSkippedMode,
        hydrationGoalText: isSkippedMode
            ? '0'
            : _normalizeHydrationText(_waterController.text),
        isHydrationInLiters: _isHydrationInLiters,
      ),
    );
  }

  Widget _buildHydrationCard({
    required double scale,
    required double contentWidth,
    required double cardHeight,
  }) {
    return SizedBox(
      width: contentWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          color: const Color(0x2EFFFFFF),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (16 * scale).clamp(12.0, 20.0).toDouble(),
          vertical: (12 * scale).clamp(8.0, 16.0).toDouble(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Water',
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: (140 * scale).clamp(130.0, 170.0).toDouble(),
              height: (56 * scale).clamp(48.0, 60.0).toDouble(),
              decoration: BoxDecoration(
                color: const Color(0x52FFFFFF),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: _EditableNutritionValueField(
                scale: scale,
                controller: _waterController,
                fontSize: (24 * scale).clamp(18.0, 30.0),
              ),
            ),
            SizedBox(width: 8 * scale),
            SizedBox(
              width: 60 * scale,
              height: 25 * scale,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  _isHydrationInLiters ? 'Liters (l)' : 'oz',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 18.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (15 * scale) + (30 * scale);
          final recommendedTop = titleTop + (50 * scale);
          final cardsTop = titleTop + (94 * scale);
          final cardHeight = (80 * scale).clamp(68.0, 96.0);
          final bottomPanelHeight = (190 * scale).clamp(162.0, 220.0);
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final backButtonWidth = 79 * scale;
          final nextButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Daily Hydration Goals?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * scale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              if (!_isSkippedMode)
                Positioned(
                  top: recommendedTop,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Recommended',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (20 * scale).clamp(16.0, 26.0),
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Column(
                    children: [
                      _buildHydrationCard(
                        scale: scale,
                        contentWidth: contentWidth,
                        cardHeight: cardHeight,
                      ),
                      SizedBox(height: 16 * scale),
                      _UnitSelectorPill(
                        scale: scale,
                        leftLabel: 'liters',
                        rightLabel: 'oz',
                        fontSize: 16,
                        isLeftSelected: _isHydrationInLiters,
                        onTapLeft: () => _setHydrationUnit(true),
                        onTapRight: () => _setHydrationUnit(false),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom + (56 * scale) + (10 * scale),
                child: Row(
                  children: [
                    SizedBox(width: backButtonWidth + (16 * scale)),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _isSkippedMode
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12 * scale,
                                  vertical: 2 * scale,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Recommended',
                                      style: TextStyle(
                                        fontSize: (20 * scale).clamp(
                                          16.0,
                                          24.0,
                                        ),
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8 * scale),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: (24 * scale).clamp(20.0, 28.0),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : (_showRevertAction
                                ? Row(
                                    children: [
                                      const Expanded(child: SizedBox.shrink()),
                                      SizedBox(width: 16 * scale),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: _revertChanges,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12 * scale,
                                                vertical: 2 * scale,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Revert',
                                                    style: TextStyle(
                                                      fontSize: (20 * scale)
                                                          .clamp(16.0, 24.0),
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8 * scale),
                                                  Icon(
                                                    Icons.undo,
                                                    color: Colors.white,
                                                    size: (22 * scale).clamp(
                                                      18.0,
                                                      28.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink()),
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
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    if (_isSkippedMode)
                      SizedBox(
                        width: nextButtonWidth,
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: _canSave
                              ? const Color(0x8FFFD206)
                              : const Color(0x14FFD206),
                          enablePressShadeFeedback: _canSave,
                          onTap: _canSave ? _saveAndClose : () {},
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: const Color(0xA3FF0606),
                          enablePressShadeFeedback: true,
                          onTap: _disableHydration,
                          child: Text(
                            'Disable',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: _canSave
                              ? const Color(0x8FFFD206)
                              : const Color(0x14FFD206),
                          enablePressShadeFeedback: _canSave,
                          onTap: _canSave ? _saveAndClose : () {},
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
  const AgeScreen({super.key, this.initialAge, this.isAccountEdit = false});

  final int? initialAge;
  final bool isAccountEdit;

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final FixedExtentScrollController _ageScrollController;
  int _selectedAge = 18;
  bool _didNavigateForward = false;
  static const int _minAge = 0;
  static const int _maxAge = 110;
  List<int> get _ages =>
      List<int>.generate(_maxAge - _minAge + 1, (index) => _minAge + index);

  @override
  void initState() {
    super.initState();
    _selectedAge = (widget.initialAge ?? _OnboardingProfileState.selectedAge)
        .clamp(_minAge, _maxAge);
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
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
    _OnboardingProfileState.selectedAge = _selectedAge;
    _didNavigateForward = true;
    if (widget.isAccountEdit) {
      Navigator.of(context).pop(_selectedAge);
      return;
    }
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
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
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
                        onTap: _goBack,
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
                              widget.isAccountEdit ? 'Save' : 'Next',
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
  const WeightScreen({
    super.key,
    this.initialWeightKg,
    this.initialWeightInKg,
    this.isAccountEdit = false,
  });

  final int? initialWeightKg;
  final bool? initialWeightInKg;
  final bool isAccountEdit;

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedWeight = 60;
  bool _isWeightInKg = true;
  bool _didNavigateForward = false;

  @override
  void initState() {
    super.initState();
    _selectedWeight =
        (widget.initialWeightKg ?? _OnboardingProfileState.selectedWeightKg)
            .clamp(20, 300);
    _isWeightInKg =
        widget.initialWeightInKg ?? _OnboardingProfileState.isWeightInKg;
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
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
    _OnboardingProfileState.selectedWeightKg = _selectedWeight;
    _OnboardingProfileState.isWeightInKg = _isWeightInKg;
    _didNavigateForward = true;
    if (widget.isAccountEdit) {
      Navigator.of(context).pop(
        _AccountWeightSelection(
          weightKg: _selectedWeight,
          isWeightInKg: _isWeightInKg,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const HeightScreen()));
  }

  void _setWeightUnit(bool isKg) {
    if (_isWeightInKg == isKg || !mounted) {
      return;
    }
    setState(() {
      _isWeightInKg = isKg;
    });
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
          final cardHeight = (140 * metrics.designScale).clamp(110.0, 170.0);
          final currentRulerGap = (205 * metrics.designScale) - cardHeight;
          final rulerTop =
              cardTop +
              cardHeight +
              (currentRulerGap * 2) -
              (55 * metrics.designScale);
          final rulerHeight = (88 * metrics.designScale).clamp(70.0, 110.0);
          final unitToggleTop =
              rulerTop + rulerHeight + (54 * metrics.designScale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
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
                  widget.isAccountEdit
                      ? 'Change of Weight?'
                      : 'What’s your Weight?',
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
                  height: cardHeight,
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
                          _isWeightInKg
                              ? '$_selectedWeight'
                              : '${(_selectedWeight * 2.2046226218).round()}',
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
                            _isWeightInKg ? 'kg' : 'lbs',
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
                top: unitToggleTop,
                left: contentLeft,
                width: contentWidth,
                child: Center(
                  child: _UnitSelectorPill(
                    scale: metrics.designScale,
                    leftLabel: 'kg',
                    rightLabel: 'lbs',
                    isLeftSelected: _isWeightInKg,
                    onTapLeft: () => _setWeightUnit(true),
                    onTapRight: () => _setWeightUnit(false),
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
                        onTap: _goBack,
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
                              widget.isAccountEdit ? 'Save' : 'Next',
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

class HeightScreen extends StatefulWidget {
  const HeightScreen({
    super.key,
    this.initialHeightCm,
    this.initialHeightInCm,
    this.isAccountEdit = false,
  });

  final int? initialHeightCm;
  final bool? initialHeightInCm;
  final bool isAccountEdit;

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedHeight = 180;
  bool _isHeightInCm = true;
  bool _didNavigateForward = false;

  @override
  void initState() {
    super.initState();
    _selectedHeight =
        (widget.initialHeightCm ?? _OnboardingProfileState.selectedHeightCm)
            .clamp(100, 240);
    _isHeightInCm =
        widget.initialHeightInCm ?? _OnboardingProfileState.isHeightInCm;
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const WeightScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _OnboardingProfileState.selectedHeightCm = _selectedHeight;
    _OnboardingProfileState.isHeightInCm = _isHeightInCm;
    _didNavigateForward = true;
    if (widget.isAccountEdit) {
      Navigator.of(context).pop(
        _AccountHeightSelection(
          heightCm: _selectedHeight,
          isHeightInCm: _isHeightInCm,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const DailyActivityScreen()));
  }

  void _setHeightUnit(bool isCm) {
    if (_isHeightInCm == isCm || !mounted) {
      return;
    }
    setState(() {
      _isHeightInCm = isCm;
    });
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
          const heightControlsLeftShift = 50.0;
          final cardWidth = (265 * metrics.designScale).clamp(220.0, 300.0);
          final cardLeft =
              contentLeft +
              ((contentWidth - cardWidth) / 2) -
              heightControlsLeftShift;
          final cardHeight = (100 * metrics.designScale).clamp(84.0, 124.0);
          final cardTop = (metrics.height - cardHeight) / 2;
          final rulerWidth = (75 * metrics.designScale).clamp(56.0, 90.0);
          final rulerHeight = (560 * metrics.designScale).clamp(420.0, 620.0);
          final rulerTop = (metrics.height - rulerHeight) / 2;
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;
          final indicatorHeight = (24 * metrics.designScale).clamp(18.0, 30.0);
          final selectedLineLength = rulerWidth * 0.96;
          final selectedLineStartX = metrics.width - selectedLineLength;
          final arrowWidth = (34 * metrics.designScale).clamp(26.0, 42.0);
          final arrowLeft = selectedLineStartX - arrowWidth;
          final arrowTop = cardTop + (cardHeight / 2) - (indicatorHeight / 2);
          final unitToggleWidth = math.min(
            264 * metrics.designScale,
            contentWidth,
          );
          final unitToggleTop =
              cardTop + cardHeight + (79 * metrics.designScale);
          final unitToggleLeft =
              contentLeft +
              ((contentWidth - unitToggleWidth) / 2) -
              heightControlsLeftShift;

          return Stack(
            children: [
              Positioned(
                top: questionTop,
                left: 0,
                right: 0,
                child: Text(
                  widget.isAccountEdit
                      ? 'Change of Height?'
                      : 'What’s your Height?',
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
                left: cardLeft,
                width: cardWidth,
                child: Container(
                  height: cardHeight,
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
                          _isHeightInCm
                              ? '$_selectedHeight'
                              : (_selectedHeight / 30.48).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: (64 * metrics.designScale).clamp(
                              52.0,
                              76.0,
                            ),
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 12 * metrics.designScale),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 10 * metrics.designScale,
                          ),
                          child: Text(
                            _isHeightInCm ? 'cm' : 'ft',
                            style: TextStyle(
                              fontSize: (32 * metrics.designScale).clamp(
                                24.0,
                                40.0,
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
                top: arrowTop,
                left: arrowLeft,
                width: arrowWidth,
                height: indicatorHeight,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LeftIndicatorArrowPainter(
                      color: Colors.white,
                      strokeWidth: (2 * metrics.designScale).clamp(1.4, 2.6),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: rulerTop,
                right: 0,
                width: rulerWidth,
                child: _HeightRuler(
                  scale: metrics.designScale,
                  value: _selectedHeight,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _selectedHeight = value);
                    }
                  },
                ),
              ),
              Positioned(
                top: unitToggleTop,
                left: unitToggleLeft,
                width: unitToggleWidth,
                child: _UnitSelectorPill(
                  scale: metrics.designScale,
                  leftLabel: 'cm',
                  rightLabel: 'ft',
                  isLeftSelected: _isHeightInCm,
                  onTapLeft: () => _setHeightUnit(true),
                  onTapRight: () => _setHeightUnit(false),
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
                        onTap: _goBack,
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
                              widget.isAccountEdit ? 'Save' : 'Next',
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

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({
    super.key,
    this.initialSelectedIndex,
    this.isAccountEdit = false,
  });

  final int? initialSelectedIndex;
  final bool isAccountEdit;

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedIndex = -1;
  bool _didNavigateForward = false;

  static const List<_ActivityLevelOption> _activityOptions = [
    _ActivityLevelOption(
      label: 'Low',
      description: 'Little to no exercise. Sitting throughout the day.',
      redBars: 1,
    ),
    _ActivityLevelOption(
      label: 'Light',
      description: 'Light exercise or sports 1-3 days a week.',
      redBars: 2,
    ),
    _ActivityLevelOption(
      label: 'Moderate',
      description: 'Exercise or sports 3-5 days a week. Active lifestyle.',
      redBars: 3,
    ),
    _ActivityLevelOption(
      label: 'Active',
      description: 'Hard exercise or sports 6-7 days a week.',
      redBars: 4,
    ),
    _ActivityLevelOption(
      label: 'Athlete',
      description: 'Very hard exercise regularly or training twice a day.',
      redBars: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        (widget.initialSelectedIndex ??
                _OnboardingProfileState.selectedActivityIndex)
            .clamp(-1, _activityOptions.length - 1);
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const HeightScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_selectedIndex < 0 || _didNavigateForward || !mounted) {
      return;
    }
    _OnboardingProfileState.selectedActivityIndex = _selectedIndex;
    _didNavigateForward = true;
    if (widget.isAccountEdit) {
      Navigator.of(context).pop(_selectedIndex);
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const BudgetPerMealScreen()));
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
          final cardsTop = titleTop + (94 * metrics.designScale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: metrics.designScale,
          );
          final backButtonWidth = 79 * metrics.designScale;
          final nextButtonWidth = 263 * metrics.designScale;
          final isActivitySelected = _selectedIndex >= 0;

          return Stack(
            children: [
              Positioned(
                top: questionTop,
                left: 0,
                right: 0,
                child: Text(
                  'Daily Activity Level?',
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
                bottom: controlsBottom + (72 * metrics.designScale),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _activityOptions.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 16 * metrics.designScale),
                  itemBuilder: (context, index) {
                    final option = _activityOptions[index];
                    return _ActivityLevelCard(
                      scale: metrics.designScale,
                      label: option.label,
                      description: option.description,
                      redBars: option.redBars,
                      isSelected: _selectedIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    );
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
                        onTap: _goBack,
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
                        fillColor: isActivitySelected
                            ? const Color(0x8FFFD206)
                            : const Color(0x14FFD206),
                        enablePressShadeFeedback: isActivitySelected,
                        onTap: isActivitySelected ? _goNext : () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isAccountEdit ? 'Save' : 'Next',
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

class BudgetPerMealScreen extends StatefulWidget {
  const BudgetPerMealScreen({
    super.key,
    this.isAccountEdit = false,
    this.showDisableButton = false,
    this.initialSelectedBudget,
    this.initialCustomBudget,
    this.initialIsCustomSelected,
    this.initialCurrencyCode,
  });

  final bool isAccountEdit;
  final bool showDisableButton;
  final int? initialSelectedBudget;
  final String? initialCustomBudget;
  final bool? initialIsCustomSelected;
  final String? initialCurrencyCode;

  @override
  State<BudgetPerMealScreen> createState() => _BudgetPerMealScreenState();
}

class _BudgetPerMealScreenState extends State<BudgetPerMealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _customBudgetController = TextEditingController();
  final FocusNode _customBudgetFocusNode = FocusNode();
  int _selectedCurrencyIndex = 0;
  bool _isCurrencyDropdownOpen = false;
  int? _selectedBudget;
  bool _isCustomSelected = false;
  bool _didNavigateForward = false;
  bool _consumeNextSelectionTap = false;

  static const List<int> _presetBudgets = <int>[100, 150, 200, 250];
  static const Map<String, String> _currencyGlyphByCode =
      _budgetCurrencyGlyphByCode;
  static const List<_CurrencyOption> _currencyOptions = <_CurrencyOption>[
    _CurrencyOption(label: 'USD (\$)', symbol: 'USD'),
    _CurrencyOption(label: 'EUR (€)', symbol: 'EUR'),
    _CurrencyOption(label: 'GBP (£)', symbol: 'GBP'),
    _CurrencyOption(label: 'INR (₹)', symbol: 'INR'),
    _CurrencyOption(label: 'CNY (¥)', symbol: 'CNY'),
    _CurrencyOption(label: 'BRL (R\$)', symbol: 'BRL'),
    _CurrencyOption(label: 'JPY (¥)', symbol: 'JPY'),
    _CurrencyOption(label: 'AUD (A\$)', symbol: 'AUD'),
    _CurrencyOption(label: 'CAD (C\$)', symbol: 'CAD'),
    _CurrencyOption(label: 'SGD (S\$)', symbol: 'SGD'),
    _CurrencyOption(label: 'AED (د.إ)', symbol: 'AED'),
    _CurrencyOption(label: 'SAR (﷼)', symbol: 'SAR'),
  ];

  @override
  void initState() {
    super.initState();
    final initialCurrencyCode =
        widget.initialCurrencyCode ??
        _OnboardingProfileState.budgetCurrencyCode;
    final preferredIndex = _currencyOptions.indexWhere(
      (_CurrencyOption option) => option.symbol == initialCurrencyCode,
    );
    final inrIndex = _currencyOptions.indexWhere(
      (_CurrencyOption option) => option.symbol == 'INR',
    );
    if (preferredIndex >= 0) {
      _selectedCurrencyIndex = preferredIndex;
    } else if (inrIndex >= 0) {
      _selectedCurrencyIndex = inrIndex;
    }

    _selectedBudget =
        widget.initialSelectedBudget ??
        _OnboardingProfileState.selectedBudgetPerMeal;
    _customBudgetController.text =
        widget.initialCustomBudget ??
        _OnboardingProfileState.customBudgetPerMeal;
    _isCustomSelected =
        widget.initialIsCustomSelected ??
        _OnboardingProfileState.isCustomBudgetPerMeal;

    if (_isCustomSelected && _customBudgetController.text.trim().isEmpty) {
      _isCustomSelected = false;
    }
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _customBudgetFocusNode.dispose();
    _customBudgetController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedBudget != null ||
      (_isCustomSelected && _customBudgetController.text.trim().isNotEmpty);

  bool _dismissKeyboardOnlyIfNeeded() {
    if (_customBudgetFocusNode.hasFocus) {
      FocusScope.of(context).unfocus();
      return true;
    }
    return false;
  }

  void _dismissKeyboardFromOutsideTap() {
    if (!_customBudgetFocusNode.hasFocus) {
      return;
    }
    _consumeNextSelectionTap = true;
    FocusScope.of(context).unfocus();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }
      _consumeNextSelectionTap = false;
    });
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    if (widget.isAccountEdit) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const DailyActivityScreen(), fromLeft: true),
    );
  }

  void _persistBudgetState({required bool enabled, required bool skipped}) {
    final customText = _customBudgetController.text.trim();
    final selectedBudget = _isCustomSelected ? null : _selectedBudget;
    final customBudget = _isCustomSelected ? customText : '';

    _OnboardingProfileState.budgetEnabled = enabled;
    _OnboardingProfileState.budgetCurrencyCode = _selectedCurrency.symbol;
    _OnboardingProfileState.selectedBudgetPerMeal = enabled
        ? selectedBudget
        : null;
    _OnboardingProfileState.customBudgetPerMeal = enabled ? customBudget : '';
    _OnboardingProfileState.isCustomBudgetPerMeal =
        enabled && _isCustomSelected && customBudget.isNotEmpty;
    _OnboardingSkipFlags.skippedBudgetSection = skipped;
  }

  void _goNext() {
    if (!_canContinue || _didNavigateForward || !mounted) {
      return;
    }
    _persistBudgetState(enabled: true, skipped: false);
    _didNavigateForward = true;
    _isCurrencyDropdownOpen = false;
    FocusScope.of(context).unfocus();
    if (widget.isAccountEdit) {
      Navigator.of(context).pop(
        _AccountBudgetSelection(
          budgetEnabled: true,
          skippedBudgetSection: false,
          currencyCode: _selectedCurrency.symbol,
          selectedBudgetPerMeal: _isCustomSelected ? null : _selectedBudget,
          customBudgetPerMeal: _isCustomSelected
              ? _customBudgetController.text.trim()
              : '',
          isCustomBudgetPerMeal:
              _isCustomSelected &&
              _customBudgetController.text.trim().isNotEmpty,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const GoalCalculationScreen()));
  }

  void _disableBudget() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _persistBudgetState(enabled: false, skipped: true);
    _didNavigateForward = true;
    _isCurrencyDropdownOpen = false;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      _AccountBudgetSelection(
        budgetEnabled: false,
        skippedBudgetSection: true,
        currencyCode: _selectedCurrency.symbol,
        selectedBudgetPerMeal: null,
        customBudgetPerMeal: '',
        isCustomBudgetPerMeal: false,
      ),
    );
  }

  void _skip() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _persistBudgetState(enabled: false, skipped: true);
    _didNavigateForward = true;
    _isCurrencyDropdownOpen = false;
    FocusScope.of(context).unfocus();
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const GoalCalculationScreen()));
  }

  void _selectPresetBudget(int value) {
    if (!mounted) {
      return;
    }
    if (_consumeNextSelectionTap) {
      _consumeNextSelectionTap = false;
      return;
    }
    if (_dismissKeyboardOnlyIfNeeded()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final shouldDeselect = !_isCustomSelected && _selectedBudget == value;
    setState(() {
      _isCurrencyDropdownOpen = false;
      _selectedBudget = shouldDeselect ? null : value;
      _isCustomSelected = false;
    });
  }

  void _selectCustomBudget() {
    if (!mounted) {
      return;
    }
    if (_consumeNextSelectionTap) {
      _consumeNextSelectionTap = false;
      return;
    }
    if (_dismissKeyboardOnlyIfNeeded()) {
      return;
    }
    final shouldDeselect = _isCustomSelected;
    setState(() {
      _isCurrencyDropdownOpen = false;
      _isCustomSelected = !shouldDeselect;
      if (!shouldDeselect) {
        _selectedBudget = null;
      }
    });
    if (shouldDeselect) {
      FocusScope.of(context).unfocus();
    } else {
      _customBudgetFocusNode.requestFocus();
    }
  }

  void _toggleCurrencyDropdown() {
    if (!mounted) {
      return;
    }
    if (_consumeNextSelectionTap) {
      _consumeNextSelectionTap = false;
      return;
    }
    if (_dismissKeyboardOnlyIfNeeded()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isCurrencyDropdownOpen = !_isCurrencyDropdownOpen;
    });
  }

  void _selectCurrencyOption(int index) {
    if (!mounted) {
      return;
    }
    if (_consumeNextSelectionTap) {
      _consumeNextSelectionTap = false;
      return;
    }
    if (_dismissKeyboardOnlyIfNeeded()) {
      return;
    }
    if (index < 0 || index >= _dropdownCurrencyOptions.length) {
      return;
    }
    setState(() {
      _selectedCurrencyIndex = index;
      _isCurrencyDropdownOpen = false;
    });
  }

  _CurrencyOption get _selectedCurrency =>
      _currencyOptions[_selectedCurrencyIndex];

  List<_CurrencyOption> get _dropdownCurrencyOptions {
    return _currencyOptions;
  }

  String _currencyBracketSymbol(_CurrencyOption option) {
    final glyph = _currencyGlyphByCode[option.symbol];
    if (glyph == null || glyph.isEmpty) {
      return option.symbol;
    }
    return glyph;
  }

  String _currencyDisplayLabel(_CurrencyOption option) {
    return option.label;
  }

  String _currencyDropdownLabel(_CurrencyOption option) {
    return option.label;
  }

  Widget _buildCurrencySelector(double scale) {
    final selectorRadius = BorderRadius.circular(16 * scale);
    final selectorBorder = Border.all(
      color: const Color(0x80FFFFFF),
      width: (1 * scale).clamp(0.8, 1.4),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleCurrencyDropdown,
      child: ClipRRect(
        borderRadius: selectorRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _currencyDropdownBlurSigma * scale,
            sigmaY: _currencyDropdownBlurSigma * scale,
          ),
          child: Container(
            width: (252 * scale).clamp(220.0, 300.0),
            height: (62 * scale).clamp(56.0, 74.0),
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            decoration: BoxDecoration(
              color: const Color(0x52FFFFFF),
              borderRadius: selectorRadius,
              border: selectorBorder,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _currencyDisplayLabel(_selectedCurrency),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: (24 * scale).clamp(18.0, 28.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                Icon(
                  _isCurrencyDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: (24 * scale).clamp(20.0, 30.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdownPanel(double scale) {
    final panelRadius = BorderRadius.circular(16 * scale);
    return ClipRRect(
      borderRadius: panelRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _currencyDropdownBlurSigma * scale,
          sigmaY: _currencyDropdownBlurSigma * scale,
        ),
        child: Container(
          width: (252 * scale).clamp(220.0, 300.0),
          constraints: BoxConstraints(
            maxHeight: (420 * scale).clamp(240.0, 520.0),
          ),
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: const Color(0x52FFFFFF),
            borderRadius: panelRadius,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _dropdownCurrencyOptions.length,
            separatorBuilder: (_, index) => SizedBox(height: 16 * scale),
            itemBuilder: (context, index) {
              final option = _dropdownCurrencyOptions[index];
              final optionRadius = BorderRadius.circular(16 * scale);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectCurrencyOption(index),
                child: Align(
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: optionRadius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _currencyDropdownOptionBlurSigma * scale,
                        sigmaY: _currencyDropdownOptionBlurSigma * scale,
                      ),
                      child: Container(
                        width: math.min(
                          218 * scale,
                          ((252 * scale).clamp(220.0, 300.0)) - (32 * scale),
                        ),
                        padding: EdgeInsets.all(8 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0x94FFFFFF),
                          borderRadius: optionRadius,
                          border: Border.all(
                            color: const Color(0x80FFFFFF),
                            width: (1 * scale).clamp(0.8, 1.4),
                          ),
                        ),
                        child: Text(
                          _currencyDropdownLabel(option),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: (24 * scale).clamp(18.0, 28.0),
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard({
    required double scale,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return _BudgetOptionCard(
      scale: scale,
      isSelected: isSelected,
      onTap: onTap,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final titleTop = metrics.padding.top + (15 * scale) + (15 * scale);
          final optionsTop = titleTop + (56 * scale);
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final selectorWidth = (252 * scale).clamp(220.0, 300.0);
          final selectorHeight = (62 * scale).clamp(56.0, 74.0);
          final bottomPanelHeight = (190 * scale).clamp(162.0, 220.0);
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final selectedCurrencySymbol = _currencyBracketSymbol(
            _selectedCurrency,
          );
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final backButtonWidth = 79 * scale;
          final nextButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: optionsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  clipBehavior: Clip.hardEdge,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _buildCurrencySelector(scale)),
                      SizedBox(height: 16 * scale),
                      _buildBudgetCard(
                        scale: scale,
                        isSelected: _isCustomSelected,
                        onTap: _selectCustomBudget,
                        content: Row(
                          children: [
                            Text(
                              selectedCurrencySymbol,
                              style: TextStyle(
                                fontSize: (20 * scale).clamp(16.0, 24.0),
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            Expanded(
                              child: TextField(
                                controller: _customBudgetController,
                                focusNode: _customBudgetFocusNode,
                                scrollPadding: EdgeInsets.zero,
                                onTapOutside: (_) {
                                  _dismissKeyboardFromOutsideTap();
                                },
                                onTap: () {
                                  if (!_isCustomSelected) {
                                    _selectCustomBudget();
                                  }
                                },
                                onChanged: (_) {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  _IndianNumberInputFormatter(
                                    allowDecimal: true,
                                  ),
                                ],
                                textInputAction: TextInputAction.done,
                                style: TextStyle(
                                  fontSize: (32 * scale).clamp(24.0, 38.0),
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: 'Custom',
                                  hintStyle: TextStyle(
                                    fontSize: (32 * scale).clamp(24.0, 38.0),
                                    color: const Color(0x29000000),
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._presetBudgets.map((budget) {
                        final isSelected =
                            !_isCustomSelected && _selectedBudget == budget;
                        return Padding(
                          padding: EdgeInsets.only(top: 16 * scale),
                          child: _buildBudgetCard(
                            scale: scale,
                            isSelected: isSelected,
                            onTap: () => _selectPresetBudget(budget),
                            content: Row(
                              children: [
                                Text(
                                  selectedCurrencySymbol,
                                  style: TextStyle(
                                    fontSize: (20 * scale).clamp(16.0, 24.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                Text(
                                  '$budget',
                                  style: TextStyle(
                                    fontSize: (32 * scale).clamp(24.0, 38.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 20 * scale),
                      Text(
                        'Share your meal budget, so AI can suggest\nfoods for your goals.',
                        style: TextStyle(
                          fontSize: (16 * scale).clamp(14.0, 20.0),
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          height: 1.98,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    'Avg Budget per Meal?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Borel',
                      fontSize: (32 * scale).clamp(24.0, 42.0),
                      color: Colors.white,
                      height: 0.99,
                    ),
                  ),
                ),
              ),
              if (_isCurrencyDropdownOpen)
                Positioned(
                  top: optionsTop + selectorHeight + (8 * scale),
                  left: contentLeft + ((contentWidth - selectorWidth) / 2),
                  width: selectorWidth,
                  child: _buildCurrencyDropdownPanel(scale),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              if (!widget.isAccountEdit)
                Positioned(
                  left: contentLeft,
                  width: contentWidth,
                  bottom: controlsBottom + (56 * scale) + (10 * scale),
                  child: Row(
                    children: [
                      SizedBox(width: backButtonWidth + (16 * scale)),
                      SizedBox(
                        width: nextButtonWidth,
                        child: Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _skip,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * scale,
                                vertical: 2 * scale,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontSize: (20 * scale).clamp(16.0, 24.0),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: (24 * scale).clamp(20.0, 28.0),
                                  ),
                                ],
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
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    if (widget.isAccountEdit && widget.showDisableButton) ...[
                      Expanded(
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: const Color(0xA3FF0606),
                          enablePressShadeFeedback: true,
                          onTap: _disableBudget,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Disable',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (34 * scale / 1.7).clamp(
                                    18.0,
                                    28.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                    ],
                    if (widget.isAccountEdit && widget.showDisableButton)
                      Expanded(
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: _canContinue
                              ? const Color(0x8FFFD206)
                              : const Color(0x14FFD206),
                          enablePressShadeFeedback: _canContinue,
                          onTap: _canContinue ? _goNext : () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (34 * scale / 1.7).clamp(
                                    18.0,
                                    28.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: nextButtonWidth,
                        child: _RotatingGlassButton(
                          scale: scale,
                          height: 56 * scale,
                          borderRadius: 32 * scale,
                          fillColor: _canContinue
                              ? const Color(0x8FFFD206)
                              : const Color(0x14FFD206),
                          enablePressShadeFeedback: _canContinue,
                          onTap: _canContinue ? _goNext : () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.isAccountEdit ? 'Save' : 'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (34 * scale / 1.7).clamp(
                                    18.0,
                                    28.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!widget.isAccountEdit) ...[
                                SizedBox(width: 12 * scale),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: (24 * scale).clamp(20.0, 28.0),
                                ),
                              ],
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

class GoalCalculationScreen extends StatefulWidget {
  const GoalCalculationScreen({super.key});

  @override
  State<GoalCalculationScreen> createState() => _GoalCalculationScreenState();
}

class _GoalCalculationScreenState extends State<GoalCalculationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _fillController;
  Timer? _nextScreenTimer;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
    _fillController = AnimationController(
      vsync: this,
      duration: _kLoadingFillDuration,
    )..repeat(reverse: true);
    _nextScreenTimer = Timer(const Duration(seconds: 3), _goToDailyGoals);
  }

  void _goToDailyGoals() {
    if (_didNavigate || !mounted) {
      return;
    }
    _didNavigate = true;
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const DailyNutritionGoalsScreen()),
    );
  }

  @override
  void dispose() {
    _nextScreenTimer?.cancel();
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
          final scale = metrics.designScale;
          final ringSize = (250 * scale).clamp(190.0, 320.0);
          final innerSize = ringSize * 0.82;
          final innerRatio = innerSize / ringSize;
          final ringTop = (296.5 * scale).clamp(
            metrics.padding.top + (140 * scale),
            metrics.height * 0.48,
          );
          final descriptionTop = ringTop + ringSize + (64 * scale);
          final strokeWidth = (1 * scale).clamp(0.8, 1.4);
          final fillProgress = Curves.easeInOut.transform(
            _fillController.value,
          );
          final rotatingAngle = (math.pi / 4) + (fillProgress * math.pi * 3);
          final rotatingLightStroke = (strokeWidth * 0.5).clamp(0.6, 1.4);

          return Stack(
            children: [
              Positioned(
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
                              glowWidth: (2 * scale).clamp(1.2, 2.8),
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
                                child: Text(
                                  'Calculating...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Borel',
                                    color: Colors.white,
                                    fontSize: (16 * scale).clamp(14.0, 22.0),
                                    height: 0.99,
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
              ),
              Positioned(
                left: (metrics.width - (358 * scale)) / 2,
                top: descriptionTop,
                width: 358 * scale,
                child: Text(
                  'Setting your goals based on standard\nrequirements, adjust them if needed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (16 * scale).clamp(14.0, 20.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                    height: 1.98,
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

class DailyNutritionGoalsScreen extends StatefulWidget {
  const DailyNutritionGoalsScreen({super.key});

  @override
  State<DailyNutritionGoalsScreen> createState() =>
      _DailyNutritionGoalsScreenState();
}

class _DailyNutritionGoalsScreenState extends State<DailyNutritionGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Map<String, TextEditingController> _goalValueControllers;
  bool _isAdvanceOpen = false;
  bool _didNavigateForward = false;
  static const List<_NutritionGoalItem> _goalItems = <_NutritionGoalItem>[
    _NutritionGoalItem(label: 'Calories', value: '2,330', unit: 'kcal'),
    _NutritionGoalItem(label: 'Protein', value: '100', unit: 'g'),
    _NutritionGoalItem(label: 'Carbohydrates', value: '100', unit: 'g'),
    _NutritionGoalItem(label: 'Fat', value: '100', unit: 'g'),
  ];
  static const List<_NutritionGoalItem> _advancedGoalItems =
      <_NutritionGoalItem>[
        _NutritionGoalItem(label: 'Fiber', value: '2,330', unit: 'g'),
        _NutritionGoalItem(label: 'Sugar', value: '100', unit: 'g'),
        _NutritionGoalItem(label: 'Sodium', value: '100', unit: 'mg'),
      ];

  @override
  void initState() {
    super.initState();
    _applyRecommendedNutritionToOnboardingProfile();
    final recommended = _computeNutritionRecommendationFromProfile();
    _goalValueControllers = <String, TextEditingController>{
      for (final item in [..._goalItems, ..._advancedGoalItems])
        item.label: TextEditingController(
          text:
              _OnboardingProfileState.nutritionGoalValues[item.label] ??
              _OnboardingProfileState.advancedNutritionGoalValues[item.label] ??
              recommended.goalValues[item.label] ??
              recommended.advancedGoalValues[item.label] ??
              '0',
        ),
    };
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    for (final controller in _goalValueControllers.values) {
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const BudgetPerMealScreen(), fromLeft: true),
    );
  }

  void _goNext() {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _OnboardingProfileState.nutritionGoalValues = <String, String>{
      for (final item in _goalItems)
        item.label: _goalValueControllers[item.label]!.text.trim(),
    };
    _OnboardingProfileState.advancedNutritionGoalValues = <String, String>{
      for (final item in _advancedGoalItems)
        item.label: _goalValueControllers[item.label]!.text.trim(),
    };
    _didNavigateForward = true;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(screen: const DailyHydrationGoalsScreen()),
    );
  }

  void _toggleAdvance() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdvanceOpen = !_isAdvanceOpen;
    });
  }

  Widget _buildNutritionGoalCard({
    required _NutritionGoalItem item,
    required TextEditingController valueController,
    required double scale,
    required double contentWidth,
    required double cardHeight,
  }) {
    return SizedBox(
      width: contentWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          color: const Color(0x2EFFFFFF),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (16 * scale).clamp(12.0, 20.0).toDouble(),
          vertical: (12 * scale).clamp(8.0, 16.0).toDouble(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: (140 * scale).clamp(130.0, 170.0).toDouble(),
              height: (56 * scale).clamp(48.0, 60.0).toDouble(),
              child: _EditableNutritionValueField(
                scale: scale,
                controller: valueController,
                fontSize: (24 * scale).clamp(18.0, 30.0),
              ),
            ),
            SizedBox(width: 8 * scale),
            SizedBox(
              width: 27 * scale,
              height: 25 * scale,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  item.unit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 18.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (15 * scale) + (30 * scale);
          final recommendedTop = titleTop + (50 * scale);
          final cardsTop = titleTop + (94 * scale);
          final cardHeight = (80 * scale).clamp(68.0, 96.0);
          final cardGap = 16 * scale;
          final controlsRowHeight = 56 * scale;
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          // Start the blur exactly where the control buttons row starts.
          final bottomPanelHeight = controlsBottom + controlsRowHeight;
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final backButtonWidth = 79 * scale;
          final nextButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Daily Nutrition Goals?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * scale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: recommendedTop,
                left: 0,
                right: 0,
                child: Text(
                  'Recommended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (20 * scale).clamp(16.0, 26.0),
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Column(
                    children: [
                      ..._goalItems.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(
                            bottom: item == _goalItems.last ? 0 : cardGap,
                          ),
                          child: _buildNutritionGoalCard(
                            item: item,
                            valueController: _goalValueControllers[item.label]!,
                            scale: scale,
                            contentWidth: contentWidth,
                            cardHeight: cardHeight,
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleAdvance,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Advance',
                              style: TextStyle(
                                fontSize: (32 * scale / 1.7).clamp(18.0, 28.0),
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(
                              _isAdvanceOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: (24 * scale).clamp(20.0, 30.0),
                            ),
                          ],
                        ),
                      ),
                      if (_isAdvanceOpen) ...[
                        SizedBox(height: 16 * scale),
                        ..._advancedGoalItems.map(
                          (item) => Padding(
                            padding: EdgeInsets.only(
                              bottom: item == _advancedGoalItems.last
                                  ? 0
                                  : cardGap,
                            ),
                            child: _buildNutritionGoalCard(
                              item: item,
                              valueController:
                                  _goalValueControllers[item.label]!,
                              scale: scale,
                              contentWidth: contentWidth,
                              cardHeight: cardHeight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
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
                        scale: scale,
                        height: controlsRowHeight,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: scale,
                        height: controlsRowHeight,
                        borderRadius: 32 * scale,
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
                                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * scale).clamp(20.0, 28.0),
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

class DailyHydrationGoalsScreen extends StatefulWidget {
  const DailyHydrationGoalsScreen({super.key});

  @override
  State<DailyHydrationGoalsScreen> createState() =>
      _DailyHydrationGoalsScreenState();
}

class _DailyHydrationGoalsScreenState extends State<DailyHydrationGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _waterController;
  bool _isHydrationInLiters = true;
  bool _didNavigateForward = false;

  @override
  void initState() {
    super.initState();
    _applyRecommendedHydrationToOnboardingProfile();
    _waterController = TextEditingController(
      text: _OnboardingProfileState.hydrationGoalText,
    );
    _isHydrationInLiters = _OnboardingProfileState.isHydrationInLiters;
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _waterController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(
        screen: const DailyNutritionGoalsScreen(),
        fromLeft: true,
      ),
    );
  }

  void _goToDietPreferences({required bool skippedHydrationSection}) {
    if (_didNavigateForward || !mounted) {
      return;
    }
    _persistHydrationState(
      enabled: !skippedHydrationSection,
      skipped: skippedHydrationSection,
    );
    _didNavigateForward = true;
    FocusScope.of(context).unfocus();
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const DietPreferenceScreen()));
  }

  void _goNext() {
    _goToDietPreferences(skippedHydrationSection: false);
  }

  void _skip() {
    _goToDietPreferences(skippedHydrationSection: true);
  }

  void _persistHydrationState({required bool enabled, required bool skipped}) {
    final goalText = _waterController.text.trim();
    final parsedGoal = _parseFormattedNumber(goalText);
    final hasValue = parsedGoal != null && parsedGoal > 0;
    _OnboardingProfileState.hydrationEnabled = enabled && hasValue;
    _OnboardingProfileState.hydrationGoalText = enabled && hasValue
        ? _formatNumberForField(parsedGoal)
        : '0';
    _OnboardingProfileState.isHydrationInLiters = _isHydrationInLiters;
    _OnboardingSkipFlags.skippedWaterSection = skipped || !enabled || !hasValue;
  }

  double? _parseFormattedNumber(String input) {
    final normalized = input.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _formatNumberForField(double value) {
    final isNegative = value < 0;
    final absValue = value.abs();
    final whole = absValue.truncate();
    final decimal = absValue - whole;
    final formattedWhole = _IndianNumberInputFormatter._formatIndianInteger(
      whole.toString(),
    );

    if (decimal < 0.0001) {
      return isNegative ? '-$formattedWhole' : formattedWhole;
    }

    String frac = absValue.toStringAsFixed(2).split('.').last;
    frac = frac.replaceFirst(RegExp(r'0+$'), '');
    final combined = '$formattedWhole.$frac';
    return isNegative ? '-$combined' : combined;
  }

  void _setHydrationUnit(bool isLiters) {
    if (_isHydrationInLiters == isLiters || !mounted) {
      return;
    }
    final currentValue = _parseFormattedNumber(_waterController.text);
    setState(() {
      _isHydrationInLiters = isLiters;
      if (currentValue != null) {
        final converted = isLiters
            ? currentValue / _ouncesPerLiter
            : currentValue * _ouncesPerLiter;
        final nextText = _formatNumberForField(converted);
        _waterController.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      }
    });
  }

  Widget _buildHydrationCard({
    required double scale,
    required double contentWidth,
    required double cardHeight,
  }) {
    return SizedBox(
      width: contentWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          color: const Color(0x2EFFFFFF),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (16 * scale).clamp(12.0, 20.0).toDouble(),
          vertical: (12 * scale).clamp(8.0, 16.0).toDouble(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Water',
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: (140 * scale).clamp(130.0, 170.0).toDouble(),
              height: (56 * scale).clamp(48.0, 60.0).toDouble(),
              child: _EditableNutritionValueField(
                scale: scale,
                controller: _waterController,
                fontSize: (24 * scale).clamp(18.0, 30.0),
              ),
            ),
            SizedBox(width: 8 * scale),
            SizedBox(
              width: 60 * scale,
              height: 25 * scale,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  _isHydrationInLiters ? 'Liters (l)' : 'oz',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 18.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (15 * scale) + (30 * scale);
          final recommendedTop = titleTop + (50 * scale);
          final cardsTop = titleTop + (94 * scale);
          final cardHeight = (80 * scale).clamp(68.0, 96.0);
          final bottomPanelHeight = (190 * scale).clamp(162.0, 220.0);
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final backButtonWidth = 79 * scale;
          final nextButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Daily Hydration Goals?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * scale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: recommendedTop,
                left: 0,
                right: 0,
                child: Text(
                  'Recommended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (20 * scale).clamp(16.0, 26.0),
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Column(
                    children: [
                      _buildHydrationCard(
                        scale: scale,
                        contentWidth: contentWidth,
                        cardHeight: cardHeight,
                      ),
                      SizedBox(height: 16 * scale),
                      _UnitSelectorPill(
                        scale: scale,
                        leftLabel: 'liters',
                        rightLabel: 'oz',
                        fontSize: 16,
                        isLeftSelected: _isHydrationInLiters,
                        onTapLeft: () => _setHydrationUnit(true),
                        onTapRight: () => _setHydrationUnit(false),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom + (56 * scale) + (10 * scale),
                child: Row(
                  children: [
                    SizedBox(width: backButtonWidth + (16 * scale)),
                    SizedBox(
                      width: nextButtonWidth,
                      child: Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _skip,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 2 * scale,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: (20 * scale).clamp(16.0, 24.0),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: (24 * scale).clamp(20.0, 28.0),
                                ),
                              ],
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
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
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
                                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * scale).clamp(20.0, 28.0),
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

class DietPreferenceScreen extends StatefulWidget {
  const DietPreferenceScreen({super.key});

  @override
  State<DietPreferenceScreen> createState() => _DietPreferenceScreenState();
}

class _DietPreferenceScreenState extends State<DietPreferenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;
  bool _didNavigateForward = false;
  bool get _canContinue => _selectedIndex != null;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _OnboardingProfileState.selectedDietPreferenceIndex
        .clamp(0, _dietPreferenceOptions.length - 1)
        .toInt();
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

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildSwipeRoute(
        screen: const DailyHydrationGoalsScreen(),
        fromLeft: true,
      ),
    );
  }

  void _goNext() {
    if (!_canContinue || _didNavigateForward || !mounted) {
      return;
    }
    _OnboardingProfileState.selectedDietPreferenceIndex = _selectedIndex!
        .clamp(0, _dietPreferenceOptions.length - 1)
        .toInt();
    _didNavigateForward = true;
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const YouAreReadyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (15 * scale) + (30 * scale);
          final cardsTop = titleTop + (94 * scale);
          final cardWidth = 171 * scale;
          final cardHeight = 141 * scale;
          final bottomPanelHeight = (190 * scale).clamp(162.0, 220.0);
          final contentBottomInset = (56 * scale).clamp(40.0, 72.0);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final backButtonWidth = 79 * scale;
          final nextButtonWidth = 263 * scale;

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Text(
                  'Diet Preference?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Borel',
                    fontSize: (32 * scale).clamp(24.0, 42.0),
                    color: Colors.white,
                    height: 0.99,
                  ),
                ),
              ),
              Positioned(
                top: cardsTop,
                left: contentLeft,
                width: contentWidth,
                bottom: contentBottomInset,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPanelHeight + (16 * scale),
                  ),
                  child: Wrap(
                    spacing: 16 * scale,
                    runSpacing: 16 * scale,
                    children: List<Widget>.generate(
                      _dietPreferenceOptions.length,
                      (index) {
                        final option = _dietPreferenceOptions[index];
                        return _DietPreferenceCard(
                          scale: scale,
                          width: cardWidth,
                          height: cardHeight,
                          label: option.label,
                          imagePath: option.imagePath,
                          isSelected: _selectedIndex == index,
                          onTap: () {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _selectedIndex = _selectedIndex == index
                                  ? null
                                  : index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
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
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    SizedBox(
                      width: nextButtonWidth,
                      child: _RotatingGlassButton(
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: _canContinue
                            ? const Color(0x8FFFD206)
                            : const Color(0x14FFD206),
                        enablePressShadeFeedback: _canContinue,
                        onTap: _canContinue ? _goNext : () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: (24 * scale).clamp(20.0, 28.0),
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

class YouAreReadyScreen extends StatefulWidget {
  const YouAreReadyScreen({super.key});

  @override
  State<YouAreReadyScreen> createState() => _YouAreReadyScreenState();
}

class _YouAreReadyScreenState extends State<YouAreReadyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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

  void _goNext() {
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(_buildSwipeRoute(screen: const DailyProgressScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final visualTop = metrics.padding.top + (68 * scale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );

          return Stack(
            children: [
              Positioned(
                top: visualTop,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SizedBox(
                      width: 200 * scale,
                      height: 275 * scale,
                      child: Image.asset(
                        "assets/You'are_ready.png",
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            color: const Color(0x80000000),
                            size: 36 * scale,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 32 * scale),
                    Text(
                      'You’re Ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: (32 * scale).clamp(24.0, 42.0),
                        color: Colors.white,
                        height: 0.99,
                      ),
                    ),
                    SizedBox(height: 46 * scale),
                    SizedBox(
                      width: 288 * scale,
                      child: Text(
                        'Start tracking your meals',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (24 * scale).clamp(18.0, 30.0),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
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
                child: _RotatingGlassButton(
                  scale: scale,
                  height: 56 * scale,
                  borderRadius: 32 * scale,
                  fillColor: const Color(0x8FFFD206),
                  enablePressShadeFeedback: true,
                  onTap: _goNext,
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
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

class DailyProgressScreen extends StatefulWidget {
  const DailyProgressScreen({
    super.key,
    this.initialSelectedBottomNavIndex = 0,
  });

  final int initialSelectedBottomNavIndex;

  @override
  State<DailyProgressScreen> createState() => _DailyProgressScreenState();
}

class _DailyProgressScreenState extends State<DailyProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedBottomNavIndex = 0;
  bool _isAdvanceOpen = false;
  bool _isMealsTimelineEditMode = false;
  bool _isHistoryViewOpen = false;
  DateTime _historySelectedDate = _MealsTimelineStore.today;

  @override
  void initState() {
    super.initState();
    _selectedBottomNavIndex = widget.initialSelectedBottomNavIndex.clamp(0, 3);
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

  void _toggleAdvance() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdvanceOpen = !_isAdvanceOpen;
    });
  }

  void _toggleMealsTimelineEditMode() {
    if (!mounted) {
      return;
    }
    if (_isHistoryViewOpen && !_isHistoryDateEditable(_historySelectedDate)) {
      return;
    }
    setState(() {
      _isMealsTimelineEditMode = !_isMealsTimelineEditMode;
    });
  }

  bool _isHistoryDateEditable(DateTime date) {
    final earliestEditableDate = _MealsTimelineStore.today.subtract(
      const Duration(days: 1),
    );
    return !_dateOnly(date).isBefore(_dateOnly(earliestEditableDate));
  }

  void _openHistoryView() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isHistoryViewOpen = true;
      _historySelectedDate = _MealsTimelineStore.today;
      _isMealsTimelineEditMode = false;
    });
  }

  void _closeHistoryView() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isHistoryViewOpen = false;
      _historySelectedDate = _MealsTimelineStore.today;
      _isMealsTimelineEditMode = false;
    });
  }

  void _shiftHistoryDateByDays(int dayDelta) {
    if (!_isHistoryViewOpen || !mounted || dayDelta == 0) {
      return;
    }
    final today = _MealsTimelineStore.today;
    final shiftedDate = _dateOnly(
      _historySelectedDate.add(Duration(days: dayDelta)),
    );
    final nextDate = shiftedDate.isAfter(today) ? today : shiftedDate;
    setState(() {
      _historySelectedDate = nextDate;
      _isMealsTimelineEditMode = false;
    });
  }

  Future<void> _openHistoryDatePicker() async {
    if (!_isHistoryViewOpen || !mounted) {
      return;
    }
    final today = _MealsTimelineStore.today;
    final pickedDate = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (dialogContext) {
        return _HistoryCalendarDialog(
          initialDate: _historySelectedDate,
          firstDate: DateTime(today.year - 5, 1, 1),
          lastDate: today,
        );
      },
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    setState(() {
      _historySelectedDate = _dateOnly(pickedDate);
      _isMealsTimelineEditMode = false;
    });
  }

  void _deleteMealsTimelineEntry(int id) {
    if (!mounted) {
      return;
    }
    setState(() {
      _MealsTimelineStore.removeById(id);
      if (_MealsTimelineStore.entries.isEmpty) {
        _isMealsTimelineEditMode = false;
      }
    });
  }

  Future<void> _confirmDeleteMealsTimelineEntry(
    _MealTimelineEntry entry,
  ) async {
    if (!mounted) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext);
        final dialogScale = (media.size.width / 393).clamp(0.82, 1.0);
        final dialogTopGap = 30 * dialogScale;
        final dialogBottomGap = 16 * dialogScale;
        final dialogWidth = math.min(
          322 * dialogScale,
          media.size.width - (32 * dialogScale),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 24 * dialogScale,
                      sigmaY: 24 * dialogScale,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: dialogWidth,
                  padding: EdgeInsets.fromLTRB(
                    16 * dialogScale,
                    0,
                    16 * dialogScale,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x8FFFFFFF),
                    borderRadius: BorderRadius.circular(16 * dialogScale),
                    border: Border.all(
                      color: const Color(0x7AFFFFFF),
                      width: (2 * dialogScale).clamp(1.0, 2.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: dialogTopGap),
                      Text(
                        'Delete Entry',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Borel',
                          fontSize: (32 * dialogScale).clamp(24.0, 34.0),
                          color: Colors.white,
                          height: 0.99,
                        ),
                      ),
                      SizedBox(height: 22 * dialogScale),
                      Text(
                        entry.timeText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (14 * dialogScale).clamp(12.0, 16.0),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8 * dialogScale),
                      Text(
                        '${entry.itemName}\n( ${entry.caloriesText} Kcal )',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (14 * dialogScale).clamp(12.0, 16.0),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 16 * dialogScale),
                      Row(
                        children: [
                          Expanded(
                            child: _RotatingGlassButton(
                              scale: dialogScale,
                              height: 56 * dialogScale,
                              borderRadius: 32 * dialogScale,
                              fillColor: Colors.white,
                              enablePressShadeFeedback: true,
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: _defaultNonBorelFontFamily,
                                  color: const Color(0xFFFFD206),
                                  fontSize: (34 * dialogScale / 1.7).clamp(
                                    18.0,
                                    24.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * dialogScale),
                          Expanded(
                            child: _RotatingGlassButton(
                              scale: dialogScale,
                              height: 56 * dialogScale,
                              borderRadius: 32 * dialogScale,
                              fillColor: const Color(0x8FFF0606),
                              enablePressShadeFeedback: true,
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontFamily: _defaultNonBorelFontFamily,
                                  color: Colors.white,
                                  fontSize: (34 * dialogScale / 1.7).clamp(
                                    18.0,
                                    24.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dialogBottomGap),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true) {
      _deleteMealsTimelineEntry(entry.id);
    }
  }

  void _openExchangeEntryScreen(int mealEntryId) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: TodaysEntryScreen(
          isExchangeEntry: true,
          exchangeTargetEntryId: mealEntryId,
        ),
      ),
    );
  }

  int _parseMealCalories(String rawCalories) {
    final parsed = double.tryParse(rawCalories.trim().replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 0;
    }
    if (parsed < 0) {
      return 0;
    }
    return parsed.round();
  }

  double _parseNumericText(String rawValue) {
    final cleaned = rawValue.trim().replaceAll(',', '').replaceAll(' ', '');
    if (cleaned.isEmpty) {
      return 0;
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 0;
    }
    return parsed;
  }

  String _formatWholeMetric(double value) {
    final rounded = value.round();
    if (rounded <= 0) {
      return '0';
    }
    return _formatGroupedWholeNumber(rounded);
  }

  String _formatCompactDecimalMetric(double value, {int maxDecimals = 2}) {
    if (value <= 0) {
      return '0';
    }
    return value
        .toStringAsFixed(maxDecimals)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatCurrencyAmount(double value) {
    if (value <= 0) {
      return '0';
    }
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return _formatGroupedWholeNumber(rounded.round());
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double _waterLitersFromEntry(_MealTimelineEntry entry) {
    final direct = _parseNumericText(entry.waterLitersText);
    if (direct > 0) {
      return direct;
    }
    final literMatch = RegExp(
      r'water\s*\(\s*([0-9]+(?:\.[0-9]+)?)\s*l\s*\)',
      caseSensitive: false,
    ).firstMatch(entry.itemName);
    if (literMatch != null) {
      return _parseNumericText(literMatch.group(1) ?? '0');
    }
    final ounceMatch = RegExp(
      r'water\s*\(\s*([0-9]+(?:\.[0-9]+)?)\s*oz\s*\)',
      caseSensitive: false,
    ).firstMatch(entry.itemName);
    if (ounceMatch != null) {
      return _parseNumericText(ounceMatch.group(1) ?? '0') / _ouncesPerLiter;
    }
    return 0;
  }

  String _percentText(double current, double target) {
    if (target <= 0) {
      return '0 %';
    }
    final percent = ((current / target) * 100).clamp(0, 999);
    return '${percent.round()} %';
  }

  double _progressFraction(double current, double target) {
    if (target <= 0) {
      return 0;
    }
    return (current / target).clamp(0.0, 1.0);
  }

  Future<void> _openMealsTimelineItemDetails(_MealTimelineEntry entry) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: _SearchFoodItemDetailsScreen(
          item: _DailyFoodCatalogItem(
            id: -entry.id,
            name: entry.itemName,
            caloriesKcal: _parseMealCalories(entry.caloriesText),
          ),
          isExchangeEntry: true,
          exchangeTargetEntryId: entry.id,
          initialItemName: entry.itemName,
          initialCaloriesText: entry.caloriesText,
          initialProteinText: entry.proteinText,
          initialCarbohydratesText: entry.carbohydratesText,
          initialFatText: entry.fatText,
          initialFiberText: entry.fiberText,
          initialSugarText: entry.sugarText,
          initialSodiumText: entry.sodiumText,
          initialBudgetText: entry.budgetAmountText,
          initialTimeText: entry.timeText,
          showAddToCustom: false,
          timelineActionLabelOverride: 'Save',
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _goToAccountPage() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(
        screen: AccountScreen(
          skippedBudgetSection: _OnboardingSkipFlags.skippedBudgetSection,
          skippedWaterSection: _OnboardingSkipFlags.skippedWaterSection,
        ),
      ),
    );
  }

  void _openTodaysEntryScreen() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(screen: const TodaysEntryScreen()),
    );
  }

  void _openBellyoAiScreen() {
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).push(_buildNoTransitionRoute(screen: const BellyoAssistantScreen()));
  }

  Widget _sectionTitle(String title, double scale) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Borel',
        fontSize: (32 * scale).clamp(24.0, 40.0),
        color: Colors.white,
        height: 0.99,
      ),
    );
  }

  Widget _outerPanel({required double scale, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x29FFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      padding: EdgeInsets.all(8 * scale),
      child: child,
    );
  }

  Widget _innerPanel({
    required double scale,
    required Widget child,
    double? height,
  }) {
    final panel = _RotatingGlassPanel(
      scale: scale,
      borderRadius: 16 * scale,
      fillColor: const Color(0x52FFFFFF),
      padding: EdgeInsets.all(8 * scale),
      enableBlur: false,
      lightLengthMultiplier: 18.0,
      child: child,
    );

    if (height == null) {
      return panel;
    }

    return SizedBox(height: height, child: panel);
  }

  Widget _metricBlock({
    required double scale,
    required String label,
    required Color accentColor,
    required String totalValueText,
    String percentText = '0 %',
    String currentText = '0',
    double progressFraction = 0.0,
    bool highlightCurrent = true,
  }) {
    final clampedProgress = progressFraction.clamp(0.0, 1.0);
    final transparentStart = (clampedProgress + 0.0001).clamp(0.0, 1.0);
    return _innerPanel(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: (14 * scale).clamp(12.0, 16.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                percentText,
                style: TextStyle(
                  fontSize: (14 * scale).clamp(12.0, 16.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Container(
            width: double.infinity,
            height: 14 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: Colors.white, width: 1 * scale),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, clampedProgress, transparentStart, 1.0],
                colors: [
                  accentColor,
                  accentColor,
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Align(
            alignment: Alignment.centerRight,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: (14 * scale).clamp(12.0, 16.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: currentText,
                    style: TextStyle(
                      color: highlightCurrent ? Colors.white : Colors.black,
                    ),
                  ),
                  TextSpan(text: ' / $totalValueText'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIconTile({
    required double scale,
    required IconData icon,
    bool selected = false,
  }) {
    return SizedBox(
      width: 48 * scale,
      height: 48 * scale,
      child: _RotatingGlassPanel(
        scale: scale,
        borderRadius: 15 * scale,
        fillColor: selected ? Colors.white : const Color(0x52FFFFFF),
        padding: EdgeInsets.zero,
        expandToBounds: true,
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0xFFFF0000),
                  blurRadius: 4,
                  blurStyle: BlurStyle.outer,
                ),
              ]
            : const <BoxShadow>[],
        enableBlur: false,
        child: Center(
          child: Icon(
            icon,
            color: selected ? Colors.black : Colors.white,
            size: 28 * scale,
          ),
        ),
      ),
    );
  }

  Widget _historyArrowButton({
    required double scale,
    required String assetPath,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return SizedBox(
      width: 56 * scale,
      height: 56 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.45,
          child: _RotatingGlassPanel(
            scale: scale,
            borderRadius: 32 * scale,
            fillColor: const Color(0x8FFFFFFF),
            padding: EdgeInsets.zero,
            expandToBounds: true,
            enableBlur: false,
            child: Center(
              child: SizedBox(
                width: 18 * scale,
                height: 18 * scale,
                child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyDatePill({
    required double scale,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 56 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 32 * scale,
          fillColor: const Color(0x52FFFFFF),
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          expandToBounds: true,
          enableBlur: false,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (20 * scale).clamp(16.0, 24.0),
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavIconButton({
    required double scale,
    required int index,
    required String assetPath,
  }) {
    final isSelected = _selectedBottomNavIndex == index;
    return SizedBox(
      width: 48 * scale,
      height: 48 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!mounted) {
            return;
          }
          if (index == 2) {
            _goToAccountPage();
            return;
          }
          if (index == 3) {
            _openTodaysEntryScreen();
            return;
          }
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 15 * scale,
          fillColor: isSelected ? Colors.white : const Color(0x52FFFFFF),
          padding: EdgeInsets.zero,
          expandToBounds: true,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFFFF0000),
                    blurRadius: 4,
                    blurStyle: BlurStyle.outer,
                  ),
                ]
              : const <BoxShadow>[],
          enableBlur: false,
          child: Center(
            child: SizedBox(
              width: 30 * scale,
              height: 30 * scale,
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  isSelected ? _bottomNavActiveIconColor : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealsTimelineEditButton({
    required double scale,
    bool showAddIcon = false,
  }) {
    return SizedBox(
      width: 48 * scale,
      height: 48 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: showAddIcon
            ? _openTodaysEntryScreen
            : _toggleMealsTimelineEditMode,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: const Color(0x4CFFFFFF),
          padding: EdgeInsets.all(12 * scale),
          expandToBounds: true,
          boxShadow: const <BoxShadow>[],
          enableBlur: false,
          child: showAddIcon
              ? Image.asset(
                  'assets/Add.png',
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.add,
                      color: Colors.white,
                      size: (20 * scale).clamp(16.0, 24.0),
                    );
                  },
                )
              : SvgPicture.asset(
                  'assets/Edit_food.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMealsTimelineActionButton({
    required double scale,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32 * scale,
      height: 32 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 9 * scale,
          fillColor: const Color(0x8FFFFFFF),
          padding: EdgeInsets.all(6 * scale),
          expandToBounds: true,
          boxShadow: const <BoxShadow>[],
          enableBlur: false,
          child: child,
        ),
      ),
    );
  }

  Widget _buildMealsTimelineViewEntries({
    required double scale,
    required List<_MealTimelineEntry> entries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(entries.length, (index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.timeText,
                style: TextStyle(
                  fontFamily: _defaultNonBorelFontFamily,
                  fontSize: (14 * scale).clamp(12.0, 16.0),
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6 * scale, right: 8 * scale),
                    child: Container(
                      width: 6 * scale,
                      height: 6 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0x99FFFFFF),
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.itemName,
                          style: TextStyle(
                            fontFamily: _defaultNonBorelFontFamily,
                            fontSize: (14 * scale).clamp(12.0, 16.0),
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '( ${entry.caloriesText} Kcal )',
                          style: TextStyle(
                            fontFamily: _defaultNonBorelFontFamily,
                            fontSize: (14 * scale).clamp(12.0, 16.0),
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMealsTimelineEditEntries({
    required double scale,
    required List<_MealTimelineEntry> entries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(entries.length, (index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: const Color(0x52FFFFFF),
                  borderRadius: BorderRadius.circular(16 * scale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.timeText,
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (14 * scale).clamp(12.0, 16.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${entry.itemName}\n( ${entry.caloriesText} Kcal )',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (14 * scale).clamp(12.0, 16.0),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Row(
                          children: [
                            _buildMealsTimelineActionButton(
                              scale: scale,
                              onTap: () => _openExchangeEntryScreen(entry.id),
                              child: SizedBox(
                                width: 16 * scale,
                                height: 17 * scale,
                                child: SvgPicture.asset(
                                  'assets/Food__exchange.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            _buildMealsTimelineActionButton(
                              scale: scale,
                              onTap: () => _openMealsTimelineItemDetails(entry),
                              child: SvgPicture.asset(
                                'assets/Edit_food.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            _buildMealsTimelineActionButton(
                              scale: scale,
                              onTap: () =>
                                  _confirmDeleteMealsTimelineEntry(entry),
                              child: SvgPicture.asset(
                                'assets/Delete.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8 * scale),
                    child: Container(
                      width: 6 * scale,
                      height: 6 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0x99FFFFFF),
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (18 * scale);
          final contentTop =
              titleTop + ((_isHistoryViewOpen ? 74 : 66) * scale);
          final isIPhone =
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              math.min(metrics.width, metrics.height) < 600;
          final controlsBottom = isIPhone
              ? metrics.padding.bottom
              : math.max(66 * scale, metrics.padding.bottom + (26 * scale));
          final navHeight = 64 * scale;
          final blurPanelHeight = navHeight + controlsBottom;
          final showFloatingBanana = !_isHistoryViewOpen;
          final bananaTopInset = controlsBottom + (74 * scale) + (99 * scale);
          final scrollTopPadding = (_isHistoryViewOpen ? 18 : 14) * scale;
          final scrollBottomPadding = showFloatingBanana
              ? math.max(
                  blurPanelHeight + (24 * scale),
                  bananaTopInset + (16 * scale),
                )
              : blurPanelHeight + (24 * scale);
          final hideWaterSection = _OnboardingSkipFlags.skippedWaterSection;
          final hideBudgetSection = _OnboardingSkipFlags.skippedBudgetSection;
          final hideMealsTimelineSection =
              hideWaterSection || hideBudgetSection;
          final todayDate = _MealsTimelineStore.today;
          final selectedProgressDate = _isHistoryViewOpen
              ? _historySelectedDate
              : todayDate;
          final isViewingToday = _isSameDate(selectedProgressDate, todayDate);
          final progressSectionTitle = isViewingToday
              ? 'Daily Progress'
              : 'Progress';
          final isHistoryDateEditable = _isHistoryDateEditable(
            selectedProgressDate,
          );
          final mealsTimelineEntries = _MealsTimelineStore.entriesForDate(
            selectedProgressDate,
          );
          final nutritionTargets = _OnboardingProfileState.nutritionGoalValues;
          final advancedNutritionTargets =
              _OnboardingProfileState.advancedNutritionGoalValues;
          final targetCalories = _parseNumericText(
            nutritionTargets['Calories'] ?? '0',
          );
          final targetProtein = _parseNumericText(
            nutritionTargets['Protein'] ?? '0',
          );
          final targetCarbohydrates = _parseNumericText(
            nutritionTargets['Carbohydrates'] ?? '0',
          );
          final targetFat = _parseNumericText(nutritionTargets['Fat'] ?? '0');
          final targetFiber = _parseNumericText(
            advancedNutritionTargets['Fiber'] ?? '0',
          );
          final targetSugar = _parseNumericText(
            advancedNutritionTargets['Sugar'] ?? '0',
          );
          final targetSodium = _parseNumericText(
            advancedNutritionTargets['Sodium'] ?? '0',
          );
          final hydrationUnitIsLiters =
              _OnboardingProfileState.isHydrationInLiters;
          final targetHydrationInputValue =
              _OnboardingProfileState.hydrationEnabled
              ? _parseNumericText(_OnboardingProfileState.hydrationGoalText)
              : 0.0;
          final targetWaterLiters = hydrationUnitIsLiters
              ? targetHydrationInputValue
              : (targetHydrationInputValue / _ouncesPerLiter);
          final budgetCurrencyGlyph =
              _budgetCurrencyGlyphByCode[_OnboardingProfileState
                  .budgetCurrencyCode] ??
              _OnboardingProfileState.budgetCurrencyCode;
          final chosenBudgetRaw = _OnboardingProfileState.isCustomBudgetPerMeal
              ? _OnboardingProfileState.customBudgetPerMeal
              : (_OnboardingProfileState.selectedBudgetPerMeal?.toString() ??
                    '0');
          final chosenBudgetTarget = _OnboardingProfileState.budgetEnabled
              ? _parseNumericText(chosenBudgetRaw)
              : 0.0;

          double consumedCalories = 0;
          double consumedProtein = 0;
          double consumedCarbohydrates = 0;
          double consumedFat = 0;
          double consumedFiber = 0;
          double consumedSugar = 0;
          double consumedSodium = 0;
          double consumedWaterLiters = 0;
          double consumedBudget = 0;
          for (final entry in mealsTimelineEntries) {
            consumedCalories += _parseNumericText(entry.caloriesText);
            consumedProtein += _parseNumericText(entry.proteinText);
            consumedCarbohydrates += _parseNumericText(entry.carbohydratesText);
            consumedFat += _parseNumericText(entry.fatText);
            consumedFiber += _parseNumericText(entry.fiberText);
            consumedSugar += _parseNumericText(entry.sugarText);
            consumedSodium += _parseNumericText(entry.sodiumText);
            consumedWaterLiters += _waterLitersFromEntry(entry);
            consumedBudget += _parseNumericText(entry.budgetAmountText);
          }

          final displayedWaterCurrent = hydrationUnitIsLiters
              ? consumedWaterLiters
              : consumedWaterLiters * _ouncesPerLiter;
          final displayedWaterTarget = hydrationUnitIsLiters
              ? targetWaterLiters
              : targetWaterLiters * _ouncesPerLiter;
          final waterUnitLabel = hydrationUnitIsLiters ? 'l' : 'oz';
          final waterTotalText =
              '${_formatCompactDecimalMetric(displayedWaterTarget, maxDecimals: 2)} $waterUnitLabel';
          final waterCurrentText = _formatCompactDecimalMetric(
            displayedWaterCurrent,
            maxDecimals: 2,
          );

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: contentTop,
                bottom: 0,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    contentLeft,
                    scrollTopPadding,
                    contentLeft,
                    scrollBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isHistoryViewOpen) ...[
                        _sectionTitle(progressSectionTitle, scale),
                        SizedBox(height: 8 * scale),
                      ],
                      _outerPanel(
                        scale: scale,
                        child: Column(
                          children: [
                            if (!hideWaterSection) ...[
                              _metricBlock(
                                scale: scale,
                                label: 'Water',
                                accentColor: const Color(0xFFDEF4FC),
                                totalValueText: waterTotalText,
                                currentText: waterCurrentText,
                                percentText: _percentText(
                                  consumedWaterLiters,
                                  targetWaterLiters,
                                ),
                                progressFraction: _progressFraction(
                                  consumedWaterLiters,
                                  targetWaterLiters,
                                ),
                                highlightCurrent: false,
                              ),
                              SizedBox(height: 8 * scale),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: _metricBlock(
                                    scale: scale,
                                    label: 'Calories',
                                    accentColor: const Color(0xFFFF8341),
                                    totalValueText:
                                        '${_formatWholeMetric(targetCalories)} Kcal',
                                    currentText: _formatWholeMetric(
                                      consumedCalories,
                                    ),
                                    percentText: _percentText(
                                      consumedCalories,
                                      targetCalories,
                                    ),
                                    progressFraction: _progressFraction(
                                      consumedCalories,
                                      targetCalories,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                Expanded(
                                  child: _metricBlock(
                                    scale: scale,
                                    label: 'Protein',
                                    accentColor: const Color(0xFF41A0FF),
                                    totalValueText:
                                        '${_formatWholeMetric(targetProtein)} g',
                                    currentText: _formatWholeMetric(
                                      consumedProtein,
                                    ),
                                    percentText: _percentText(
                                      consumedProtein,
                                      targetProtein,
                                    ),
                                    progressFraction: _progressFraction(
                                      consumedProtein,
                                      targetProtein,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8 * scale),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricBlock(
                                    scale: scale,
                                    label: 'Carbohydrates',
                                    accentColor: const Color(0xFFC940FF),
                                    totalValueText:
                                        '${_formatWholeMetric(targetCarbohydrates)} g',
                                    currentText: _formatWholeMetric(
                                      consumedCarbohydrates,
                                    ),
                                    percentText: _percentText(
                                      consumedCarbohydrates,
                                      targetCarbohydrates,
                                    ),
                                    progressFraction: _progressFraction(
                                      consumedCarbohydrates,
                                      targetCarbohydrates,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                Expanded(
                                  child: _metricBlock(
                                    scale: scale,
                                    label: 'Fat',
                                    accentColor: const Color(0xFFFFE241),
                                    totalValueText:
                                        '${_formatWholeMetric(targetFat)} g',
                                    currentText: _formatWholeMetric(
                                      consumedFat,
                                    ),
                                    percentText: _percentText(
                                      consumedFat,
                                      targetFat,
                                    ),
                                    progressFraction: _progressFraction(
                                      consumedFat,
                                      targetFat,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16 * scale),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleAdvance,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Advance',
                                      style: TextStyle(
                                        fontSize: (20 * scale).clamp(
                                          16.0,
                                          24.0,
                                        ),
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
                                    Icon(
                                      _isAdvanceOpen
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: (26 * scale).clamp(20.0, 32.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isAdvanceOpen) ...[
                              SizedBox(height: 16 * scale),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricBlock(
                                      scale: scale,
                                      label: 'Fiber',
                                      accentColor: const Color(0xFFF3E5AB),
                                      totalValueText:
                                          '${_formatWholeMetric(targetFiber)} g',
                                      currentText: _formatWholeMetric(
                                        consumedFiber,
                                      ),
                                      percentText: _percentText(
                                        consumedFiber,
                                        targetFiber,
                                      ),
                                      progressFraction: _progressFraction(
                                        consumedFiber,
                                        targetFiber,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Expanded(
                                    child: _metricBlock(
                                      scale: scale,
                                      label: 'Sodium',
                                      accentColor: Colors.white,
                                      totalValueText:
                                          '${_formatWholeMetric(targetSodium)} mg',
                                      currentText: _formatWholeMetric(
                                        consumedSodium,
                                      ),
                                      percentText: _percentText(
                                        consumedSodium,
                                        targetSodium,
                                      ),
                                      progressFraction: _progressFraction(
                                        consumedSodium,
                                        targetSodium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8 * scale),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: (167 * scale).clamp(140.0, 220.0),
                                  child: _metricBlock(
                                    scale: scale,
                                    label: 'Sugar',
                                    accentColor: const Color(0xFFFF4144),
                                    totalValueText:
                                        '${_formatWholeMetric(targetSugar)} g',
                                    currentText: _formatWholeMetric(
                                      consumedSugar,
                                    ),
                                    percentText: _percentText(
                                      consumedSugar,
                                      targetSugar,
                                    ),
                                    progressFraction: _progressFraction(
                                      consumedSugar,
                                      targetSugar,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!hideBudgetSection) ...[
                        SizedBox(height: 30 * scale),
                        _sectionTitle("Today’s Budget", scale),
                        SizedBox(height: 8 * scale),
                        _outerPanel(
                          scale: scale,
                          child: _metricBlock(
                            scale: scale,
                            label: 'Spent Today',
                            accentColor: const Color(0xFF00A814),
                            totalValueText:
                                '$budgetCurrencyGlyph ${_formatCurrencyAmount(chosenBudgetTarget)}',
                            currentText:
                                '$budgetCurrencyGlyph ${_formatCurrencyAmount(consumedBudget)}',
                            percentText: _percentText(
                              consumedBudget,
                              chosenBudgetTarget,
                            ),
                            progressFraction: _progressFraction(
                              consumedBudget,
                              chosenBudgetTarget,
                            ),
                          ),
                        ),
                      ],
                      if (!_isHistoryViewOpen) ...[
                        SizedBox(height: 30 * scale),
                        _sectionTitle('Bellyo Suggestion', scale),
                        SizedBox(height: 8 * scale),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openBellyoAiScreen,
                          child: _outerPanel(
                            scale: scale,
                            child: _innerPanel(
                              scale: scale,
                              height: 88,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'Your source for expert nutrition tips and covering healthy recipes, cooking hacks.',
                                        style: TextStyle(
                                          fontSize: (14 * scale).clamp(
                                            12.0,
                                            16.0,
                                          ),
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: (18 * scale).clamp(14.0, 22.0),
                                    height: (18 * scale).clamp(14.0, 22.0),
                                    child: SvgPicture.asset(
                                      'assets/Chat.svg',
                                      fit: BoxFit.contain,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!hideMealsTimelineSection) ...[
                        SizedBox(height: 30 * scale),
                        _sectionTitle('Meals Timeline', scale),
                        SizedBox(height: 8 * scale),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x29FFFFFF),
                            borderRadius: BorderRadius.circular(16 * scale),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x3DFFFFFF),
                              borderRadius: BorderRadius.circular(16 * scale),
                            ),
                            child: mealsTimelineEntries.isEmpty
                                ? SizedBox(
                                    height: 72,
                                    child: Row(
                                      mainAxisAlignment: isHistoryDateEditable
                                          ? MainAxisAlignment.spaceBetween
                                          : MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0x66FFFFFF),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'No meals added yet',
                                              style: TextStyle(
                                                fontFamily: 'Nata Sans',
                                                fontSize: 14,
                                                height: 1,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isHistoryDateEditable)
                                          _buildMealsTimelineEditButton(
                                            scale: scale,
                                            showAddIcon: true,
                                          ),
                                      ],
                                    ),
                                  )
                                : (_isMealsTimelineEditMode &&
                                      isHistoryDateEditable)
                                ? _buildMealsTimelineEditEntries(
                                    scale: scale,
                                    entries: mealsTimelineEntries,
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildMealsTimelineViewEntries(
                                          scale: scale,
                                          entries: mealsTimelineEntries,
                                        ),
                                      ),
                                      if (isHistoryDateEditable) ...[
                                        SizedBox(width: 8 * scale),
                                        _buildMealsTimelineEditButton(
                                          scale: scale,
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: titleTop,
                left: contentLeft,
                width: contentWidth,
                child: SizedBox(
                  height: 56 * scale,
                  child: _isHistoryViewOpen
                      ? Row(
                          children: [
                            _historyArrowButton(
                              scale: scale,
                              assetPath: 'assets/Back_arrow.svg',
                              onTap: () => _shiftHistoryDateByDays(-1),
                            ),
                            SizedBox(width: 16 * scale),
                            Expanded(
                              child: _historyDatePill(
                                scale: scale,
                                label: _formatHistoryDateLabel(
                                  selectedProgressDate,
                                ),
                                onTap: _openHistoryDatePicker,
                              ),
                            ),
                            SizedBox(width: 16 * scale),
                            _historyArrowButton(
                              scale: scale,
                              assetPath: 'assets/Front_arrow.svg',
                              onTap: selectedProgressDate.isBefore(todayDate)
                                  ? () => _shiftHistoryDateByDays(1)
                                  : null,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _sectionTitle('Daily Progress', scale),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _openHistoryView,
                              child: Transform.translate(
                                offset: Offset(0, -8 * scale),
                                child: _navIconTile(
                                  scale: scale,
                                  icon: Icons.history,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: blurPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              if (showFloatingBanana)
                Positioned(
                  right: 16 * scale,
                  bottom: controlsBottom + (74 * scale),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openBellyoAiScreen,
                    child: SizedBox(
                      width: 72 * scale,
                      height: 99 * scale,
                      child: Image.asset(
                        'assets/Bellyo_ai.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            color: const Color(0x80000000),
                            size: 36 * scale,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: _isHistoryViewOpen
                    ? _RotatingGlassButton(
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _closeHistoryView,
                        child: SizedBox(
                          width: 18 * scale,
                          height: 18 * scale,
                          child: SvgPicture.asset(
                            'assets/Below_back.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16 * scale),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: _dailyProgressMenuBarBlurSigma,
                                  sigmaY: _dailyProgressMenuBarBlurSigma,
                                ),
                                child: Container(
                                  height: navHeight,
                                  decoration: BoxDecoration(
                                    color: _menuBarBlockFillColor,
                                    borderRadius: BorderRadius.circular(
                                      16 * scale,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(8 * scale),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _bottomNavIconButton(
                                        scale: scale,
                                        index: 0,
                                        assetPath: 'assets/Home_in.svg',
                                      ),
                                      _bottomNavIconButton(
                                        scale: scale,
                                        index: 1,
                                        assetPath: 'assets/Notification_in.svg',
                                      ),
                                      _bottomNavIconButton(
                                        scale: scale,
                                        index: 2,
                                        assetPath: 'assets/Account_in.svg',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16 * scale),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16 * scale),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: _dailyProgressMenuBarBlurSigma,
                                sigmaY: _dailyProgressMenuBarBlurSigma,
                              ),
                              child: Container(
                                width: navHeight,
                                height: navHeight,
                                decoration: BoxDecoration(
                                  color: _menuBarBlockFillColor,
                                  borderRadius: BorderRadius.circular(
                                    16 * scale,
                                  ),
                                ),
                                padding: EdgeInsets.all(8 * scale),
                                child: _bottomNavIconButton(
                                  scale: scale,
                                  index: 3,
                                  assetPath: 'assets/Add_new.svg',
                                ),
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

class BellyoAssistantScreen extends StatefulWidget {
  const BellyoAssistantScreen({super.key});

  @override
  State<BellyoAssistantScreen> createState() => _BellyoAssistantScreenState();
}

class _BellyoAssistantScreenState extends State<BellyoAssistantScreen>
    with SingleTickerProviderStateMixin {
  static const String _assistantSystemPromptBase =
      'You are Bellyo, a practical diet assistant inside a food tracking app. '
      'Answer in a friendly and concise way. '
      'Give realistic food suggestions, simple portion ideas, and budget-aware tips. '
      'If information is missing, ask one short follow-up question. '
      'Do not invent medical facts. '
      'Always respect the user diet preference and avoid suggesting foods outside that preference.';

  late final TextEditingController _promptController;
  late final ScrollController _messageScrollController;
  late final AnimationController _loadingDotsController;
  final List<_BellyoAssistantMessage> _messages = <_BellyoAssistantMessage>[];
  bool _isAsking = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController()..addListener(_handlePromptEdit);
    _messageScrollController = ScrollController();
    _loadingDotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _promptController.removeListener(_handlePromptEdit);
    _promptController.dispose();
    _messageScrollController.dispose();
    _loadingDotsController.dispose();
    super.dispose();
  }

  void _handlePromptEdit() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyPromptSuggestion(String suggestion) {
    _promptController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
  }

  void _startNewChat() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.clear();
      _isAsking = false;
    });
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }
      final offset = _messageScrollController.position.maxScrollExtent;
      _messageScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _buildAssistantSystemPrompt() async {
    final safeDietPreferenceIndex = _OnboardingProfileState
        .selectedDietPreferenceIndex
        .clamp(0, _dietPreferenceOptions.length - 1);
    final dietPreference =
        _dietPreferenceOptions[safeDietPreferenceIndex].label;
    final preferredCountry = _OnboardingProfileState.selectedCountryName.trim();
    final foodContext = await _DailyFoodDatabase.buildAssistantFoodContext(
      selectedDietPreferenceIndex:
          _OnboardingProfileState.selectedDietPreferenceIndex,
      preferredCountry: preferredCountry,
    );
    final promptParts = <String>[
      _assistantSystemPromptBase,
      'User diet preference: $dietPreference.',
    ];
    if (preferredCountry.isNotEmpty) {
      promptParts.add(
        'User preferred country cuisine priority: $preferredCountry.',
      );
    }
    if (foodContext.isNotEmpty) {
      promptParts.add(foodContext);
    }
    return promptParts.join(' ');
  }

  Future<List<Map<String, String>>> _buildApiMessages() async {
    final systemPrompt = await _buildAssistantSystemPrompt();
    final startIndex = _messages.length > _bellyoAssistantHistoryLimit
        ? _messages.length - _bellyoAssistantHistoryLimit
        : 0;
    final history = _messages.sublist(startIndex);
    return <Map<String, String>>[
      <String, String>{'role': 'system', 'content': systemPrompt},
      ...history.map(
        (message) => <String, String>{
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.text,
        },
      ),
    ];
  }

  String _resolveOllamaEndpoint() {
    final configuredEndpoint = _bellyoAssistantOllamaEndpoint.trim();
    if (configuredEndpoint.isNotEmpty) {
      return configuredEndpoint;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:11434/api/chat';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator host-loopback bridge.
        return 'http://10.0.2.2:11434/api/chat';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:11434/api/chat';
    }
  }

  String _extractOllamaReply(Map<String, dynamic>? responseJson) {
    if (responseJson == null) {
      return '';
    }
    final message = responseJson['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
    }
    final content = responseJson['response'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    return '';
  }

  String _buildOfflineDietReply(String prompt) {
    final query = prompt.toLowerCase();
    final hasBudgetIntent =
        query.contains('budget') ||
        query.contains('cheap') ||
        query.contains('under') ||
        query.contains('₹') ||
        query.contains('inr') ||
        query.contains('rupee');
    final hasProteinIntent =
        query.contains('protein') || query.contains('muscle');
    final hasWeightLossIntent =
        query.contains('weight loss') ||
        query.contains('lose weight') ||
        query.contains('low calorie') ||
        query.contains('fat loss');
    final hasHydrationIntent =
        query.contains('water') || query.contains('hydrate');
    final hasMealTimingIntent =
        query.contains('breakfast') ||
        query.contains('lunch') ||
        query.contains('dinner') ||
        query.contains('snack') ||
        query.contains('meal');

    if (hasBudgetIntent && hasProteinIntent) {
      return 'Try these high-protein, low-cost options:\n'
          '1) Moong chilla + curd\n'
          '2) Egg bhurji + 2 rotis\n'
          '3) Soya chunks pulao + salad\n'
          '4) Peanut chaat + buttermilk\n'
          'Target ~20-30g protein per meal.';
    }

    if (hasProteinIntent) {
      return 'Easy protein ideas:\n'
          '1) Breakfast: 2 eggs + milk / paneer sandwich\n'
          '2) Lunch: dal + rice + curd + salad\n'
          '3) Snack: roasted chana + fruit\n'
          '4) Dinner: paneer/tofu/egg curry + roti\n'
          'Aim for protein in every meal.';
    }

    if (hasWeightLossIntent) {
      return 'Simple fat-loss plate method:\n'
          '1) Half plate vegetables\n'
          '2) Quarter plate protein (dal/paneer/egg/chicken)\n'
          '3) Quarter plate carbs (rice/roti)\n'
          '4) Add one fruit and enough water\n'
          'Keep snacks portion-controlled.';
    }

    if (hasHydrationIntent) {
      return 'Hydration plan:\n'
          '1) Start day with 300-500 ml water\n'
          '2) Drink 200-250 ml every 2-3 hours\n'
          '3) Add buttermilk/coconut water once daily\n'
          '4) Extra water around workouts';
    }

    if (hasMealTimingIntent) {
      return 'Balanced day example:\n'
          '1) Breakfast: oats/upma + curd/eggs\n'
          '2) Lunch: dal + rice/roti + sabzi\n'
          '3) Snack: fruit + nuts/chana\n'
          '4) Dinner: light protein + vegetables\n'
          'Keep dinner 2-3 hours before sleep.';
    }

    return 'I can still help with quick diet guidance.\n'
        'Ask like:\n'
        '1) "High protein meal under ₹150"\n'
        '2) "Low calorie dinner ideas"\n'
        '3) "Quick healthy snacks"';
  }

  String _normalizeAssistantReply(String reply) {
    final trimmedReply = reply.trim();
    if (trimmedReply.isEmpty) {
      return 'I did not catch that. Please ask again.';
    }
    return trimmedReply;
  }

  void _appendAssistantReply({required String reply}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(
        _BellyoAssistantMessage(
          role: _BellyoAssistantRole.assistant,
          text: reply,
        ),
      );
      _isAsking = false;
    });
    _scheduleScrollToBottom();
  }

  void _appendAssistantConnectionError({required String endpoint}) {
    _appendAssistantReply(
      reply:
          'I could not connect to local AI at $endpoint.\n'
          'Make sure Ollama is running and this endpoint matches your device type.',
    );
  }

  Future<void> _sendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isAsking) {
      return;
    }

    _promptController.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(
        _BellyoAssistantMessage(role: _BellyoAssistantRole.user, text: prompt),
      );
      _isAsking = true;
    });
    _scheduleScrollToBottom();

    try {
      final endpoint = _resolveOllamaEndpoint();
      final apiMessages = await _buildApiMessages();
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'model': _bellyoAssistantOllamaModel,
              'messages': apiMessages,
              'stream': false,
              'options': <String, dynamic>{'temperature': 0.4},
            }),
          )
          .timeout(const Duration(seconds: 30));

      Map<String, dynamic>? responseJson;
      if (response.body.isNotEmpty) {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          responseJson = parsed;
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Ollama request failed (${response.statusCode}).');
      }

      final reply = _extractOllamaReply(responseJson);
      if (reply.isEmpty) {
        throw Exception('No reply from Ollama.');
      }

      _appendAssistantReply(reply: _normalizeAssistantReply(reply));
    } on TimeoutException {
      final endpoint = _resolveOllamaEndpoint();
      if (_bellyoAssistantEnableOfflineFallback) {
        _appendAssistantReply(reply: _buildOfflineDietReply(prompt));
        return;
      }
      _appendAssistantConnectionError(endpoint: endpoint);
    } catch (_) {
      final endpoint = _resolveOllamaEndpoint();
      if (_bellyoAssistantEnableOfflineFallback) {
        _appendAssistantReply(reply: _buildOfflineDietReply(prompt));
        return;
      }
      _appendAssistantConnectionError(endpoint: endpoint);
    }
  }

  Widget _buildSuggestionChip({
    required double scale,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: const Color(0x52FFFFFF),
          borderRadius: BorderRadius.circular(32 * scale),
          border: Border.all(color: const Color(0x8FFFFFFF), width: 1 * scale),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _defaultNonBorelFontFamily,
            fontSize: (16 * scale).clamp(14.0, 18.0),
            color: Colors.black,
            fontWeight: FontWeight.w400,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionRow({
    required double scale,
    required List<_BellyoQuickPrompt> prompts,
  }) {
    return SizedBox(
      height: 40 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: prompts.length,
        separatorBuilder: (context, index) => SizedBox(width: 8 * scale),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return _buildSuggestionChip(
            scale: scale,
            label: prompt.label,
            onTap: () => _applyPromptSuggestion(prompt.prompt),
          );
        },
      ),
    );
  }

  Widget _buildBellyoLoadingDots({required double scale}) {
    final dotSize = (8 * scale).clamp(6.0, 10.0);
    final spacing = dotSize * 1.35;
    final trackWidth = (dotSize * 3) + (spacing * 2);

    Widget buildStaticDot() {
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
    }

    return SizedBox(
      width: trackWidth,
      height: dotSize,
      child: AnimatedBuilder(
        animation: _loadingDotsController,
        builder: (context, _) {
          final step = (_loadingDotsController.value * 3).floor().clamp(0, 2);
          final yellowLeft = step * (dotSize + spacing);

          return Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildStaticDot(),
                  buildStaticDot(),
                  buildStaticDot(),
                ],
              ),
              Positioned(
                left: yellowLeft,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD206),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatBubble({
    required double scale,
    required _BellyoAssistantMessage message,
    bool isPending = false,
  }) {
    if (isPending) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 10 * scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14 * scale),
                child: Image.asset(
                  'assets/AI_Profile.png',
                  width: 28 * scale,
                  height: 28 * scale,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 8 * scale),
              _buildBellyoLoadingDots(scale: scale),
            ],
          ),
        ),
      );
    }

    final isUser = message.isUser;
    final horizontalInset = 52 * scale;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: isUser ? 280 * scale : 248 * scale),
      margin: EdgeInsets.only(
        left: isUser ? horizontalInset : 0,
        right: isUser ? 0 : horizontalInset,
        bottom: 10 * scale,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0x61FFFFFF) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18 * scale),
          topRight: Radius.circular(18 * scale),
          bottomLeft: Radius.circular(isUser ? 18 * scale : 4 * scale),
          bottomRight: Radius.circular(isUser ? 4 * scale : 18 * scale),
        ),
        border: Border.all(color: const Color(0x8FFFFFFF), width: 1 * scale),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontFamily: _defaultNonBorelFontFamily,
          fontSize: (15 * scale).clamp(13.0, 18.0),
          color: Colors.black,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
      ),
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14 * scale),
            child: Image.asset(
              'assets/AI_Profile.png',
              width: 28 * scale,
              height: 28 * scale,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8 * scale),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildConversationBody({
    required double scale,
    required double bottomInset,
    required EdgeInsets viewPadding,
  }) {
    if (_messages.isEmpty) {
      return Align(
        alignment: const Alignment(0, -0.10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 168 * scale,
                child: Image.asset(
                  'assets/Bellyo_open_page.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              SizedBox(height: 20 * scale),
              Text(
                'Ask me anything about food,\nmeals, calories, or what to eat next.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _defaultNonBorelFontFamily,
                  fontSize: (16 * scale).clamp(14.0, 18.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = _messages.length + (_isAsking ? 1 : 0);
    final topOffset = viewPadding.top + (72 * scale);
    final promptAreaHeight = (204 * scale) + viewPadding.bottom + bottomInset;

    return Positioned.fill(
      top: topOffset,
      left: 0,
      right: 0,
      bottom: 0,
      child: ListView.builder(
        controller: _messageScrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24 * scale,
          16 * scale,
          24 * scale,
          promptAreaHeight + (10 * scale),
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < _messages.length) {
            return _buildChatBubble(scale: scale, message: _messages[index]);
          }
          return _buildChatBubble(
            scale: scale,
            message: const _BellyoAssistantMessage(
              role: _BellyoAssistantRole.assistant,
              text: '',
            ),
            isPending: true,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = (media.size.width / 390).clamp(0.82, 1.08);
    final bottomInset = media.viewInsets.bottom;
    final hasPromptInput = _promptController.text.trim().isNotEmpty;
    final canSendPrompt = hasPromptInput && !_isAsking;
    final hasUserPrompted = _messages.any((message) => message.isUser);
    final firstRowItemCount = (_bellyoAssistantPromptSuggestions.length / 2)
        .ceil();
    final firstRowPrompts = _bellyoAssistantPromptSuggestions
        .take(firstRowItemCount)
        .toList(growable: false);
    final secondRowPrompts = _bellyoAssistantPromptSuggestions
        .skip(firstRowItemCount)
        .toList(growable: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFF8E92),
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFFFF8E92))),
            Positioned(
              bottom: -84 * scale,
              left: -30 * scale,
              right: -30 * scale,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 100 * scale,
                  sigmaY: 100 * scale,
                ),
                child: Container(
                  height: 240 * scale,
                  color: const Color(0xFFFFDC92),
                ),
              ),
            ),
            Positioned(
              top: 92 * scale,
              left: -112 * scale,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 100 * scale,
                  sigmaY: 100 * scale,
                ),
                child: Container(
                  width: 196 * scale,
                  height: 244 * scale,
                  color: const Color(0xFF92EBFF),
                ),
              ),
            ),
            Positioned(
              top: 170 * scale,
              right: -56 * scale,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 50 * scale,
                  sigmaY: 50 * scale,
                ),
                child: Container(
                  width: 195 * scale,
                  height: 244 * scale,
                  color: const Color(0xFFFF7375),
                ),
              ),
            ),
            _buildConversationBody(
              scale: scale,
              bottomInset: bottomInset,
              viewPadding: media.padding,
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: SizedBox(
                  height: 48 * scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, 15 * scale),
                        child: Text(
                          'Bellyo',
                          style: TextStyle(
                            fontFamily: 'Borel',
                            fontSize: (32 * scale).clamp(24.0, 38.0),
                            color: Colors.white,
                            height: 0.99,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 48 * scale,
                          height: 48 * scale,
                          child: _RotatingGlassButton(
                            scale: scale,
                            height: 48 * scale,
                            borderRadius: 24 * scale,
                            fillColor: Colors.white,
                            enablePressShadeFeedback: true,
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: const Color(0xFFFFD206),
                              size: (24 * scale).clamp(20.0, 28.0),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _startNewChat,
                          child: Container(
                            width: 48 * scale,
                            height: 48 * scale,
                            decoration: BoxDecoration(
                              color: const Color(0x29FFFFFF),
                              borderRadius: BorderRadius.circular(16 * scale),
                              border: Border.all(
                                color: const Color(0x8FFFFFFF),
                                width: 1 * scale,
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 34 * scale,
                                height: 25 * scale,
                                child: SvgPicture.asset(
                                  'assets/New_chat.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(color: const Color(0xFFFF8E92)),
                        ),
                        Positioned(
                          bottom: -84 * scale,
                          left: -30 * scale,
                          right: -30 * scale,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 100 * scale,
                              sigmaY: 100 * scale,
                            ),
                            child: Container(
                              height: 240 * scale,
                              color: const Color(0xFFFFDC92),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            10 * scale,
                            0,
                            (8 * scale) + media.padding.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!hasUserPrompted) ...[
                                _buildSuggestionRow(
                                  scale: scale,
                                  prompts: firstRowPrompts,
                                ),
                                SizedBox(height: 8 * scale),
                                _buildSuggestionRow(
                                  scale: scale,
                                  prompts: secondRowPrompts,
                                ),
                                SizedBox(height: 10 * scale),
                              ],
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                ),
                                child: Container(
                                  height: 56 * scale,
                                  decoration: BoxDecoration(
                                    color: const Color(0x52FFFFFF),
                                    borderRadius: BorderRadius.circular(
                                      32 * scale,
                                    ),
                                    border: Border.all(
                                      color: const Color(0x8FFFFFFF),
                                      width: 1 * scale,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _promptController,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _sendPrompt(),
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (16 * scale).clamp(
                                              14.0,
                                              18.0,
                                            ),
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          cursorColor: Colors.black,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            isCollapsed: true,
                                            hintText: 'Ask',
                                            hintStyle: TextStyle(
                                              fontFamily:
                                                  _defaultNonBorelFontFamily,
                                              fontSize: (16 * scale).clamp(
                                                14.0,
                                                18.0,
                                              ),
                                              color: const Color(0x52000000),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8 * scale),
                                      SizedBox(
                                        width: 32 * scale,
                                        height: 32 * scale,
                                        child: _RotatingGlassButton(
                                          scale: scale,
                                          height: 32 * scale,
                                          borderRadius: 16 * scale,
                                          fillColor: canSendPrompt
                                              ? Colors.white
                                              : const Color(0x29FFFFFF),
                                          enablePressShadeFeedback: true,
                                          onTap: canSendPrompt
                                              ? _sendPrompt
                                              : () {},
                                          showBorderLight: canSendPrompt,
                                          child: _isAsking
                                              ? SizedBox(
                                                  width: 14 * scale,
                                                  height: 14 * scale,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2 * scale,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.black),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.black,
                                                  size: (18 * scale).clamp(
                                                    14.0,
                                                    20.0,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCalendarDialog extends StatefulWidget {
  const _HistoryCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_HistoryCalendarDialog> createState() => _HistoryCalendarDialogState();
}

class _HistoryCalendarDialogState extends State<_HistoryCalendarDialog> {
  static const List<String> _weekdayLabels = <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  DateTime get _minDate => _dateOnly(widget.firstDate);
  DateTime get _maxDate => _dateOnly(widget.lastDate);
  DateTime get _minMonth => DateTime(_minDate.year, _minDate.month);
  DateTime get _maxMonth => DateTime(_maxDate.year, _maxDate.month);

  @override
  void initState() {
    super.initState();
    final clampedDate = _clampDate(_dateOnly(widget.initialDate));
    _selectedDate = clampedDate;
    _visibleMonth = DateTime(clampedDate.year, clampedDate.month);
  }

  DateTime _clampDate(DateTime value) {
    if (value.isBefore(_minDate)) {
      return _minDate;
    }
    if (value.isAfter(_maxDate)) {
      return _maxDate;
    }
    return value;
  }

  String _monthLabel(DateTime month) {
    return '${_historyMonthNames[month.month - 1]}, ${month.year}';
  }

  void _shiftMonth(int monthDelta) {
    if (monthDelta == 0) {
      return;
    }
    final candidate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + monthDelta,
    );
    if (candidate.isBefore(_minMonth) || candidate.isAfter(_maxMonth)) {
      return;
    }
    setState(() {
      _visibleMonth = candidate;
    });
  }

  List<DateTime?> _calendarSlotsForVisibleMonth() {
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = monthStart.weekday % 7;
    final usedSlots = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (usedSlots % 7)) % 7;
    final totalSlots = usedSlots + trailingBlanks;
    final slots = List<DateTime?>.filled(totalSlots, null);
    for (int day = 1; day <= daysInMonth; day++) {
      final slotIndex = leadingBlanks + day - 1;
      slots[slotIndex] = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    }
    return slots;
  }

  bool _isDateEnabled(DateTime date) {
    final normalized = _dateOnly(date);
    return !normalized.isBefore(_minDate) && !normalized.isAfter(_maxDate);
  }

  Widget _buildMonthArrow({
    required String assetPath,
    required bool enabled,
    required VoidCallback onTap,
    required double scale,
  }) {
    return SizedBox(
      width: 18 * scale,
      height: 16 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.35,
          child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildDayChip({required double scale, required DateTime? date}) {
    if (date == null) {
      return SizedBox(width: 40 * scale, height: 40 * scale);
    }

    final dayDate = date;
    final isEnabled = _isDateEnabled(dayDate);
    final isSelected = _isSameDate(dayDate, _selectedDate);
    final isToday = _isSameDate(dayDate, _MealsTimelineStore.today);
    final hasSelectedStyle = isSelected;
    final fillColor = (isSelected || isToday)
        ? Colors.white
        : const Color(0x8FFFFFFF);

    return SizedBox(
      width: 40 * scale,
      height: 40 * scale,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.35,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32 * scale),
              boxShadow: hasSelectedStyle
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0xFFFF0000),
                        blurRadius: 2,
                        blurStyle: BlurStyle.outer,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: _RotatingGlassButton(
              scale: scale,
              height: 40 * scale,
              borderRadius: 32 * scale,
              fillColor: fillColor,
              enablePressShadeFeedback: isEnabled,
              showBorderLight: false,
              onTap: () =>
                  Navigator.of(context).pop<DateTime>(_dateOnly(dayDate)),
              child: Text(
                '${dayDate.day}',
                style: TextStyle(
                  fontFamily: _defaultNonBorelFontFamily,
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = (media.size.width / 393).clamp(0.82, 1.0);
    final slots = _calendarSlotsForVisibleMonth();
    final rowCount = (slots.length / 7).round();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.black.withValues(alpha: 0.14)),
                ),
              ),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * scale),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 40 * scale,
                  sigmaY: 40 * scale,
                ),
                child: Container(
                  width: math.min(342 * scale, media.size.width - (32 * scale)),
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0x52FFFFFF),
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMonthArrow(
                              assetPath: 'assets/Back_arrow.svg',
                              enabled: !_visibleMonth.isAtSameMomentAs(
                                _minMonth,
                              ),
                              onTap: () => _shiftMonth(-1),
                              scale: scale,
                            ),
                            Text(
                              _monthLabel(_visibleMonth),
                              style: TextStyle(
                                fontFamily: _defaultNonBorelFontFamily,
                                fontSize: (24 * scale).clamp(20.0, 28.0),
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildMonthArrow(
                              assetPath: 'assets/Front_arrow.svg',
                              enabled: !_visibleMonth.isAtSameMomentAs(
                                _maxMonth,
                              ),
                              onTap: () => _shiftMonth(1),
                              scale: scale,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weekdayLabels
                            .map(
                              (label) => SizedBox(
                                width: 31 * scale,
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      SizedBox(height: 16 * scale),
                      for (int row = 0; row < rowCount; row++) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List<Widget>.generate(7, (column) {
                            final index = (row * 7) + column;
                            final date = index < slots.length
                                ? slots[index]
                                : null;
                            return _buildDayChip(scale: scale, date: date);
                          }),
                        ),
                        if (row != rowCount - 1) SizedBox(height: 8 * scale),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodaysEntryScreen extends StatefulWidget {
  const TodaysEntryScreen({
    super.key,
    this.isExchangeEntry = false,
    this.exchangeTargetEntryId,
  });

  final bool isExchangeEntry;
  final int? exchangeTargetEntryId;

  @override
  State<TodaysEntryScreen> createState() => _TodaysEntryScreenState();
}

class _TodaysEntryScreenState extends State<TodaysEntryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedWaterAmountIndex = 0;
  double _waterIntakeLiters = 0.0;
  bool _waterEditedManually = false;
  bool _isCustomWaterEntrySelected = false;
  TimeOfDay _selectedTime = _currentLocalTimeOfDay();
  late final TextEditingController _waterController;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final FocusNode _waterFocusNode;
  late final FocusNode _hourFocusNode;
  late final FocusNode _minuteFocusNode;
  final GlobalKey _waterFieldKey = GlobalKey();
  final GlobalKey _hourFieldKey = GlobalKey();
  final GlobalKey _minuteFieldKey = GlobalKey();

  static const List<double> _waterPresetAmountsLiters = <double>[
    0.25,
    0.5,
    1.0,
  ];

  bool get _isExchangeMode =>
      widget.isExchangeEntry && widget.exchangeTargetEntryId != null;

  String get _entryHeadingText =>
      widget.isExchangeEntry ? 'Exchange Entry' : 'Today’s Entry';

  String get _entryActionLabel => widget.isExchangeEntry ? 'Exchange' : 'Add';

  bool get _showEntryActionIcon => !widget.isExchangeEntry;

  bool get _isAmSelected => _selectedTime.period == DayPeriod.am;
  bool get _waterUnitIsLiters => _OnboardingProfileState.isHydrationInLiters;
  String get _waterUnitSuffix => _waterUnitIsLiters ? 'l' : 'oz';
  String get _waterUnitLabel => _waterUnitIsLiters ? 'Liters (l)' : 'oz';

  String get _timeHourText {
    final hour = _selectedTime.hourOfPeriod;
    final displayHour = hour == 0 ? 12 : hour;
    return displayHour.toString().padLeft(2, '0');
  }

  String get _timeMinuteText => _selectedTime.minute.toString().padLeft(2, '0');

  String _formatWaterAmount(double value, {required int maxDecimals}) {
    if (value <= 0) {
      return '0';
    }
    return value
        .toStringAsFixed(maxDecimals)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatWaterLiters(double liters) =>
      _formatWaterAmount(liters, maxDecimals: 3);

  double _displayedWaterFromLiters(double liters) {
    return _waterUnitIsLiters ? liters : liters * _ouncesPerLiter;
  }

  double _litersFromDisplayedWater(double displayedValue) {
    return _waterUnitIsLiters
        ? displayedValue
        : (displayedValue / _ouncesPerLiter);
  }

  String _formatDisplayedWaterValue(double liters) {
    final maxDecimals = _waterUnitIsLiters ? 3 : 1;
    final displayed = _displayedWaterFromLiters(liters);
    return _formatWaterAmount(displayed, maxDecimals: maxDecimals);
  }

  String _waterPresetLabel(double liters) {
    final maxDecimals = _waterUnitIsLiters ? 3 : 1;
    final displayed = _displayedWaterFromLiters(liters);
    final amountText = _formatWaterAmount(displayed, maxDecimals: maxDecimals);
    return '$amountText $_waterUnitSuffix';
  }

  bool get _canAddWaterEntry {
    final parsedDisplayed = double.tryParse(
      _waterController.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
    );
    if (parsedDisplayed == null || parsedDisplayed <= 0) {
      return false;
    }
    return _litersFromDisplayedWater(parsedDisplayed) > 0;
  }

  int _waterAmountIndexForValue(double liters) {
    for (int i = 0; i < _waterPresetAmountsLiters.length; i++) {
      final amount = _waterPresetAmountsLiters[i];
      if ((amount - liters).abs() <= 0.0005) {
        return i;
      }
    }
    return -1;
  }

  void _ensureFieldVisible(GlobalKey fieldKey) {
    final fieldContext = fieldKey.currentContext;
    if (fieldContext == null || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.25,
      );
    });
  }

  void _ensureFieldVisibleAfterKeyboard({
    required GlobalKey fieldKey,
    required FocusNode focusNode,
  }) {
    _ensureFieldVisible(fieldKey);
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || !focusNode.hasFocus) {
        return;
      }
      _ensureFieldVisible(fieldKey);
    });
  }

  void _commitWaterFromController() {
    final parsedDisplayed = double.tryParse(
      _waterController.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
    );
    if (parsedDisplayed == null || parsedDisplayed < 0) {
      setState(() {
        _waterController.text = _formatDisplayedWaterValue(_waterIntakeLiters);
      });
      return;
    }
    final parsedLiters = _litersFromDisplayedWater(parsedDisplayed);
    setState(() {
      _waterIntakeLiters = parsedLiters;
      _selectedWaterAmountIndex = _waterEditedManually
          ? -1
          : _waterAmountIndexForValue(parsedLiters);
      if (_waterEditedManually) {
        _isCustomWaterEntrySelected = true;
      }
      _waterController.text = _formatDisplayedWaterValue(_waterIntakeLiters);
      _waterController.selection = TextSelection.fromPosition(
        TextPosition(offset: _waterController.text.length),
      );
    });
  }

  void _commitHourFromController() {
    final parsed = int.tryParse(_hourController.text.trim());
    if (parsed != null && parsed >= 1 && parsed <= 12) {
      var nextHour = parsed % 12;
      if (!_isAmSelected) {
        nextHour += 12;
      }
      setState(() {
        _selectedTime = _selectedTime.replacing(hour: nextHour);
      });
    }
    setState(() {
      _hourController.text = _timeHourText;
      _minuteController.text = _timeMinuteText;
    });
  }

  void _commitMinuteFromController() {
    final parsed = int.tryParse(_minuteController.text.trim());
    if (parsed != null && parsed >= 0 && parsed <= 59) {
      setState(() {
        _selectedTime = _selectedTime.replacing(minute: parsed);
      });
    }
    setState(() {
      _hourController.text = _timeHourText;
      _minuteController.text = _timeMinuteText;
    });
  }

  void _setAmPm(bool useAm) {
    final hour = _selectedTime.hour;
    int nextHour = hour;
    if (useAm && hour >= 12) {
      nextHour = hour - 12;
    } else if (!useAm && hour < 12) {
      nextHour = hour + 12;
    }
    if (nextHour == hour) {
      return;
    }
    setState(() {
      _selectedTime = _selectedTime.replacing(hour: nextHour);
      _hourController.text = _timeHourText;
      _minuteController.text = _timeMinuteText;
    });
  }

  void _addWaterEntryToTimeline() {
    if (!_canAddWaterEntry) {
      return;
    }
    final waterLitersText = _formatWaterLiters(_waterIntakeLiters);
    final displayedWaterText = _formatDisplayedWaterValue(_waterIntakeLiters);
    final itemName = displayedWaterText == '0'
        ? 'Water'
        : 'Water ($displayedWaterText $_waterUnitSuffix)';
    _MealsTimelineStore.addOrReplace(
      entryId: _isExchangeMode ? widget.exchangeTargetEntryId : null,
      timeText: _MealsTimelineStore.timeTextFromTimeOfDay(_selectedTime),
      itemName: itemName,
      caloriesText: '0',
      preserveExistingTimeText: _isExchangeMode,
      waterLitersText: waterLitersText,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _waterController = TextEditingController(
      text: _formatDisplayedWaterValue(0),
    );
    _hourController = TextEditingController(text: _timeHourText);
    _minuteController = TextEditingController(text: _timeMinuteText);
    _waterFocusNode = FocusNode()
      ..addListener(() {
        if (_waterFocusNode.hasFocus) {
          if (mounted) {
            setState(() {});
          }
          _ensureFieldVisible(_waterFieldKey);
          return;
        }
        _commitWaterFromController();
      });
    _hourFocusNode = FocusNode()
      ..addListener(() {
        if (_hourFocusNode.hasFocus) {
          if (mounted) {
            setState(() {});
          }
          _ensureFieldVisibleAfterKeyboard(
            fieldKey: _hourFieldKey,
            focusNode: _hourFocusNode,
          );
          return;
        }
        _commitHourFromController();
      });
    _minuteFocusNode = FocusNode()
      ..addListener(() {
        if (_minuteFocusNode.hasFocus) {
          if (mounted) {
            setState(() {});
          }
          _ensureFieldVisibleAfterKeyboard(
            fieldKey: _minuteFieldKey,
            focusNode: _minuteFocusNode,
          );
          return;
        }
        _commitMinuteFromController();
      });
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _waterFocusNode.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _waterController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goToDailyProgressTab(int tabIndex) {
    if (!mounted) {
      return;
    }
    if (tabIndex == 3) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(
        screen: DailyProgressScreen(initialSelectedBottomNavIndex: tabIndex),
      ),
    );
  }

  void _openCustomEntriesScreen() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: CustomEntriesScreen(
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
        ),
      ),
    );
  }

  void _openNewCustomEntryScreen() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: NewCustomEntryScreen(
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
        ),
      ),
    );
  }

  void _openFavoritesScreen() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: FavoritesScreen(
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
        ),
      ),
    );
  }

  void _openSearchFoodScreen() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: SearchFoodScreen(
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
        ),
      ),
    );
  }

  void _goToAccountPage() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(
        screen: AccountScreen(
          skippedBudgetSection: _OnboardingSkipFlags.skippedBudgetSection,
          skippedWaterSection: _OnboardingSkipFlags.skippedWaterSection,
        ),
      ),
    );
  }

  Widget _bottomNavIconButton({
    required double scale,
    required String assetPath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 48 * scale,
      height: 48 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 15 * scale,
          fillColor: isSelected ? Colors.white : const Color(0x52FFFFFF),
          padding: EdgeInsets.zero,
          expandToBounds: true,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFFFF0000),
                    blurRadius: 4,
                    blurStyle: BlurStyle.outer,
                  ),
                ]
              : const <BoxShadow>[],
          enableBlur: false,
          child: Center(
            child: SizedBox(
              width: 30 * scale,
              height: 30 * scale,
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  isSelected ? _bottomNavActiveIconColor : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _waterAmountChip({
    required double scale,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _TodaysEntryWaterAmountChip(
      scale: scale,
      label: label,
      isSelected: selected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final canAddWaterEntry = _canAddWaterEntry;
          final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
          final isKeyboardVisible = keyboardInset > 0;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final contentTop = metrics.padding.top + (16 * scale);
          final isIPhone =
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              math.min(metrics.width, metrics.height) < 600;
          final controlsBottom = isIPhone
              ? metrics.padding.bottom
              : math.max(66 * scale, metrics.padding.bottom + (26 * scale));
          final navHeight = 64 * scale;
          final blurPanelHeight = (navHeight - (8 * scale)) + controlsBottom;
          final effectiveBottomOverlayHeight = isKeyboardVisible
              ? 0.0
              : blurPanelHeight;
          final scrollBottomPadding =
              effectiveBottomOverlayHeight + keyboardInset + (24 * scale);

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: contentTop,
                bottom: 0,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    contentLeft,
                    32 * scale,
                    contentLeft,
                    scrollBottomPadding,
                  ),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _entryHeadingText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Borel',
                            fontSize: (32 * scale).clamp(24.0, 40.0),
                            color: Colors.white,
                            height: 0.99,
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                        Container(
                          padding: EdgeInsets.all(8 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0x29FFFFFF),
                            borderRadius: BorderRadius.circular(32 * scale),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TodaysEntryGlassTile(
                                  scale: scale,
                                  height: 56 * scale,
                                  borderRadius: 32 * scale,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                  ),
                                  onTap: _openSearchFoodScreen,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Search Food',
                                        style: TextStyle(
                                          fontFamily:
                                              _defaultNonBorelFontFamily,
                                          fontSize: (16 * scale).clamp(
                                            14.0,
                                            20.0,
                                          ),
                                          color: const Color(0x52000000),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 16 * scale,
                                        height: 16 * scale,
                                        child: SvgPicture.asset(
                                          'assets/Serach_food.svg',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16 * scale),
                              _TodaysEntryGlassTile(
                                scale: scale,
                                width: 56 * scale,
                                height: 56 * scale,
                                borderRadius: 32 * scale,
                                onTap: _openFavoritesScreen,
                                child: Icon(
                                  Icons.favorite,
                                  color: const Color(0xFFFF0000),
                                  size: (24 * scale).clamp(20.0, 28.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                        Container(
                          padding: EdgeInsets.all(8 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0x29FFFFFF),
                            borderRadius: BorderRadius.circular(32 * scale),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TodaysEntryGlassTile(
                                  scale: scale,
                                  height: 56 * scale,
                                  borderRadius: 32 * scale,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                  ),
                                  onTap: _openNewCustomEntryScreen,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Custom Food Entry',
                                        style: TextStyle(
                                          fontFamily:
                                              _defaultNonBorelFontFamily,
                                          fontSize: (16 * scale).clamp(
                                            14.0,
                                            20.0,
                                          ),
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.black,
                                        size: (24 * scale).clamp(20.0, 28.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16 * scale),
                              _TodaysEntryGlassTile(
                                scale: scale,
                                width: 56 * scale,
                                height: 56 * scale,
                                borderRadius: 32 * scale,
                                onTap: _openCustomEntriesScreen,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: (34 * scale).clamp(24.0, 38.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Water Intake',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Borel',
                            fontSize: (32 * scale).clamp(24.0, 40.0),
                            color: Colors.white,
                            height: 0.99,
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x29FFFFFF),
                            borderRadius: BorderRadius.circular(16 * scale),
                          ),
                          padding: EdgeInsets.all(8 * scale),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x3DFFFFFF),
                                  borderRadius: BorderRadius.circular(
                                    16 * scale,
                                  ),
                                ),
                                padding: EdgeInsets.all(8 * scale),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16 * scale),
                                      decoration: BoxDecoration(
                                        color: const Color(0x3DFFFFFF),
                                        borderRadius: BorderRadius.circular(
                                          16 * scale,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Water',
                                            style: TextStyle(
                                              fontFamily:
                                                  _defaultNonBorelFontFamily,
                                              fontSize: (16 * scale).clamp(
                                                14.0,
                                                20.0,
                                              ),
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              _TodaysEntryGlassTile(
                                                scale: scale,
                                                width: (140 * scale).clamp(
                                                  120.0,
                                                  168.0,
                                                ),
                                                borderRadius: 15 * scale,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16 * scale,
                                                  vertical: 8 * scale,
                                                ),
                                                inactiveFillColor: const Color(
                                                  0x3DFFFFFF,
                                                ),
                                                selectedFillColor: Colors.white,
                                                isSelected:
                                                    _waterFocusNode.hasFocus ||
                                                    _isCustomWaterEntrySelected,
                                                unfocusOnLongPress: true,
                                                onTap: () => _waterFocusNode
                                                    .requestFocus(),
                                                child: Center(
                                                  child: SizedBox(
                                                    key: _waterFieldKey,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      controller:
                                                          _waterController,
                                                      focusNode:
                                                          _waterFocusNode,
                                                      scrollPadding:
                                                          EdgeInsets.zero,
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(r'[0-9.,]'),
                                                        ),
                                                      ],
                                                      onChanged: (_) {
                                                        if (!mounted) {
                                                          return;
                                                        }
                                                        setState(() {
                                                          _waterEditedManually =
                                                              true;
                                                          _isCustomWaterEntrySelected =
                                                              true;
                                                          _selectedWaterAmountIndex =
                                                              -1;
                                                        });
                                                      },
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      enableInteractiveSelection:
                                                          false,
                                                      onSubmitted: (_) =>
                                                          _waterFocusNode
                                                              .unfocus(),
                                                      onTapOutside: (_) =>
                                                          _waterFocusNode
                                                              .unfocus(),
                                                      decoration:
                                                          const InputDecoration.collapsed(
                                                            hintText: '',
                                                          ),
                                                      style: TextStyle(
                                                        fontFamily:
                                                            _defaultNonBorelFontFamily,
                                                        fontSize: (24 * scale)
                                                            .clamp(18.0, 30.0),
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8 * scale),
                                              Text(
                                                _waterUnitLabel,
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (14 * scale).clamp(
                                                    12.0,
                                                    18.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16 * scale),
                                    Row(
                                      children: List<Widget>.generate(
                                        _waterPresetAmountsLiters.length,
                                        (index) => Padding(
                                          padding: EdgeInsets.only(
                                            right:
                                                index ==
                                                    _waterPresetAmountsLiters
                                                            .length -
                                                        1
                                                ? 0
                                                : 16 * scale,
                                          ),
                                          child: _waterAmountChip(
                                            scale: scale,
                                            label: _waterPresetLabel(
                                              _waterPresetAmountsLiters[index],
                                            ),
                                            selected:
                                                _selectedWaterAmountIndex ==
                                                index,
                                            onTap: () {
                                              if (!mounted) {
                                                return;
                                              }
                                              final waterAmountLiters =
                                                  _waterPresetAmountsLiters[index];
                                              setState(() {
                                                _waterEditedManually = false;
                                                _isCustomWaterEntrySelected =
                                                    false;
                                                _selectedWaterAmountIndex =
                                                    index;
                                                _waterIntakeLiters =
                                                    waterAmountLiters;
                                                _waterController.text =
                                                    _formatDisplayedWaterValue(
                                                      _waterIntakeLiters,
                                                    );
                                                _waterController.selection =
                                                    TextSelection.fromPosition(
                                                      TextPosition(
                                                        offset: _waterController
                                                            .text
                                                            .length,
                                                      ),
                                                    );
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16 * scale),
                              Container(
                                padding: EdgeInsets.all(16 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0x52FFFFFF),
                                  borderRadius: BorderRadius.circular(
                                    16 * scale,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Time',
                                      style: TextStyle(
                                        fontFamily: _defaultNonBorelFontFamily,
                                        fontSize: (16 * scale).clamp(
                                          14.0,
                                          20.0,
                                        ),
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        _TodaysEntryGlassTile(
                                          scale: scale,
                                          width: 62 * scale,
                                          height: 82 * scale,
                                          borderRadius: 15 * scale,
                                          inactiveFillColor: const Color(
                                            0x52FFFFFF,
                                          ),
                                          selectedFillColor: Colors.white,
                                          isSelected: _hourFocusNode.hasFocus,
                                          unfocusOnLongPress: true,
                                          onTap: () =>
                                              _hourFocusNode.requestFocus(),
                                          child: Center(
                                            child: SizedBox(
                                              key: _hourFieldKey,
                                              width: double.infinity,
                                              child: TextField(
                                                controller: _hourController,
                                                focusNode: _hourFocusNode,
                                                scrollPadding: EdgeInsets.zero,
                                                textAlign: TextAlign.center,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                textInputAction:
                                                    TextInputAction.done,
                                                enableInteractiveSelection:
                                                    false,
                                                onSubmitted: (_) =>
                                                    _hourFocusNode.unfocus(),
                                                onTapOutside: (_) =>
                                                    _hourFocusNode.unfocus(),
                                                decoration:
                                                    const InputDecoration.collapsed(
                                                      hintText: '',
                                                    ),
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (24 * scale).clamp(
                                                    18.0,
                                                    30.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8 * scale),
                                        Text(
                                          ':',
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (30 * scale).clamp(
                                              22.0,
                                              34.0,
                                            ),
                                            color: const Color(0x80FFFFFF),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8 * scale),
                                        _TodaysEntryGlassTile(
                                          scale: scale,
                                          width: 62 * scale,
                                          height: 82 * scale,
                                          borderRadius: 15 * scale,
                                          inactiveFillColor: const Color(
                                            0x52FFFFFF,
                                          ),
                                          selectedFillColor: Colors.white,
                                          isSelected: _minuteFocusNode.hasFocus,
                                          unfocusOnLongPress: true,
                                          onTap: () =>
                                              _minuteFocusNode.requestFocus(),
                                          child: Center(
                                            child: SizedBox(
                                              key: _minuteFieldKey,
                                              width: double.infinity,
                                              child: TextField(
                                                controller: _minuteController,
                                                focusNode: _minuteFocusNode,
                                                scrollPadding: EdgeInsets.zero,
                                                textAlign: TextAlign.center,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                textInputAction:
                                                    TextInputAction.done,
                                                enableInteractiveSelection:
                                                    false,
                                                onSubmitted: (_) =>
                                                    _minuteFocusNode.unfocus(),
                                                onTapOutside: (_) =>
                                                    _minuteFocusNode.unfocus(),
                                                decoration:
                                                    const InputDecoration.collapsed(
                                                      hintText: '',
                                                    ),
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (24 * scale).clamp(
                                                    18.0,
                                                    30.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8 * scale),
                                        Column(
                                          children: [
                                            _TodaysEntryGlassTile(
                                              scale: scale,
                                              borderRadius: 15 * scale,
                                              padding: EdgeInsets.all(
                                                8 * scale,
                                              ),
                                              isSelected: _isAmSelected,
                                              unfocusOnLongPress: true,
                                              onTap: () => _setAmPm(true),
                                              child: Text(
                                                'AM',
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (16 * scale).clamp(
                                                    14.0,
                                                    20.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8 * scale),
                                            _TodaysEntryGlassTile(
                                              scale: scale,
                                              borderRadius: 15 * scale,
                                              padding: EdgeInsets.all(
                                                8 * scale,
                                              ),
                                              isSelected: !_isAmSelected,
                                              unfocusOnLongPress: true,
                                              onTap: () => _setAmPm(false),
                                              child: Text(
                                                'PM',
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (16 * scale).clamp(
                                                    14.0,
                                                    20.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16 * scale),
                              _GlassNextButton(
                                scale: scale,
                                label: _entryActionLabel,
                                showArrowIcon: false,
                                trailingIcon: _showEntryActionIcon
                                    ? Icons.add
                                    : null,
                                trailingIconSize: 24,
                                enabled: canAddWaterEntry,
                                onTap: _addWaterEntryToTimeline,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isKeyboardVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: blurPanelHeight,
                  child: _buildBottomBlurFadeOverlay(),
                ),
              if (!isKeyboardVisible)
                Positioned(
                  left: contentLeft,
                  width: contentWidth,
                  bottom: controlsBottom,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16 * scale),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _dailyProgressMenuBarBlurSigma,
                              sigmaY: _dailyProgressMenuBarBlurSigma,
                            ),
                            child: Container(
                              height: navHeight,
                              decoration: BoxDecoration(
                                color: _menuBarBlockFillColor,
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                              padding: EdgeInsets.all(8 * scale),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _bottomNavIconButton(
                                    scale: scale,
                                    assetPath: 'assets/Home_in.svg',
                                    isSelected: false,
                                    onTap: () => _goToDailyProgressTab(0),
                                  ),
                                  _bottomNavIconButton(
                                    scale: scale,
                                    assetPath: 'assets/Notification_in.svg',
                                    isSelected: false,
                                    onTap: () => _goToDailyProgressTab(1),
                                  ),
                                  _bottomNavIconButton(
                                    scale: scale,
                                    assetPath: 'assets/Account_in.svg',
                                    isSelected: false,
                                    onTap: _goToAccountPage,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16 * scale),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: _dailyProgressMenuBarBlurSigma,
                            sigmaY: _dailyProgressMenuBarBlurSigma,
                          ),
                          child: Container(
                            width: navHeight,
                            height: navHeight,
                            decoration: BoxDecoration(
                              color: _menuBarBlockFillColor,
                              borderRadius: BorderRadius.circular(16 * scale),
                            ),
                            padding: EdgeInsets.all(8 * scale),
                            child: _bottomNavIconButton(
                              scale: scale,
                              assetPath: 'assets/Add_new.svg',
                              isSelected: true,
                              onTap: () {},
                            ),
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

class SearchFoodScreen extends StatefulWidget {
  const SearchFoodScreen({
    super.key,
    this.isExchangeEntry = false,
    this.exchangeTargetEntryId,
  });

  final bool isExchangeEntry;
  final int? exchangeTargetEntryId;

  @override
  State<SearchFoodScreen> createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  Timer? _searchDebounce;
  int _searchRequestToken = 0;
  bool _isLoadingResults = false;
  List<_DailyFoodCatalogItem> _searchResults = const <_DailyFoodCatalogItem>[];

  String get _entryHeadingText =>
      widget.isExchangeEntry ? 'Exchange Entry' : 'Today’s Entry';

  String get _trimmedQuery => _searchController.text.trim();
  bool get _hasQuery => _trimmedQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();

    _searchController.addListener(_handleQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    _searchDebounce?.cancel();
    if (!_hasQuery) {
      _searchRequestToken++;
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingResults = false;
        _searchResults = const <_DailyFoodCatalogItem>[];
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      _runFoodSearch(_trimmedQuery);
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _runFoodSearch(String query) async {
    final requestToken = ++_searchRequestToken;
    if (mounted) {
      setState(() {
        _isLoadingResults = true;
      });
    }

    final results = await _DailyFoodDatabase.searchFoods(query);
    if (!mounted || requestToken != _searchRequestToken) {
      return;
    }

    setState(() {
      _isLoadingResults = false;
      _searchResults = results;
    });
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _goToDailyProgressTab(int tabIndex) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(
        screen: DailyProgressScreen(initialSelectedBottomNavIndex: tabIndex),
      ),
    );
  }

  void _goToAccountPage() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(
        screen: AccountScreen(
          skippedBudgetSection: _OnboardingSkipFlags.skippedBudgetSection,
          skippedWaterSection: _OnboardingSkipFlags.skippedWaterSection,
        ),
      ),
    );
  }

  void _toggleFavorite(_DailyFoodCatalogItem item) {
    if (!mounted) {
      return;
    }
    final nextFavorite = !item.isFavorite;
    _DailyFoodDatabase.setFavorite(item.id, nextFavorite);
    setState(() {
      _searchResults = _searchResults
          .map(
            (food) => food.id == item.id
                ? food.copyWith(isFavorite: nextFavorite)
                : food,
          )
          .toList(growable: false);
    });
  }

  Future<void> _openFoodItemDetails(_DailyFoodCatalogItem item) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: _SearchFoodItemDetailsScreen(
          item: item,
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
          initialCaloriesText: item.caloriesText,
          initialProteinText: item.proteinText,
          initialCarbohydratesText: item.carbohydratesText,
          initialFatText: item.fatText,
          initialFiberText: item.fiberText,
          initialSugarText: item.sugarText,
          initialSodiumText: item.sodiumText,
          initialBudgetText: item.budgetTextForCurrency(
            _OnboardingProfileState.budgetCurrencyCode,
          ),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _searchResults = _searchResults
          .map(
            (food) => food.copyWith(
              isFavorite: _DailyFoodDatabase.isFavorite(food.id),
            ),
          )
          .toList(growable: false);
    });
  }

  Widget _bottomNavIconButton({
    required double scale,
    required String assetPath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 48 * scale,
      height: 48 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 15 * scale,
          fillColor: isSelected ? Colors.white : const Color(0x52FFFFFF),
          padding: EdgeInsets.zero,
          expandToBounds: true,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFFFF0000),
                    blurRadius: 4,
                    blurStyle: BlurStyle.outer,
                  ),
                ]
              : const <BoxShadow>[],
          enableBlur: false,
          child: Center(
            child: SizedBox(
              width: 30 * scale,
              height: 30 * scale,
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  isSelected ? _bottomNavActiveIconColor : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard({
    required _DailyFoodCatalogItem item,
    required double scale,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFoodItemDetails(item),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: const Color(0x52FFFFFF),
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 62 * scale,
              height: 62 * scale,
              child: _RotatingGlassPanel(
                scale: scale,
                borderRadius: 16 * scale,
                fillColor: const Color(0x52FFFFFF),
                padding: EdgeInsets.all(12 * scale),
                expandToBounds: true,
                boxShadow: const <BoxShadow>[],
                enableBlur: false,
                child: SvgPicture.asset('assets/Food.svg', fit: BoxFit.contain),
              ),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: _defaultNonBorelFontFamily,
                      fontSize: (16 * scale).clamp(14.0, 20.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    '${item.caloriesKcal} kcal',
                    style: TextStyle(
                      fontFamily: _defaultNonBorelFontFamily,
                      fontSize: (16 * scale).clamp(14.0, 20.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleFavorite(item),
              child: Padding(
                padding: EdgeInsets.all(4 * scale),
                child: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: item.isFavorite
                      ? const Color(0xFFFF0000)
                      : Colors.white,
                  size: (24 * scale).clamp(20.0, 28.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
          final isKeyboardVisible = keyboardInset > 0;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final contentTop = metrics.padding.top + (16 * scale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final navHeight = 64 * scale;
          final backButtonHeight = 56 * scale;
          final showBackOnlyControls = _hasQuery && !isKeyboardVisible;
          final controlsRowHeight = showBackOnlyControls
              ? backButtonHeight
              : navHeight;
          final blurPanelHeight =
              (controlsRowHeight - (showBackOnlyControls ? 0 : (8 * scale))) +
              controlsBottom;
          final scrollBottomPadding =
              blurPanelHeight + keyboardInset + (24 * scale);

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: contentTop,
                bottom: 0,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    contentLeft,
                    16,
                    contentLeft,
                    scrollBottomPadding,
                  ),
                  children: [
                    Text(
                      _entryHeadingText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: (32 * scale).clamp(24.0, 40.0),
                        color: Colors.white,
                        height: 0.99,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0x29FFFFFF),
                        borderRadius: BorderRadius.circular(32 * scale),
                      ),
                      child: Container(
                        height: 56 * scale,
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0x52FFFFFF),
                          borderRadius: BorderRadius.circular(32 * scale),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.search,
                                style: TextStyle(
                                  fontFamily: _defaultNonBorelFontFamily,
                                  fontSize: (16 * scale).clamp(14.0, 20.0),
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: 'Search Food',
                                  hintStyle: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: const Color(0x52000000),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16 * scale,
                              height: 16 * scale,
                              child: SvgPicture.asset(
                                'assets/Serach_food.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hasQuery) ...[
                      SizedBox(height: 18 * scale),
                      if (_isLoadingResults)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20 * scale),
                          child: Center(
                            child: SizedBox(
                              width: (24 * scale).clamp(20.0, 30.0),
                              height: (24 * scale).clamp(20.0, 30.0),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (_searchResults.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20 * scale),
                          child: Center(
                            child: Text(
                              'No Foods Found',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _defaultNonBorelFontFamily,
                                fontSize: (20 * scale).clamp(16.0, 24.0),
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List<Widget>.generate(_searchResults.length, (
                          index,
                        ) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _searchResults.length - 1
                                  ? 0
                                  : 18 * scale,
                            ),
                            child: _buildSearchResultCard(
                              item: _searchResults[index],
                              scale: scale,
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: blurPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: showBackOnlyControls
                    ? _TodaysEntryGlassTile(
                        scale: scale,
                        height: backButtonHeight,
                        borderRadius: 32 * scale,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        onTap: _goBack,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: const Color(0xFFFFD206),
                            size: (26 * scale).clamp(20.0, 30.0),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16 * scale),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: _dailyProgressMenuBarBlurSigma,
                                  sigmaY: _dailyProgressMenuBarBlurSigma,
                                ),
                                child: Container(
                                  height: navHeight,
                                  decoration: BoxDecoration(
                                    color: _menuBarBlockFillColor,
                                    borderRadius: BorderRadius.circular(
                                      16 * scale,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(8 * scale),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _bottomNavIconButton(
                                        scale: scale,
                                        assetPath: 'assets/Home_in.svg',
                                        isSelected: false,
                                        onTap: () => _goToDailyProgressTab(0),
                                      ),
                                      _bottomNavIconButton(
                                        scale: scale,
                                        assetPath: 'assets/Notification_in.svg',
                                        isSelected: false,
                                        onTap: () => _goToDailyProgressTab(1),
                                      ),
                                      _bottomNavIconButton(
                                        scale: scale,
                                        assetPath: 'assets/Account_in.svg',
                                        isSelected: false,
                                        onTap: _goToAccountPage,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16 * scale),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16 * scale),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: _dailyProgressMenuBarBlurSigma,
                                sigmaY: _dailyProgressMenuBarBlurSigma,
                              ),
                              child: Container(
                                width: navHeight,
                                height: navHeight,
                                decoration: BoxDecoration(
                                  color: _menuBarBlockFillColor,
                                  borderRadius: BorderRadius.circular(
                                    16 * scale,
                                  ),
                                ),
                                padding: EdgeInsets.all(8 * scale),
                                child: _bottomNavIconButton(
                                  scale: scale,
                                  assetPath: 'assets/Add_new.svg',
                                  isSelected: true,
                                  onTap: () {},
                                ),
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

class _SearchFoodItemDetailsScreen extends StatefulWidget {
  const _SearchFoodItemDetailsScreen({
    required this.item,
    this.isExchangeEntry = false,
    this.exchangeTargetEntryId,
    this.initialItemName,
    this.initialCaloriesText,
    this.initialProteinText,
    this.initialCarbohydratesText,
    this.initialFatText,
    this.initialFiberText,
    this.initialSugarText,
    this.initialSodiumText,
    this.initialBudgetText,
    this.initialTimeText,
    this.showAddToCustom = true,
    this.timelineActionLabelOverride,
  });

  final _DailyFoodCatalogItem item;
  final bool isExchangeEntry;
  final int? exchangeTargetEntryId;
  final String? initialItemName;
  final String? initialCaloriesText;
  final String? initialProteinText;
  final String? initialCarbohydratesText;
  final String? initialFatText;
  final String? initialFiberText;
  final String? initialSugarText;
  final String? initialSodiumText;
  final String? initialBudgetText;
  final String? initialTimeText;
  final bool showAddToCustom;
  final String? timelineActionLabelOverride;

  @override
  State<_SearchFoodItemDetailsScreen> createState() =>
      _SearchFoodItemDetailsScreenState();
}

class _SearchFoodItemDetailsScreenState
    extends State<_SearchFoodItemDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late TimeOfDay _selectedTime;
  bool _isAdvanceOpen = false;
  bool _isFavorite = false;
  int _selectedQuantityUnitIndex = 0;

  late final TextEditingController _itemNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final TextEditingController _budgetPriceController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _sugarController;
  late final TextEditingController _sodiumController;

  late final FocusNode _itemNameFocusNode;
  late final FocusNode _quantityFocusNode;
  late final FocusNode _hourFocusNode;
  late final FocusNode _minuteFocusNode;
  late final FocusNode _budgetPriceFocusNode;
  late final FocusNode _caloriesFocusNode;
  late final FocusNode _proteinFocusNode;
  late final FocusNode _carbsFocusNode;
  late final FocusNode _fatFocusNode;
  late final FocusNode _fiberFocusNode;
  late final FocusNode _sugarFocusNode;
  late final FocusNode _sodiumFocusNode;

  final GlobalKey _itemNameFieldKey = GlobalKey();
  final GlobalKey _quantityFieldKey = GlobalKey();
  final GlobalKey _hourFieldKey = GlobalKey();
  final GlobalKey _minuteFieldKey = GlobalKey();
  final GlobalKey _budgetPriceFieldKey = GlobalKey();
  final GlobalKey _caloriesFieldKey = GlobalKey();
  final GlobalKey _proteinFieldKey = GlobalKey();
  final GlobalKey _carbsFieldKey = GlobalKey();
  final GlobalKey _fatFieldKey = GlobalKey();
  final GlobalKey _fiberFieldKey = GlobalKey();
  final GlobalKey _sugarFieldKey = GlobalKey();
  final GlobalKey _sodiumFieldKey = GlobalKey();
  static const List<double> _budgetPresetValues = <double>[100, 150, 200];
  static const List<_CustomEntryQuantityUnitOption> _quantityUnitOptions =
      <_CustomEntryQuantityUnitOption>[
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Unit',
          displaySuffix: '',
          usesStepControls: true,
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Grams (g)',
          displaySuffix: 'g',
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Milligrams (mg)',
          displaySuffix: 'mg',
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Liter (l)',
          displaySuffix: 'liter (l)',
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Milliliter (ml)',
          displaySuffix: 'ml',
        ),
      ];

  late String _initialName;
  late String _initialCalories;
  late String _initialProtein;
  late String _initialCarbs;
  late String _initialFat;
  late String _initialFiber;
  late String _initialSugar;
  late String _initialSodium;
  late String _initialBudget;
  late int _initialHour24;
  late int _initialMinute;
  late bool _initialFavorite;

  bool get _isExchangeMode =>
      widget.isExchangeEntry && widget.exchangeTargetEntryId != null;

  String get _timelineActionLabel =>
      widget.timelineActionLabelOverride ??
      (widget.isExchangeEntry ? 'Exchange' : 'Add');

  bool get _showTimelineActionIcon => !widget.isExchangeEntry;

  bool get _isAmSelected => _selectedTime.hour < 12;

  bool get _showBudgetSection =>
      _OnboardingProfileState.budgetEnabled &&
      !_OnboardingSkipFlags.skippedBudgetSection;

  String get _budgetCurrencyCode =>
      _OnboardingProfileState.budgetCurrencyCode.trim().toUpperCase();

  String get _budgetCurrencyGlyph =>
      _budgetCurrencyGlyphByCode[_budgetCurrencyCode] ?? _budgetCurrencyCode;

  _CustomEntryQuantityUnitOption get _selectedQuantityUnit =>
      _quantityUnitOptions[_selectedQuantityUnitIndex];

  bool get _showItemQuantity =>
      widget.item.quantityTypeLabel.trim().isNotEmpty ||
      widget.item.quantityAmountText.trim().isNotEmpty;

  String get _timeHourText {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    return hour.toString().padLeft(2, '0');
  }

  String get _timeMinuteText => _selectedTime.minute.toString().padLeft(2, '0');

  TimeOfDay _parseTimeTextOrDefault(String? rawText) {
    // Item details should always open with the present local time.
    return _currentLocalTimeOfDay();
  }

  String _normalizeItemName(String raw) => raw.trim();

  String _normalizedNumericText(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return '0';
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null) {
      return '0';
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  int _quantityUnitIndexFromType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    switch (normalized) {
      case 'unit':
        return 0;
      case 'g':
      case 'gram':
      case 'grams':
        return 1;
      case 'mg':
      case 'milligram':
      case 'milligrams':
        return 2;
      case 'l':
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return 3;
      case 'ml':
      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
        return 4;
      default:
        return 0;
    }
  }

  String _normalizedQuantityText(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return _selectedQuantityUnit.usesStepControls ? '1' : '';
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) {
      return _selectedQuantityUnit.usesStepControls ? '1' : '';
    }
    if (_selectedQuantityUnit.usesStepControls) {
      return parsed.round().clamp(1, 9999).toString();
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _adjustUnitQuantity(int delta) {
    final parsed = int.tryParse(_quantityController.text.trim()) ?? 1;
    final next = (parsed + delta).clamp(1, 9999);
    setState(() {
      _quantityController.text = next.toString();
    });
  }

  void _captureInitialState() {
    _initialName = _normalizeItemName(_itemNameController.text);
    _initialCalories = _normalizedNumericText(_caloriesController.text);
    _initialProtein = _normalizedNumericText(_proteinController.text);
    _initialCarbs = _normalizedNumericText(_carbsController.text);
    _initialFat = _normalizedNumericText(_fatController.text);
    _initialFiber = _normalizedNumericText(_fiberController.text);
    _initialSugar = _normalizedNumericText(_sugarController.text);
    _initialSodium = _normalizedNumericText(_sodiumController.text);
    _initialBudget = _normalizedBudgetText(_budgetPriceController.text);
    _initialHour24 = _selectedTime.hour;
    _initialMinute = _selectedTime.minute;
    _initialFavorite = _isFavorite;
  }

  bool get _canAddToCustom {
    return _normalizeItemName(_itemNameController.text) != _initialName ||
        _normalizedNumericText(_caloriesController.text) != _initialCalories ||
        _normalizedNumericText(_proteinController.text) != _initialProtein ||
        _normalizedNumericText(_carbsController.text) != _initialCarbs ||
        _normalizedNumericText(_fatController.text) != _initialFat ||
        _normalizedNumericText(_fiberController.text) != _initialFiber ||
        _normalizedNumericText(_sugarController.text) != _initialSugar ||
        _normalizedNumericText(_sodiumController.text) != _initialSodium ||
        (_showBudgetSection &&
            _normalizedBudgetText(_budgetPriceController.text) !=
                _initialBudget) ||
        _selectedTime.hour != _initialHour24 ||
        _selectedTime.minute != _initialMinute ||
        _isFavorite != _initialFavorite;
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(widget.item.copyWith(isFavorite: _isFavorite));
  }

  void _ensureFieldVisible(GlobalKey fieldKey) {
    final fieldContext = fieldKey.currentContext;
    if (fieldContext == null || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.25,
      );
    });
  }

  void _ensureFieldVisibleAfterKeyboard({
    required GlobalKey fieldKey,
    required FocusNode focusNode,
  }) {
    _ensureFieldVisible(fieldKey);
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || !focusNode.hasFocus) {
        return;
      }
      _ensureFieldVisible(fieldKey);
    });
  }

  void _commitHourFromController() {
    final parsed = int.tryParse(_hourController.text.trim());
    if (parsed != null && parsed >= 1 && parsed <= 12) {
      var nextHour = parsed % 12;
      if (!_isAmSelected) {
        nextHour += 12;
      }
      setState(() {
        _selectedTime = _selectedTime.replacing(hour: nextHour);
      });
    }
    _hourController.text = _timeHourText;
    _minuteController.text = _timeMinuteText;
  }

  void _commitMinuteFromController() {
    final parsed = int.tryParse(_minuteController.text.trim());
    if (parsed != null && parsed >= 0 && parsed <= 59) {
      setState(() {
        _selectedTime = _selectedTime.replacing(minute: parsed);
      });
    }
    _hourController.text = _timeHourText;
    _minuteController.text = _timeMinuteText;
  }

  void _setAmPm(bool useAm) {
    final hour = _selectedTime.hour;
    int nextHour = hour;
    if (useAm && hour >= 12) {
      nextHour = hour - 12;
    } else if (!useAm && hour < 12) {
      nextHour = hour + 12;
    }
    if (nextHour == hour) {
      return;
    }
    setState(() {
      _selectedTime = _selectedTime.replacing(hour: nextHour);
      _hourController.text = _timeHourText;
      _minuteController.text = _timeMinuteText;
    });
  }

  String _normalizedBudgetText(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return '';
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return '';
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _commitBudgetFromController() {
    final normalized = _normalizedBudgetText(_budgetPriceController.text);
    setState(() {
      _budgetPriceController.text = normalized;
      _budgetPriceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _budgetPriceController.text.length),
      );
    });
  }

  double? _parsedBudgetValue() {
    final normalized = _normalizedBudgetText(_budgetPriceController.text);
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  bool _isBudgetPresetSelected(double preset) {
    final value = _parsedBudgetValue();
    if (value == null) {
      return false;
    }
    return (value - preset).abs() <= 0.0001;
  }

  void _setBudgetPreset(double value) {
    final text = _normalizedBudgetText(value.toString());
    setState(() {
      _budgetPriceController.text = text;
      _budgetPriceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _budgetPriceController.text.length),
      );
    });
  }

  void _bindFieldFocus({
    required FocusNode focusNode,
    required GlobalKey fieldKey,
    VoidCallback? onFocusLost,
  }) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        if (mounted) {
          setState(() {});
        }
        _ensureFieldVisibleAfterKeyboard(
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      } else {
        if (mounted) {
          setState(() {});
        }
        onFocusLost?.call();
      }
    });
  }

  void _toggleFavorite() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _DailyFoodDatabase.setFavorite(widget.item.id, _isFavorite);
  }

  void _addToCustomEntries() {
    if (!_canAddToCustom) {
      return;
    }
    final entry = _CustomFoodEntryStore.create(
      name: _normalizeItemName(_itemNameController.text),
      caloriesText: _normalizedNumericText(_caloriesController.text),
      timeText:
          '$_timeHourText:$_timeMinuteText ${_isAmSelected ? 'AM' : 'PM'}',
      budgetAmountText: _showBudgetSection
          ? _normalizedBudgetText(_budgetPriceController.text)
          : '0',
      proteinText: _normalizedNumericText(_proteinController.text),
      carbohydratesText: _normalizedNumericText(_carbsController.text),
      fatText: _normalizedNumericText(_fatController.text),
      fiberText: _normalizedNumericText(_fiberController.text),
      sugarText: _normalizedNumericText(_sugarController.text),
      sodiumText: _normalizedNumericText(_sodiumController.text),
      isFavorite: _isFavorite,
    );
    _CustomFoodEntryStore.add(entry);
    _captureInitialState();
    if (mounted) {
      setState(() {});
    }
  }

  void _addToMealsTimeline() {
    final itemName = _normalizeItemName(_itemNameController.text);
    if (itemName.isEmpty) {
      return;
    }
    _MealsTimelineStore.addOrReplace(
      entryId: _isExchangeMode ? widget.exchangeTargetEntryId : null,
      timeText:
          '$_timeHourText:$_timeMinuteText ${_isAmSelected ? 'AM' : 'PM'}',
      itemName: itemName,
      caloriesText: _normalizedNumericText(_caloriesController.text),
      preserveExistingTimeText: _isExchangeMode,
      proteinText: _normalizedNumericText(_proteinController.text),
      carbohydratesText: _normalizedNumericText(_carbsController.text),
      fatText: _normalizedNumericText(_fatController.text),
      fiberText: _normalizedNumericText(_fiberController.text),
      sugarText: _normalizedNumericText(_sugarController.text),
      sodiumText: _normalizedNumericText(_sodiumController.text),
      budgetAmountText: _showBudgetSection
          ? _normalizedBudgetText(_budgetPriceController.text)
          : (_normalizedBudgetText(widget.initialBudgetText ?? '').isNotEmpty
                ? _normalizedBudgetText(widget.initialBudgetText ?? '')
                : '0'),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Widget _nutritionCard({
    required double scale,
    required String label,
    required String unit,
    required TextEditingController controller,
    required FocusNode focusNode,
    required GlobalKey fieldKey,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (16 * scale).clamp(14.0, 20.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _TodaysEntryGlassTile(
            scale: scale,
            width: (140 * scale).clamp(120.0, 168.0),
            height: 47 * scale,
            borderRadius: 15 * scale,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            inactiveFillColor: const Color(0x52FFFFFF),
            selectedFillColor: Colors.white,
            isSelected: focusNode.hasFocus,
            unfocusOnLongPress: true,
            onTap: () => focusNode.requestFocus(),
            child: Center(
              child: SizedBox(
                key: fieldKey,
                width: double.infinity,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  scrollPadding: EdgeInsets.zero,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textInputAction: TextInputAction.done,
                  enableInteractiveSelection: false,
                  onSubmitted: (_) => focusNode.unfocus(),
                  onTapOutside: (_) => focusNode.unfocus(),
                  decoration: const InputDecoration.collapsed(hintText: '0'),
                  style: TextStyle(
                    fontFamily: _defaultNonBorelFontFamily,
                    fontSize: (24 * scale).clamp(18.0, 30.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          SizedBox(
            width: 28 * scale,
            child: Text(
              unit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (14 * scale).clamp(12.0, 18.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard(double scale) {
    final showsStepControls = _selectedQuantityUnit.usesStepControls;
    final quantityHintText = showsStepControls
        ? '1'
        : (_quantityFocusNode.hasFocus ? '' : '0');
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x3DFFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Row(
        children: [
          if (showsStepControls) ...[
            _TodaysEntryGlassTile(
              scale: scale,
              width: 47 * scale,
              height: 47 * scale,
              borderRadius: 15 * scale,
              padding: EdgeInsets.zero,
              inactiveFillColor: const Color(0x52FFFFFF),
              selectedFillColor: const Color(0x52FFFFFF),
              unfocusOnLongPress: true,
              onTap: () => _adjustUnitQuantity(-1),
              child: Icon(
                Icons.remove,
                color: Colors.white,
                size: (24 * scale).clamp(18.0, 28.0),
              ),
            ),
            SizedBox(width: 8 * scale),
          ],
          _TodaysEntryGlassTile(
            scale: scale,
            width: 140 * scale,
            height: 47 * scale,
            borderRadius: 15 * scale,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            inactiveFillColor: const Color(0x52FFFFFF),
            selectedFillColor: Colors.white,
            isSelected: _quantityFocusNode.hasFocus,
            unfocusOnLongPress: true,
            onTap: () => _quantityFocusNode.requestFocus(),
            child: Center(
              child: SizedBox(
                key: _quantityFieldKey,
                width: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressDown: (_) => _quantityFocusNode.unfocus(),
                  onLongPressStart: (_) => _quantityFocusNode.unfocus(),
                  onLongPressEnd: (_) => _quantityFocusNode.unfocus(),
                  onLongPressCancel: _quantityFocusNode.unfocus,
                  onLongPress: _quantityFocusNode.unfocus,
                  child: TextField(
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    scrollPadding: EdgeInsets.zero,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: false,
                    onSubmitted: (_) => _quantityFocusNode.unfocus(),
                    onTapOutside: (_) => _quantityFocusNode.unfocus(),
                    decoration: InputDecoration.collapsed(
                      hintText: quantityHintText,
                      hintStyle: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (24 * scale).clamp(18.0, 30.0),
                        color: const Color(0x80000000),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: _defaultNonBorelFontFamily,
                      fontSize: (24 * scale).clamp(18.0, 30.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showsStepControls) ...[
            SizedBox(width: 8 * scale),
            _TodaysEntryGlassTile(
              scale: scale,
              width: 47 * scale,
              height: 47 * scale,
              borderRadius: 15 * scale,
              padding: EdgeInsets.zero,
              inactiveFillColor: const Color(0x52FFFFFF),
              selectedFillColor: const Color(0x52FFFFFF),
              unfocusOnLongPress: true,
              onTap: () => _adjustUnitQuantity(1),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: (24 * scale).clamp(18.0, 28.0),
              ),
            ),
          ] else ...[
            SizedBox(width: 16 * scale),
            Text(
              _selectedQuantityUnit.displaySuffix,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final initialName = widget.initialItemName?.trim();
    final seededName = (initialName != null && initialName.isNotEmpty)
        ? initialName
        : widget.item.name;
    final seededCalories =
        double.tryParse(
          (widget.initialCaloriesText ?? '').trim().replaceAll(',', '.'),
        )?.round() ??
        widget.item.caloriesKcal;
    final calories = seededCalories.clamp(0, 99999);
    final defaultProtein = (calories * 0.15 / 4).round();
    final defaultCarbs = (calories * 0.55 / 4).round();
    final defaultFat = (calories * 0.30 / 9).round();
    final seededProtein = _normalizedNumericText(
      widget.initialProteinText ?? defaultProtein.clamp(0, 9999).toString(),
    );
    final seededCarbs = _normalizedNumericText(
      widget.initialCarbohydratesText ?? defaultCarbs.clamp(0, 9999).toString(),
    );
    final seededFat = _normalizedNumericText(
      widget.initialFatText ?? defaultFat.clamp(0, 9999).toString(),
    );
    final seededFiber = _normalizedNumericText(widget.initialFiberText ?? '0');
    final seededSugar = _normalizedNumericText(widget.initialSugarText ?? '0');
    final seededSodium = _normalizedNumericText(
      widget.initialSodiumText ?? '0',
    );
    _selectedQuantityUnitIndex = _quantityUnitIndexFromType(
      widget.item.quantityTypeLabel,
    );

    _selectedTime = _parseTimeTextOrDefault(widget.initialTimeText);
    _isFavorite = widget.item.isFavorite;

    _itemNameController = TextEditingController(text: seededName);
    _quantityController = TextEditingController(
      text: _normalizedQuantityText(widget.item.quantityAmountText),
    );
    _hourController = TextEditingController(text: _timeHourText);
    _minuteController = TextEditingController(text: _timeMinuteText);
    _budgetPriceController = TextEditingController(
      text: _normalizedBudgetText(widget.initialBudgetText ?? ''),
    );
    _caloriesController = TextEditingController(text: calories.toString());
    _proteinController = TextEditingController(text: seededProtein);
    _carbsController = TextEditingController(text: seededCarbs);
    _fatController = TextEditingController(text: seededFat);
    _fiberController = TextEditingController(text: seededFiber);
    _sugarController = TextEditingController(text: seededSugar);
    _sodiumController = TextEditingController(text: seededSodium);

    _itemNameFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();
    _budgetPriceFocusNode = FocusNode();
    _caloriesFocusNode = FocusNode();
    _proteinFocusNode = FocusNode();
    _carbsFocusNode = FocusNode();
    _fatFocusNode = FocusNode();
    _fiberFocusNode = FocusNode();
    _sugarFocusNode = FocusNode();
    _sodiumFocusNode = FocusNode();

    _bindFieldFocus(focusNode: _itemNameFocusNode, fieldKey: _itemNameFieldKey);
    _bindFieldFocus(
      focusNode: _quantityFocusNode,
      fieldKey: _quantityFieldKey,
      onFocusLost: () {
        _quantityController.text = _normalizedQuantityText(
          _quantityController.text,
        );
      },
    );
    _bindFieldFocus(
      focusNode: _hourFocusNode,
      fieldKey: _hourFieldKey,
      onFocusLost: _commitHourFromController,
    );
    _bindFieldFocus(
      focusNode: _minuteFocusNode,
      fieldKey: _minuteFieldKey,
      onFocusLost: _commitMinuteFromController,
    );
    _bindFieldFocus(
      focusNode: _budgetPriceFocusNode,
      fieldKey: _budgetPriceFieldKey,
      onFocusLost: _commitBudgetFromController,
    );
    _bindFieldFocus(focusNode: _caloriesFocusNode, fieldKey: _caloriesFieldKey);
    _bindFieldFocus(focusNode: _proteinFocusNode, fieldKey: _proteinFieldKey);
    _bindFieldFocus(focusNode: _carbsFocusNode, fieldKey: _carbsFieldKey);
    _bindFieldFocus(focusNode: _fatFocusNode, fieldKey: _fatFieldKey);
    _bindFieldFocus(focusNode: _fiberFocusNode, fieldKey: _fiberFieldKey);
    _bindFieldFocus(focusNode: _sugarFocusNode, fieldKey: _sugarFieldKey);
    _bindFieldFocus(focusNode: _sodiumFocusNode, fieldKey: _sodiumFieldKey);

    for (final controller in <TextEditingController>[
      _itemNameController,
      _quantityController,
      _budgetPriceController,
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
      _fiberController,
      _sugarController,
      _sodiumController,
    ]) {
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }

    _captureInitialState();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _itemNameFocusNode.dispose();
    _quantityFocusNode.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _budgetPriceFocusNode.dispose();
    _caloriesFocusNode.dispose();
    _proteinFocusNode.dispose();
    _carbsFocusNode.dispose();
    _fatFocusNode.dispose();
    _fiberFocusNode.dispose();
    _sugarFocusNode.dispose();
    _sodiumFocusNode.dispose();

    _itemNameController.dispose();
    _quantityController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _budgetPriceController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (18 * scale);
          final contentTop = titleTop + (48 * scale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final bottomRowHeight = 56 * scale;
          final blurPanelHeight = bottomRowHeight + controlsBottom;
          final scrollBottomPadding =
              blurPanelHeight + keyboardInset + (24 * scale);

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: contentTop,
                bottom: 0,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    contentLeft,
                    16,
                    contentLeft,
                    scrollBottomPadding,
                  ),
                  children: [
                    Text(
                      'Item Name',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _TodaysEntryGlassTile(
                            scale: scale,
                            height: 56 * scale,
                            borderRadius: 16 * scale,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 16 * scale,
                            ),
                            inactiveFillColor: const Color(0x52FFFFFF),
                            selectedFillColor: Colors.white,
                            isSelected: _itemNameFocusNode.hasFocus,
                            unfocusOnLongPress: true,
                            onTap: () => _itemNameFocusNode.requestFocus(),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                key: _itemNameFieldKey,
                                width: double.infinity,
                                child: TextField(
                                  controller: _itemNameController,
                                  focusNode: _itemNameFocusNode,
                                  scrollPadding: EdgeInsets.zero,
                                  textAlign: TextAlign.left,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) =>
                                      _itemNameFocusNode.unfocus(),
                                  onTapOutside: (_) =>
                                      _itemNameFocusNode.unfocus(),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Item Name',
                                  ),
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16 * scale),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleFavorite,
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? const Color(0xFFFF0000)
                                : Colors.white,
                            size: (28 * scale).clamp(22.0, 32.0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * scale),
                    if (_showItemQuantity) ...[
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (16 * scale).clamp(14.0, 20.0),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      _buildQuantityCard(scale),
                      SizedBox(height: 24 * scale),
                    ],
                    Text(
                      'Meal Time',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    Container(
                      padding: EdgeInsets.all(16 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0x52FFFFFF),
                        borderRadius: BorderRadius.circular(16 * scale),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TodaysEntryGlassTile(
                            scale: scale,
                            width: 62 * scale,
                            height: 82 * scale,
                            borderRadius: 15 * scale,
                            inactiveFillColor: const Color(0x52FFFFFF),
                            selectedFillColor: Colors.white,
                            isSelected: _hourFocusNode.hasFocus,
                            unfocusOnLongPress: true,
                            onTap: () => _hourFocusNode.requestFocus(),
                            child: Center(
                              child: SizedBox(
                                key: _hourFieldKey,
                                width: double.infinity,
                                child: TextField(
                                  controller: _hourController,
                                  focusNode: _hourFocusNode,
                                  scrollPadding: EdgeInsets.zero,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) => _hourFocusNode.unfocus(),
                                  onTapOutside: (_) => _hourFocusNode.unfocus(),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: '',
                                  ),
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (24 * scale).clamp(18.0, 30.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            ':',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (30 * scale).clamp(22.0, 34.0),
                              color: const Color(0x80FFFFFF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          _TodaysEntryGlassTile(
                            scale: scale,
                            width: 62 * scale,
                            height: 82 * scale,
                            borderRadius: 15 * scale,
                            inactiveFillColor: const Color(0x52FFFFFF),
                            selectedFillColor: Colors.white,
                            isSelected: _minuteFocusNode.hasFocus,
                            unfocusOnLongPress: true,
                            onTap: () => _minuteFocusNode.requestFocus(),
                            child: Center(
                              child: SizedBox(
                                key: _minuteFieldKey,
                                width: double.infinity,
                                child: TextField(
                                  controller: _minuteController,
                                  focusNode: _minuteFocusNode,
                                  scrollPadding: EdgeInsets.zero,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) =>
                                      _minuteFocusNode.unfocus(),
                                  onTapOutside: (_) =>
                                      _minuteFocusNode.unfocus(),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: '',
                                  ),
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (24 * scale).clamp(18.0, 30.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Column(
                            children: [
                              _TodaysEntryGlassTile(
                                scale: scale,
                                borderRadius: 15 * scale,
                                padding: EdgeInsets.all(8 * scale),
                                isSelected: _isAmSelected,
                                unfocusOnLongPress: true,
                                onTap: () => _setAmPm(true),
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              _TodaysEntryGlassTile(
                                scale: scale,
                                borderRadius: 15 * scale,
                                padding: EdgeInsets.all(8 * scale),
                                isSelected: !_isAmSelected,
                                unfocusOnLongPress: true,
                                onTap: () => _setAmPm(false),
                                child: Text(
                                  'PM',
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * scale),
                    if (_showBudgetSection) ...[
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (16 * scale).clamp(14.0, 20.0),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Container(
                        padding: EdgeInsets.all(8 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0x3DFFFFFF),
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0x3DFFFFFF),
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (16 * scale).clamp(14.0, 20.0),
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _budgetCurrencyGlyph,
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (14 * scale).clamp(12.0, 18.0),
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  _TodaysEntryGlassTile(
                                    scale: scale,
                                    width: (140 * scale).clamp(120.0, 168.0),
                                    height: 47 * scale,
                                    borderRadius: 15 * scale,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * scale,
                                      vertical: 8 * scale,
                                    ),
                                    inactiveFillColor: const Color(0x3DFFFFFF),
                                    selectedFillColor: Colors.white,
                                    isSelected: _budgetPriceFocusNode.hasFocus,
                                    unfocusOnLongPress: true,
                                    onTap: () =>
                                        _budgetPriceFocusNode.requestFocus(),
                                    child: Center(
                                      child: SizedBox(
                                        key: _budgetPriceFieldKey,
                                        width: double.infinity,
                                        child: TextField(
                                          controller: _budgetPriceController,
                                          focusNode: _budgetPriceFocusNode,
                                          scrollPadding: EdgeInsets.zero,
                                          textAlign: TextAlign.center,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9.,]'),
                                            ),
                                          ],
                                          textInputAction: TextInputAction.done,
                                          enableInteractiveSelection: false,
                                          onSubmitted: (_) =>
                                              _budgetPriceFocusNode.unfocus(),
                                          onTapOutside: (_) =>
                                              _budgetPriceFocusNode.unfocus(),
                                          decoration: InputDecoration.collapsed(
                                            hintText: '0',
                                            hintStyle: TextStyle(
                                              fontFamily:
                                                  _defaultNonBorelFontFamily,
                                              fontSize: (24 * scale).clamp(
                                                18.0,
                                                30.0,
                                              ),
                                              color: const Color(0x29000000),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (24 * scale).clamp(
                                              18.0,
                                              30.0,
                                            ),
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Text(
                                    '/meal',
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (14 * scale).clamp(12.0, 18.0),
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            Row(
                              children: _budgetPresetValues
                                  .map((preset) {
                                    final isSelected = _isBudgetPresetSelected(
                                      preset,
                                    );
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right:
                                              preset == _budgetPresetValues.last
                                              ? 0
                                              : 16 * scale,
                                        ),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _setBudgetPreset(preset),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16 * scale,
                                              vertical: 8 * scale,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0x52FFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    15 * scale,
                                                  ),
                                              border: Border.all(
                                                color: const Color(0x80FFFFFF),
                                                width: (1 * scale).clamp(
                                                  0.8,
                                                  1.4,
                                                ),
                                              ),
                                              boxShadow: isSelected
                                                  ? const <BoxShadow>[
                                                      BoxShadow(
                                                        color: Color(
                                                          0xFFFF0000,
                                                        ),
                                                        blurRadius: 4,
                                                        blurStyle:
                                                            BlurStyle.outer,
                                                      ),
                                                    ]
                                                  : const <BoxShadow>[],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_budgetCurrencyGlyph ${preset.toInt()}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (24 * scale).clamp(
                                                    18.0,
                                                    30.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                    ],
                    Text(
                      'Nutritional Value',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 18 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Calories',
                      unit: 'kcal',
                      controller: _caloriesController,
                      focusNode: _caloriesFocusNode,
                      fieldKey: _caloriesFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Protein',
                      unit: 'g',
                      controller: _proteinController,
                      focusNode: _proteinFocusNode,
                      fieldKey: _proteinFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Carbohydrates',
                      unit: 'g',
                      controller: _carbsController,
                      focusNode: _carbsFocusNode,
                      fieldKey: _carbsFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Fat',
                      unit: 'g',
                      controller: _fatController,
                      focusNode: _fatFocusNode,
                      fieldKey: _fatFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isAdvanceOpen = !_isAdvanceOpen;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Advance',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (20 * scale).clamp(16.0, 24.0),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 10 * scale),
                          Icon(
                            _isAdvanceOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: (26 * scale).clamp(20.0, 30.0),
                          ),
                        ],
                      ),
                    ),
                    if (_isAdvanceOpen) ...[
                      SizedBox(height: 16 * scale),
                      _nutritionCard(
                        scale: scale,
                        label: 'Fiber',
                        unit: 'g',
                        controller: _fiberController,
                        focusNode: _fiberFocusNode,
                        fieldKey: _fiberFieldKey,
                      ),
                      SizedBox(height: 16 * scale),
                      _nutritionCard(
                        scale: scale,
                        label: 'Sugar',
                        unit: 'g',
                        controller: _sugarController,
                        focusNode: _sugarFocusNode,
                        fieldKey: _sugarFieldKey,
                      ),
                      SizedBox(height: 16 * scale),
                      _nutritionCard(
                        scale: scale,
                        label: 'Sodium',
                        unit: 'mg',
                        controller: _sodiumController,
                        focusNode: _sodiumFocusNode,
                        fieldKey: _sodiumFieldKey,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 48 * scale,
                    child: Center(
                      child: Text(
                        'Item Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Borel',
                          fontSize: (32 * scale).clamp(24.0, 42.0),
                          color: Colors.white,
                          height: 0.99,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: blurPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    SizedBox(
                      width: 56 * scale,
                      child: _RotatingGlassButton(
                        scale: scale,
                        height: bottomRowHeight,
                        borderRadius: 32 * scale,
                        fillColor: Colors.white,
                        enablePressShadeFeedback: true,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (26 * scale).clamp(20.0, 30.0),
                        ),
                      ),
                    ),
                    if (widget.showAddToCustom) ...[
                      SizedBox(width: 16 * scale),
                      SizedBox(
                        width: (150 * scale).clamp(120.0, 170.0),
                        child: _GlassNextButton(
                          scale: scale,
                          label: 'Add to Custom',
                          showArrowIcon: false,
                          baseColor: const Color(0xFF00B2FF),
                          enabledAlpha: 0x8F,
                          disabledAlpha: 0x29,
                          enabled: _canAddToCustom,
                          onTap: _addToCustomEntries,
                        ),
                      ),
                    ],
                    SizedBox(width: 16 * scale),
                    Expanded(
                      child: _GlassNextButton(
                        scale: scale,
                        label: _timelineActionLabel,
                        showArrowIcon: false,
                        trailingIcon: _showTimelineActionIcon
                            ? Icons.add
                            : null,
                        trailingIconSize: 24,
                        onTap: _addToMealsTimeline,
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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    this.isExchangeEntry = false,
    this.exchangeTargetEntryId,
  });

  final bool isExchangeEntry;
  final int? exchangeTargetEntryId;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openNewCustomEntryScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: NewCustomEntryScreen(
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final titleTop = metrics.padding.top + (18 * scale);
          final searchTop = titleTop + (62 * scale);
          final listTop = searchTop + (30 * scale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final bottomRowHeight = 56 * scale;
          final bottomPanelTopPadding = 0.0;
          final bottomPanelHeight =
              bottomRowHeight +
              bottomPanelTopPadding +
              math.max(metrics.padding.bottom, 24 * scale);
          final contentBottomInset =
              bottomPanelHeight + controlsBottom + (24 * scale);
          final allFavorites = _CustomFoodEntryStore.entries
              .where((entry) => entry.isFavorite)
              .toList(growable: false);
          final hasFavorites = allFavorites.isNotEmpty;
          final searchQuery = _searchController.text.trim().toLowerCase();
          final visibleFavorites = searchQuery.isEmpty
              ? allFavorites
              : allFavorites
                    .where(
                      (entry) => entry.name.toLowerCase().contains(searchQuery),
                    )
                    .toList();

          return Stack(
            children: [
              Positioned(
                top: titleTop,
                left: 16 * scale,
                right: 16 * scale,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 48 * scale,
                    child: Center(
                      child: Text(
                        'Favorites',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Borel',
                          fontSize: (32 * scale).clamp(24.0, 42.0),
                          color: Colors.white,
                          height: 0.99,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (hasFavorites)
                Positioned(
                  top: searchTop,
                  left: 16 * scale,
                  right: 16 * scale,
                  child: Container(
                    height: 56 * scale,
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0x52FFFFFF),
                      borderRadius: BorderRadius.circular(32 * scale),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (16 * scale).clamp(14.0, 20.0),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Search Favorites',
                              hintStyle: TextStyle(
                                fontFamily: _defaultNonBorelFontFamily,
                                fontSize: (16 * scale).clamp(14.0, 20.0),
                                color: const Color(0x52000000),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.search,
                          color: Colors.black,
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasFavorites)
                Positioned(
                  left: 16 * scale,
                  right: 16 * scale,
                  top: listTop,
                  bottom: contentBottomInset,
                  child: visibleFavorites.isEmpty
                      ? Center(
                          child: Text(
                            'No Favorites Added',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (24 * scale).clamp(18.0, 30.0),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleFavorites.length,
                          separatorBuilder: (_, index) =>
                              SizedBox(height: 16 * scale),
                          itemBuilder: (context, index) {
                            final entry = visibleFavorites[index];
                            return Container(
                              padding: EdgeInsets.all(16 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0x52FFFFFF),
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 62 * scale,
                                    height: 62 * scale,
                                    child: _RotatingGlassPanel(
                                      scale: scale,
                                      borderRadius: 16 * scale,
                                      fillColor: const Color(0x52FFFFFF),
                                      padding: EdgeInsets.all(12 * scale),
                                      expandToBounds: true,
                                      boxShadow: const <BoxShadow>[],
                                      enableBlur: false,
                                      child: SvgPicture.asset(
                                        'assets/Food.svg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          entry.name,
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (16 * scale).clamp(
                                              14.0,
                                              20.0,
                                            ),
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8 * scale),
                                        Text(
                                          '${entry.caloriesText} kcal',
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (16 * scale).clamp(
                                              14.0,
                                              20.0,
                                            ),
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.favorite,
                                    color: const Color(0xFFFF0000),
                                    size: (24 * scale).clamp(20.0, 28.0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              if (!hasFavorites)
                Positioned(
                  left: 16 * scale,
                  right: 16 * scale,
                  top: titleTop + (86 * scale),
                  bottom: contentBottomInset,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/No_Favorites.png',
                          width: (168 * scale).clamp(120.0, 220.0),
                          height: (255 * scale).clamp(182.0, 320.0),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 20 * scale),
                        Text(
                          'No Favorites Added',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _defaultNonBorelFontFamily,
                            fontSize: (24 * scale).clamp(18.0, 30.0),
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildBottomBlurFadeOverlay()),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        10 * scale,
                        bottomPanelTopPadding,
                        10 * scale,
                        0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 79 * scale,
                                child: _TodaysEntryGlassTile(
                                  scale: scale,
                                  height: bottomRowHeight,
                                  borderRadius: 32 * scale,
                                  inactiveFillColor: Colors.white,
                                  selectedFillColor: Colors.white,
                                  onTap: _goBack,
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: const Color(0xFFFFD206),
                                    size: (26 * scale).clamp(20.0, 30.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16 * scale),
                              Expanded(
                                child: _TodaysEntryGlassTile(
                                  scale: scale,
                                  height: bottomRowHeight,
                                  borderRadius: 32 * scale,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                  ),
                                  inactiveFillColor: const Color(0x52FFFFFF),
                                  selectedFillColor: Colors.white,
                                  onTap: _openNewCustomEntryScreen,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Custom Food Entry',
                                        style: TextStyle(
                                          fontFamily:
                                              _defaultNonBorelFontFamily,
                                          fontSize: (16 * scale).clamp(
                                            14.0,
                                            20.0,
                                          ),
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.black,
                                        size: (24 * scale).clamp(20.0, 28.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: math.max(
                              metrics.padding.bottom,
                              24 * scale,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                margin: EdgeInsets.only(top: 8 * scale),
                                width: 134 * scale,
                                height: (5 * scale).clamp(3.5, 6.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    100 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

class CustomEntriesScreen extends StatefulWidget {
  const CustomEntriesScreen({
    super.key,
    this.isExchangeEntry = false,
    this.exchangeTargetEntryId,
  });

  final bool isExchangeEntry;
  final int? exchangeTargetEntryId;

  @override
  State<CustomEntriesScreen> createState() => _CustomEntriesScreenState();
}

class _CustomEntriesScreenState extends State<CustomEntriesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _searchController;
  bool _isSelectMode = false;
  final Set<int> _selectedEntryIds = <int>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _toggleSelectMode() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedEntryIds.clear();
    });
  }

  void _toggleEntrySelection(int entryId) {
    if (!mounted || !_isSelectMode) {
      return;
    }
    setState(() {
      if (!_selectedEntryIds.add(entryId)) {
        _selectedEntryIds.remove(entryId);
      }
    });
  }

  void _toggleEntryFavorite(_CustomFoodEntry entry) {
    if (!mounted) {
      return;
    }
    setState(() {
      _CustomFoodEntryStore.setFavoriteById(entry.id, !entry.isFavorite);
    });
  }

  int _parseEntryCalories(String rawCalories) {
    final parsed = double.tryParse(rawCalories.trim().replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 0;
    }
    return parsed.round();
  }

  Future<void> _openCustomEntryItemDetails(_CustomFoodEntry entry) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: _SearchFoodItemDetailsScreen(
          item: _DailyFoodCatalogItem(
            id: -entry.id,
            name: entry.name,
            caloriesKcal: _parseEntryCalories(entry.caloriesText),
            isFavorite: entry.isFavorite,
          ),
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
          initialItemName: entry.name,
          initialCaloriesText: entry.caloriesText,
          initialProteinText: entry.proteinText,
          initialCarbohydratesText: entry.carbohydratesText,
          initialFatText: entry.fatText,
          initialFiberText: entry.fiberText,
          initialSugarText: entry.sugarText,
          initialSodiumText: entry.sodiumText,
          initialBudgetText: entry.budgetAmountText,
          initialTimeText: entry.timeText,
          showAddToCustom: false,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  bool get _canDeleteSelectedEntries => _selectedEntryIds.isNotEmpty;

  void _deleteSelectedEntries() {
    if (!_canDeleteSelectedEntries || !mounted) {
      return;
    }
    setState(() {
      final idsToDelete = _selectedEntryIds.toList(growable: false);
      for (final id in idsToDelete) {
        _CustomFoodEntryStore.removeById(id);
      }
      _selectedEntryIds.clear();
      _isSelectMode = false;
    });
  }

  Future<void> _openNewCustomEntryScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      _buildNoTransitionRoute(
        screen: NewCustomEntryScreen(
          isExchangeEntry: widget.isExchangeEntry,
          exchangeTargetEntryId: widget.exchangeTargetEntryId,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final titleTop = metrics.padding.top + (18 * scale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final titleRowTop = titleTop;
          final searchTop = titleRowTop + (62 * scale);
          final listTop = searchTop + (30 * scale);
          final bottomRowHeight = 56 * scale;
          final bottomPanelTopPadding = 0.0;
          final bottomPanelHeight =
              bottomRowHeight +
              bottomPanelTopPadding +
              math.max(metrics.padding.bottom, 24 * scale);
          final searchQuery = _searchController.text.trim().toLowerCase();
          final allEntries = _CustomFoodEntryStore.entries;
          final isCompletelyEmpty = allEntries.isEmpty;
          final visibleEntries = searchQuery.isEmpty
              ? allEntries
              : allEntries
                    .where(
                      (entry) => entry.name.toLowerCase().contains(searchQuery),
                    )
                    .toList();

          return Stack(
            children: [
              Positioned(
                top: titleRowTop,
                left: 16 * scale,
                right: 16 * scale,
                child: isCompletelyEmpty
                    ? Center(
                        child: Transform.translate(
                          offset: Offset(0, 13 * scale),
                          child: Text(
                            'Custom Entries',
                            style: TextStyle(
                              fontFamily: 'Borel',
                              fontSize: (32 * scale).clamp(24.0, 42.0),
                              color: Colors.white,
                              height: 0.99,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Transform.translate(
                            offset: Offset(0, 13 * scale),
                            child: Text(
                              'Custom Entries',
                              style: TextStyle(
                                fontFamily: 'Borel',
                                fontSize: (32 * scale).clamp(24.0, 42.0),
                                color: Colors.white,
                                height: 0.99,
                              ),
                            ),
                          ),
                          _isSelectMode
                              ? _TodaysEntryGlassTile(
                                  scale: scale,
                                  width: 65 * scale,
                                  height: 37 * scale,
                                  borderRadius: 15 * scale,
                                  padding: EdgeInsets.zero,
                                  inactiveFillColor: Colors.white,
                                  selectedFillColor: Colors.white,
                                  onTap: _toggleSelectMode,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: (24 * scale).clamp(18.0, 28.0),
                                  ),
                                )
                              : _TodaysEntryGlassTile(
                                  scale: scale,
                                  borderRadius: 15 * scale,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12 * scale,
                                    vertical: 8 * scale,
                                  ),
                                  inactiveFillColor: const Color(0x52FFFFFF),
                                  selectedFillColor: Colors.white,
                                  onTap: _toggleSelectMode,
                                  child: Text(
                                    'Select',
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (16 * scale).clamp(14.0, 20.0),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ],
                      ),
              ),
              if (!isCompletelyEmpty)
                Positioned(
                  top: searchTop,
                  left: 16 * scale,
                  right: 16 * scale,
                  child: Container(
                    height: 56 * scale,
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0x52FFFFFF),
                      borderRadius: BorderRadius.circular(32 * scale),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (16 * scale).clamp(14.0, 20.0),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Search Custom Entries',
                              hintStyle: TextStyle(
                                fontFamily: _defaultNonBorelFontFamily,
                                fontSize: (16 * scale).clamp(14.0, 20.0),
                                color: const Color(0x52000000),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.search,
                          color: Colors.black,
                          size: (24 * scale).clamp(20.0, 28.0),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 16 * scale,
                right: 16 * scale,
                top: isCompletelyEmpty
                    ? (titleRowTop + (172 * scale))
                    : listTop,
                bottom: bottomPanelHeight + controlsBottom + (24 * scale),
                child: isCompletelyEmpty
                    ? Column(
                        children: [
                          SizedBox(
                            width: 168 * scale,
                            height: 255 * scale,
                            child: Image.asset(
                              'assets/No_custom_entries.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported_outlined,
                                  color: const Color(0x80000000),
                                  size: (64 * scale).clamp(40.0, 84.0),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 18 * scale),
                          Text(
                            'No Custom Food Entries',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (24 * scale).clamp(20.0, 30.0),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : visibleEntries.isEmpty
                    ? Center(
                        child: Text(
                          'No Custom Food Entries',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _defaultNonBorelFontFamily,
                            fontSize: (24 * scale).clamp(18.0, 30.0),
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: visibleEntries.length,
                        separatorBuilder: (_, index) =>
                            SizedBox(height: 16 * scale),
                        itemBuilder: (context, index) {
                          final entry = visibleEntries[index];
                          if (_isSelectMode) {
                            return _CustomEntrySelectableTile(
                              key: ValueKey<int>(entry.id),
                              scale: scale,
                              entry: entry,
                              isSelected: _selectedEntryIds.contains(entry.id),
                              onTap: () => _toggleEntrySelection(entry.id),
                              onToggleFavorite: () =>
                                  _toggleEntryFavorite(entry),
                            );
                          }
                          return _CustomEntrySwipeTile(
                            key: ValueKey<int>(entry.id),
                            scale: scale,
                            entry: entry,
                            onTap: () => _openCustomEntryItemDetails(entry),
                            onToggleFavorite: () => _toggleEntryFavorite(entry),
                            onDelete: () {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _CustomFoodEntryStore.removeById(entry.id);
                              });
                            },
                          );
                        },
                      ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomPanelHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildBottomBlurFadeOverlay()),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        10 * scale,
                        bottomPanelTopPadding,
                        10 * scale,
                        0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 79 * scale,
                                child: _TodaysEntryGlassTile(
                                  scale: scale,
                                  height: bottomRowHeight,
                                  borderRadius: 32 * scale,
                                  inactiveFillColor: Colors.white,
                                  selectedFillColor: Colors.white,
                                  onTap: _goBack,
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: const Color(0xFFFFD206),
                                    size: (26 * scale).clamp(20.0, 30.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16 * scale),
                              Expanded(
                                child: _isSelectMode
                                    ? _RotatingGlassButton(
                                        scale: scale,
                                        height: bottomRowHeight,
                                        borderRadius: 32 * scale,
                                        fillColor: _canDeleteSelectedEntries
                                            ? const Color(0x8FFF0606)
                                            : const Color(0x14FF0606),
                                        enablePressShadeFeedback:
                                            _canDeleteSelectedEntries,
                                        onTap: _canDeleteSelectedEntries
                                            ? _deleteSelectedEntries
                                            : () {},
                                        child: Text(
                                          'Delete Entries',
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (34 * scale / 1.7).clamp(
                                              18.0,
                                              28.0,
                                            ),
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : _TodaysEntryGlassTile(
                                        scale: scale,
                                        height: bottomRowHeight,
                                        borderRadius: 32 * scale,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16 * scale,
                                        ),
                                        inactiveFillColor: const Color(
                                          0x52FFFFFF,
                                        ),
                                        selectedFillColor: Colors.white,
                                        onTap: _openNewCustomEntryScreen,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Custom Food Entry',
                                              style: TextStyle(
                                                fontFamily:
                                                    _defaultNonBorelFontFamily,
                                                fontSize: (16 * scale).clamp(
                                                  14.0,
                                                  20.0,
                                                ),
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.black,
                                              size: (24 * scale).clamp(
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
                          SizedBox(
                            height: math.max(
                              metrics.padding.bottom,
                              24 * scale,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                margin: EdgeInsets.only(top: 8 * scale),
                                width: 134 * scale,
                                height: (5 * scale).clamp(3.5, 6.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    100 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _CustomEntrySwipeTile extends StatefulWidget {
  const _CustomEntrySwipeTile({
    super.key,
    required this.scale,
    required this.entry,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final double scale;
  final _CustomFoodEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  @override
  State<_CustomEntrySwipeTile> createState() => _CustomEntrySwipeTileState();
}

class _CustomEntrySwipeTileState extends State<_CustomEntrySwipeTile> {
  static const Duration _slideDuration = Duration(milliseconds: 220);
  static const Curve _slideCurve = Curves.easeOutCubic;

  bool _isDragging = false;
  double _dragOffsetX = 0;
  double _targetOffsetX = 0;

  double get _maxRevealOffset => (62 + 24) * widget.scale;

  void _closeDeleteAction() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isDragging = false;
      _dragOffsetX = 0;
      _targetOffsetX = 0;
    });
  }

  void _openDeleteAction() {
    if (!mounted) {
      return;
    }
    final revealOffset = -_maxRevealOffset;
    setState(() {
      _isDragging = false;
      _dragOffsetX = revealOffset;
      _targetOffsetX = revealOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final entry = widget.entry;
    final revealOffset = -_maxRevealOffset;
    final currentOffsetX = _isDragging ? _dragOffsetX : _targetOffsetX;
    final revealProgress = ((-currentOffsetX) / _maxRevealOffset).clamp(
      0.0,
      1.0,
    );
    final deleteSlideOffsetX = (1 - revealProgress) * (74 * scale);
    final backgroundButton = SizedBox(
      width: 62 * scale,
      height: 62 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDelete,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: const Color(0x52FFFFFF),
          padding: EdgeInsets.all(15 * scale),
          expandToBounds: true,
          boxShadow: const <BoxShadow>[],
          enableBlur: false,
          child: SvgPicture.asset('assets/Delete.svg', fit: BoxFit.contain),
        ),
      ),
    );

    final foregroundCard = Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62 * scale,
            height: 62 * scale,
            child: _RotatingGlassPanel(
              scale: scale,
              borderRadius: 16 * scale,
              fillColor: const Color(0x52FFFFFF),
              padding: EdgeInsets.all(12 * scale),
              expandToBounds: true,
              boxShadow: const <BoxShadow>[],
              enableBlur: false,
              child: SvgPicture.asset('assets/Food.svg', fit: BoxFit.contain),
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontFamily: _defaultNonBorelFontFamily,
                    fontSize: (16 * scale).clamp(14.0, 20.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  '${entry.caloriesText} kcal',
                  style: TextStyle(
                    fontFamily: _defaultNonBorelFontFamily,
                    fontSize: (16 * scale).clamp(14.0, 20.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggleFavorite,
            child: Padding(
              padding: EdgeInsets.all(4 * scale),
              child: Icon(
                entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: entry.isFavorite
                    ? const Color(0xFFFF0000)
                    : Colors.white,
                size: (24 * scale).clamp(20.0, 28.0),
              ),
            ),
          ),
        ],
      ),
    );

    final foreground = _isDragging
        ? Transform.translate(
            offset: Offset(_dragOffsetX, 0),
            child: foregroundCard,
          )
        : AnimatedContainer(
            duration: _slideDuration,
            curve: _slideCurve,
            transform: Matrix4.translationValues(_targetOffsetX, 0, 0),
            child: foregroundCard,
          );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_targetOffsetX != 0 || _isDragging) {
          _closeDeleteAction();
          return;
        }
        widget.onTap();
      },
      onHorizontalDragStart: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isDragging = true;
          _dragOffsetX = _targetOffsetX;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (!mounted) {
          return;
        }
        final nextOffset = (_dragOffsetX + details.delta.dx).clamp(
          revealOffset,
          0.0,
        );
        setState(() {
          _dragOffsetX = nextOffset;
        });
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final draggedRatio = revealOffset == 0
            ? 0.0
            : (_dragOffsetX.abs() / revealOffset.abs());
        final shouldOpen = velocity < -320 || draggedRatio >= 0.45;
        if (shouldOpen) {
          _openDeleteAction();
          return;
        }
        _closeDeleteAction();
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: IgnorePointer(
                ignoring: revealProgress <= 0.01,
                child: Opacity(
                  opacity: revealProgress,
                  child: Transform.translate(
                    offset: Offset(deleteSlideOffsetX, 0),
                    child: backgroundButton,
                  ),
                ),
              ),
            ),
          ),
          foreground,
        ],
      ),
    );
  }
}

class _CustomEntrySelectableTile extends StatelessWidget {
  const _CustomEntrySelectableTile({
    super.key,
    required this.scale,
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final double scale;
  final _CustomFoodEntry entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0x52FFFFFF),
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 62 * scale,
              height: 62 * scale,
              child: _RotatingGlassPanel(
                scale: scale,
                borderRadius: 16 * scale,
                fillColor: const Color(0x52FFFFFF),
                padding: EdgeInsets.all(12 * scale),
                expandToBounds: true,
                boxShadow: const <BoxShadow>[],
                enableBlur: false,
                child: SvgPicture.asset('assets/Food.svg', fit: BoxFit.contain),
              ),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontFamily: _defaultNonBorelFontFamily,
                      fontSize: (16 * scale).clamp(14.0, 20.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    '${entry.caloriesText} kcal',
                    style: TextStyle(
                      fontFamily: _defaultNonBorelFontFamily,
                      fontSize: (16 * scale).clamp(14.0, 20.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleFavorite,
              child: Padding(
                padding: EdgeInsets.all(4 * scale),
                child: Icon(
                  entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: entry.isFavorite
                      ? const Color(0xFFFF0000)
                      : Colors.white,
                  size: (24 * scale).clamp(20.0, 28.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewCustomEntryScreen extends StatefulWidget {
  const NewCustomEntryScreen({
    super.key,
    this.isExchangeEntry = false,
    this.exchangeTargetEntryId,
  });

  final bool isExchangeEntry;
  final int? exchangeTargetEntryId;

  @override
  State<NewCustomEntryScreen> createState() => _NewCustomEntryScreenState();
}

class _NewCustomEntryScreenState extends State<NewCustomEntryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  TimeOfDay _selectedTime = _currentLocalTimeOfDay();
  bool _isAdvanceOpen = false;
  bool _isFavorite = false;
  bool _isQuantityUnitDropdownOpen = false;
  int _selectedQuantityUnitIndex = 0;
  final List<_CustomFoodEntry> _pendingCustomEntries = <_CustomFoodEntry>[];

  late final TextEditingController _itemNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final TextEditingController _budgetPriceController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _sugarController;
  late final TextEditingController _sodiumController;

  late final FocusNode _itemNameFocusNode;
  late final FocusNode _quantityFocusNode;
  late final FocusNode _hourFocusNode;
  late final FocusNode _minuteFocusNode;
  late final FocusNode _budgetPriceFocusNode;
  late final FocusNode _caloriesFocusNode;
  late final FocusNode _proteinFocusNode;
  late final FocusNode _carbsFocusNode;
  late final FocusNode _fatFocusNode;
  late final FocusNode _fiberFocusNode;
  late final FocusNode _sugarFocusNode;
  late final FocusNode _sodiumFocusNode;

  final GlobalKey _itemNameFieldKey = GlobalKey();
  final GlobalKey _quantityFieldKey = GlobalKey();
  final GlobalKey _hourFieldKey = GlobalKey();
  final GlobalKey _minuteFieldKey = GlobalKey();
  final GlobalKey _budgetPriceFieldKey = GlobalKey();
  final GlobalKey _caloriesFieldKey = GlobalKey();
  final GlobalKey _proteinFieldKey = GlobalKey();
  final GlobalKey _carbsFieldKey = GlobalKey();
  final GlobalKey _fatFieldKey = GlobalKey();
  final GlobalKey _fiberFieldKey = GlobalKey();
  final GlobalKey _sugarFieldKey = GlobalKey();
  final GlobalKey _sodiumFieldKey = GlobalKey();
  static const List<double> _budgetPresetValues = <double>[100, 150, 200];
  static const List<_CustomEntryQuantityUnitOption> _quantityUnitOptions =
      <_CustomEntryQuantityUnitOption>[
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Unit',
          displaySuffix: '',
          usesStepControls: true,
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Grams (g)',
          displaySuffix: 'g',
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Milligrams (mg)',
          displaySuffix: 'mg',
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Liter (l)',
          displaySuffix: 'liter (l)',
        ),
        _CustomEntryQuantityUnitOption(
          dropdownLabel: 'Milliliter (ml)',
          displaySuffix: 'ml',
        ),
      ];

  bool get _isExchangeMode =>
      widget.isExchangeEntry && widget.exchangeTargetEntryId != null;

  String get _timelineActionLabel =>
      widget.isExchangeEntry ? 'Exchange' : 'Add';

  bool get _showTimelineActionIcon => !widget.isExchangeEntry;

  bool get _isAmSelected => _selectedTime.hour < 12;

  bool get _showBudgetSection =>
      _OnboardingProfileState.budgetEnabled &&
      !_OnboardingSkipFlags.skippedBudgetSection;

  String get _budgetCurrencyCode =>
      _OnboardingProfileState.budgetCurrencyCode.trim().toUpperCase();

  String get _budgetCurrencyGlyph =>
      _budgetCurrencyGlyphByCode[_budgetCurrencyCode] ?? _budgetCurrencyCode;

  _CustomEntryQuantityUnitOption get _selectedQuantityUnit =>
      _quantityUnitOptions[_selectedQuantityUnitIndex];

  String get _timeHourText {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    return hour.toString().padLeft(2, '0');
  }

  String get _timeMinuteText => _selectedTime.minute.toString().padLeft(2, '0');

  String _normalizedQuantityText(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return _selectedQuantityUnit.usesStepControls ? '1' : '';
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) {
      return _selectedQuantityUnit.usesStepControls ? '1' : '';
    }
    if (_selectedQuantityUnit.usesStepControls) {
      return parsed.round().clamp(1, 9999).toString();
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _toggleQuantityUnitDropdown() {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isQuantityUnitDropdownOpen = !_isQuantityUnitDropdownOpen;
    });
  }

  void _selectQuantityUnitOption(int index) {
    if (!mounted || index < 0 || index >= _quantityUnitOptions.length) {
      return;
    }
    final previousUsesStepControls = _selectedQuantityUnit.usesStepControls;
    final previousValue = _quantityController.text;
    setState(() {
      _selectedQuantityUnitIndex = index;
      _isQuantityUnitDropdownOpen = false;
      final normalized = _normalizedQuantityText(previousValue);
      if (!_selectedQuantityUnit.usesStepControls &&
          previousUsesStepControls &&
          normalized == '1') {
        _quantityController.text = '';
      } else {
        _quantityController.text = normalized;
      }
    });
  }

  void _adjustUnitQuantity(int delta) {
    final parsed = int.tryParse(_quantityController.text.trim()) ?? 1;
    final next = (parsed + delta).clamp(1, 9999);
    setState(() {
      _quantityController.text = next.toString();
    });
  }

  bool get _hasPendingCustomEntries => _pendingCustomEntries.isNotEmpty;

  String _dialogCaloriesText(_CustomFoodEntry entry) {
    final parsed = double.tryParse(
      entry.caloriesText.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return '0';
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _savePendingCustomEntries() {
    for (final entry in _pendingCustomEntries) {
      _CustomFoodEntryStore.add(entry);
    }
    _pendingCustomEntries.clear();
  }

  void _discardPendingCustomEntries() {
    _pendingCustomEntries.clear();
  }

  Future<bool?> _showSaveToCustomPrompt(_CustomFoodEntry entry) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext);
        final scale = (math.min(media.size.width, media.size.height) / 390)
            .clamp(0.86, 1.06);
        final cardWidth = math.min(
          322 * scale,
          media.size.width - (32 * scale),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: cardWidth,
                  padding: EdgeInsets.fromLTRB(
                    8 * scale,
                    16 * scale,
                    8 * scale,
                    16 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x52FFFFFF),
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 16 * scale),
                      Text(
                        'Custom Entries',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Borel',
                          fontSize: (32 * scale).clamp(24.0, 36.0),
                          color: Colors.white,
                          height: 0.99,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        '${entry.name}\n( ${_dialogCaloriesText(entry)} Kcal )',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (14 * scale).clamp(12.0, 18.0),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 32 * scale),
                      _RotatingGlassButton(
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: const Color(0x9400B2FF),
                        enablePressShadeFeedback: true,
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Center(
                          child: Text(
                            'Save to Custom',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (20 * scale).clamp(16.0, 24.0),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      _RotatingGlassButton(
                        scale: scale,
                        height: 56 * scale,
                        borderRadius: 32 * scale,
                        fillColor: const Color(0x8FFF0606),
                        enablePressShadeFeedback: true,
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Center(
                          child: Text(
                            'Discard',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (20 * scale).clamp(16.0, 24.0),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _handleBackAttempt() async {
    if (!_hasPendingCustomEntries) {
      return true;
    }
    final promptResult = await _showSaveToCustomPrompt(
      _pendingCustomEntries.last,
    );
    if (promptResult == true) {
      _savePendingCustomEntries();
      return true;
    }
    if (promptResult == false) {
      _discardPendingCustomEntries();
      return true;
    }
    return false;
  }

  Future<void> _goBack() async {
    if (!mounted) {
      return;
    }
    final canPop = await _handleBackAttempt();
    if (!mounted || !canPop) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _ensureFieldVisible(GlobalKey fieldKey) {
    final fieldContext = fieldKey.currentContext;
    if (fieldContext == null || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.25,
      );
    });
  }

  void _ensureFieldVisibleAfterKeyboard({
    required GlobalKey fieldKey,
    required FocusNode focusNode,
  }) {
    _ensureFieldVisible(fieldKey);
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || !focusNode.hasFocus) {
        return;
      }
      _ensureFieldVisible(fieldKey);
    });
  }

  void _commitHourFromController() {
    final parsed = int.tryParse(_hourController.text.trim());
    if (parsed != null && parsed >= 1 && parsed <= 12) {
      var nextHour = parsed % 12;
      if (!_isAmSelected) {
        nextHour += 12;
      }
      setState(() {
        _selectedTime = _selectedTime.replacing(hour: nextHour);
      });
    }
    _hourController.text = _timeHourText;
    _minuteController.text = _timeMinuteText;
  }

  void _commitMinuteFromController() {
    final parsed = int.tryParse(_minuteController.text.trim());
    if (parsed != null && parsed >= 0 && parsed <= 59) {
      setState(() {
        _selectedTime = _selectedTime.replacing(minute: parsed);
      });
    }
    _hourController.text = _timeHourText;
    _minuteController.text = _timeMinuteText;
  }

  void _setAmPm(bool useAm) {
    final hour = _selectedTime.hour;
    int nextHour = hour;
    if (useAm && hour >= 12) {
      nextHour = hour - 12;
    } else if (!useAm && hour < 12) {
      nextHour = hour + 12;
    }
    if (nextHour == hour) {
      return;
    }
    setState(() {
      _selectedTime = _selectedTime.replacing(hour: nextHour);
      _hourController.text = _timeHourText;
      _minuteController.text = _timeMinuteText;
    });
  }

  String _normalizedNumericText(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return '0';
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null) {
      return '0';
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _normalizedBudgetText(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return '';
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return '';
    }
    if ((parsed - parsed.roundToDouble()).abs() < 0.0001) {
      return parsed.round().toString();
    }
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _commitBudgetFromController() {
    final normalized = _normalizedBudgetText(_budgetPriceController.text);
    setState(() {
      _budgetPriceController.text = normalized;
      _budgetPriceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _budgetPriceController.text.length),
      );
    });
  }

  double? _parsedBudgetValue() {
    final normalized = _normalizedBudgetText(_budgetPriceController.text);
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  bool _isBudgetPresetSelected(double preset) {
    final value = _parsedBudgetValue();
    if (value == null) {
      return false;
    }
    return (value - preset).abs() <= 0.0001;
  }

  void _setBudgetPreset(double value) {
    final text = _normalizedBudgetText(value.toString());
    setState(() {
      _budgetPriceController.text = text;
      _budgetPriceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _budgetPriceController.text.length),
      );
    });
  }

  bool get _canAddEntry {
    return _itemNameController.text.trim().isNotEmpty;
  }

  void _resetAfterAdd() {
    setState(() {
      _itemNameController.text = '';
      _quantityController.text = '1';
      _selectedQuantityUnitIndex = 0;
      _isQuantityUnitDropdownOpen = false;
      _budgetPriceController.text = '';
      _caloriesController.text = '0';
      _proteinController.text = '0';
      _carbsController.text = '0';
      _fatController.text = '0';
      _fiberController.text = '0';
      _sugarController.text = '0';
      _sodiumController.text = '0';
      _selectedTime = _currentLocalTimeOfDay();
      _hourController.text = _timeHourText;
      _minuteController.text = _timeMinuteText;
      _isFavorite = false;
      _isAdvanceOpen = false;
    });
  }

  void _addCustomEntry() {
    if (!_canAddEntry) {
      return;
    }
    _quantityController.text = _normalizedQuantityText(
      _quantityController.text,
    );
    final entry = _CustomFoodEntryStore.create(
      name: _itemNameController.text.trim(),
      caloriesText: _normalizedNumericText(_caloriesController.text),
      timeText:
          '$_timeHourText:$_timeMinuteText ${_isAmSelected ? 'AM' : 'PM'}',
      budgetAmountText: _showBudgetSection
          ? _normalizedBudgetText(_budgetPriceController.text)
          : '0',
      proteinText: _normalizedNumericText(_proteinController.text),
      carbohydratesText: _normalizedNumericText(_carbsController.text),
      fatText: _normalizedNumericText(_fatController.text),
      fiberText: _normalizedNumericText(_fiberController.text),
      sugarText: _normalizedNumericText(_sugarController.text),
      sodiumText: _normalizedNumericText(_sodiumController.text),
      isFavorite: _isFavorite,
    );
    _pendingCustomEntries.add(entry);
    _MealsTimelineStore.addOrReplace(
      entryId: _isExchangeMode ? widget.exchangeTargetEntryId : null,
      timeText: entry.timeText,
      itemName: entry.name,
      caloriesText: entry.caloriesText,
      preserveExistingTimeText: _isExchangeMode,
      proteinText: entry.proteinText,
      carbohydratesText: entry.carbohydratesText,
      fatText: entry.fatText,
      fiberText: entry.fiberText,
      sugarText: entry.sugarText,
      sodiumText: entry.sodiumText,
      budgetAmountText: entry.budgetAmountText,
    );
    _resetAfterAdd();
  }

  void _bindFieldFocus({
    required FocusNode focusNode,
    required GlobalKey fieldKey,
    VoidCallback? onFocusLost,
  }) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        if (mounted) {
          setState(() {});
        }
        _ensureFieldVisibleAfterKeyboard(
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      } else {
        if (mounted) {
          setState(() {});
        }
        onFocusLost?.call();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(text: '');
    _quantityController = TextEditingController(text: '1');
    _hourController = TextEditingController(text: _timeHourText);
    _minuteController = TextEditingController(text: _timeMinuteText);
    _budgetPriceController = TextEditingController(text: '');
    _caloriesController = TextEditingController(text: '0');
    _proteinController = TextEditingController(text: '0');
    _carbsController = TextEditingController(text: '0');
    _fatController = TextEditingController(text: '0');
    _fiberController = TextEditingController(text: '0');
    _sugarController = TextEditingController(text: '0');
    _sodiumController = TextEditingController(text: '0');

    _itemNameFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();
    _budgetPriceFocusNode = FocusNode();
    _caloriesFocusNode = FocusNode();
    _proteinFocusNode = FocusNode();
    _carbsFocusNode = FocusNode();
    _fatFocusNode = FocusNode();
    _fiberFocusNode = FocusNode();
    _sugarFocusNode = FocusNode();
    _sodiumFocusNode = FocusNode();

    _bindFieldFocus(focusNode: _itemNameFocusNode, fieldKey: _itemNameFieldKey);
    _bindFieldFocus(
      focusNode: _quantityFocusNode,
      fieldKey: _quantityFieldKey,
      onFocusLost: () {
        _quantityController.text = _normalizedQuantityText(
          _quantityController.text,
        );
      },
    );
    _bindFieldFocus(
      focusNode: _hourFocusNode,
      fieldKey: _hourFieldKey,
      onFocusLost: _commitHourFromController,
    );
    _bindFieldFocus(
      focusNode: _minuteFocusNode,
      fieldKey: _minuteFieldKey,
      onFocusLost: _commitMinuteFromController,
    );
    _bindFieldFocus(
      focusNode: _budgetPriceFocusNode,
      fieldKey: _budgetPriceFieldKey,
      onFocusLost: _commitBudgetFromController,
    );
    _bindFieldFocus(focusNode: _caloriesFocusNode, fieldKey: _caloriesFieldKey);
    _bindFieldFocus(focusNode: _proteinFocusNode, fieldKey: _proteinFieldKey);
    _bindFieldFocus(focusNode: _carbsFocusNode, fieldKey: _carbsFieldKey);
    _bindFieldFocus(focusNode: _fatFocusNode, fieldKey: _fatFieldKey);
    _bindFieldFocus(focusNode: _fiberFocusNode, fieldKey: _fiberFieldKey);
    _bindFieldFocus(focusNode: _sugarFocusNode, fieldKey: _sugarFieldKey);
    _bindFieldFocus(focusNode: _sodiumFocusNode, fieldKey: _sodiumFieldKey);

    for (final controller in <TextEditingController>[
      _itemNameController,
      _quantityController,
      _budgetPriceController,
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
      _fiberController,
      _sugarController,
      _sodiumController,
    ]) {
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }

    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _itemNameFocusNode.dispose();
    _quantityFocusNode.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _budgetPriceFocusNode.dispose();
    _caloriesFocusNode.dispose();
    _proteinFocusNode.dispose();
    _carbsFocusNode.dispose();
    _fatFocusNode.dispose();
    _fiberFocusNode.dispose();
    _sugarFocusNode.dispose();
    _sodiumFocusNode.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _budgetPriceController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _nutritionCard({
    required double scale,
    required String label,
    required String unit,
    required TextEditingController controller,
    required FocusNode focusNode,
    required GlobalKey fieldKey,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (16 * scale).clamp(14.0, 20.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _TodaysEntryGlassTile(
            scale: scale,
            width: (140 * scale).clamp(120.0, 168.0),
            height: 47 * scale,
            borderRadius: 15 * scale,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            inactiveFillColor: const Color(0x52FFFFFF),
            selectedFillColor: Colors.white,
            isSelected: focusNode.hasFocus,
            unfocusOnLongPress: true,
            onTap: () => focusNode.requestFocus(),
            child: Center(
              child: SizedBox(
                key: fieldKey,
                width: double.infinity,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  scrollPadding: EdgeInsets.zero,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textInputAction: TextInputAction.done,
                  enableInteractiveSelection: false,
                  onSubmitted: (_) => focusNode.unfocus(),
                  onTapOutside: (_) => focusNode.unfocus(),
                  decoration: const InputDecoration.collapsed(hintText: '0'),
                  style: TextStyle(
                    fontFamily: _defaultNonBorelFontFamily,
                    fontSize: (24 * scale).clamp(18.0, 30.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          SizedBox(
            width: 28 * scale,
            child: Text(
              unit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (14 * scale).clamp(12.0, 18.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityUnitDropdownPanel(double scale) {
    final panelRadius = BorderRadius.circular(16 * scale);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: panelRadius,
      ),
      child: Column(
        children: List<Widget>.generate(_quantityUnitOptions.length, (index) {
          final option = _quantityUnitOptions[index];
          final isSelected = index == _selectedQuantityUnitIndex;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _quantityUnitOptions.length - 1 ? 0 : 16 * scale,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectQuantityUnitOption(index),
              child: Container(
                width: 218 * scale,
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(
                    color: const Color(0x80FFFFFF),
                    width: (1 * scale).clamp(0.8, 1.4),
                  ),
                  boxShadow: isSelected
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: Color(0xFFFF0000),
                            blurRadius: 2,
                            blurStyle: BlurStyle.outer,
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: Text(
                  option.dropdownLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _defaultNonBorelFontFamily,
                    fontSize: (24 * scale).clamp(18.0, 28.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuantityCard(double scale) {
    final showsStepControls = _selectedQuantityUnit.usesStepControls;
    final quantityHintText = showsStepControls
        ? '1'
        : (_quantityFocusNode.hasFocus ? '' : '0');
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x3DFFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showsStepControls) ...[
                _TodaysEntryGlassTile(
                  scale: scale,
                  width: 47 * scale,
                  height: 47 * scale,
                  borderRadius: 15 * scale,
                  padding: EdgeInsets.zero,
                  inactiveFillColor: const Color(0x52FFFFFF),
                  selectedFillColor: const Color(0x52FFFFFF),
                  unfocusOnLongPress: true,
                  onTap: () => _adjustUnitQuantity(-1),
                  child: Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: (24 * scale).clamp(18.0, 28.0),
                  ),
                ),
                SizedBox(width: 8 * scale),
              ],
              _TodaysEntryGlassTile(
                scale: scale,
                width: 140 * scale,
                height: 47 * scale,
                borderRadius: 15 * scale,
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                inactiveFillColor: const Color(0x52FFFFFF),
                selectedFillColor: Colors.white,
                isSelected: _quantityFocusNode.hasFocus,
                unfocusOnLongPress: true,
                onTap: () => _quantityFocusNode.requestFocus(),
                child: Center(
                  child: SizedBox(
                    key: _quantityFieldKey,
                    width: double.infinity,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPressDown: (_) => _quantityFocusNode.unfocus(),
                      onLongPressStart: (_) => _quantityFocusNode.unfocus(),
                      onLongPressEnd: (_) => _quantityFocusNode.unfocus(),
                      onLongPressCancel: _quantityFocusNode.unfocus,
                      onLongPress: _quantityFocusNode.unfocus,
                      child: TextField(
                        controller: _quantityController,
                        focusNode: _quantityFocusNode,
                        scrollPadding: EdgeInsets.zero,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        textInputAction: TextInputAction.done,
                        enableInteractiveSelection: false,
                        onSubmitted: (_) => _quantityFocusNode.unfocus(),
                        onTapOutside: (_) => _quantityFocusNode.unfocus(),
                        decoration: InputDecoration.collapsed(
                          hintText: quantityHintText,
                          hintStyle: TextStyle(
                            fontFamily: _defaultNonBorelFontFamily,
                            fontSize: (24 * scale).clamp(18.0, 30.0),
                            color: const Color(0x80000000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (24 * scale).clamp(18.0, 30.0),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showsStepControls) ...[
                SizedBox(width: 8 * scale),
                _TodaysEntryGlassTile(
                  scale: scale,
                  width: 47 * scale,
                  height: 47 * scale,
                  borderRadius: 15 * scale,
                  padding: EdgeInsets.zero,
                  inactiveFillColor: const Color(0x52FFFFFF),
                  selectedFillColor: const Color(0x52FFFFFF),
                  unfocusOnLongPress: true,
                  onTap: () => _adjustUnitQuantity(1),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: (24 * scale).clamp(18.0, 28.0),
                  ),
                ),
              ] else ...[
                SizedBox(width: 16 * scale),
                Text(
                  _selectedQuantityUnit.displaySuffix,
                  style: TextStyle(
                    fontFamily: _defaultNonBorelFontFamily,
                    fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleQuantityUnitDropdown,
            child: SizedBox(
              width: 16 * scale,
              height: 16 * scale,
              child: Icon(
                _isQuantityUnitDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white,
                size: (20 * scale).clamp(16.0, 24.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (18 * scale);
          final contentTop = titleTop + (42 * scale);
          final controlsBottom = _actionControlsBottomInset(
            metrics: metrics,
            scale: scale,
          );
          final bottomRowHeight = 56 * scale;
          final blurPanelHeight = bottomRowHeight + controlsBottom;
          final scrollBottomPadding =
              blurPanelHeight + keyboardInset + (24 * scale);

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: contentTop,
                bottom: 0,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    contentLeft,
                    16,
                    contentLeft,
                    scrollBottomPadding,
                  ),
                  children: [
                    Text(
                      'Item Name',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _TodaysEntryGlassTile(
                            scale: scale,
                            height: 56 * scale,
                            borderRadius: 16 * scale,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 16 * scale,
                            ),
                            inactiveFillColor: const Color(0x52FFFFFF),
                            selectedFillColor: Colors.white,
                            isSelected: _itemNameFocusNode.hasFocus,
                            unfocusOnLongPress: true,
                            onTap: () => _itemNameFocusNode.requestFocus(),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                key: _itemNameFieldKey,
                                width: double.infinity,
                                child: TextField(
                                  controller: _itemNameController,
                                  focusNode: _itemNameFocusNode,
                                  scrollPadding: EdgeInsets.zero,
                                  textAlign: TextAlign.left,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) =>
                                      _itemNameFocusNode.unfocus(),
                                  onTapOutside: (_) =>
                                      _itemNameFocusNode.unfocus(),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Item Name',
                                  ),
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16 * scale),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _isFavorite = !_isFavorite;
                            });
                          },
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? const Color(0xFFFF0000)
                                : Colors.white,
                            size: (28 * scale).clamp(22.0, 32.0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * scale),
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    _buildQuantityCard(scale),
                    if (_isQuantityUnitDropdownOpen) ...[
                      SizedBox(height: 16 * scale),
                      _buildQuantityUnitDropdownPanel(scale),
                    ],
                    SizedBox(height: 24 * scale),
                    Text(
                      'Meal Time',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    Container(
                      padding: EdgeInsets.all(16 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0x52FFFFFF),
                        borderRadius: BorderRadius.circular(16 * scale),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TodaysEntryGlassTile(
                            scale: scale,
                            width: 62 * scale,
                            height: 82 * scale,
                            borderRadius: 15 * scale,
                            inactiveFillColor: const Color(0x52FFFFFF),
                            selectedFillColor: Colors.white,
                            isSelected: _hourFocusNode.hasFocus,
                            unfocusOnLongPress: true,
                            onTap: () => _hourFocusNode.requestFocus(),
                            child: Center(
                              child: SizedBox(
                                key: _hourFieldKey,
                                width: double.infinity,
                                child: TextField(
                                  controller: _hourController,
                                  focusNode: _hourFocusNode,
                                  scrollPadding: EdgeInsets.zero,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) => _hourFocusNode.unfocus(),
                                  onTapOutside: (_) => _hourFocusNode.unfocus(),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: '',
                                  ),
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (24 * scale).clamp(18.0, 30.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            ':',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (30 * scale).clamp(22.0, 34.0),
                              color: const Color(0x80FFFFFF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          _TodaysEntryGlassTile(
                            scale: scale,
                            width: 62 * scale,
                            height: 82 * scale,
                            borderRadius: 15 * scale,
                            inactiveFillColor: const Color(0x52FFFFFF),
                            selectedFillColor: Colors.white,
                            isSelected: _minuteFocusNode.hasFocus,
                            unfocusOnLongPress: true,
                            onTap: () => _minuteFocusNode.requestFocus(),
                            child: Center(
                              child: SizedBox(
                                key: _minuteFieldKey,
                                width: double.infinity,
                                child: TextField(
                                  controller: _minuteController,
                                  focusNode: _minuteFocusNode,
                                  scrollPadding: EdgeInsets.zero,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) =>
                                      _minuteFocusNode.unfocus(),
                                  onTapOutside: (_) =>
                                      _minuteFocusNode.unfocus(),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: '',
                                  ),
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (24 * scale).clamp(18.0, 30.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Column(
                            children: [
                              _TodaysEntryGlassTile(
                                scale: scale,
                                borderRadius: 15 * scale,
                                padding: EdgeInsets.all(8 * scale),
                                isSelected: _isAmSelected,
                                unfocusOnLongPress: true,
                                onTap: () => _setAmPm(true),
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              _TodaysEntryGlassTile(
                                scale: scale,
                                borderRadius: 15 * scale,
                                padding: EdgeInsets.all(8 * scale),
                                isSelected: !_isAmSelected,
                                unfocusOnLongPress: true,
                                onTap: () => _setAmPm(false),
                                child: Text(
                                  'PM',
                                  style: TextStyle(
                                    fontFamily: _defaultNonBorelFontFamily,
                                    fontSize: (16 * scale).clamp(14.0, 20.0),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * scale),
                    if (_showBudgetSection) ...[
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontFamily: _defaultNonBorelFontFamily,
                          fontSize: (16 * scale).clamp(14.0, 20.0),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Container(
                        padding: EdgeInsets.all(8 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0x3DFFFFFF),
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0x3DFFFFFF),
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (16 * scale).clamp(14.0, 20.0),
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _budgetCurrencyGlyph,
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (14 * scale).clamp(12.0, 18.0),
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  _TodaysEntryGlassTile(
                                    scale: scale,
                                    width: (140 * scale).clamp(120.0, 168.0),
                                    height: 47 * scale,
                                    borderRadius: 15 * scale,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * scale,
                                      vertical: 8 * scale,
                                    ),
                                    inactiveFillColor: const Color(0x3DFFFFFF),
                                    selectedFillColor: Colors.white,
                                    isSelected: _budgetPriceFocusNode.hasFocus,
                                    unfocusOnLongPress: true,
                                    onTap: () =>
                                        _budgetPriceFocusNode.requestFocus(),
                                    child: Center(
                                      child: SizedBox(
                                        key: _budgetPriceFieldKey,
                                        width: double.infinity,
                                        child: TextField(
                                          controller: _budgetPriceController,
                                          focusNode: _budgetPriceFocusNode,
                                          scrollPadding: EdgeInsets.zero,
                                          textAlign: TextAlign.center,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9.,]'),
                                            ),
                                          ],
                                          textInputAction: TextInputAction.done,
                                          enableInteractiveSelection: false,
                                          onSubmitted: (_) =>
                                              _budgetPriceFocusNode.unfocus(),
                                          onTapOutside: (_) =>
                                              _budgetPriceFocusNode.unfocus(),
                                          decoration: InputDecoration.collapsed(
                                            hintText: '0',
                                            hintStyle: TextStyle(
                                              fontFamily:
                                                  _defaultNonBorelFontFamily,
                                              fontSize: (24 * scale).clamp(
                                                18.0,
                                                30.0,
                                              ),
                                              color: const Color(0x29000000),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontFamily:
                                                _defaultNonBorelFontFamily,
                                            fontSize: (24 * scale).clamp(
                                              18.0,
                                              30.0,
                                            ),
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Text(
                                    '/meal',
                                    style: TextStyle(
                                      fontFamily: _defaultNonBorelFontFamily,
                                      fontSize: (14 * scale).clamp(12.0, 18.0),
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            Row(
                              children: _budgetPresetValues
                                  .map((preset) {
                                    final isSelected = _isBudgetPresetSelected(
                                      preset,
                                    );
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right:
                                              preset == _budgetPresetValues.last
                                              ? 0
                                              : 16 * scale,
                                        ),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _setBudgetPreset(preset),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16 * scale,
                                              vertical: 8 * scale,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0x52FFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    15 * scale,
                                                  ),
                                              border: Border.all(
                                                color: const Color(0x80FFFFFF),
                                                width: (1 * scale).clamp(
                                                  0.8,
                                                  1.4,
                                                ),
                                              ),
                                              boxShadow: isSelected
                                                  ? const <BoxShadow>[
                                                      BoxShadow(
                                                        color: Color(
                                                          0xFFFF0000,
                                                        ),
                                                        blurRadius: 4,
                                                        blurStyle:
                                                            BlurStyle.outer,
                                                      ),
                                                    ]
                                                  : const <BoxShadow>[],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_budgetCurrencyGlyph ${preset.toInt()}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily:
                                                      _defaultNonBorelFontFamily,
                                                  fontSize: (24 * scale).clamp(
                                                    18.0,
                                                    30.0,
                                                  ),
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                    ],
                    Text(
                      'Nutritional Value',
                      style: TextStyle(
                        fontFamily: _defaultNonBorelFontFamily,
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 18 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Calories',
                      unit: 'kcal',
                      controller: _caloriesController,
                      focusNode: _caloriesFocusNode,
                      fieldKey: _caloriesFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Protein',
                      unit: 'g',
                      controller: _proteinController,
                      focusNode: _proteinFocusNode,
                      fieldKey: _proteinFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Carbohydrates',
                      unit: 'g',
                      controller: _carbsController,
                      focusNode: _carbsFocusNode,
                      fieldKey: _carbsFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    _nutritionCard(
                      scale: scale,
                      label: 'Fat',
                      unit: 'g',
                      controller: _fatController,
                      focusNode: _fatFocusNode,
                      fieldKey: _fatFieldKey,
                    ),
                    SizedBox(height: 16 * scale),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isAdvanceOpen = !_isAdvanceOpen;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Advance',
                            style: TextStyle(
                              fontFamily: _defaultNonBorelFontFamily,
                              fontSize: (20 * scale).clamp(16.0, 24.0),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 16 * scale),
                          Icon(
                            _isAdvanceOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: (26 * scale).clamp(20.0, 30.0),
                          ),
                        ],
                      ),
                    ),
                    if (_isAdvanceOpen) ...[
                      SizedBox(height: 16 * scale),
                      _nutritionCard(
                        scale: scale,
                        label: 'Fiber',
                        unit: 'g',
                        controller: _fiberController,
                        focusNode: _fiberFocusNode,
                        fieldKey: _fiberFieldKey,
                      ),
                      SizedBox(height: 16 * scale),
                      _nutritionCard(
                        scale: scale,
                        label: 'Sugar',
                        unit: 'g',
                        controller: _sugarController,
                        focusNode: _sugarFocusNode,
                        fieldKey: _sugarFieldKey,
                      ),
                      SizedBox(height: 16 * scale),
                      _nutritionCard(
                        scale: scale,
                        label: 'Sodium',
                        unit: 'mg',
                        controller: _sodiumController,
                        focusNode: _sodiumFocusNode,
                        fieldKey: _sodiumFieldKey,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 48 * scale,
                    child: Center(
                      child: Text(
                        'New Custom Entry',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Borel',
                          fontSize: (32 * scale).clamp(24.0, 42.0),
                          color: Colors.white,
                          height: 0.99,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: blurPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    SizedBox(
                      width: 79 * scale,
                      child: _TodaysEntryGlassTile(
                        scale: scale,
                        height: bottomRowHeight,
                        borderRadius: 32 * scale,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        onTap: _goBack,
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFFFD206),
                          size: (26 * scale).clamp(20.0, 30.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    Expanded(
                      child: _GlassNextButton(
                        scale: scale,
                        label: _timelineActionLabel,
                        showArrowIcon: false,
                        trailingIcon: _showTimelineActionIcon
                            ? Icons.add
                            : null,
                        trailingIconSize: 24,
                        enabled: _canAddEntry,
                        onTap: _addCustomEntry,
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

class _TodaysEntryWaterAmountChip extends StatefulWidget {
  const _TodaysEntryWaterAmountChip({
    required this.scale,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TodaysEntryWaterAmountChip> createState() =>
      _TodaysEntryWaterAmountChipState();
}

class _TodaysEntryWaterAmountChipState
    extends State<_TodaysEntryWaterAmountChip> {
  static const Duration _tapFlashDuration = Duration(milliseconds: 120);

  bool _isLongPressed = false;
  bool _isClicked = false;

  void _flashTapState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isClicked = true;
      _isLongPressed = false;
    });
    Future<void>.delayed(_tapFlashDuration, () {
      if (!mounted || widget.isSelected || _isLongPressed || !_isClicked) {
        return;
      }
      setState(() {
        _isClicked = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _TodaysEntryWaterAmountChip oldWidget) {
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
        _flashTapState();
        widget.onTap();
      },
      child: SizedBox(
        width: 98,
        height: 47,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 15 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.zero,
          expandToBounds: true,
          boxShadow: shadows,
          enableBlur: false,
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: _defaultNonBorelFontFamily,
                fontSize: (24 * scale).clamp(18.0, 28.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodaysEntryGlassTile extends StatefulWidget {
  const _TodaysEntryGlassTile({
    required this.scale,
    required this.borderRadius,
    required this.child,
    required this.onTap,
    this.width,
    this.height,
    this.padding,
    this.isSelected = false,
    this.inactiveFillColor = const Color(0x52FFFFFF),
    this.selectedFillColor = Colors.white,
    this.unfocusOnLongPress = false,
  });

  final double scale;
  final double borderRadius;
  final Widget child;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;
  final Color inactiveFillColor;
  final Color selectedFillColor;
  final bool unfocusOnLongPress;

  @override
  State<_TodaysEntryGlassTile> createState() => _TodaysEntryGlassTileState();
}

class _TodaysEntryGlassTileState extends State<_TodaysEntryGlassTile> {
  static const Duration _tapFlashDuration = Duration(milliseconds: 120);

  bool _isLongPressed = false;
  bool _isClicked = false;

  void _unfocusIfNeeded() {
    if (!widget.unfocusOnLongPress) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _resetLongPressState() {
    if (!mounted) {
      return;
    }
    if (!_isLongPressed && !_isClicked) {
      return;
    }
    setState(() {
      _isLongPressed = false;
      _isClicked = false;
    });
  }

  void _flashTapState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isClicked = true;
      _isLongPressed = false;
    });
    Future<void>.delayed(_tapFlashDuration, () {
      if (!mounted || widget.isSelected || _isLongPressed || !_isClicked) {
        return;
      }
      setState(() {
        _isClicked = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _TodaysEntryGlassTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && _isClicked && !_isLongPressed) {
      setState(() {
        _isClicked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isClicked || widget.isSelected;
    final fillColor = _isLongPressed
        ? Colors.transparent
        : (isActive ? widget.selectedFillColor : widget.inactiveFillColor);
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

    Widget tile = _RotatingGlassPanel(
      scale: widget.scale,
      borderRadius: widget.borderRadius,
      fillColor: fillColor,
      padding: widget.padding ?? EdgeInsets.zero,
      // Fill vertical size when height is provided, but avoid width-only
      // expansion (which can create infinite-height constraints in rows).
      expandToBounds: widget.height != null,
      boxShadow: shadows,
      enableBlur: false,
      child: widget.child,
    );

    if (widget.width != null || widget.height != null) {
      tile = SizedBox(width: widget.width, height: widget.height, child: tile);
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) {
        if (_isLongPressed) {
          _unfocusIfNeeded();
          _resetLongPressState();
        }
      },
      onPointerCancel: (_) {
        if (_isLongPressed) {
          _unfocusIfNeeded();
          _resetLongPressState();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressDown: (_) {
          _unfocusIfNeeded();
          setState(() {
            _isLongPressed = true;
            _isClicked = false;
          });
        },
        onLongPressStart: (_) {
          _unfocusIfNeeded();
          setState(() {
            _isLongPressed = true;
            _isClicked = false;
          });
        },
        onLongPressUp: () {
          _unfocusIfNeeded();
          _resetLongPressState();
        },
        onLongPressEnd: (_) {
          _unfocusIfNeeded();
          _resetLongPressState();
        },
        onLongPressCancel: () {
          _unfocusIfNeeded();
          _resetLongPressState();
        },
        onTap: () {
          _flashTapState();
          widget.onTap();
        },
        child: tile,
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.skippedBudgetSection,
    required this.skippedWaterSection,
  });

  final bool skippedBudgetSection;
  final bool skippedWaterSection;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accountCardFillColor = Color(0x52FFFFFF);

  late final AnimationController _controller;
  late final TextEditingController _accountNameController;
  late final FocusNode _accountNameFocusNode;
  int _selectedGoalIndex = 2;
  int _selectedAge = 21;
  int _selectedWeightKg = 66;
  bool _isWeightInKg = true;
  int _selectedHeightCm = 160;
  bool _isHeightInCm = true;
  int _selectedActivityIndex = 1;
  bool _budgetEnabled = true;
  bool _skippedBudgetSection = false;
  bool _hydrationEnabled = true;
  bool _skippedWaterSection = false;
  String _hydrationGoalText = '3';
  bool _isHydrationInLiters = true;
  String _budgetCurrencyCode = 'INR';
  int? _selectedBudgetPerMeal = 200;
  String _customBudgetPerMeal = '';
  bool _isCustomBudgetPerMeal = false;
  int _selectedDietPreferenceIndex = _defaultDietPreferenceIndex;
  Map<String, String> _nutritionGoalValues = Map<String, String>.from(
    _defaultNutritionGoalValues,
  );
  Map<String, String> _advancedNutritionGoalValues = Map<String, String>.from(
    _defaultAdvancedNutritionGoalValues,
  );

  static const List<String> _goalLabels = <String>[
    'Lose Weight',
    'Gain Weight',
    'Gain Muscle',
    'Maintain',
  ];
  static const List<String> _activityLabels = <String>[
    'Low',
    'Light',
    'Moderate',
    'Active',
    'Athlete',
  ];
  static const List<String> _dietPreferenceLabels = <String>[
    'Vegetarian',
    'Non-vegetarian',
    'Eggetarian',
    'Vegan',
  ];

  @override
  void initState() {
    super.initState();
    _accountNameController = TextEditingController(
      text: _OnboardingProfileState.selectedName.trim(),
    );
    _accountNameFocusNode = FocusNode();
    _accountNameFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _selectedGoalIndex = _OnboardingProfileState.selectedGoalIndex.clamp(
      0,
      _goalLabels.length - 1,
    );
    _selectedAge = _OnboardingProfileState.selectedAge.clamp(0, 110);
    _selectedWeightKg = _OnboardingProfileState.selectedWeightKg.clamp(20, 300);
    _isWeightInKg = _OnboardingProfileState.isWeightInKg;
    _selectedHeightCm = _OnboardingProfileState.selectedHeightCm.clamp(
      100,
      240,
    );
    _isHeightInCm = _OnboardingProfileState.isHeightInCm;
    _selectedActivityIndex = _OnboardingProfileState.selectedActivityIndex
        .clamp(0, _activityLabels.length - 1);
    _budgetEnabled = _OnboardingProfileState.budgetEnabled;
    _skippedBudgetSection = _OnboardingSkipFlags.skippedBudgetSection;
    _hydrationEnabled = _OnboardingProfileState.hydrationEnabled;
    _skippedWaterSection = _OnboardingSkipFlags.skippedWaterSection;
    _hydrationGoalText = _OnboardingProfileState.hydrationGoalText;
    _isHydrationInLiters = _OnboardingProfileState.isHydrationInLiters;
    _budgetCurrencyCode = _OnboardingProfileState.budgetCurrencyCode;
    _selectedBudgetPerMeal = _OnboardingProfileState.selectedBudgetPerMeal;
    _customBudgetPerMeal = _OnboardingProfileState.customBudgetPerMeal;
    _isCustomBudgetPerMeal = _OnboardingProfileState.isCustomBudgetPerMeal;
    _nutritionGoalValues = Map<String, String>.from(
      _OnboardingProfileState.nutritionGoalValues,
    );
    _advancedNutritionGoalValues = Map<String, String>.from(
      _OnboardingProfileState.advancedNutritionGoalValues,
    );
    _selectedDietPreferenceIndex = _OnboardingProfileState
        .selectedDietPreferenceIndex
        .clamp(0, _dietPreferenceLabels.length - 1)
        .toInt();
    _controller = AnimationController(
      vsync: this,
      duration: _kBackgroundMotionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _accountNameFocusNode.dispose();
    _accountNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goToDailyProgressTab(int tabIndex) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      _buildNoTransitionRoute(
        screen: tabIndex == 3
            ? const TodaysEntryScreen()
            : DailyProgressScreen(initialSelectedBottomNavIndex: tabIndex),
      ),
    );
  }

  void _refreshCalculatedTargetsFromInputs() {
    final recommendation = _computeNutritionRecommendation(
      goalIndex: _selectedGoalIndex,
      ageYears: _selectedAge,
      weightKg: _selectedWeightKg,
      heightCm: _selectedHeightCm,
      activityIndex: _selectedActivityIndex,
      genderIndex: _OnboardingProfileState.selectedGenderIndex,
    );
    _nutritionGoalValues = Map<String, String>.from(recommendation.goalValues);
    _advancedNutritionGoalValues = Map<String, String>.from(
      recommendation.advancedGoalValues,
    );
    _hydrationGoalText = _computeHydrationGoalTextFromProfile(
      goalIndex: _selectedGoalIndex,
      weightKg: _selectedWeightKg,
      activityIndex: _selectedActivityIndex,
      outputInLiters: _isHydrationInLiters,
    );

    _OnboardingProfileState.nutritionGoalValues = Map<String, String>.from(
      _nutritionGoalValues,
    );
    _OnboardingProfileState.advancedNutritionGoalValues =
        Map<String, String>.from(_advancedNutritionGoalValues);
    _OnboardingProfileState.hydrationGoalText = _hydrationGoalText;
    _OnboardingProfileState.isHydrationInLiters = _isHydrationInLiters;
  }

  Future<void> _openGoalScreen() async {
    if (!mounted) {
      return;
    }
    final updatedGoalIndex = await Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        transitionDuration: _kScreenFadeDuration,
        reverseTransitionDuration: _kScreenFadeDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AccountGoalScreen(initialSelectedGoalIndex: _selectedGoalIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );
          return RepaintBoundary(
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
    if (!mounted || updatedGoalIndex == null) {
      return;
    }
    final clampedGoalIndex = updatedGoalIndex.clamp(0, _goalLabels.length - 1);
    setState(() {
      _selectedGoalIndex = clampedGoalIndex;
      _refreshCalculatedTargetsFromInputs();
    });
    _OnboardingProfileState.selectedGoalIndex = clampedGoalIndex;
  }

  PageRouteBuilder<T> _buildAccountEditRoute<T>({required Widget screen}) {
    return PageRouteBuilder<T>(
      transitionDuration: _kScreenFadeDuration,
      reverseTransitionDuration: _kScreenFadeDuration,
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            );
        return RepaintBoundary(
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }

  Future<void> _openAgeScreen() async {
    if (!mounted) {
      return;
    }
    final updatedAge = await Navigator.of(context).push<int>(
      _buildAccountEditRoute<int>(
        screen: AgeScreen(initialAge: _selectedAge, isAccountEdit: true),
      ),
    );
    if (!mounted || updatedAge == null) {
      return;
    }
    final clampedAge = updatedAge.clamp(0, 110);
    setState(() {
      _selectedAge = clampedAge;
      _refreshCalculatedTargetsFromInputs();
    });
    _OnboardingProfileState.selectedAge = clampedAge;
  }

  Future<void> _openWeightScreen() async {
    if (!mounted) {
      return;
    }
    final updatedWeight = await Navigator.of(context)
        .push<_AccountWeightSelection>(
          _buildAccountEditRoute<_AccountWeightSelection>(
            screen: WeightScreen(
              initialWeightKg: _selectedWeightKg,
              initialWeightInKg: _isWeightInKg,
              isAccountEdit: true,
            ),
          ),
        );
    if (!mounted || updatedWeight == null) {
      return;
    }
    setState(() {
      _selectedWeightKg = updatedWeight.weightKg.clamp(20, 300);
      _isWeightInKg = updatedWeight.isWeightInKg;
      _refreshCalculatedTargetsFromInputs();
    });
    _OnboardingProfileState.selectedWeightKg = _selectedWeightKg;
    _OnboardingProfileState.isWeightInKg = _isWeightInKg;
  }

  Future<void> _openHeightScreen() async {
    if (!mounted) {
      return;
    }
    final updatedHeight = await Navigator.of(context)
        .push<_AccountHeightSelection>(
          _buildAccountEditRoute<_AccountHeightSelection>(
            screen: HeightScreen(
              initialHeightCm: _selectedHeightCm,
              initialHeightInCm: _isHeightInCm,
              isAccountEdit: true,
            ),
          ),
        );
    if (!mounted || updatedHeight == null) {
      return;
    }
    setState(() {
      _selectedHeightCm = updatedHeight.heightCm.clamp(100, 240);
      _isHeightInCm = updatedHeight.isHeightInCm;
      _refreshCalculatedTargetsFromInputs();
    });
    _OnboardingProfileState.selectedHeightCm = _selectedHeightCm;
    _OnboardingProfileState.isHeightInCm = _isHeightInCm;
  }

  Future<void> _openActivityScreen() async {
    if (!mounted) {
      return;
    }
    final updatedIndex = await Navigator.of(context).push<int>(
      _buildAccountEditRoute<int>(
        screen: DailyActivityScreen(
          initialSelectedIndex: _selectedActivityIndex,
          isAccountEdit: true,
        ),
      ),
    );
    if (!mounted || updatedIndex == null) {
      return;
    }
    final clampedIndex = updatedIndex.clamp(0, _activityLabels.length - 1);
    setState(() {
      _selectedActivityIndex = clampedIndex;
      _refreshCalculatedTargetsFromInputs();
    });
    _OnboardingProfileState.selectedActivityIndex = clampedIndex;
  }

  bool get _hasEnteredBudget {
    final customValue = _customBudgetPerMeal.trim();
    final hasValue = _isCustomBudgetPerMeal
        ? customValue.isNotEmpty
        : _selectedBudgetPerMeal != null;
    return _budgetEnabled && !_skippedBudgetSection && hasValue;
  }

  String _budgetValueLabel() {
    final glyph =
        _budgetCurrencyGlyphByCode[_budgetCurrencyCode] ?? _budgetCurrencyCode;
    final amount = _isCustomBudgetPerMeal
        ? _customBudgetPerMeal.trim()
        : (_selectedBudgetPerMeal?.toString() ?? '');
    if (amount.isEmpty) {
      return '';
    }
    return '$glyph $amount';
  }

  double? _parseHydrationGoalValue(String input) {
    final normalized = input.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  bool get _hasEnteredHydration {
    final hydrationGoal = _parseHydrationGoalValue(_hydrationGoalText);
    return _hydrationEnabled &&
        !_skippedWaterSection &&
        hydrationGoal != null &&
        hydrationGoal > 0;
  }

  String _hydrationValueLabel() {
    final hydrationGoal = _hydrationGoalText.trim();
    if (hydrationGoal.isEmpty) {
      return '';
    }
    return '$hydrationGoal ${_isHydrationInLiters ? 'l' : 'oz'}';
  }

  Future<void> _openBudgetScreen() async {
    if (!mounted) {
      return;
    }
    final result = await Navigator.of(context).push<_AccountBudgetSelection>(
      _buildAccountEditRoute<_AccountBudgetSelection>(
        screen: BudgetPerMealScreen(
          isAccountEdit: true,
          showDisableButton: _hasEnteredBudget,
          initialSelectedBudget: _selectedBudgetPerMeal,
          initialCustomBudget: _customBudgetPerMeal,
          initialIsCustomSelected: _isCustomBudgetPerMeal,
          initialCurrencyCode: _budgetCurrencyCode,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _budgetEnabled = result.budgetEnabled;
      _skippedBudgetSection = result.skippedBudgetSection;
      _budgetCurrencyCode = result.currencyCode;
      _selectedBudgetPerMeal = result.selectedBudgetPerMeal;
      _customBudgetPerMeal = result.customBudgetPerMeal;
      _isCustomBudgetPerMeal = result.isCustomBudgetPerMeal;
    });

    _OnboardingProfileState.budgetEnabled = result.budgetEnabled;
    _OnboardingProfileState.budgetCurrencyCode = result.currencyCode;
    _OnboardingProfileState.selectedBudgetPerMeal =
        result.selectedBudgetPerMeal;
    _OnboardingProfileState.customBudgetPerMeal = result.customBudgetPerMeal;
    _OnboardingProfileState.isCustomBudgetPerMeal =
        result.isCustomBudgetPerMeal;
    _OnboardingSkipFlags.skippedBudgetSection = result.skippedBudgetSection;
  }

  Future<void> _openNutritionGoalsScreen() async {
    if (!mounted) {
      return;
    }
    final recommendation = _computeNutritionRecommendation(
      goalIndex: _selectedGoalIndex,
      ageYears: _selectedAge,
      weightKg: _selectedWeightKg,
      heightCm: _selectedHeightCm,
      activityIndex: _selectedActivityIndex,
      genderIndex: _OnboardingProfileState.selectedGenderIndex,
    );
    final result = await Navigator.of(context).push<_AccountNutritionSelection>(
      _buildAccountEditRoute<_AccountNutritionSelection>(
        screen: AccountDailyNutritionGoalsScreen(
          initialGoalValues: recommendation.goalValues,
          initialAdvancedGoalValues: recommendation.advancedGoalValues,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _nutritionGoalValues = Map<String, String>.from(result.goalValues);
      _advancedNutritionGoalValues = Map<String, String>.from(
        result.advancedGoalValues,
      );
    });
    _OnboardingProfileState.nutritionGoalValues = Map<String, String>.from(
      result.goalValues,
    );
    _OnboardingProfileState.advancedNutritionGoalValues =
        Map<String, String>.from(result.advancedGoalValues);
  }

  Future<void> _openHydrationGoalsScreen() async {
    if (!mounted) {
      return;
    }
    final recommendedHydrationGoalText = _computeHydrationGoalTextFromProfile(
      goalIndex: _selectedGoalIndex,
      weightKg: _selectedWeightKg,
      activityIndex: _selectedActivityIndex,
      outputInLiters: _isHydrationInLiters,
    );
    final result = await Navigator.of(context).push<_AccountHydrationSelection>(
      _buildAccountEditRoute<_AccountHydrationSelection>(
        screen: AccountDailyHydrationGoalsScreen(
          initiallySkippedHydrationSection: _skippedWaterSection,
          initialHydrationEnabled: _hydrationEnabled,
          initialHydrationGoalText: recommendedHydrationGoalText,
          initialHydrationInLiters: _isHydrationInLiters,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _hydrationEnabled = result.hydrationEnabled;
      _skippedWaterSection = result.skippedHydrationSection;
      _hydrationGoalText = result.hydrationGoalText;
      _isHydrationInLiters = result.isHydrationInLiters;
    });

    _OnboardingProfileState.hydrationEnabled = result.hydrationEnabled;
    _OnboardingProfileState.hydrationGoalText = result.hydrationGoalText;
    _OnboardingProfileState.isHydrationInLiters = result.isHydrationInLiters;
    _OnboardingSkipFlags.skippedWaterSection = result.skippedHydrationSection;
  }

  Future<void> _openDietPreferenceScreen() async {
    if (!mounted) {
      return;
    }
    final selectedIndex = await Navigator.of(context).push<int>(
      _buildAccountEditRoute<int>(
        screen: AccountDietPreferenceScreen(
          initialSelectedIndex: _selectedDietPreferenceIndex,
        ),
      ),
    );
    if (!mounted || selectedIndex == null) {
      return;
    }
    final clampedIndex = selectedIndex
        .clamp(0, _dietPreferenceLabels.length - 1)
        .toInt();
    setState(() => _selectedDietPreferenceIndex = clampedIndex);
    _OnboardingProfileState.selectedDietPreferenceIndex = clampedIndex;
  }

  Future<void> _openTermsScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      _buildAccountEditRoute<void>(screen: const AccountTermsScreen()),
    );
  }

  Future<void> _openAccountDeletionScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      _buildAccountEditRoute<void>(screen: const AccountDeletionScreen()),
    );
  }

  Widget _sectionTitle(String title, double scale) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Borel',
        fontSize: (32 * scale).clamp(24.0, 40.0),
        color: Colors.white,
        height: 0.99,
      ),
    );
  }

  Widget _nameCard({required double scale}) {
    final isFocused = _accountNameFocusNode.hasFocus;
    return SizedBox(
      height: 56 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _accountNameFocusNode.requestFocus(),
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: isFocused ? Colors.white : _accountCardFillColor,
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          expandToBounds: true,
          boxShadow: isFocused
              ? const [
                  BoxShadow(
                    color: Color(0xFFFF0000),
                    blurRadius: 4,
                    blurStyle: BlurStyle.outer,
                  ),
                ]
              : const <BoxShadow>[],
          enableBlur: false,
          child: Center(
            child: TextField(
              controller: _accountNameController,
              focusNode: _accountNameFocusNode,
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: false,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: Colors.black,
              onChanged: (value) {
                _OnboardingProfileState.selectedName = value.trim();
              },
              onEditingComplete: () {
                FocusScope.of(context).unfocus();
                final trimmed = _accountNameController.text.trim();
                if (_accountNameController.text != trimmed) {
                  _accountNameController.value = TextEditingValue(
                    text: trimmed,
                    selection: TextSelection.collapsed(offset: trimmed.length),
                  );
                }
                _OnboardingProfileState.selectedName = trimmed;
              },
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
                final trimmed = _accountNameController.text.trim();
                if (_accountNameController.text != trimmed) {
                  _accountNameController.value = TextEditingValue(
                    text: trimmed,
                    selection: TextSelection.collapsed(offset: trimmed.length),
                  );
                }
                _OnboardingProfileState.selectedName = trimmed;
              },
              style: TextStyle(
                fontSize: (40 * scale).clamp(16.0, 22.0),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Name',
                hintStyle: TextStyle(
                  color: const Color(0x80000000),
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileInfoCard({
    required double scale,
    required String label,
    String? value,
    bool showPlaceholder = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 56 * scale,
          child: _RotatingGlassPanel(
            scale: scale,
            borderRadius: 16 * scale,
            fillColor: _accountCardFillColor,
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 6 * scale,
            ),
            expandToBounds: true,
            enableBlur: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 16.0),
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                if (showPlaceholder)
                  _addPlaceholderChip(scale: scale)
                else
                  Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: (14 * scale).clamp(12.0, 16.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required double scale,
    required String title,
    String? value,
    bool showPlaceholder = false,
    bool showArrow = true,
    Color titleColor = Colors.white,
    bool centerTitle = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 56 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: _accountCardFillColor,
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          expandToBounds: true,
          enableBlur: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    fontSize: (16 * scale).clamp(14.0, 20.0),
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showPlaceholder)
                Padding(
                  padding: EdgeInsets.only(right: 10 * scale),
                  child: _addPlaceholderChip(scale: scale),
                ),
              if (value != null)
                Padding(
                  padding: EdgeInsets.only(right: 10 * scale),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: (16 * scale).clamp(14.0, 20.0),
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (showArrow)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: (22 * scale).clamp(18.0, 28.0),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addPlaceholderChip({required double scale}) {
    final chipSize = 18 * scale;
    return SizedBox(
      width: chipSize,
      height: chipSize,
      child: _RotatingGlassPanel(
        scale: scale,
        borderRadius: 5 * scale,
        fillColor: _accountCardFillColor,
        padding: EdgeInsets.all(2 * scale),
        expandToBounds: true,
        enableBlur: false,
        child: Center(
          child: Image.asset(
            'assets/Add.png',
            fit: BoxFit.contain,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.add,
                color: Colors.white,
                size: (12 * scale).clamp(10.0, 14.0),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _bottomNavIconButton({
    required double scale,
    required String assetPath,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 48 * scale,
      height: 48 * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 15 * scale,
          fillColor: isSelected ? Colors.white : _accountCardFillColor,
          padding: EdgeInsets.zero,
          expandToBounds: true,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFFFF0000),
                    blurRadius: 4,
                    blurStyle: BlurStyle.outer,
                  ),
                ]
              : const <BoxShadow>[],
          enableBlur: false,
          child: Center(
            child: SizedBox(
              width: 30 * scale,
              height: 30 * scale,
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  isSelected ? _bottomNavActiveIconColor : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _AnimatedGradientScene(
        animation: _controller,
        contentBuilder: (context, metrics) {
          final scale = metrics.designScale;
          final contentWidth = math.min(
            358 * scale,
            metrics.width - (32 * scale),
          );
          final contentLeft = (metrics.width - contentWidth) / 2;
          final titleTop = metrics.padding.top + (18 * scale);
          final contentTop = titleTop + (58 * scale);
          final isIPhone =
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              math.min(metrics.width, metrics.height) < 600;
          final controlsBottom = isIPhone
              ? metrics.padding.bottom
              : math.max(66 * scale, metrics.padding.bottom + (26 * scale));
          final navHeight = 64 * scale;
          final blurPanelHeight = navHeight + controlsBottom;
          final scrollBottomPadding = blurPanelHeight + (24 * scale);
          final showBudgetPlaceholder = !_hasEnteredBudget;
          final showHydrationPlaceholder = !_hasEnteredHydration;

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: contentTop,
                bottom: 0,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    contentLeft,
                    10,
                    contentLeft,
                    scrollBottomPadding,
                  ),
                  child: Column(
                    children: [
                      _nameCard(scale: scale),
                      SizedBox(height: 8 * scale),
                      Row(
                        children: [
                          _profileInfoCard(
                            scale: scale,
                            label: 'Goal',
                            value: _goalLabels[_selectedGoalIndex],
                            onTap: _openGoalScreen,
                          ),
                          SizedBox(width: 8 * scale),
                          _profileInfoCard(
                            scale: scale,
                            label: 'Age',
                            value: '$_selectedAge',
                            onTap: _openAgeScreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Row(
                        children: [
                          _profileInfoCard(
                            scale: scale,
                            label: 'Weight',
                            value: _isWeightInKg
                                ? '$_selectedWeightKg Kg'
                                : '${(_selectedWeightKg * 2.2046226218).round()} lbs',
                            onTap: _openWeightScreen,
                          ),
                          SizedBox(width: 8 * scale),
                          _profileInfoCard(
                            scale: scale,
                            label: 'Height',
                            value: _isHeightInCm
                                ? '$_selectedHeightCm cm'
                                : '${(_selectedHeightCm / 30.48).toStringAsFixed(1)} ft',
                            onTap: _openHeightScreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Row(
                        children: [
                          _profileInfoCard(
                            scale: scale,
                            label: 'Daily Activity Level',
                            value: _activityLabels[_selectedActivityIndex],
                            onTap: _openActivityScreen,
                          ),
                          SizedBox(width: 8 * scale),
                          _profileInfoCard(
                            scale: scale,
                            label: 'Avg Budget per Meal',
                            value: _budgetValueLabel(),
                            showPlaceholder: showBudgetPlaceholder,
                            onTap: _openBudgetScreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      _actionTile(
                        scale: scale,
                        title: 'Daily Nutrition Goals',
                        onTap: _openNutritionGoalsScreen,
                      ),
                      SizedBox(height: 8 * scale),
                      _actionTile(
                        scale: scale,
                        title: 'Daily Hydration Goals',
                        value: showHydrationPlaceholder
                            ? null
                            : _hydrationValueLabel(),
                        showPlaceholder: showHydrationPlaceholder,
                        onTap: _openHydrationGoalsScreen,
                      ),
                      SizedBox(height: 8 * scale),
                      _actionTile(
                        scale: scale,
                        title: 'Diet Preference',
                        value:
                            _dietPreferenceLabels[_selectedDietPreferenceIndex],
                        onTap: _openDietPreferenceScreen,
                      ),
                      SizedBox(height: 8 * scale),
                      _actionTile(
                        scale: scale,
                        title: 'Terms',
                        onTap: _openTermsScreen,
                      ),
                      SizedBox(height: 8 * scale),
                      _actionTile(scale: scale, title: 'About'),
                      SizedBox(height: 8 * scale),
                      _actionTile(
                        scale: scale,
                        title: 'Account Deletion',
                        onTap: _openAccountDeletionScreen,
                      ),
                      SizedBox(height: 8 * scale),
                      _actionTile(
                        scale: scale,
                        title: 'Logout',
                        titleColor: const Color(0xFFFF0000),
                        showArrow: false,
                        centerTitle: true,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 48 * scale,
                    child: Center(child: _sectionTitle('Account', scale)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: blurPanelHeight,
                child: _buildBottomBlurFadeOverlay(),
              ),
              Positioned(
                left: contentLeft,
                width: contentWidth,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16 * scale),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: _dailyProgressMenuBarBlurSigma,
                            sigmaY: _dailyProgressMenuBarBlurSigma,
                          ),
                          child: Container(
                            height: navHeight,
                            decoration: BoxDecoration(
                              color: _menuBarBlockFillColor,
                              borderRadius: BorderRadius.circular(16 * scale),
                            ),
                            padding: EdgeInsets.all(8 * scale),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _bottomNavIconButton(
                                  scale: scale,
                                  assetPath: 'assets/Home_in.svg',
                                  isSelected: false,
                                  onTap: () => _goToDailyProgressTab(0),
                                ),
                                _bottomNavIconButton(
                                  scale: scale,
                                  assetPath: 'assets/Notification_in.svg',
                                  isSelected: false,
                                  onTap: () => _goToDailyProgressTab(1),
                                ),
                                _bottomNavIconButton(
                                  scale: scale,
                                  assetPath: 'assets/Account_in.svg',
                                  isSelected: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16 * scale),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _dailyProgressMenuBarBlurSigma,
                          sigmaY: _dailyProgressMenuBarBlurSigma,
                        ),
                        child: Container(
                          width: navHeight,
                          height: navHeight,
                          decoration: BoxDecoration(
                            color: _menuBarBlockFillColor,
                            borderRadius: BorderRadius.circular(16 * scale),
                          ),
                          padding: EdgeInsets.all(8 * scale),
                          child: _bottomNavIconButton(
                            scale: scale,
                            assetPath: 'assets/Add_new.svg',
                            isSelected: false,
                            onTap: () => _goToDailyProgressTab(3),
                          ),
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

class _DietPreferenceOption {
  const _DietPreferenceOption({required this.label, required this.imagePath});

  final String label;
  final String imagePath;
}

class _BudgetOptionCard extends StatefulWidget {
  const _BudgetOptionCard({
    required this.scale,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  final double scale;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_BudgetOptionCard> createState() => _BudgetOptionCardState();
}

class _BudgetOptionCardState extends State<_BudgetOptionCard> {
  bool _isLongPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isActive = widget.isSelected;
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
        });
      },
      onLongPressStart: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLongPressed = true;
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
        if (!mounted) {
          return;
        }
        setState(() {
          _isLongPressed = false;
        });
        widget.onTap();
      },
      child: SizedBox(
        height: (74 * scale).clamp(66.0, 88.0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          child: _RotatingGlassPanel(
            scale: scale,
            borderRadius: 16 * scale,
            fillColor: fillColor,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            expandToBounds: true,
            boxShadow: shadows,
            enableBlur: false,
            child: Align(alignment: Alignment.centerLeft, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _DietPreferenceCard extends StatefulWidget {
  const _DietPreferenceCard({
    required this.scale,
    required this.width,
    required this.height,
    required this.label,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.showSelectionGlow = true,
  });

  final double scale;
  final double width;
  final double height;
  final String label;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showSelectionGlow;

  @override
  State<_DietPreferenceCard> createState() => _DietPreferenceCardState();
}

class _DietPreferenceCardState extends State<_DietPreferenceCard> {
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  void didUpdateWidget(covariant _DietPreferenceCard oldWidget) {
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
    final hasShadow = widget.showSelectionGlow && (_isLongPressed || isActive);
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
        width: widget.width,
        height: widget.height,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 15 * scale,
          ),
          expandToBounds: true,
          boxShadow: shadows,
          enableBlur: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80 * scale,
                height: 80 * scale,
                child: Image.asset(
                  widget.imagePath,
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
              SizedBox(height: 6 * scale),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 20.0),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionGoalItem {
  const _NutritionGoalItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;
}

class _EditableNutritionValueField extends StatefulWidget {
  const _EditableNutritionValueField({
    required this.scale,
    required this.controller,
    required this.fontSize,
  });

  final double scale;
  final TextEditingController controller;
  final double fontSize;

  @override
  State<_EditableNutritionValueField> createState() =>
      _EditableNutritionValueFieldState();
}

class _EditableNutritionValueFieldState
    extends State<_EditableNutritionValueField> {
  final FocusNode _focusNode = FocusNode();
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        setState(() {
          _isLongPressed = false;
          _isClicked = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = _isLongPressed
        ? Colors.transparent
        : (_isClicked ? Colors.white : const Color(0x40FFFFFF));
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
        if (!mounted) {
          return;
        }
        setState(() {
          _isClicked = true;
          _isLongPressed = false;
        });
        _focusNode.requestFocus();
      },
      child: _RotatingGlassPanel(
        scale: widget.scale,
        borderRadius: 15,
        fillColor: fillColor,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * widget.scale,
          vertical: 8 * widget.scale,
        ),
        expandToBounds: true,
        boxShadow: shadows,
        enableBlur: false,
        child: Align(
          alignment: Alignment.center,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              _IndianNumberInputFormatter(allowDecimal: true),
            ],
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            maxLines: 1,
            enableInteractiveSelection: false,
            scrollPadding: EdgeInsets.zero,
            style: TextStyle(
              fontSize: widget.fontSize,
              color: Colors.black,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
            strutStyle: StrutStyle(
              fontSize: widget.fontSize,
              height: 1.0,
              forceStrutHeight: true,
            ),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () {
              if (!mounted) {
                return;
              }
              setState(() {
                _isClicked = true;
                _isLongPressed = false;
              });
            },
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
        ),
      ),
    );
  }
}

class _UnitSelectorPill extends StatelessWidget {
  const _UnitSelectorPill({
    required this.scale,
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeftSelected,
    this.fontSize,
    this.onTapLeft,
    this.onTapRight,
  });

  final double scale;
  final String leftLabel;
  final String rightLabel;
  final bool isLeftSelected;
  final double? fontSize;
  final VoidCallback? onTapLeft;
  final VoidCallback? onTapRight;

  @override
  Widget build(BuildContext context) {
    final selectedWidth = 124 * scale;
    final unselectedWidth = 116 * scale;
    final selectedDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32 * scale),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFFFF0000),
          blurRadius: 2,
          blurStyle: BlurStyle.outer,
        ),
      ],
    );
    final textStyle = TextStyle(
      fontSize: fontSize ?? (32 * scale).clamp(24.0, 40.0),
      color: Colors.black,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    return Container(
      width: 264 * scale,
      height: 64 * scale,
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: const Color(0x29FFFFFF),
        borderRadius: BorderRadius.circular(32 * scale),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapLeft,
            child: Container(
              width: selectedWidth,
              height: 48 * scale,
              decoration: isLeftSelected ? selectedDecoration : null,
              child: Center(child: Text(leftLabel, style: textStyle)),
            ),
          ),
          SizedBox(width: 8 * scale),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapRight,
            child: Container(
              width: unselectedWidth,
              height: 48 * scale,
              decoration: isLeftSelected ? null : selectedDecoration,
              child: Center(
                child: Text(
                  rightLabel,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLevelOption {
  const _ActivityLevelOption({
    required this.label,
    required this.description,
    required this.redBars,
  });

  final String label;
  final String description;
  final int redBars;
}

class _CurrencyOption {
  const _CurrencyOption({required this.label, required this.symbol});

  final String label;
  final String symbol;
}

class _CustomEntryQuantityUnitOption {
  const _CustomEntryQuantityUnitOption({
    required this.dropdownLabel,
    required this.displaySuffix,
    this.usesStepControls = false,
  });

  final String dropdownLabel;
  final String displaySuffix;
  final bool usesStepControls;
}

class _ActivityLevelCard extends StatefulWidget {
  const _ActivityLevelCard({
    required this.scale,
    required this.label,
    required this.description,
    required this.redBars,
    required this.isSelected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final String description;
  final int redBars;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ActivityLevelCard> createState() => _ActivityLevelCardState();
}

class _ActivityLevelCardState extends State<_ActivityLevelCard> {
  bool _isLongPressed = false;
  bool _isClicked = false;

  @override
  void didUpdateWidget(covariant _ActivityLevelCard oldWidget) {
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
    final cardPadding = 16 * scale;
    final indicatorGap = 8.0;
    final indicatorBarWidth = (10 * scale).clamp(8.0, 12.0);
    final indicatorBarHeight = (4 * scale).clamp(3.0, 5.0);
    final indicatorStackHeight = (indicatorBarHeight * 5) + (indicatorGap * 4);
    final baseCardHeight = (84 * scale).clamp(72.0, 106.0);
    final cardHeight = math.max(
      baseCardHeight,
      (cardPadding * 2) + indicatorStackHeight,
    );
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
            _isLongPressed = false;
            _isClicked = true;
          });
        }
        widget.onTap();
      },
      child: SizedBox(
        height: cardHeight,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.all(cardPadding),
          expandToBounds: true,
          boxShadow: shadows,
          enableBlur: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (16 * scale).clamp(14.0, 20.0),
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: (6 * scale).clamp(4.0, 8.0)),
                    Flexible(
                      child: Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (12 * scale).clamp(10.0, 15.0),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * scale),
              SizedBox(
                height: indicatorStackHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List<Widget>.generate(9, (index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 8);
                    }

                    final barIndex = index ~/ 2;
                    final isRed = barIndex >= (5 - widget.redBars);
                    return Container(
                      width: indicatorBarWidth,
                      height: indicatorBarHeight,
                      decoration: BoxDecoration(
                        color: isRed ? const Color(0xFFFF787A) : Colors.white,
                        borderRadius: BorderRadius.circular(4 * scale),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeightRuler extends StatefulWidget {
  const _HeightRuler({
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final int value;
  final ValueChanged<int> onChanged;

  static const int _minHeight = 50;
  static const int _maxHeight = 280;

  @override
  State<_HeightRuler> createState() => _HeightRulerState();
}

class _HeightRulerState extends State<_HeightRuler> {
  double _dragRemainderPx = 0;

  void _applyDeltaPx(double deltaPx) {
    final pixelsPerCm = (10 * widget.scale).clamp(8.0, 14.0);
    // Drag up increases, drag down decreases.
    _dragRemainderPx -= deltaPx;
    final deltaCm = (_dragRemainderPx / pixelsPerCm).truncate();

    if (deltaCm != 0) {
      final next = (widget.value - deltaCm).clamp(
        _HeightRuler._minHeight,
        _HeightRuler._maxHeight,
      );
      if (next != widget.value) {
        widget.onChanged(next);
      }
      _dragRemainderPx -= deltaCm * pixelsPerCm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final rulerHeight = (560 * scale).clamp(420.0, 620.0);

    return SizedBox(
      height: rulerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              _applyDeltaPx(details.delta.dy);
            },
            onVerticalDragEnd: (_) {
              _dragRemainderPx = 0;
            },
            onTapDown: (details) {
              final pixelsPerCm = (10 * scale).clamp(8.0, 14.0);
              final dyFromCenter =
                  details.localPosition.dy - (constraints.maxHeight / 2);
              final jumpCm = (dyFromCenter / pixelsPerCm).round();
              if (jumpCm == 0) {
                return;
              }
              final next = (widget.value - jumpCm).clamp(
                _HeightRuler._minHeight,
                _HeightRuler._maxHeight,
              );
              if (next != widget.value) {
                widget.onChanged(next);
              }
            },
            child: CustomPaint(
              painter: _HeightTicksPainter(
                scale: scale,
                value: widget.value,
                minHeight: _HeightRuler._minHeight,
                maxHeight: _HeightRuler._maxHeight,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeightTicksPainter extends CustomPainter {
  const _HeightTicksPainter({
    required this.scale,
    required this.value,
    required this.minHeight,
    required this.maxHeight,
  });

  final double scale;
  final int value;
  final int minHeight;
  final int maxHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final spacing = (10 * scale).clamp(8.0, 14.0);
    final strokeWidth = (2 * scale).clamp(1.2, 2.4);
    final centerIndex = value;
    final visibleTicks = (size.height / spacing).ceil() + 6;
    final minTick = math.max(minHeight, centerIndex - visibleTicks);
    final maxTick = math.min(maxHeight, centerIndex + visibleTicks);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int tick = minTick; tick <= maxTick; tick++) {
      final y = centerY - ((tick - centerIndex) * spacing);
      if (y < -4 || y > size.height + 4) {
        continue;
      }

      final isCenter = tick == centerIndex;
      final isMajor = tick % 5 == 0;
      final lineLength = isCenter
          ? (size.width * 0.96)
          : (isMajor ? (size.width * 0.72) : (size.width * 0.5));
      final distanceRatio = ((y - centerY).abs() / (size.height / 2)).clamp(
        0.0,
        1.0,
      );
      final opacity = (1.0 - (distanceRatio * 0.5)).clamp(0.35, 1.0);

      paint.color = isCenter
          ? Colors.white
          : Colors.black.withValues(alpha: opacity);
      canvas.drawLine(
        Offset(size.width - lineLength, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeightTicksPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.value != value ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}

class _LeftIndicatorArrowPainter extends CustomPainter {
  const _LeftIndicatorArrowPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final headBaseX = (size.width * 0.55)
        .clamp(10.0, size.width * 0.72)
        .toDouble();
    final headHalfHeight = (size.height * 0.38)
        .clamp(6.0, size.height * 0.5)
        .toDouble();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The shaft's right edge attaches exactly where the selected white line ends.
    canvas.drawLine(
      Offset(headBaseX, centerY),
      Offset(size.width, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(headBaseX, centerY),
      Offset(size.width, centerY - headHalfHeight),
      paint,
    );
    canvas.drawLine(
      Offset(headBaseX, centerY),
      Offset(size.width, centerY + headHalfHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LeftIndicatorArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
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

  static const int _minWeight = 0;
  static const int _maxWeight = 200;

  @override
  State<_WeightRuler> createState() => _WeightRulerState();
}

class _WeightRulerState extends State<_WeightRuler> {
  double _dragRemainderPx = 0;

  void _applyDeltaPx(double deltaPx) {
    final pixelsPerKg = (20 * widget.scale).clamp(14.0, 26.0);
    // Right drag decreases, left drag increases.
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
    final markerAnchorInset = (18 * scale).clamp(14.0, 24.0);
    final markerSize = markerAnchorInset * 2;

    return SizedBox(
      height: rulerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              // Right drag decreases, left drag increases.
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
              final next = (widget.value + jumpKg).clamp(
                _WeightRuler._minWeight,
                _WeightRuler._maxWeight,
              );
              if (next != widget.value) {
                widget.onChanged(next);
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WeightTicksPainter(
                      scale: scale,
                      value: widget.value,
                      minWeight: _WeightRuler._minWeight,
                      maxWeight: _WeightRuler._maxWeight,
                      baselineBottomInset: markerAnchorInset,
                    ),
                  ),
                ),
                Positioned(
                  top: rulerHeight - markerAnchorInset,
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
      final availableHeight = baseY.clamp(0.0, size.height);
      final lineHeight = isCenter
          ? (availableHeight * 1.5)
          : (isMajor ? (availableHeight * 0.82) : (availableHeight * 0.5));
      final distanceRatio = ((x - centerX).abs() / (size.width / 2)).clamp(
        0.0,
        1.0,
      );
      final opacity = (1.0 - (distanceRatio * 0.5)).clamp(0.35, 1.0);

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
        height: 152 * scale,
        child: _RotatingGlassPanel(
          scale: scale,
          borderRadius: 16 * scale,
          fillColor: fillColor,
          padding: EdgeInsets.all(16 * scale),
          expandToBounds: true,
          boxShadow: shadows,
          enableBlur: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
          enableBlur: false,
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
    this.enableBlur = false,
    this.lightLengthMultiplier = 18.0,
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
  final double lightLengthMultiplier;

  @override
  State<_RotatingGlassPanel> createState() => _RotatingGlassPanelState();
}

class _RotatingGlassPanelState extends State<_RotatingGlassPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lightController;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScrollPosition = Scrollable.maybeOf(context)?.position;
    if (!identical(_scrollPosition, nextScrollPosition)) {
      _scrollPosition?.isScrollingNotifier.removeListener(
        _handleScrollActivityChange,
      );
      _scrollPosition = nextScrollPosition;
      _scrollPosition?.isScrollingNotifier.addListener(
        _handleScrollActivityChange,
      );
    }
    _syncBorderAnimation();
  }

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(
      _handleScrollActivityChange,
    );
    _lightController.dispose();
    super.dispose();
  }

  void _handleScrollActivityChange() {
    _syncBorderAnimation();
  }

  void _syncBorderAnimation() {
    final shouldAnimate =
        mounted &&
        TickerMode.valuesOf(context).enabled &&
        !(_scrollPosition?.isScrollingNotifier.value ?? false);
    if (shouldAnimate) {
      if (!_lightController.isAnimating) {
        _lightController.repeat();
      }
      return;
    }
    if (_lightController.isAnimating) {
      _lightController.stop(canceled: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final radius = widget.borderRadius;
    final borderStroke = (2 * scale).clamp(1.2, 2.8);
    final rotatingLightStroke = (borderStroke * 0.5).clamp(0.6, 1.4);
    final panelContent = Container(
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
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  willChange: true,
                  painter: _RotatingBorderLightPainter(
                    rotation: _lightController,
                    borderRadius: radius,
                    strokeWidth: rotatingLightStroke,
                    glowWidth: (2 * scale).clamp(1.2, 2.8),
                    borderStroke: borderStroke,
                    lightLengthMultiplier: widget.lightLengthMultiplier,
                  ),
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
  }
}

class _GlassNextButton extends StatefulWidget {
  const _GlassNextButton({
    required this.scale,
    required this.onTap,
    this.enabled = true,
    this.label = 'Next',
    this.showArrowIcon = true,
    this.trailingIcon,
    this.trailingIconSize = 24,
    this.baseColor = const Color(0xFFFFD206),
    this.enabledAlpha = 0x8F,
    this.disabledAlpha = 0x14,
  });

  final double scale;
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool showArrowIcon;
  final IconData? trailingIcon;
  final double trailingIconSize;
  final Color baseColor;
  final int enabledAlpha;
  final int disabledAlpha;

  @override
  State<_GlassNextButton> createState() => _GlassNextButtonState();
}

class _GlassNextButtonState extends State<_GlassNextButton>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final trailingIconData = widget.trailingIcon;
    final shouldShowArrow = widget.showArrowIcon && trailingIconData == null;
    final shouldShowTrailingIcon = shouldShowArrow || trailingIconData != null;
    final fillAlpha =
        (widget.enabled ? widget.enabledAlpha : widget.disabledAlpha)
            .clamp(0, 255)
            .toInt();
    return _RotatingGlassButton(
      scale: scale,
      height: 56 * scale,
      borderRadius: 32 * scale,
      fillColor: widget.baseColor.withAlpha(fillAlpha),
      enablePressShadeFeedback: widget.enabled,
      onTap: widget.enabled ? widget.onTap : () {},
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: Colors.white,
                fontSize: (34 * scale / 1.7).clamp(18.0, 28.0),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (shouldShowTrailingIcon) ...[
              SizedBox(width: 12 * scale),
              Icon(
                trailingIconData ?? Icons.arrow_forward,
                color: Colors.white,
                size: widget.trailingIconSize * scale,
              ),
            ],
          ],
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
              enableBlur: false,
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
    this.showBorderLight = true,
  });

  final double scale;
  final double height;
  final double borderRadius;
  final Color fillColor;
  final VoidCallback onTap;
  final Widget child;
  final bool enablePressShadeFeedback;
  final bool showBorderLight;

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
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBorderAnimation();
  }

  @override
  void didUpdateWidget(covariant _RotatingGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBorderLight != widget.showBorderLight) {
      _syncBorderAnimation();
    }
  }

  @override
  void dispose() {
    _lightController.dispose();
    super.dispose();
  }

  void _syncBorderAnimation() {
    final shouldAnimate =
        mounted &&
        widget.showBorderLight &&
        TickerMode.valuesOf(context).enabled;
    if (shouldAnimate) {
      if (!_lightController.isAnimating) {
        _lightController.repeat();
      }
      return;
    }
    if (_lightController.isAnimating) {
      _lightController.stop(canceled: false);
    }
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
            if (widget.showBorderLight)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RotatingBorderLightPainter(
                      rotation: _lightController,
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
  }
}

class _RotatingBorderLightPainter extends CustomPainter {
  const _RotatingBorderLightPainter({
    required this.rotation,
    required this.borderRadius,
    required this.strokeWidth,
    required this.glowWidth,
    required this.borderStroke,
    this.lightLengthMultiplier = 18.0,
  }) : super(repaint: rotation);

  final Animation<double> rotation;
  final double borderRadius;
  final double strokeWidth;
  final double glowWidth;
  final double borderStroke;
  final double lightLengthMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = (math.pi / 4) + (rotation.value * math.pi * 2);
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
      stops: _buildLightStops(lightLengthMultiplier),
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
    return oldDelegate.rotation != rotation ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glowWidth != glowWidth ||
        oldDelegate.borderStroke != borderStroke ||
        oldDelegate.lightLengthMultiplier != lightLengthMultiplier;
  }

  static List<double> _buildLightStops(double lengthMultiplier) {
    final factor = math.max(1.0, lengthMultiplier);
    const firstCenter = 0.122;
    const secondCenter = 0.622;

    double scaleStop({
      required double value,
      required double center,
      required double min,
      required double max,
    }) {
      return (center + ((value - center) * factor)).clamp(min, max).toDouble();
    }

    return [
      0.0,
      scaleStop(value: 0.062, center: firstCenter, min: 0.0, max: 0.5),
      scaleStop(value: 0.086, center: firstCenter, min: 0.0, max: 0.5),
      scaleStop(value: 0.104, center: firstCenter, min: 0.0, max: 0.5),
      firstCenter,
      scaleStop(value: 0.14, center: firstCenter, min: 0.0, max: 0.5),
      scaleStop(value: 0.166, center: firstCenter, min: 0.0, max: 0.5),
      0.5,
      scaleStop(value: 0.56, center: secondCenter, min: 0.5, max: 1.0),
      scaleStop(value: 0.586, center: secondCenter, min: 0.5, max: 1.0),
      scaleStop(value: 0.604, center: secondCenter, min: 0.5, max: 1.0),
      secondCenter,
      scaleStop(value: 0.64, center: secondCenter, min: 0.5, max: 1.0),
      scaleStop(value: 0.666, center: secondCenter, min: 0.5, max: 1.0),
      scaleStop(value: 0.69, center: secondCenter, min: 0.5, max: 1.0),
      1.0,
    ];
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
                  color: const Color(0xFFCBF6FF),
                  blurSigma: 1000 * designScale,
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

import 'package:flutter/material.dart';

class OnboardingSlide {
  final String lottieAsset;   // animation Lottie
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color titleColor;

  const OnboardingSlide({
    required this.lottieAsset,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.titleColor,
  });
}

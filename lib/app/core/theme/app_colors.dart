import 'package:flutter/material.dart';

/// App-wide semantic color tokens matching index.css variables for the Light theme palette.
/// To change the entire app's color palette, simply modify the values in [AppColors.light].
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color input;
  final Color ring;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;

  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.input,
    required this.ring,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
  });

  /// Light theme palette (equivalent to :root in index.css)
  static const AppColors light = AppColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFFAB0D0C),
    card: Color(0xFFFFFBF5),
    cardForeground: Color(0xFFAB0D0C),
    popover: Color(0xFFFFFBF5),
    popoverForeground: Color(0xFFAB0D0C),
    primary: Color(0xFFDD1110),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFF3E0),
    secondaryForeground: Color(0xFF7C0909),
    muted: Color(0xFFFFF3E0),
    mutedForeground: Color(0xFF2D2828),
    accent: Color(0xFFF02F2E),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFF02F2E),
    border: Color(0xFFC5C4C4),
    input: Color(0xFFFFFBF5),
    ring: Color(0xFFFFA71A),
    chart1: Color(0xFFDD1110),
    chart2: Color(0xFFAB0D0C),
    chart3: Color(0xFFFFA71A),
    chart4: Color(0xFFFFBA4D),
    chart5: Color(0xFF7C0909),
    sidebar: Color(0xFFDD1110),
    sidebarForeground: Color(0xFFFFFFFF),
    sidebarPrimary: Color(0xFFF02F2E),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFAB0D0C),
    sidebarAccentForeground: Color(0xFFFFFFFF),
    sidebarBorder: Color(0x38FFFFFF),
    sidebarRing: Color(0xFFFFA71A),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? border,
    Color? input,
    Color? ring,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarPrimaryForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
    Color? sidebarBorder,
    Color? sidebarRing,
  }) {
    return AppColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      sidebar: sidebar ?? this.sidebar,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
      sidebarPrimaryForeground:
          sidebarPrimaryForeground ?? this.sidebarPrimaryForeground,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      sidebarAccentForeground:
          sidebarAccentForeground ?? this.sidebarAccentForeground,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarRing: sidebarRing ?? this.sidebarRing,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t) ?? background,
      foreground: Color.lerp(foreground, other.foreground, t) ?? foreground,
      card: Color.lerp(card, other.card, t) ?? card,
      cardForeground:
          Color.lerp(cardForeground, other.cardForeground, t) ?? cardForeground,
      popover: Color.lerp(popover, other.popover, t) ?? popover,
      popoverForeground:
          Color.lerp(popoverForeground, other.popoverForeground, t) ??
          popoverForeground,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t) ??
          primaryForeground,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t) ??
          secondaryForeground,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t) ??
          mutedForeground,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t) ??
          accentForeground,
      destructive: Color.lerp(destructive, other.destructive, t) ?? destructive,
      border: Color.lerp(border, other.border, t) ?? border,
      input: Color.lerp(input, other.input, t) ?? input,
      ring: Color.lerp(ring, other.ring, t) ?? ring,
      chart1: Color.lerp(chart1, other.chart1, t) ?? chart1,
      chart2: Color.lerp(chart2, other.chart2, t) ?? chart2,
      chart3: Color.lerp(chart3, other.chart3, t) ?? chart3,
      chart4: Color.lerp(chart4, other.chart4, t) ?? chart4,
      chart5: Color.lerp(chart5, other.chart5, t) ?? chart5,
      sidebar: Color.lerp(sidebar, other.sidebar, t) ?? sidebar,
      sidebarForeground:
          Color.lerp(sidebarForeground, other.sidebarForeground, t) ??
          sidebarForeground,
      sidebarPrimary:
          Color.lerp(sidebarPrimary, other.sidebarPrimary, t) ?? sidebarPrimary,
      sidebarPrimaryForeground:
          Color.lerp(
            sidebarPrimaryForeground,
            other.sidebarPrimaryForeground,
            t,
          ) ??
          sidebarPrimaryForeground,
      sidebarAccent:
          Color.lerp(sidebarAccent, other.sidebarAccent, t) ?? sidebarAccent,
      sidebarAccentForeground:
          Color.lerp(
            sidebarAccentForeground,
            other.sidebarAccentForeground,
            t,
          ) ??
          sidebarAccentForeground,
      sidebarBorder:
          Color.lerp(sidebarBorder, other.sidebarBorder, t) ?? sidebarBorder,
      sidebarRing: Color.lerp(sidebarRing, other.sidebarRing, t) ?? sidebarRing,
    );
  }
}

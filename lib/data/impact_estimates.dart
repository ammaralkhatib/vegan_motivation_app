import '../l10n/app_localizations.dart';

/// Per-day impact estimates for a fully plant-based day.
///
/// Sources: aggregated figures popularized by TheVeganCalculator.com,
/// drawing on the Cowspiracy fact sheet and Water Footprint Network data.
/// These are rough, commonly cited approximations meant for motivation,
/// not scientific precision — the in-app info sheet says so explicitly.
abstract final class ImpactEstimates {
  /// ~1 animal life spared per plant-based day.
  static const animalsPerDay = 1.0;

  /// ~9 kg CO₂-equivalent avoided per day.
  static const co2KgPerDay = 9.0;

  /// ~4,164 litres of water saved per day (often quoted as 1,100 gallons).
  static const waterLitresPerDay = 4164.0;

  /// ~18 kg of grain redirected per day.
  static const grainKgPerDay = 18.0;

  /// ~3 m² of forest spared per day.
  static const forestM2PerDay = 3.0;
}

class ImpactStat {
  const ImpactStat({
    required this.emoji,
    required this.id,
    required this.perDay,
    required this.format,
  });

  final String emoji;

  /// Stable id; the visible label is resolved via [impactStatLabel] in the UI.
  final String id;
  final double perDay;
  final String Function(double value) format;
}

/// Localized label for an [ImpactStat] id (data layer stays string-free,
/// 011 Requirement-5 pattern).
String impactStatLabel(AppLocalizations l, String id) => switch (id) {
      'animals' => l.journeyImpactAnimals,
      'co2' => l.journeyImpactCo2,
      'water' => l.journeyImpactWater,
      'grain' => l.journeyImpactGrain,
      _ => l.journeyImpactForest,
    };

String _compact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.round().toString();
}

final impactStats = [
  ImpactStat(
    emoji: '🐷',
    id: 'animals',
    perDay: ImpactEstimates.animalsPerDay,
    format: _compact,
  ),
  ImpactStat(
    emoji: '🌫️',
    id: 'co2',
    perDay: ImpactEstimates.co2KgPerDay,
    format: _compact,
  ),
  ImpactStat(
    emoji: '💧',
    id: 'water',
    perDay: ImpactEstimates.waterLitresPerDay,
    format: _compact,
  ),
  ImpactStat(
    emoji: '🌾',
    id: 'grain',
    perDay: ImpactEstimates.grainKgPerDay,
    format: _compact,
  ),
  ImpactStat(
    emoji: '🌳',
    id: 'forest',
    perDay: ImpactEstimates.forestM2PerDay,
    format: _compact,
  ),
];

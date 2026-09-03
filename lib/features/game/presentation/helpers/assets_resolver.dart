// lib/features/game/presentation/helpers/virus_asset_resolver.dart
import '../../../../core/constants/app_icon_constants.dart';

class AssetsResolver {
  static String? resolve({
    required int virusCount,
    required bool isCritical,
  }) {
    if (virusCount <= 0) return null;

    return switch (virusCount) {
      1 => isCritical
          ? AppIconConstants.corona1fast
          : AppIconConstants.corona1slow,
      2 => isCritical
          ? AppIconConstants.corona2fast
          : AppIconConstants.corona2slow,
      3 => AppIconConstants.corona3,
      _ => AppIconConstants.corona1slow,
    };
  }
}

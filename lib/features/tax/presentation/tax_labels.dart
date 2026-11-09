import '../../../l10n/app_localizations.dart';
import '../domain/entities/tax_section.dart';

extension TaxSectionLabels on TaxSection {
  /// Short chip label, e.g. `🏛️ 80C`.
  String get chipLabel => '$emoji $code';

  /// What usually counts towards this section.
  String description(AppLocalizations l10n) => switch (this) {
    TaxSection.s80C => l10n.tax_desc80C,
    TaxSection.s80D => l10n.tax_desc80D,
    TaxSection.hra => l10n.tax_descHra,
    TaxSection.s80G => l10n.tax_desc80G,
    TaxSection.s80E => l10n.tax_desc80E,
  };
}

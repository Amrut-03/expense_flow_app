import '../entities/tax_section.dart';

/// Guesses which tax section an expense belongs to from its text.
///
/// Deliberately conservative: it only fires on phrases that are
/// unambiguous ("LIC premium", "house rent", "donation"), and the user always
/// confirms the tag in the form.
abstract final class TaxTagSuggester {
  static final Map<TaxSection, List<String>> _phrases = {
    // Most specific sections first: "education loan" must not fall through
    // to a generic match, and "health insurance" must beat "insurance".
    TaxSection.s80E: ['education loan', 'student loan'],
    TaxSection.s80D: [
      'health insurance',
      'mediclaim',
      'star health',
      'care health',
      'niva bupa',
      'max bupa',
      'health checkup',
      'health check up',
      'preventive checkup',
      'medical insurance',
    ],
    TaxSection.s80C: [
      'lic',
      'life insurance',
      'term insurance',
      'term plan',
      'ppf',
      'elss',
      'tax saver',
      'sukanya',
      'ssy',
      'nsc',
      'tuition',
      'tution',
      'school fee',
      'school fees',
      'home loan principal',
    ],
    TaxSection.hra: ['house rent', 'room rent', 'flat rent', 'pg rent', 'rent'],
    TaxSection.s80G: [
      'donation',
      'donated',
      'donate',
      'charity',
      'pm cares',
      'ngo',
    ],
  };

  static final Map<TaxSection, RegExp> _patterns = {
    for (final entry in _phrases.entries)
      entry.key: RegExp(
        '\\b(?:${entry.value.map(RegExp.escape).join('|')})\\b',
        caseSensitive: false,
      ),
  };

  /// Returns the section matched by [title], [merchant] or [note], if any.
  static TaxSection? suggest({String? title, String? merchant, String? note}) {
    final text = [title, merchant, note].whereType<String>().join(' ');
    if (text.trim().isEmpty) return null;

    for (final entry in _patterns.entries) {
      if (entry.value.hasMatch(text)) return entry.key;
    }
    return null;
  }
}

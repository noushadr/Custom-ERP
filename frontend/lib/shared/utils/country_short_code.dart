/// Maps free-text country values actually present in this app's real
/// imported data (Leads' sales-log import, Clients' SEO/sales-log imports)
/// — including typos and cities entered in place of a country, e.g.
/// "Dubai", "Rawalpindi" — to a short display code and an ISO 3166-1
/// alpha-2 code (for the flag emoji). Lookup is case-insensitive; anything
/// not covered here falls back to the original text rather than guessing.
/// Shared between the Leads and Clients & Projects pages, which draw from
/// the same real-world data.
const kCountryShortCodes = {
  'pakistan': 'PK',
  'pakisan': 'PK',
  'karachi': 'PK',
  'rawalpindi': 'PK',
  'uae': 'UAE',
  'dubai': 'UAE',
  'united arab emirates': 'UAE',
  'uk': 'UK',
  'united kingdom': 'UK',
  'usa': 'USA',
  'us': 'USA',
  'united states': 'USA',
  'saudi arabia': 'KSA',
  'saudia': 'KSA',
  'sa': 'KSA',
  'riyadh': 'KSA',
  'australia': 'AU',
  'india': 'IN',
  'germany': 'DE',
  'italy': 'IT',
  'oman': 'OM',
  'china': 'CN',
  'canada': 'CA',
  'ca': 'CA',
  'singapore': 'SG',
  'uganda': 'UG',
  'kuwait': 'KW',
  'morocco': 'MA',
  'netherlands': 'NL',
  'netherland': 'NL',
  'qatar': 'QA',
  'south africa': 'ZA',
  'laos': 'LA',
  'malaysia': 'MY',
  'bangladesh': 'BD',
  'bahrain': 'BH',
  'turkiye/turkey': 'TR',
  'turkey': 'TR',
  'turkiye': 'TR',
  'switzerland': 'CH',
  'spain': 'ES',
  'france': 'FR',
  'slovenia': 'SI',
  'afghanistan': 'AF',
  'georgia': 'GE',
  'portugal': 'PT',
  'belgium': 'BE',
  'vietnam': 'VN',
  'botswana': 'BW',
  'philippines': 'PH',
  'nigeria': 'NG',
  'japan': 'JP',
  'ethopia': 'ET',
  'ethiopia': 'ET',
  'latvia': 'LV',
};

/// Same keys as [kCountryShortCodes], but the *real* ISO 3166-1 alpha-2
/// code — distinct from the display code for a few countries where the
/// commonly-used short label isn't the ISO code (UK→GB, USA→US, KSA→SA).
/// This is what the flag emoji is actually computed from.
const _kCountryIsoCodes = {
  'pakistan': 'PK',
  'pakisan': 'PK',
  'karachi': 'PK',
  'rawalpindi': 'PK',
  'uae': 'AE',
  'dubai': 'AE',
  'united arab emirates': 'AE',
  'uk': 'GB',
  'united kingdom': 'GB',
  'usa': 'US',
  'us': 'US',
  'united states': 'US',
  'saudi arabia': 'SA',
  'saudia': 'SA',
  'sa': 'SA',
  'riyadh': 'SA',
  'australia': 'AU',
  'india': 'IN',
  'germany': 'DE',
  'italy': 'IT',
  'oman': 'OM',
  'china': 'CN',
  'canada': 'CA',
  'ca': 'CA',
  'singapore': 'SG',
  'uganda': 'UG',
  'kuwait': 'KW',
  'morocco': 'MA',
  'netherlands': 'NL',
  'netherland': 'NL',
  'qatar': 'QA',
  'south africa': 'ZA',
  'laos': 'LA',
  'malaysia': 'MY',
  'bangladesh': 'BD',
  'bahrain': 'BH',
  'turkiye/turkey': 'TR',
  'turkey': 'TR',
  'turkiye': 'TR',
  'switzerland': 'CH',
  'spain': 'ES',
  'france': 'FR',
  'slovenia': 'SI',
  'afghanistan': 'AF',
  'georgia': 'GE',
  'portugal': 'PT',
  'belgium': 'BE',
  'vietnam': 'VN',
  'botswana': 'BW',
  'philippines': 'PH',
  'nigeria': 'NG',
  'japan': 'JP',
  'ethopia': 'ET',
  'ethiopia': 'ET',
  'latvia': 'LV',
};

/// Short display code for a country value, falling back to the original
/// text unchanged when it isn't in [kCountryShortCodes] — never invents a
/// code for a value it doesn't recognize.
String? formatCountryShort(String? country) {
  if (country == null) return null;
  final trimmed = country.trim();
  if (trimmed.isEmpty) return null;
  return kCountryShortCodes[trimmed.toLowerCase()] ?? trimmed;
}

/// Converts a 2-letter ISO 3166-1 alpha-2 code (e.g. "PK") to its flag
/// emoji by combining the two Unicode regional-indicator symbols — the
/// standard way flag emoji are composed, no image assets needed.
String _flagEmoji(String isoCode) {
  final codeUnits = isoCode.toUpperCase().codeUnits;
  return String.fromCharCodes(
    codeUnits.map((unit) => 0x1F1E6 + (unit - 0x41)),
  );
}

/// Flag emoji + short code for a country value (e.g. "🇵🇰 PK") — used
/// everywhere a country is displayed, so a flag reads at a glance instead
/// of a name. Falls back to the plain short/original text (no flag) when
/// the country isn't in [_kCountryIsoCodes] — never guesses at a flag.
String? formatCountryFlag(String? country) {
  if (country == null) return null;
  final trimmed = country.trim();
  if (trimmed.isEmpty) return null;
  final key = trimmed.toLowerCase();
  final isoCode = _kCountryIsoCodes[key];
  final shortCode = kCountryShortCodes[key] ?? trimmed;
  return isoCode == null ? shortCode : '${_flagEmoji(isoCode)} $shortCode';
}

import 'dart:io';
import '../services/profile_service.dart';

/// Helper class for currency detection and mapping
class CurrencyHelper {
  /// Map common cricket-nation cities to their currency codes
  static const Map<String, String> _cityToCurrency = {
    // UK cities
    'london': 'GBP', 'manchester': 'GBP', 'birmingham': 'GBP',
    'leeds': 'GBP', 'sheffield': 'GBP', 'liverpool': 'GBP',
    'bristol': 'GBP', 'nottingham': 'GBP', 'leicester': 'GBP',
    'cardiff': 'GBP', 'edinburgh': 'GBP', 'glasgow': 'GBP',
    'belfast': 'GBP', 'durham': 'GBP', 'chester-le-street': 'GBP',
    'southampton': 'GBP', 'hove': 'GBP', 'taunton': 'GBP',
    'worcester': 'GBP', 'chester': 'GBP',
    // Australian cities
    'sydney': 'AUD', 'melbourne': 'AUD', 'brisbane': 'AUD',
    'perth': 'AUD', 'adelaide': 'AUD', 'hobart': 'AUD',
    'canberra': 'AUD', 'darwin': 'AUD', 'gold coast': 'AUD',
    // Indian cities
    'mumbai': 'INR', 'delhi': 'INR', 'bangalore': 'INR',
    'bengaluru': 'INR', 'chennai': 'INR', 'kolkata': 'INR',
    'hyderabad': 'INR', 'pune': 'INR', 'ahmedabad': 'INR',
    'jaipur': 'INR', 'nagpur': 'INR', 'chandigarh': 'INR',
    'indore': 'INR', 'mohali': 'INR', 'visakhapatnam': 'INR',
    // Pakistani cities
    'karachi': 'PKR', 'lahore': 'PKR', 'islamabad': 'PKR',
    'rawalpindi': 'PKR', 'faisalabad': 'PKR', 'multan': 'PKR',
    'peshawar': 'PKR', 'quetta': 'PKR',
    // New Zealand cities
    'auckland': 'NZD', 'wellington': 'NZD', 'christchurch': 'NZD',
    'hamilton': 'NZD', 'dunedin': 'NZD', 'napier': 'NZD',
    // South African cities
    'johannesburg': 'ZAR', 'cape town': 'ZAR', 'durban': 'ZAR',
    'pretoria': 'ZAR', 'port elizabeth': 'ZAR', 'gqeberha': 'ZAR',
    'centurion': 'ZAR', 'paarl': 'ZAR', 'east london': 'ZAR',
    // Sri Lankan cities
    'colombo': 'LKR', 'kandy': 'LKR', 'galle': 'LKR', 'dambulla': 'LKR',
    // Bangladeshi cities
    'dhaka': 'BDT', 'chittagong': 'BDT', 'sylhet': 'BDT', 'khulna': 'BDT',
    // UAE cities
    'dubai': 'AED', 'abu dhabi': 'AED', 'sharjah': 'AED',
    // Canadian cities
    'toronto': 'CAD', 'vancouver': 'CAD', 'montreal': 'CAD',
    'calgary': 'CAD', 'ottawa': 'CAD', 'edmonton': 'CAD',
    // Irish cities
    'dublin': 'EUR', 'cork': 'EUR', 'galway': 'EUR',
    // Zimbabwean cities
    'harare': 'ZWL', 'bulawayo': 'ZWL',
    // West Indian cities
    'kingston': 'JMD', 'bridgetown': 'BBD', 'port of spain': 'TTD',
  };

  /// Map country names/codes to currency codes
  static const Map<String, String> _countryToCurrency = {
    // United Kingdom
    'united kingdom': 'GBP',
    'uk': 'GBP',
    'england': 'GBP',
    'scotland': 'GBP',
    'wales': 'GBP',
    'northern ireland': 'GBP',
    
    // United States
    'united states': 'USD',
    'usa': 'USD',
    'us': 'USD',
    'america': 'USD',
    
    // Eurozone Countries
    'germany': 'EUR',
    'france': 'EUR',
    'italy': 'EUR',
    'spain': 'EUR',
    'netherlands': 'EUR',
    'belgium': 'EUR',
    'austria': 'EUR',
    'portugal': 'EUR',
    'ireland': 'EUR',
    'greece': 'EUR',
    'finland': 'EUR',
    'luxembourg': 'EUR',
    
    // India
    'india': 'INR',
    'bharat': 'INR',
    
    // Australia
    'australia': 'AUD',
    
    // Canada
    'canada': 'CAD',
    
    // New Zealand
    'new zealand': 'NZD',
    
    // South Africa
    'south africa': 'ZAR',
    
    // Pakistan
    'pakistan': 'PKR',
    
    // Bangladesh
    'bangladesh': 'BDT',
    
    // Sri Lanka
    'sri lanka': 'LKR',
    
    // UAE
    'united arab emirates': 'AED',
    'uae': 'AED',
    'dubai': 'AED',
    
    // Singapore
    'singapore': 'SGD',
    
    // Malaysia
    'malaysia': 'MYR',
    
    // Thailand
    'thailand': 'THB',
    
    // Japan
    'japan': 'JPY',
    
    // China
    'china': 'CNY',
    
    // Hong Kong
    'hong kong': 'HKD',
    
    // Switzerland
    'switzerland': 'CHF',
    
    // Sweden
    'sweden': 'SEK',
    
    // Norway
    'norway': 'NOK',
    
    // Denmark
    'denmark': 'DKK',
    
    // Poland
    'poland': 'PLN',
    
    // Czech Republic
    'czech republic': 'CZK',
    
    // Brazil
    'brazil': 'BRL',
    
    // Mexico
    'mexico': 'MXN',
    
    // Argentina
    'argentina': 'ARS',
    
    // Kenya
    'kenya': 'KES',
    
    // Nigeria
    'nigeria': 'NGN',
    
    // Egypt
    'egypt': 'EGP',
    
    // Turkey
    'turkey': 'TRY',
    
    // Saudi Arabia
    'saudi arabia': 'SAR',
    
    // Qatar
    'qatar': 'QAR',
    
    // Kuwait
    'kuwait': 'KWD',
    
    // Oman
    'oman': 'OMR',
    
    // Bahrain
    'bahrain': 'BHD',
    
    // Zimbabwe
    'zimbabwe': 'ZWL',
    
    // West Indies Countries
    'jamaica': 'JMD',
    'trinidad and tobago': 'TTD',
    'barbados': 'BBD',
  };

  /// Currency symbols mapping
  static const Map<String, String> _currencySymbols = {
    'GBP': '£',
    'USD': '\$',
    'EUR': '€',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'NZD': 'NZ\$',
    'ZAR': 'R',
    'PKR': 'Rs',
    'BDT': '৳',
    'LKR': 'Rs',
    'AED': 'د.إ',
    'SGD': 'S\$',
    'MYR': 'RM',
    'THB': '฿',
    'JPY': '¥',
    'CNY': '¥',
    'HKD': 'HK\$',
    'CHF': 'Fr',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'CZK': 'Kč',
    'BRL': 'R\$',
    'MXN': 'MX\$',
    'ARS': '\$',
    'KES': 'KSh',
    'NGN': '₦',
    'EGP': 'E£',
    'TRY': '₺',
    'SAR': 'SR',
    'QAR': 'QR',
    'KWD': 'KD',
    'OMR': 'OMR',
    'BHD': 'BD',
    'ZWL': 'Z\$',
    'JMD': 'J\$',
    'TTD': 'TT\$',
    'BBD': 'Bds\$',
  };

  /// Default currency if location cannot be determined
  static const String defaultCurrency = 'GBP';

  /// Extract currency from location string (e.g., "London, UK" -> "GBP")
  static String getCurrencyFromLocation(String? location) {
    if (location == null || location.isEmpty) {
      return defaultCurrency;
    }

    final locationLower = location.toLowerCase();

    // 1. Try to match country names/codes in the location string
    for (final entry in _countryToCurrency.entries) {
      if (locationLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Try to match against known city names
    for (final entry in _cityToCurrency.entries) {
      if (locationLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. If no match found, return default
    return defaultCurrency;
  }

  /// Get currency from the device's system locale (e.g., "en_AU" → "AUD")
  static String getCurrencyFromDeviceLocale() {
    try {
      final locale = Platform.localeName; // e.g. "en_AU", "hi_IN", "en_GB"
      final parts = locale.split('_');
      final countryCode = parts.length >= 2 ? parts.last.toUpperCase() : '';
      const localeToCountry = {
        'AU': 'australia', 'IN': 'india', 'GB': 'united kingdom',
        'UK': 'united kingdom', 'US': 'united states', 'PK': 'pakistan',
        'NZ': 'new zealand', 'ZA': 'south africa', 'LK': 'sri lanka',
        'BD': 'bangladesh', 'AE': 'uae', 'CA': 'canada', 'IE': 'ireland',
        'ZW': 'zimbabwe', 'JM': 'jamaica', 'TT': 'trinidad and tobago',
        'BB': 'barbados', 'DE': 'germany', 'FR': 'france', 'IT': 'italy',
        'ES': 'spain', 'NL': 'netherlands', 'JP': 'japan', 'CN': 'china',
        'MY': 'malaysia', 'SG': 'singapore', 'TH': 'thailand',
      };
      final countryName = localeToCountry[countryCode];
      if (countryName != null) {
        return _countryToCurrency[countryName] ?? defaultCurrency;
      }
    } catch (_) {}
    return defaultCurrency;
  }

  /// Load the coach's currency using a 4-level fallback strategy:
  ///   1. Top-level `currency` field on coachProfile
  ///   2. `defaultPricing.currency` field
  ///   3. Location-based detection from `country` → `city`
  ///   4. Device system locale
  /// Returns the resolved currency code (e.g. "GBP", "INR", "AUD").
  static Future<String> loadUserCurrency() async {
    try {
      final profile = await ProfileService.getProfile();
      final coachProfile = profile['coachProfile'] as Map<String, dynamic>?;

      if (coachProfile != null) {
        // 1. Top-level currency field
        final saved = coachProfile['currency'] as String?;
        if (saved != null && saved.isNotEmpty && saved != 'USD') return saved;

        // 2. defaultPricing.currency
        final defaultPricing = coachProfile['defaultPricing'] as Map<String, dynamic>?;
        final pricingCurrency = defaultPricing?['currency'] as String?;
        if (pricingCurrency != null && pricingCurrency.isNotEmpty && pricingCurrency != 'USD') {
          return pricingCurrency;
        }

        // 3. Location detection: country preferred over city
        final country = coachProfile['country'] as String?;
        final city = coachProfile['city'] as String?;
        final location = country ?? city;
        if (location != null && location.isNotEmpty) {
          final detected = getCurrencyFromLocation(location);
          if (detected != defaultCurrency) return detected;
        }
      }
    } catch (_) {}

    // 4. Device locale
    final localeCurrency = getCurrencyFromDeviceLocale();
    return localeCurrency;
  }

  /// Extract country from location string
  static String? extractCountry(String? location) {
    if (location == null || location.isEmpty) {
      return null;
    }

    // Usually country is the last part after comma
    final parts = location.split(',');
    if (parts.length >= 2) {
      final country = parts.last.trim().toLowerCase();
      
      // Check if this matches any known country
      for (final countryKey in _countryToCurrency.keys) {
        if (country.contains(countryKey) || countryKey.contains(country)) {
          return parts.last.trim(); // Return original case
        }
      }
    }

    return null;
  }

  /// Get currency symbol for a currency code
  static String getCurrencySymbol(String currencyCode) {
    return _currencySymbols[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Get full currency name
  static String getCurrencyName(String currencyCode) {
    const currencyNames = {
      'GBP': 'British Pound',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'INR': 'Indian Rupee',
      'AUD': 'Australian Dollar',
      'CAD': 'Canadian Dollar',
      'NZD': 'New Zealand Dollar',
      'ZAR': 'South African Rand',
      'PKR': 'Pakistani Rupee',
      'BDT': 'Bangladeshi Taka',
      'LKR': 'Sri Lankan Rupee',
      'AED': 'UAE Dirham',
      'SGD': 'Singapore Dollar',
      'MYR': 'Malaysian Ringgit',
      'THB': 'Thai Baht',
      'JPY': 'Japanese Yen',
      'CNY': 'Chinese Yuan',
      'HKD': 'Hong Kong Dollar',
      'CHF': 'Swiss Franc',
      'SEK': 'Swedish Krona',
      'NOK': 'Norwegian Krone',
      'DKK': 'Danish Krone',
      'PLN': 'Polish Zloty',
      'CZK': 'Czech Koruna',
      'BRL': 'Brazilian Real',
      'MXN': 'Mexican Peso',
      'ARS': 'Argentine Peso',
      'KES': 'Kenyan Shilling',
      'NGN': 'Nigerian Naira',
      'EGP': 'Egyptian Pound',
      'TRY': 'Turkish Lira',
      'SAR': 'Saudi Riyal',
      'QAR': 'Qatari Riyal',
      'KWD': 'Kuwaiti Dinar',
      'OMR': 'Omani Rial',
      'BHD': 'Bahraini Dinar',
      'ZWL': 'Zimbabwean Dollar',
      'JMD': 'Jamaican Dollar',
      'TTD': 'Trinidad and Tobago Dollar',
      'BBD': 'Barbadian Dollar',
    };

    return currencyNames[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Check if a currency is supported
  static bool isCurrencySupported(String currencyCode) {
    return _currencySymbols.containsKey(currencyCode.toUpperCase());
  }

  /// Get list of all supported currencies
  static List<String> getSupportedCurrencies() {
    return _currencySymbols.keys.toList();
  }
}

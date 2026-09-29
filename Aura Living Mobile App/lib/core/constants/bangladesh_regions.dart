/// Bangladesh Administrative Divisions, Districts, and Validation Utilities
class BangladeshRegions {
  BangladeshRegions._();

  static const String country = 'Bangladesh';
  static const String countryCode = '+880';
  static const String currencySymbol = '৳';
  static const String currencyCode = 'BDT';

  /// Standard BD Mobile Phone Validation Regex
  /// Matches +8801XXXXXXXXX or 01XXXXXXXXX (11-14 digits total)
  static final RegExp phoneRegex = RegExp(r'^(?:\+?880|0)1[3-9]\d{8}$');

  /// Standard 4-digit Bangladesh Postal Code Regex
  static final RegExp postalCodeRegex = RegExp(r'^\d{4}$');

  /// Validates and normalizes phone number to standard +8801XXXXXXXXX format
  static String? normalizePhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'[\s\-]'), '');
    if (!phoneRegex.hasMatch(clean)) return null;
    if (clean.startsWith('+880')) return clean;
    if (clean.startsWith('880')) return '+$clean';
    if (clean.startsWith('0')) return '+880${clean.substring(1)}';
    return '+880$clean';
  }

  /// 8 Administrative Divisions of Bangladesh
  static const List<String> divisions = [
    'Dhaka',
    'Chattogram',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
  ];

  /// Districts grouped by Division
  static const Map<String, List<String>> districtsByDivision = {
    'Dhaka': [
      'Dhaka',
      'Gazipur',
      'Narayanganj',
      'Tangail',
      'Narsingdi',
      'Faridpur',
      'Gopalganj',
      'Kishoreganj',
      'Madaripur',
      'Manikganj',
      'Munshiganj',
      'Rajbari',
      'Shariatpur',
    ],
    'Chattogram': [
      'Chattogram',
      'Cox\'s Bazar',
      'Cumilla',
      'Feni',
      'Brahmanbaria',
      'Noakhali',
      'Chandpur',
      'Lakshmipur',
      'Khagrachhari',
      'Rangamati',
      'Bandarban',
    ],
    'Rajshahi': [
      'Rajshahi',
      'Bogura',
      'Pabna',
      'Sirajganj',
      'Naogaon',
      'Natore',
      'Chapai Nawabganj',
      'Joypurhat',
    ],
    'Khulna': [
      'Khulna',
      'Jashore',
      'Kushtia',
      'Jhenaidah',
      'Satkhira',
      'Bagerhat',
      'Chuadanga',
      'Magura',
      'Meherpur',
      'Narail',
    ],
    'Barishal': [
      'Barishal',
      'Patuakhali',
      'Bhola',
      'Pirojpur',
      'Barguna',
      'Jhalokathi',
    ],
    'Sylhet': [
      'Sylhet',
      'Moulvibazar',
      'Habiganj',
      'Sunamganj',
    ],
    'Rangpur': [
      'Rangpur',
      'Dinajpur',
      'Gaibandha',
      'Kurigram',
      'Lalmonirhat',
      'Nilphamari',
      'Panchagarh',
      'Thakurgaon',
    ],
    'Mymensingh': [
      'Mymensingh',
      'Jamalpur',
      'Netrokona',
      'Sherpur',
    ],
  };

  /// Common Upazilas/Thanas for prominent urban districts
  static const Map<String, List<String>> thanasByDistrict = {
    'Dhaka': [
      'Gulshan',
      'Banani',
      'Dhanmondi',
      'Uttara',
      'Mirpur',
      'Mohammadpur',
      'Badda',
      'Motijheel',
      'Bashundhara R/A',
      'Tejgaon',
      'Lalbagh',
      'Khilgaon',
      'Paltan',
      'Savar',
      'Keraniganj',
    ],
    'Chattogram': [
      'Kotwali',
      'Panchlaish',
      'Khulshi',
      'Halishahar',
      'Agrabad',
      'Double Mooring',
      'Chandgaon',
      'Bakalia',
      'Pahartali',
    ],
    'Sylhet': [
      'Sylhet Sadar',
      'Kotwali',
      'Amberkhana',
      'Zindabazar',
      'Beanibazar',
      'Golapganj',
      'Sreemangal',
    ],
    'Rajshahi': [
      'Boalia',
      'Motihar',
      'Rajpara',
      'Shah Makhdum',
      'Paba',
    ],
    'Khulna': [
      'Khulna Sadar',
      'Sonadanga',
      'Khalishpur',
      'Daulatpur',
      'Khan Jahan Ali',
    ],
  };

  /// Returns thanas for district, or fallback default thanas if not specifically mapped
  static List<String> getThanasForDistrict(String district) {
    if (thanasByDistrict.containsKey(district)) {
      return thanasByDistrict[district]!;
    }
    return [
      '$district Sadar',
      'North $district',
      'South $district',
      'Central Thana',
    ];
  }
}

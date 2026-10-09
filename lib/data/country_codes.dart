class CountryCodeData {
  final String code;
  final String name;
  final String flag;
  final String dialCode;
  final String pattern;

  const CountryCodeData(
    this.code,
    this.name,
    this.flag,
    this.dialCode, [
    this.pattern = '',
  ]);

  String get dial => '+$dialCode';

  bool get hasCustomPattern => pattern.isNotEmpty;

  String get dialWithoutPlus => dialCode;
}

class CountryCodes {
  static const List<CountryCodeData> all = [
    CountryCodeData('AF', 'Afghanistan', '🇦🇫', '93', r'7\d{8}'),
    CountryCodeData('AL', 'Albania', '🇦🇱', '355', r'6\d{8}'),
    CountryCodeData('DZ', 'Algeria', '🇩🇿', '213', r'[567]\d{8}'),
    CountryCodeData('AS', 'American Samoa', '🇦🇸', '1684'),
    CountryCodeData('AD', 'Andorra', '🇦🇩', '376', r'\d{6}'),
    CountryCodeData('AO', 'Angola', '🇦🇴', '244', r'9\d{8}'),
    CountryCodeData('AI', 'Anguilla', '🇦🇮', '1264', r'\d{7}'),
    CountryCodeData('AG', 'Antigua and Barbuda', '🇦🇬', '1268', r'\d{7}'),
    CountryCodeData('AR', 'Argentina', '🇦🇷', '54', r'\d{8,11}'),
    CountryCodeData('AM', 'Armenia', '🇦🇲', '374', r'\d{8}'),
    CountryCodeData('AW', 'Aruba', '🇦🇼', '297', r'\d{7}'),
    CountryCodeData('AU', 'Australia', '🇦🇺', '61', r'4\d{8}'),
    CountryCodeData('AT', 'Austria', '🇦🇹', '43', r'6\d{8,9}'),
    CountryCodeData('AZ', 'Azerbaijan', '🇦🇿', '994', r'\d{9}'),
    CountryCodeData('BS', 'Bahamas', '🇧🇸', '1242', r'\d{7}'),
    CountryCodeData('BH', 'Bahrain', '🇧🇭', '973', r'[3-9]\d{7}'),
    CountryCodeData('BD', 'Bangladesh', '🇧🇩', '880', r'1\d{9}'),
    CountryCodeData('BB', 'Barbados', '🇧🇧', '1246', r'\d{7}'),
    CountryCodeData('BY', 'Belarus', '🇧🇾', '375', r'\d{9}'),
    CountryCodeData('BE', 'Belgium', '🇧🇪', '32', r'4[5-9]\d{7}'),
    CountryCodeData('BZ', 'Belize', '🇧🇿', '501', r'\d{7}'),
    CountryCodeData('BJ', 'Benin', '🇧🇯', '229', r'\d{8}'),
    CountryCodeData('BM', 'Bermuda', '🇧🇲', '1441', r'\d{7}'),
    CountryCodeData('BT', 'Bhutan', '🇧🇹', '975', r'\d{8}'),
    CountryCodeData('BO', 'Bolivia', '🇧🇴', '591', r'\d{8}'),
    CountryCodeData('BA', 'Bosnia and Herzegovina', '🇧🇦', '387', r'6\d{7}'),
    CountryCodeData('BW', 'Botswana', '🇧🇼', '267', r'7\d{7}'),
    CountryCodeData('BR', 'Brazil', '🇧🇷', '55', r'[1-9]\d{9,10}'),
    CountryCodeData('VG', 'British Virgin Islands', '🇻🇬', '1284', r'\d{7}'),
    CountryCodeData('BN', 'Brunei', '🇧🇳', '673', r'\d{7}'),
    CountryCodeData('BG', 'Bulgaria', '🇧🇬', '359', r'8\d{8}'),
    CountryCodeData('BF', 'Burkina Faso', '🇧🇫', '226', r'\d{8}'),
    CountryCodeData('BI', 'Burundi', '🇧🇮', '257', r'\d{8}'),
    CountryCodeData('KH', 'Cambodia', '🇰🇭', '855', r'\d{8,9}'),
    CountryCodeData('CM', 'Cameroon', '🇨🇲', '237', r'6\d{8}'),
    CountryCodeData('CA', 'Canada', '🇨🇦', '1', r'\d{10}'),
    CountryCodeData('CV', 'Cape Verde', '🇨🇻', '238', r'\d{7}'),
    CountryCodeData('KY', 'Cayman Islands', '🇰🇾', '1345', r'\d{7}'),
    CountryCodeData('CF', 'Central African Republic', '🇨🇫', '236', r'\d{8}'),
    CountryCodeData('TD', 'Chad', '🇹🇩', '235', r'\d{8}'),
    CountryCodeData('CL', 'Chile', '🇨🇱', '56', r'9\d{8}'),
    CountryCodeData('CN', 'China', '🇨🇳', '86', r'1\d{10}'),
    CountryCodeData('CO', 'Colombia', '🇨🇴', '57', r'3\d{9}'),
    CountryCodeData('KM', 'Comoros', '🇰🇲', '269', r'\d{7}'),
    CountryCodeData('CG', 'Congo', '🇨🇬', '242', r'\d{9}'),
    CountryCodeData('CD', 'Congo (DRC)', '🇨🇩', '243', r'\d{9}'),
    CountryCodeData('CK', 'Cook Islands', '🇨🇰', '682', r'\d{5}'),
    CountryCodeData('CR', 'Costa Rica', '🇨🇷', '506', r'\d{8}'),
    CountryCodeData('CI', 'Côte d\'Ivoire', '🇨🇮', '225', r'\d{8,10}'),
    CountryCodeData('HR', 'Croatia', '🇭🇷', '385', r'9\d{8}'),
    CountryCodeData('CU', 'Cuba', '🇨🇺', '53', r'\d{8}'),
    CountryCodeData('CY', 'Cyprus', '🇨🇾', '357', r'9\d{7}'),
    CountryCodeData('CZ', 'Czech Republic', '🇨🇿', '420', r'[5-9]\d{8}'),
    CountryCodeData('DK', 'Denmark', '🇩🇰', '45', r'[2-9]\d{7}'),
    CountryCodeData('DJ', 'Djibouti', '🇩🇯', '253', r'\d{8}'),
    CountryCodeData('DM', 'Dominica', '🇩🇲', '1767', r'\d{7}'),
    CountryCodeData('DO', 'Dominican Republic', '🇩🇴', '1809', r'\d{10}'),
    CountryCodeData('EC', 'Ecuador', '🇪🇨', '593', r'9\d{8}'),
    CountryCodeData('EG', 'Egypt', '🇪🇬', '20', r'1\d{9}'),
    CountryCodeData('SV', 'El Salvador', '🇸🇻', '503', r'\d{8}'),
    CountryCodeData('GQ', 'Equatorial Guinea', '🇬🇶', '240', r'\d{9}'),
    CountryCodeData('ER', 'Eritrea', '🇪🇷', '291', r'\d{7}'),
    CountryCodeData('EE', 'Estonia', '🇪🇪', '372', r'[5-9]\d{7}'),
    CountryCodeData('SZ', 'Eswatini', '🇸🇿', '268', r'\d{8}'),
    CountryCodeData('ET', 'Ethiopia', '🇪🇹', '251', r'9\d{8}'),
    CountryCodeData('FK', 'Falkland Islands', '🇫🇰', '500', r'\d{5}'),
    CountryCodeData('FO', 'Faroe Islands', '🇫🇴', '298', r'\d{6}'),
    CountryCodeData('FJ', 'Fiji', '🇫🇯', '679', r'\d{7}'),
    CountryCodeData('FI', 'Finland', '🇫🇮', '358', r'[45]\d{8}'),
    CountryCodeData('FR', 'France', '🇫🇷', '33', r'[67]\d{8}'),
    CountryCodeData('GF', 'French Guiana', '🇬🇫', '594', r'\d{9}'),
    CountryCodeData('PF', 'French Polynesia', '🇵🇫', '689', r'\d{8}'),
    CountryCodeData('GA', 'Gabon', '🇬🇦', '241', r'\d{8}'),
    CountryCodeData('GM', 'Gambia', '🇬🇲', '220', r'\d{7}'),
    CountryCodeData('GE', 'Georgia', '🇬🇪', '995', r'[5-9]\d{8}'),
    CountryCodeData('DE', 'Germany', '🇩🇪', '49', r'1[5-7]\d{8,9}'),
    CountryCodeData('GH', 'Ghana', '🇬🇭', '233', r'[2-5]\d{8}'),
    CountryCodeData('GI', 'Gibraltar', '🇬🇮', '350', r'\d{8}'),
    CountryCodeData('GR', 'Greece', '🇬🇷', '30', r'6\d{9}'),
    CountryCodeData('GL', 'Greenland', '🇬🇱', '299', r'\d{6}'),
    CountryCodeData('GD', 'Grenada', '🇬🇩', '1473', r'\d{7}'),
    CountryCodeData('GP', 'Guadeloupe', '🇬🇵', '590', r'\d{9}'),
    CountryCodeData('GU', 'Guam', '🇬🇺', '1671', r'\d{7}'),
    CountryCodeData('GT', 'Guatemala', '🇬🇹', '502', r'\d{8}'),
    CountryCodeData('GN', 'Guinea', '🇬🇳', '224', r'\d{9}'),
    CountryCodeData('GW', 'Guinea-Bissau', '🇬🇼', '245', r'\d{7}'),
    CountryCodeData('GY', 'Guyana', '🇬🇾', '592', r'\d{7}'),
    CountryCodeData('HT', 'Haiti', '🇭🇹', '509', r'\d{8}'),
    CountryCodeData('HN', 'Honduras', '🇭🇳', '504', r'\d{8}'),
    CountryCodeData('HK', 'Hong Kong', '🇭🇰', '852', r'[5-9]\d{7}'),
    CountryCodeData('HU', 'Hungary', '🇭🇺', '36', r'[1-9]\d{8}'),
    CountryCodeData('IS', 'Iceland', '🇮🇸', '354', r'[4-9]\d{6}'),
    CountryCodeData('IN', 'India', '🇮🇳', '91', r'[6-9]\d{9}'),
    CountryCodeData('ID', 'Indonesia', '🇮🇩', '62', r'8\d{8,11}'),
    CountryCodeData('IR', 'Iran', '🇮🇷', '98', r'9\d{9}'),
    CountryCodeData('IQ', 'Iraq', '🇮🇶', '964', r'7\d{9}'),
    CountryCodeData('IE', 'Ireland', '🇮🇪', '353', r'[78]\d{8}'),
    CountryCodeData('IL', 'Israel', '🇮🇱', '972', r'5\d{8}'),
    CountryCodeData('IT', 'Italy', '🇮🇹', '39', r'3\d{9}'),
    CountryCodeData('JM', 'Jamaica', '🇯🇲', '1876', r'\d{10}'),
    CountryCodeData('JP', 'Japan', '🇯🇵', '81', r'[7-9]0\d{8}'),
    CountryCodeData('JO', 'Jordan', '🇯🇴', '962', r'7\d{8}'),
    CountryCodeData('KZ', 'Kazakhstan', '🇰🇿', '7', r'7\d{9}'),
    CountryCodeData('KE', 'Kenya', '🇰🇪', '254', r'[17]\d{8}'),
    CountryCodeData('KI', 'Kiribati', '🇰🇮', '686', r'\d{5}'),
    CountryCodeData('XK', 'Kosovo', '🇽🇰', '383', r'[4-6]\d{7}'),
    CountryCodeData('KW', 'Kuwait', '🇰🇼', '965', r'[569]\d{7}'),
    CountryCodeData('KG', 'Kyrgyzstan', '🇰🇬', '996', r'\d{9}'),
    CountryCodeData('LA', 'Laos', '🇱🇦', '856', r'20\d{8}'),
    CountryCodeData('LV', 'Latvia', '🇱🇻', '371', r'[2-9]\d{7}'),
    CountryCodeData('LB', 'Lebanon', '🇱🇧', '961', r'[3-9]\d{7}'),
    CountryCodeData('LS', 'Lesotho', '🇱🇸', '266', r'\d{8}'),
    CountryCodeData('LR', 'Liberia', '🇱🇷', '231', r'\d{8}'),
    CountryCodeData('LY', 'Libya', '🇱🇾', '218', r'9\d{8}'),
    CountryCodeData('LI', 'Liechtenstein', '🇱🇮', '423', r'\d{7}'),
    CountryCodeData('LT', 'Lithuania', '🇱🇹', '370', r'[6-9]\d{7}'),
    CountryCodeData('LU', 'Luxembourg', '🇱🇺', '352', r'[26]\d{8}'),
    CountryCodeData('MO', 'Macau', '🇲🇴', '853', r'\d{8}'),
    CountryCodeData('MG', 'Madagascar', '🇲🇬', '261', r'\d{9}'),
    CountryCodeData('MW', 'Malawi', '🇲🇼', '265', r'\d{9}'),
    CountryCodeData('MY', 'Malaysia', '🇲🇾', '60', r'1\d{8,9}'),
    CountryCodeData('MV', 'Maldives', '🇲🇻', '960', r'\d{7}'),
    CountryCodeData('ML', 'Mali', '🇲🇱', '223', r'\d{8}'),
    CountryCodeData('MT', 'Malta', '🇲🇹', '356', r'[79]\d{7}'),
    CountryCodeData('MH', 'Marshall Islands', '🇲🇭', '692', r'\d{7}'),
    CountryCodeData('MQ', 'Martinique', '🇲🇶', '596', r'\d{9}'),
    CountryCodeData('MR', 'Mauritania', '🇲🇷', '222', r'\d{8}'),
    CountryCodeData('MU', 'Mauritius', '🇲🇺', '230', r'\d{8}'),
    CountryCodeData('YT', 'Mayotte', '🇾🇹', '262', r'\d{9}'),
    CountryCodeData('MX', 'Mexico', '🇲🇽', '52', r'[1-9]\d{9}'),
    CountryCodeData('FM', 'Micronesia', '🇫🇲', '691', r'\d{7}'),
    CountryCodeData('MD', 'Moldova', '🇲🇩', '373', r'[6-8]\d{7}'),
    CountryCodeData('MC', 'Monaco', '🇲🇨', '377', r'\d{8}'),
    CountryCodeData('MN', 'Mongolia', '🇲🇳', '976', r'[5-9]\d{7}'),
    CountryCodeData('ME', 'Montenegro', '🇲🇪', '382', r'[6-9]\d{7}'),
    CountryCodeData('MS', 'Montserrat', '🇲🇸', '1664', r'\d{7}'),
    CountryCodeData('MA', 'Morocco', '🇲🇦', '212', r'[567]\d{8}'),
    CountryCodeData('MZ', 'Mozambique', '🇲🇿', '258', r'\d{9}'),
    CountryCodeData('MM', 'Myanmar', '🇲🇲', '95', r'\d{8,10}'),
    CountryCodeData('NA', 'Namibia', '🇳🇦', '264', r'\d{9}'),
    CountryCodeData('NR', 'Nauru', '🇳🇷', '674', r'\d{7}'),
    CountryCodeData('NP', 'Nepal', '🇳🇵', '977', r'9[6-8]\d{8}'),
    CountryCodeData('NL', 'Netherlands', '🇳🇱', '31', r'6\d{8}'),
    CountryCodeData('NC', 'New Caledonia', '🇳🇨', '687', r'\d{8}'),
    CountryCodeData('NZ', 'New Zealand', '🇳🇿', '64', r'2[1-9]\d{7}'),
    CountryCodeData('NI', 'Nicaragua', '🇳🇮', '505', r'\d{8}'),
    CountryCodeData('NE', 'Niger', '🇳🇪', '227', r'\d{8}'),
    CountryCodeData('NG', 'Nigeria', '🇳🇬', '234', r'[789]\d{9}'),
    CountryCodeData('NU', 'Niue', '🇳🇺', '683', r'\d{4}'),
    CountryCodeData('KP', 'North Korea', '🇰🇵', '850', r'\d{8,10}'),
    CountryCodeData('MK', 'North Macedonia', '🇲🇰', '389', r'7\d{7}'),
    CountryCodeData('MP', 'Northern Mariana Islands', '🇲🇵', '1670', r'\d{7}'),
    CountryCodeData('NO', 'Norway', '🇳🇴', '47', r'[4-9]\d{7}'),
    CountryCodeData('OM', 'Oman', '🇴🇲', '968', r'[79]\d{7}'),
    CountryCodeData('PK', 'Pakistan', '🇵🇰', '92', r'3\d{9}'),
    CountryCodeData('PW', 'Palau', '🇵🇼', '680', r'\d{7}'),
    CountryCodeData('PS', 'Palestine', '🇵🇸', '970', r'5\d{8}'),
    CountryCodeData('PA', 'Panama', '🇵🇦', '507', r'\d{8}'),
    CountryCodeData('PG', 'Papua New Guinea', '🇵🇬', '675', r'\d{8}'),
    CountryCodeData('PY', 'Paraguay', '🇵🇾', '595', r'\d{9}'),
    CountryCodeData('PE', 'Peru', '🇵🇪', '51', r'9\d{8}'),
    CountryCodeData('PH', 'Philippines', '🇵🇭', '63', r'9\d{9}'),
    CountryCodeData('PL', 'Poland', '🇵🇱', '48', r'[5-8]\d{8}'),
    CountryCodeData('PT', 'Portugal', '🇵🇹', '351', r'9\d{8}'),
    CountryCodeData('PR', 'Puerto Rico', '🇵🇷', '1787', r'\d{10}'),
    CountryCodeData('QA', 'Qatar', '🇶🇦', '974', r'[3567]\d{7}'),
    CountryCodeData('RE', 'Réunion', '🇷🇪', '262', r'\d{9}'),
    CountryCodeData('RO', 'Romania', '🇷🇴', '40', r'[2-9]\d{8}'),
    CountryCodeData('RU', 'Russia', '🇷🇺', '7', r'\d{10}'),
    CountryCodeData('RW', 'Rwanda', '🇷🇼', '250', r'7\d{8}'),
    CountryCodeData('BL', 'Saint Barthélemy', '🇧🇱', '590', r'\d{9}'),
    CountryCodeData('SH', 'Saint Helena', '🇸🇭', '290', r'\d{4,6}'),
    CountryCodeData('KN', 'Saint Kitts and Nevis', '🇰🇳', '1869', r'\d{7}'),
    CountryCodeData('LC', 'Saint Lucia', '🇱🇨', '1758', r'\d{7}'),
    CountryCodeData('MF', 'Saint Martin', '🇲🇫', '590', r'\d{9}'),
    CountryCodeData('PM', 'Saint Pierre and Miquelon', '🇵🇲', '508', r'\d{6}'),
    CountryCodeData('VC', 'Saint Vincent and the Grenadines', '🇻🇨', '1784', r'\d{7}'),
    CountryCodeData('WS', 'Samoa', '🇼🇸', '685', r'\d{6}'),
    CountryCodeData('SM', 'San Marino', '🇸🇲', '378', r'\d{8}'),
    CountryCodeData('ST', 'São Tomé and Príncipe', '🇸🇹', '239', r'\d{7}'),
    CountryCodeData('SA', 'Saudi Arabia', '🇸🇦', '966', r'5\d{8}'),
    CountryCodeData('SN', 'Senegal', '🇸🇳', '221', r'\d{9}'),
    CountryCodeData('RS', 'Serbia', '🇷🇸', '381', r'6\d{8}'),
    CountryCodeData('SC', 'Seychelles', '🇸🇨', '248', r'\d{7}'),
    CountryCodeData('SL', 'Sierra Leone', '🇸🇱', '232', r'\d{8}'),
    CountryCodeData('SG', 'Singapore', '🇸🇬', '65', r'[3689]\d{7}'),
    CountryCodeData('SX', 'Sint Maarten', '🇸🇽', '1721', r'\d{7}'),
    CountryCodeData('SK', 'Slovakia', '🇸🇰', '421', r'\d{9}'),
    CountryCodeData('SI', 'Slovenia', '🇸🇮', '386', r'[3-9]\d{7}'),
    CountryCodeData('SB', 'Solomon Islands', '🇸🇧', '677', r'\d{7}'),
    CountryCodeData('SO', 'Somalia', '🇸🇴', '252', r'\d{9}'),
    CountryCodeData('ZA', 'South Africa', '🇿🇦', '27', r'[5-9]\d{8}'),
    CountryCodeData('KR', 'South Korea', '🇰🇷', '82', r'1\d{9,10}'),
    CountryCodeData('SS', 'South Sudan', '🇸🇸', '211', r'\d{9}'),
    CountryCodeData('ES', 'Spain', '🇪🇸', '34', r'[67]\d{8}'),
    CountryCodeData('LK', 'Sri Lanka', '🇱🇰', '94', r'7\d{8}'),
    CountryCodeData('SD', 'Sudan', '🇸🇩', '249', r'9\d{8}'),
    CountryCodeData('SR', 'Suriname', '🇸🇷', '597', r'\d{7}'),
    CountryCodeData('SE', 'Sweden', '🇸🇪', '46', r'[67]\d{8}'),
    CountryCodeData('CH', 'Switzerland', '🇨🇭', '41', r'[78]\d{8}'),
    CountryCodeData('SY', 'Syria', '🇸🇾', '963', r'[19]\d{8}'),
    CountryCodeData('TW', 'Taiwan', '🇹🇼', '886', r'9\d{8}'),
    CountryCodeData('TJ', 'Tajikistan', '🇹🇯', '992', r'\d{9}'),
    CountryCodeData('TZ', 'Tanzania', '🇹🇿', '255', r'[67]\d{8}'),
    CountryCodeData('TH', 'Thailand', '🇹🇭', '66', r'[6-9]\d{8}'),
    CountryCodeData('TL', 'Timor-Leste', '🇹🇱', '670', r'\d{8}'),
    CountryCodeData('TG', 'Togo', '🇹🇬', '228', r'\d{8}'),
    CountryCodeData('TO', 'Tonga', '🇹🇴', '676', r'\d{5}'),
    CountryCodeData('TT', 'Trinidad and Tobago', '🇹🇹', '1868', r'\d{7}'),
    CountryCodeData('TN', 'Tunisia', '🇹🇳', '216', r'[259]\d{7}'),
    CountryCodeData('TR', 'Turkey', '🇹🇷', '90', r'5\d{9}'),
    CountryCodeData('TM', 'Turkmenistan', '🇹🇲', '993', r'\d{8}'),
    CountryCodeData('TC', 'Turks and Caicos Islands', '🇹🇨', '1649', r'\d{7}'),
    CountryCodeData('TV', 'Tuvalu', '🇹🇻', '688', r'\d{5}'),
    CountryCodeData('UG', 'Uganda', '🇺🇬', '256', r'7\d{8}'),
    CountryCodeData('UA', 'Ukraine', '🇺🇦', '380', r'[3-9]\d{8}'),
    CountryCodeData('AE', 'United Arab Emirates', '🇦🇪', '971', r'5\d{8}'),
    CountryCodeData('GB', 'United Kingdom', '🇬🇧', '44', r'7\d{9}'),
    CountryCodeData('US', 'United States', '🇺🇸', '1', r'\d{10}'),
    CountryCodeData('UY', 'Uruguay', '🇺🇾', '598', r'\d{8}'),
    CountryCodeData('VI', 'U.S. Virgin Islands', '🇻🇮', '1340', r'\d{7}'),
    CountryCodeData('UZ', 'Uzbekistan', '🇺🇿', '998', r'\d{9}'),
    CountryCodeData('VU', 'Vanuatu', '🇻🇺', '678', r'\d{7}'),
    CountryCodeData('VE', 'Venezuela', '🇻🇪', '58', r'4\d{9}'),
    CountryCodeData('VN', 'Vietnam', '🇻🇳', '84', r'[3-9]\d{8}'),
    CountryCodeData('WF', 'Wallis and Futuna', '🇼🇫', '681', r'\d{6}'),
    CountryCodeData('YE', 'Yemen', '🇾🇪', '967', r'[73]\d{8}'),
    CountryCodeData('ZM', 'Zambia', '🇿🇲', '260', r'\d{9}'),
    CountryCodeData('ZW', 'Zimbabwe', '🇿🇼', '263', r'[67]\d{8}'),
  ];

  static CountryCodeData get defaultCountry {
    return all.firstWhere(
      (c) => c.code == 'AE',
      orElse: () => all.first,
    );
  }

  static final List<String> _gulfCodes = const ['AE', 'SA', 'KW', 'QA', 'BH', 'OM'];

  static List<CountryCodeData> get gulf {
    return _gulfCodes
        .map((code) => all.firstWhere((c) => c.code == code))
        .toList();
  }

  static List<CountryCodeData> searchGulf(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return gulf;
    return gulf.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.dial.contains(q.replaceFirst('+', '')) ||
          c.code.toLowerCase() == q;
    }).toList();
  }

  static List<CountryCodeData> get sorted {
    final list = List<CountryCodeData>.from(all);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  static List<CountryCodeData> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sorted;
    return sorted.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.dial.contains(q.replaceFirst('+', '')) ||
          c.code.toLowerCase() == q;
    }).toList();
  }

  static String nationalDigits(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  static String toE164(CountryCodeData country, String input) {
    return '+${country.dialCode}${nationalDigits(input)}';
  }

  static String? validate(CountryCodeData country, String? input) {
    if (input == null || input.trim().isEmpty) return 'empty';
    final national = nationalDigits(input);
    if (national.isEmpty) return 'invalid';
    if (country.hasCustomPattern) {
      if (!RegExp('^${country.pattern}\$').hasMatch(national)) {
        return 'invalid';
      }
    } else {
      if (national.length < 6 || national.length > 12) return 'invalid';
    }
    return null;
  }
}

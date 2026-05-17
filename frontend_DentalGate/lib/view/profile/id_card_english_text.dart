/// تحويل نصوص بطاقة الهوية للإنجليزية عند الإدخال بالعربية.
abstract final class IdCardEnglishText {
  static final RegExp _arabicScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');

  static bool containsArabic(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _arabicScript.hasMatch(value);
  }

  static String _normalizeKey(String value) {
    var s = value.trim().toLowerCase();
    const replacements = <String, String>{
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ى': 'ي',
      'ة': 'ه',
      'ؤ': 'و',
      'ئ': 'ي',
    };
    for (final e in replacements.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  static const Map<String, String> _roman = {
    'ا': 'a',
    'ب': 'b',
    'ت': 't',
    'ث': 'th',
    'ج': 'j',
    'ح': 'h',
    'خ': 'kh',
    'د': 'd',
    'ذ': 'dh',
    'ر': 'r',
    'ز': 'z',
    'س': 's',
    'ش': 'sh',
    'ص': 's',
    'ض': 'd',
    'ط': 't',
    'ظ': 'z',
    'ع': 'a',
    'غ': 'gh',
    'ف': 'f',
    'ق': 'q',
    'ك': 'k',
    'ل': 'l',
    'م': 'm',
    'ن': 'n',
    'ه': 'h',
    'و': 'w',
    'ي': 'y',
    'ء': '',
    'ئ': 'y',
    'ؤ': 'w',
  };

  /// كلمات شائعة (أسماء / ألقاب) بتهجئة إنجليزية معتادة.
  static const Map<String, String> _knownWords = {
    'مهند': 'Muhannad',
    'محمد': 'Muhammad',
    'احمد': 'Ahmad',
    'علي': 'Ali',
    'حسن': 'Hassan',
    'حسين': 'Hussein',
    'عمر': 'Omar',
    'خالد': 'Khaled',
    'يوسف': 'Youssef',
    'مصطفى': 'Mustafa',
    'عبد': 'Abd',
    'عبدالله': 'Abdullah',
    'عبد الله': 'Abdullah',
    'مالكي': 'Maliki',
    'المالكي': 'Al-Maliki',
    'العبيدي': 'Al-Obaidi',
    'الجبوري': 'Al-Jubouri',
    'السعدي': 'Al-Saadi',
  };

  static const Map<String, String> _governoratesNormalized = {
    'بغداد': 'Baghdad',
    'نينوي': 'Nineveh',
    'البصره': 'Basra',
    'اربيل': 'Erbil',
    'النجف': 'Najaf',
    'كربلاء': 'Karbala',
    'السليمانيه': 'Sulaymaniyah',
    'دهوك': 'Duhok',
    'كركوك': 'Kirkuk',
    'الانبار': 'Anbar',
    'ديالى': 'Diyala',
    'صلاح الدين': 'Salah al-Din',
    'بابل': 'Babylon',
    'واسط': 'Wasit',
    'ذي قار': 'Dhi Qar',
    'ميسان': 'Maysan',
    'المثني': 'Al Muthanna',
    'القادسيه': 'Al-Qadisiyyah',
  };

  static const Map<String, String> _specialtiesNormalized = {
    'طبيب اسنان': 'Dentist',
    'طبيب الاسنان': 'Dentist',
    'طبيب اسنان عام': 'General Dentist',
    'طبيب الاسنان عام': 'General Dentist',
    'طبيبه اسنان': 'Dentist',
    'طبيبه الاسنان': 'Dentist',
    'مساعد طبيب': 'Dental Assistant',
    'مساعد طبيب اسنان': 'Dental Assistant',
    'مساعده طبيب': 'Dental Assistant',
    'تقني اسنان': 'Dental Technician',
    'تقني الاسنان': 'Dental Technician',
    'اخصائي اسنان': 'Dental Specialist',
    'اخصائي الاسنان': 'Dental Specialist',
    'دكتور اسنان': 'Dentist',
    'دكتور الاسنان': 'Dentist',
  };

  static const Map<String, String> _genders = {
    'ذكر': 'Male',
    'انثى': 'Female',
    'أنثى': 'Female',
    'male': 'Male',
    'm': 'Male',
    'female': 'Female',
    'f': 'Female',
  };

  static String _transliterateWord(String word) {
    if (word.isEmpty) return '';

    final known = _knownWords[word] ?? _knownWords[_normalizeKey(word)];
    if (known != null) return known;

    if (word.startsWith('ال') && word.length > 2) {
      final rest = word.substring(2);
      final restT = _transliterateWord(rest);
      if (restT.isEmpty) return 'Al';
      return 'Al-$restT';
    }

    final buf = StringBuffer();
    for (final rune in word.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == 'ة') {
        buf.write('a');
        continue;
      }
      final mapped = _roman[ch];
      if (mapped != null) {
        buf.write(mapped);
      }
    }

    var out = buf.toString();
    if (out.isEmpty) return '';
    // دمج أحرف مكررة بسيطة (مثل a+a)
    out = out.replaceAll(RegExp(r'aa+'), 'a');
    return _titleToken(out);
  }

  static String transliterate(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    return parts.map(_transliterateWord).join(' ');
  }

  static String _titleToken(String token) {
    if (token.isEmpty) return token;
    if (token.startsWith('Al-') && token.length > 3) {
      final rest = token.substring(3);
      return 'Al-${rest[0].toUpperCase()}${rest.substring(1)}';
    }
    return '${token[0].toUpperCase()}${token.substring(1)}';
  }

  /// إن كان النص إنجليزياً يُعاد كما هو؛ وإلا تُطبَّق الترجمة أو التهجئة.
  static String display(
    String? raw,
    String Function(String normalized) translate, {
    bool transliterateFallback = false,
  }) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return '—';
    if (!containsArabic(t)) return t;
    final translated = translate(_normalizeKey(t));
    if (translated.isNotEmpty) return translated;
    if (transliterateFallback) {
      final roman = transliterate(t);
      return roman.isNotEmpty ? roman : t;
    }
    return t;
  }

  static String name(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return 'Dentist';
    if (!containsArabic(t)) return t;
    final roman = transliterate(t);
    return roman.isNotEmpty ? roman : t;
  }

  static String specialty(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return '';
    if (!containsArabic(t)) return t;
    final mapped = _specialtiesNormalized[_normalizeKey(t)];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    final roman = transliterate(t);
    return roman.isNotEmpty ? roman : t;
  }

  static String city(String? raw) =>
      display(raw, (n) => _governoratesNormalized[n] ?? '');

  static String gender(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return '—';
    if (!containsArabic(t)) {
      final n = t.toLowerCase();
      return _genders[n] ?? t;
    }
    return _genders[_normalizeKey(t)] ?? _genders[t] ?? t;
  }

  static String age(int? years) {
    if (years == null) return '—';
    return '$years years';
  }

  static String phone(String raw) => raw.trim();
}

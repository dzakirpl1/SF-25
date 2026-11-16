class UserSettings {
  final String userId;
  final String theme;
  final String accentColor;
  final String timezone;
  final String locale;
  final String currency;
  final int weekStart;
  final int dayStartHour;
  final bool appLockEnabled;
  final bool pinEnabled;
  final bool biometricEnabled;
  final int lockTimeoutMinutes;
  final DateTime? updatedAt;

  UserSettings({
    required this.userId,
    this.theme = 'system',
    this.accentColor = 'teal',
    this.timezone = 'Asia/Jakarta',
    this.locale = 'id_ID',
    this.currency = 'IDR',
    this.weekStart = 1,
    this.dayStartHour = 4,
    this.appLockEnabled = false,
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.lockTimeoutMinutes = 5,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      theme: json['theme'] as String? ?? 'system',
      accentColor: json['accent_color'] as String? ?? 'teal',
      timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
      locale: json['locale'] as String? ?? 'id_ID',
      currency: json['currency'] as String? ?? 'IDR',
      weekStart: json['week_start'] as int? ?? 1,
      dayStartHour: json['day_start_hour'] as int? ?? 4,
      appLockEnabled: json['app_lock_enabled'] as bool? ?? false,
      pinEnabled: json['pin_enabled'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      lockTimeoutMinutes: json['lock_timeout_minutes'] as int? ?? 5,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'theme': theme,
      'accent_color': accentColor,
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      'week_start': weekStart,
      'day_start_hour': dayStartHour,
      'app_lock_enabled': appLockEnabled,
      'pin_enabled': pinEnabled,
      'biometric_enabled': biometricEnabled,
      'lock_timeout_minutes': lockTimeoutMinutes,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? theme,
    String? accentColor,
    String? timezone,
    String? locale,
    String? currency,
    int? weekStart,
    int? dayStartHour,
    bool? appLockEnabled,
    bool? pinEnabled,
    bool? biometricEnabled,
    int? lockTimeoutMinutes,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId,
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      weekStart: weekStart ?? this.weekStart,
      dayStartHour: dayStartHour ?? this.dayStartHour,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

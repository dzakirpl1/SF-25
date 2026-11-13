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
    };
  }
}

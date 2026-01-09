/// User Settings Model
/// Represents user settings data from the API matching backend schema

// ============ Theme Settings ============
class ThemeSettings {
  final String mode; // 'light', 'dark', 'system'
  final String? primaryColor;
  final String fontSize; // 'small', 'medium', 'large'
  final List<String>? customFonts;

  ThemeSettings({
    this.mode = 'system',
    this.primaryColor,
    this.fontSize = 'medium',
    this.customFonts,
  });

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      mode: json['mode'] ?? 'system',
      primaryColor: json['primaryColor'],
      fontSize: json['fontSize'] ?? 'medium',
      customFonts: json['customFonts'] != null
          ? List<String>.from(json['customFonts'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      if (primaryColor != null) 'primaryColor': primaryColor,
      'fontSize': fontSize,
      if (customFonts != null) 'customFonts': customFonts,
    };
  }

  ThemeSettings copyWith({
    String? mode,
    String? primaryColor,
    String? fontSize,
    List<String>? customFonts,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      fontSize: fontSize ?? this.fontSize,
      customFonts: customFonts ?? this.customFonts,
    );
  }
}

// ============ Quiet Hours Settings ============
class QuietHoursSettings {
  final bool enabled;
  final String? start;
  final String? end;
  final String? timezone;

  QuietHoursSettings({
    this.enabled = false,
    this.start,
    this.end,
    this.timezone,
  });

  factory QuietHoursSettings.fromJson(Map<String, dynamic> json) {
    return QuietHoursSettings(
      enabled: json['enabled'] ?? false,
      start: json['start'],
      end: json['end'],
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (timezone != null) 'timezone': timezone,
    };
  }

  QuietHoursSettings copyWith({
    bool? enabled,
    String? start,
    String? end,
    String? timezone,
  }) {
    return QuietHoursSettings(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
      timezone: timezone ?? this.timezone,
    );
  }
}

// ============ Notification Settings ============
class NotificationSettings {
  final bool email;
  final bool push;
  final bool sms;
  final bool marketing;
  final bool sound;
  final String? customSoundUrl;
  final QuietHoursSettings quietHours;

  NotificationSettings({
    this.email = true,
    this.push = true,
    this.sms = false,
    this.marketing = false,
    this.sound = true,
    this.customSoundUrl,
    QuietHoursSettings? quietHours,
  }) : quietHours = quietHours ?? QuietHoursSettings();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      email: json['email'] ?? true,
      push: json['push'] ?? true,
      sms: json['sms'] ?? false,
      marketing: json['marketing'] ?? false,
      sound: json['sound'] ?? true,
      customSoundUrl: json['customSoundUrl'],
      quietHours: json['quietHours'] != null
          ? QuietHoursSettings.fromJson(json['quietHours'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'push': push,
      'sms': sms,
      'marketing': marketing,
      'sound': sound,
      if (customSoundUrl != null) 'customSoundUrl': customSoundUrl,
      'quietHours': quietHours.toJson(),
    };
  }

  NotificationSettings copyWith({
    bool? email,
    bool? push,
    bool? sms,
    bool? marketing,
    bool? sound,
    String? customSoundUrl,
    QuietHoursSettings? quietHours,
  }) {
    return NotificationSettings(
      email: email ?? this.email,
      push: push ?? this.push,
      sms: sms ?? this.sms,
      marketing: marketing ?? this.marketing,
      sound: sound ?? this.sound,
      customSoundUrl: customSoundUrl ?? this.customSoundUrl,
      quietHours: quietHours ?? this.quietHours,
    );
  }
}

// ============ Privacy Settings ============
class PrivacySettings {
  final String profileVisibility; // 'public', 'private', 'friends'
  final bool showOnlineStatus;
  final bool showLastSeen;
  final String? showProfilePhoto; // 'everyone', 'friends', 'none'
  final bool allowTagging;
  final String allowMessages; // 'everyone', 'friends', 'none'

  PrivacySettings({
    this.profileVisibility = 'public',
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.showProfilePhoto,
    this.allowTagging = true,
    this.allowMessages = 'everyone',
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: json['profileVisibility'] ?? 'public',
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      showLastSeen: json['showLastSeen'] ?? true,
      showProfilePhoto: json['showProfilePhoto'],
      allowTagging: json['allowTagging'] ?? true,
      allowMessages: json['allowMessages'] ?? 'everyone',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      if (showProfilePhoto != null) 'showProfilePhoto': showProfilePhoto,
      'allowTagging': allowTagging,
      'allowMessages': allowMessages,
    };
  }

  PrivacySettings copyWith({
    String? profileVisibility,
    bool? showOnlineStatus,
    bool? showLastSeen,
    String? showProfilePhoto,
    bool? allowTagging,
    String? allowMessages,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showProfilePhoto: showProfilePhoto ?? this.showProfilePhoto,
      allowTagging: allowTagging ?? this.allowTagging,
      allowMessages: allowMessages ?? this.allowMessages,
    );
  }
}

// ============ Preference Settings ============
class PreferenceSettings {
  final String language;
  final String timezone;
  final String dateFormat;
  final String timeFormat; // '12h', '24h'
  final String currency;
  final String weekStartDay; // 'sunday', 'monday'
  final String measurements; // 'metric', 'imperial'

  PreferenceSettings({
    this.language = 'en',
    this.timezone = 'UTC',
    this.dateFormat = 'YYYY-MM-DD',
    this.timeFormat = '12h',
    this.currency = 'USD',
    this.weekStartDay = 'monday',
    this.measurements = 'metric',
  });

  factory PreferenceSettings.fromJson(Map<String, dynamic> json) {
    return PreferenceSettings(
      language: json['language'] ?? 'en',
      timezone: json['timezone'] ?? 'UTC',
      dateFormat: json['dateFormat'] ?? 'YYYY-MM-DD',
      timeFormat: json['timeFormat'] ?? '12h',
      currency: json['currency'] ?? 'USD',
      weekStartDay: json['weekStartDay'] ?? 'monday',
      measurements: json['measurements'] ?? 'metric',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'timezone': timezone,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'currency': currency,
      'weekStartDay': weekStartDay,
      'measurements': measurements,
    };
  }

  PreferenceSettings copyWith({
    String? language,
    String? timezone,
    String? dateFormat,
    String? timeFormat,
    String? currency,
    String? weekStartDay,
    String? measurements,
  }) {
    return PreferenceSettings(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      currency: currency ?? this.currency,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      measurements: measurements ?? this.measurements,
    );
  }
}

// ============ Custom Layout Settings ============
class CustomLayoutSettings {
  final List<String>? widgets;
  final List<String>? order;

  CustomLayoutSettings({
    this.widgets,
    this.order,
  });

  factory CustomLayoutSettings.fromJson(Map<String, dynamic> json) {
    return CustomLayoutSettings(
      widgets:
          json['widgets'] != null ? List<String>.from(json['widgets']) : null,
      order: json['order'] != null ? List<String>.from(json['order']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (widgets != null) 'widgets': widgets,
      if (order != null) 'order': order,
    };
  }
}

// ============ Layout Settings ============
class LayoutSettings {
  final bool sidebarCollapsed;
  final bool compactView;
  final bool showTutorials;
  final String defaultView; // 'grid', 'list'
  final CustomLayoutSettings? customLayout;

  LayoutSettings({
    this.sidebarCollapsed = false,
    this.compactView = false,
    this.showTutorials = true,
    this.defaultView = 'grid',
    this.customLayout,
  });

  factory LayoutSettings.fromJson(Map<String, dynamic> json) {
    return LayoutSettings(
      sidebarCollapsed: json['sidebarCollapsed'] ?? false,
      compactView: json['compactView'] ?? false,
      showTutorials: json['showTutorials'] ?? true,
      defaultView: json['defaultView'] ?? 'grid',
      customLayout: json['customLayout'] != null
          ? CustomLayoutSettings.fromJson(json['customLayout'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sidebarCollapsed': sidebarCollapsed,
      'compactView': compactView,
      'showTutorials': showTutorials,
      'defaultView': defaultView,
      if (customLayout != null) 'customLayout': customLayout!.toJson(),
    };
  }

  LayoutSettings copyWith({
    bool? sidebarCollapsed,
    bool? compactView,
    bool? showTutorials,
    String? defaultView,
    CustomLayoutSettings? customLayout,
  }) {
    return LayoutSettings(
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      compactView: compactView ?? this.compactView,
      showTutorials: showTutorials ?? this.showTutorials,
      defaultView: defaultView ?? this.defaultView,
      customLayout: customLayout ?? this.customLayout,
    );
  }
}

// ============ Accessibility Settings ============
class AccessibilitySettings {
  final bool highContrast;
  final bool reducedMotion;
  final bool screenReader;
  final int? fontSize;
  final int? textSpacing;
  final String cursorSize; // 'default', 'large'

  AccessibilitySettings({
    this.highContrast = false,
    this.reducedMotion = false,
    this.screenReader = false,
    this.fontSize,
    this.textSpacing,
    this.cursorSize = 'default',
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      highContrast: json['highContrast'] ?? false,
      reducedMotion: json['reducedMotion'] ?? false,
      screenReader: json['screenReader'] ?? false,
      fontSize: json['fontSize'],
      textSpacing: json['textSpacing'],
      cursorSize: json['cursorSize'] ?? 'default',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highContrast': highContrast,
      'reducedMotion': reducedMotion,
      'screenReader': screenReader,
      if (fontSize != null) 'fontSize': fontSize,
      if (textSpacing != null) 'textSpacing': textSpacing,
      'cursorSize': cursorSize,
    };
  }

  AccessibilitySettings copyWith({
    bool? highContrast,
    bool? reducedMotion,
    bool? screenReader,
    int? fontSize,
    int? textSpacing,
    String? cursorSize,
  }) {
    return AccessibilitySettings(
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      screenReader: screenReader ?? this.screenReader,
      fontSize: fontSize ?? this.fontSize,
      textSpacing: textSpacing ?? this.textSpacing,
      cursorSize: cursorSize ?? this.cursorSize,
    );
  }
}

// ============ Last Login Info ============
class LastLoginInfo {
  final String? device;
  final String? browser;
  final String? location;
  final DateTime? timestamp;
  final String? ip;
  final String? userAgent;

  LastLoginInfo({
    this.device,
    this.browser,
    this.location,
    this.timestamp,
    this.ip,
    this.userAgent,
  });

  factory LastLoginInfo.fromJson(Map<String, dynamic> json) {
    return LastLoginInfo(
      device: json['device'],
      browser: json['browser'],
      location: json['location'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      ip: json['ip'],
      userAgent: json['userAgent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (device != null) 'device': device,
      if (browser != null) 'browser': browser,
      if (location != null) 'location': location,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (ip != null) 'ip': ip,
      if (userAgent != null) 'userAgent': userAgent,
    };
  }
}

// ============ AI Feature Usage ============
class AIFeatureUsage {
  final bool isOpened;
  final DateTime? lastOpened;
  final int usageCount;
  final List<String>? favoriteFeatures;

  AIFeatureUsage({
    this.isOpened = false,
    this.lastOpened,
    this.usageCount = 0,
    this.favoriteFeatures,
  });

  factory AIFeatureUsage.fromJson(Map<String, dynamic> json) {
    return AIFeatureUsage(
      isOpened: json['isOpened'] ?? false,
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'])
          : null,
      usageCount: json['usageCount'] ?? 0,
      favoriteFeatures: json['favoriteFeatures'] != null
          ? List<String>.from(json['favoriteFeatures'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpened': isOpened,
      if (lastOpened != null) 'lastOpened': lastOpened!.toIso8601String(),
      'usageCount': usageCount,
      if (favoriteFeatures != null) 'favoriteFeatures': favoriteFeatures,
    };
  }
}

// ============ Reels Preferences ============
class ReelsPreferences {
  final bool autoPlay;
  final double? defaultVolume;

  ReelsPreferences({
    this.autoPlay = true,
    this.defaultVolume,
  });

  factory ReelsPreferences.fromJson(Map<String, dynamic> json) {
    return ReelsPreferences(
      autoPlay: json['autoPlay'] ?? true,
      defaultVolume: json['defaultVolume']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoPlay': autoPlay,
      if (defaultVolume != null) 'defaultVolume': defaultVolume,
    };
  }
}

// ============ Reels Feature Usage ============
class ReelsFeatureUsage {
  final bool isOpened;
  final DateTime? lastOpened;
  final int viewCount;
  final ReelsPreferences? preferences;

  ReelsFeatureUsage({
    this.isOpened = false,
    this.lastOpened,
    this.viewCount = 0,
    this.preferences,
  });

  factory ReelsFeatureUsage.fromJson(Map<String, dynamic> json) {
    return ReelsFeatureUsage(
      isOpened: json['isOpened'] ?? false,
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'])
          : null,
      viewCount: json['viewCount'] ?? 0,
      preferences: json['preferences'] != null
          ? ReelsPreferences.fromJson(json['preferences'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpened': isOpened,
      if (lastOpened != null) 'lastOpened': lastOpened!.toIso8601String(),
      'viewCount': viewCount,
      if (preferences != null) 'preferences': preferences!.toJson(),
    };
  }
}

// ============ Feature Usage ============
class FeatureUsage {
  final AIFeatureUsage ai;
  final ReelsFeatureUsage reels;

  FeatureUsage({
    AIFeatureUsage? ai,
    ReelsFeatureUsage? reels,
  })  : ai = ai ?? AIFeatureUsage(),
        reels = reels ?? ReelsFeatureUsage();

  factory FeatureUsage.fromJson(Map<String, dynamic> json) {
    return FeatureUsage(
      ai: json['ai'] != null ? AIFeatureUsage.fromJson(json['ai']) : null,
      reels: json['reels'] != null
          ? ReelsFeatureUsage.fromJson(json['reels'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ai': ai.toJson(),
      'reels': reels.toJson(),
    };
  }
}

// ============ Analytics Settings ============
class AnalyticsSettings {
  final int? timeSpent;
  final DateTime? lastActive;
  final List<String>? favoriteFeatures;
  final double? engagementScore;

  AnalyticsSettings({
    this.timeSpent,
    this.lastActive,
    this.favoriteFeatures,
    this.engagementScore,
  });

  factory AnalyticsSettings.fromJson(Map<String, dynamic> json) {
    return AnalyticsSettings(
      timeSpent: json['timeSpent'],
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      favoriteFeatures: json['favoriteFeatures'] != null
          ? List<String>.from(json['favoriteFeatures'])
          : null,
      engagementScore: json['engagementScore']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (timeSpent != null) 'timeSpent': timeSpent,
      if (lastActive != null) 'lastActive': lastActive!.toIso8601String(),
      if (favoriteFeatures != null) 'favoriteFeatures': favoriteFeatures,
      if (engagementScore != null) 'engagementScore': engagementScore,
    };
  }
}

// ============ Main User Settings Model ============
class UserSettings {
  final String? id;
  final String? userId;
  final ThemeSettings theme;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final PreferenceSettings preferences;
  final LayoutSettings layout;
  final AccessibilitySettings accessibility;
  final LastLoginInfo? lastLoginInfo;
  final FeatureUsage featureUsage;
  final AnalyticsSettings? analytics;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    this.id,
    this.userId,
    ThemeSettings? theme,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    PreferenceSettings? preferences,
    LayoutSettings? layout,
    AccessibilitySettings? accessibility,
    this.lastLoginInfo,
    FeatureUsage? featureUsage,
    this.analytics,
    this.createdAt,
    this.updatedAt,
  })  : theme = theme ?? ThemeSettings(),
        notifications = notifications ?? NotificationSettings(),
        privacy = privacy ?? PrivacySettings(),
        preferences = preferences ?? PreferenceSettings(),
        layout = layout ?? LayoutSettings(),
        accessibility = accessibility ?? AccessibilitySettings(),
        featureUsage = featureUsage ?? FeatureUsage();

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['_id'],
      userId: json['userId'],
      theme: json['theme'] != null
          ? ThemeSettings.fromJson(json['theme'])
          : null,
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(json['notifications'])
          : null,
      privacy: json['privacy'] != null
          ? PrivacySettings.fromJson(json['privacy'])
          : null,
      preferences: json['preferences'] != null
          ? PreferenceSettings.fromJson(json['preferences'])
          : null,
      layout: json['layout'] != null
          ? LayoutSettings.fromJson(json['layout'])
          : null,
      accessibility: json['accessibility'] != null
          ? AccessibilitySettings.fromJson(json['accessibility'])
          : null,
      lastLoginInfo: json['lastLoginInfo'] != null
          ? LastLoginInfo.fromJson(json['lastLoginInfo'])
          : null,
      featureUsage: json['featureUsage'] != null
          ? FeatureUsage.fromJson(json['featureUsage'])
          : null,
      analytics: json['analytics'] != null
          ? AnalyticsSettings.fromJson(json['analytics'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (userId != null) 'userId': userId,
      'theme': theme.toJson(),
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'preferences': preferences.toJson(),
      'layout': layout.toJson(),
      'accessibility': accessibility.toJson(),
      if (lastLoginInfo != null) 'lastLoginInfo': lastLoginInfo!.toJson(),
      'featureUsage': featureUsage.toJson(),
      if (analytics != null) 'analytics': analytics!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    ThemeSettings? theme,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    PreferenceSettings? preferences,
    LayoutSettings? layout,
    AccessibilitySettings? accessibility,
    LastLoginInfo? lastLoginInfo,
    FeatureUsage? featureUsage,
    AnalyticsSettings? analytics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      preferences: preferences ?? this.preferences,
      layout: layout ?? this.layout,
      accessibility: accessibility ?? this.accessibility,
      lastLoginInfo: lastLoginInfo ?? this.lastLoginInfo,
      featureUsage: featureUsage ?? this.featureUsage,
      analytics: analytics ?? this.analytics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

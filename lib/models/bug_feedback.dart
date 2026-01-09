/// Bug Feedback Model
/// Represents bug/feedback report data for the API

class BugFeedback {
  final String? id;
  final String? userId;
  final String? email;
  final String message;
  final String bugType;
  final String? customBugType;
  final String severity;
  final String? browserInfo;
  final String? osInfo;
  final String? screenResolution;
  final String? appVersion;
  final LocationInfo? location;
  final List<String>? attachmentUrls;
  final String? stepsToReproduce;
  final String? status;
  final String? response;
  final DateTime? createdAt;

  BugFeedback({
    this.id,
    this.userId,
    this.email,
    required this.message,
    required this.bugType,
    this.customBugType,
    this.severity = 'Medium',
    this.browserInfo,
    this.osInfo,
    this.screenResolution,
    this.appVersion,
    this.location,
    this.attachmentUrls,
    this.stepsToReproduce,
    this.status,
    this.response,
    this.createdAt,
  });

  factory BugFeedback.fromJson(Map<String, dynamic> json) {
    return BugFeedback(
      id: json['_id'],
      userId: json['user'],
      email: json['email'],
      message: json['message'] ?? '',
      bugType: json['bugType'] ?? 'Other',
      customBugType: json['customBugType'],
      severity: json['severity'] ?? 'Medium',
      browserInfo: json['browserInfo'],
      osInfo: json['osInfo'],
      screenResolution: json['screenResolution'],
      appVersion: json['appVersion'],
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'])
          : null,
      attachmentUrls: json['attachmentUrls'] != null
          ? List<String>.from(json['attachmentUrls'])
          : null,
      stepsToReproduce: json['stepsToReproduce'],
      status: json['status'],
      response: json['response'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (userId != null) 'user': userId,
      if (email != null) 'email': email,
      'message': message,
      'bugType': bugType,
      if (customBugType != null) 'customBugType': customBugType,
      'severity': severity,
      if (browserInfo != null) 'browserInfo': browserInfo,
      if (osInfo != null) 'osInfo': osInfo,
      if (screenResolution != null) 'screenResolution': screenResolution,
      if (appVersion != null) 'appVersion': appVersion,
      if (location != null) 'location': location!.toJson(),
      if (attachmentUrls != null) 'attachmentUrls': attachmentUrls,
      if (stepsToReproduce != null) 'stepsToReproduce': stepsToReproduce,
    };
  }
}

class LocationInfo {
  final String? city;
  final String? country;
  final String? region;
  final String? ip;
  final String? latitude;
  final String? longitude;

  LocationInfo({
    this.city,
    this.country,
    this.region,
    this.ip,
    this.latitude,
    this.longitude,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      city: json['city'],
      country: json['country'],
      region: json['region'],
      ip: json['ip'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (region != null) 'region': region,
      if (ip != null) 'ip': ip,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

/// Bug type options matching backend enum
class BugTypes {
  static const List<String> all = [
    'UI Issue',
    'Crash',
    'Performance',
    'Suggestion',
    'Security',
    'Functionality',
    'Other',
  ];

  static const Map<String, String> icons = {
    'UI Issue': '🎨',
    'Crash': '💥',
    'Performance': '⚡',
    'Suggestion': '💡',
    'Security': '🔒',
    'Functionality': '⚙️',
    'Other': '📝',
  };
}

/// Severity levels matching backend enum
class SeverityLevels {
  static const List<String> all = ['Critical', 'High', 'Medium', 'Low'];

  static const Map<String, String> colors = {
    'Critical': '#FF0000',
    'High': '#FF6600',
    'Medium': '#FFCC00',
    'Low': '#00CC00',
  };
}

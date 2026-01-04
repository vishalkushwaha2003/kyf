/// User Profile Model
/// Represents user profile data from the API

class UserProfile {
  final String fullName;
  final String username;
  final String phoneNumber;
  final String gender;
  final int age;
  final String? dob;
  final String city;
  final String country;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isSubscribed;
  final SubscriptionInfo subscription;
  final ProfilePhoto? photo;
  final String? video;

  UserProfile({
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.gender,
    required this.age,
    this.dob,
    required this.city,
    required this.country,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isSubscribed,
    required this.subscription,
    this.photo,
    this.video,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? 'Not to say',
      age: json['age'] ?? 0,
      dob: json['dob'],
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isSubscribed: json['isSubscribed'] ?? false,
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      photo: json['photo'] != null ? ProfilePhoto.fromJson(json['photo']) : null,
      video: json['video'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'username': username,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'age': age,
      'dob': dob,
      'city': city,
      'country': country,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isSubscribed': isSubscribed,
      'subscription': subscription.toJson(),
      'photo': photo?.toJson(),
      'video': video,
    };
  }

  /// Check if user has a profile photo
  bool get hasPhoto => photo?.url != null && photo!.url.isNotEmpty;

  /// Get photo URL (thumbnail or full)
  String? get photoUrl => photo?.thumbnailUrl ?? photo?.url;

  /// Get initials for avatar
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Get formatted DOB
  String get formattedDob {
    if (dob == null) return 'Not set';
    try {
      final date = DateTime.parse(dob!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dob!;
    }
  }
}

class ProfilePhoto {
  final String url;
  final String? thumbnailUrl;

  ProfilePhoto({
    required this.url,
    this.thumbnailUrl,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnail_url': thumbnailUrl,
    };
  }
}

class SubscriptionInfo {
  final String type;
  final String status;

  SubscriptionInfo({
    required this.type,
    required this.status,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      type: json['type'] ?? 'Free',
      status: json['status'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
    };
  }
}

import 'package:kyf/config/env_config.dart';

/// API Configuration
/// Contains base URL, version, and API-related constants

class ApiConfig {
  ApiConfig._();

  // These are now getters since they read from .env at runtime
  static String get baseUrl => EnvConfig.apiUrl;
  static String get version => EnvConfig.apiVersion;

  // Full API Base URL
  static String get fullBaseUrl => '$baseUrl/api/$version';
}

/// HTTP Methods
class HttpMethods {
  HttpMethods._();

  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String patch = 'PATCH';
  static const String delete = 'DELETE';
}

/// API Endpoints
class Endpoints {
  Endpoints._();

  // ============ Auth Endpoints ============
  static const auth = _AuthEndpoints();

  // ============ User Endpoints ============
  static const users = _UserEndpoints();

  // ============ AI Endpoints ============
  static const ai = _AIEndpoints();

  // ============ Subscription Endpoints ============
  static const subscriptions = _SubscriptionEndpoints();

  // ============ Settings Endpoints ============
  static const settings = _SettingsEndpoints();

  // ============ Feedback Endpoints ============
  static const feedback = _FeedbackEndpoints();
}

/// Auth Endpoints
class _AuthEndpoints {
  const _AuthEndpoints();

  String get login => '/api/${ApiConfig.version}/users/login';
  String get signup => '/api/${ApiConfig.version}/users/signup';
  String get generateOtp => '/api/${ApiConfig.version}/auth/generate_otp';
  String get verifyOtp => '/api/${ApiConfig.version}/auth/verify_otp';
  String get refreshToken => '/api/${ApiConfig.version}/auth/refresh_token';
}

/// User Endpoints
class _UserEndpoints {
  const _UserEndpoints();

  String get profile => '/api/${ApiConfig.version}/users/profile';
  String get update => '/api/${ApiConfig.version}/users/profile';
  String get getById => '/api/${ApiConfig.version}/users/get_user_by_id';
  String get getByMobile => '/api/${ApiConfig.version}/users/get_user_by_mobile';
  String get logout => '/api/${ApiConfig.version}/users/logout';
  String get emailVerification => '/api/${ApiConfig.version}/users/email_verification';
  String get allUsers => '/api/${ApiConfig.version}/users/all-users';
}

/// AI Endpoints
class _AIEndpoints {
  const _AIEndpoints();

  String get processChat => '/api/${ApiConfig.version}/auth/process';
}

/// Subscription Endpoints
class _SubscriptionEndpoints {
  const _SubscriptionEndpoints();

  String get create => '/api/${ApiConfig.version}/subscriptions/create';
  String get current => '/api/${ApiConfig.version}/subscriptions/current';
  String get cancel => '/api/${ApiConfig.version}/subscriptions/cancel';
  String get plans => '/api/${ApiConfig.version}/subscriptions/plans';
  String get history => '/api/${ApiConfig.version}/subscriptions/history';
  String get details => '/api/${ApiConfig.version}/subscriptions/details';
  String get config => '/api/${ApiConfig.version}/subscriptions/config';

  // Dynamic endpoints with ID
  String cancelById(String subscriptionId) =>
      '/api/${ApiConfig.version}/subscriptions/cancel/$subscriptionId';
  String paymentStatus(String subscriptionId) =>
      '/api/${ApiConfig.version}/subscriptions/payment-status/$subscriptionId';
  String detailsById(String subscriptionId) =>
      '/api/${ApiConfig.version}/subscriptions/details/$subscriptionId';
}

/// Settings Endpoints
class _SettingsEndpoints {
  const _SettingsEndpoints();

  String get initialize => '/api/${ApiConfig.version}/settings/initialize';
  String get fetch => '/api/${ApiConfig.version}/settings/fetch';
  String get theme => '/api/${ApiConfig.version}/settings/theme';
  String get notifications => '/api/${ApiConfig.version}/settings/notifications';
  String get privacy => '/api/${ApiConfig.version}/settings/privacy';
  String get preferences => '/api/${ApiConfig.version}/settings/preferences';
  String get layout => '/api/${ApiConfig.version}/settings/layout';
  String get accessibility => '/api/${ApiConfig.version}/settings/accessibility';
}

/// Feedback Endpoints
class _FeedbackEndpoints {
  const _FeedbackEndpoints();

  String get submit => '/api/${ApiConfig.version}/feedback/bug';
  String get list => '/api/${ApiConfig.version}/feedback/my-feedback';
}

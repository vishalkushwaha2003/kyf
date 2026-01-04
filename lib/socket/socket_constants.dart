/// Socket Constants
/// Defines all socket event names and status codes

class SocketConstants {
  SocketConstants._();

  // Auth Events
  static const auth = _AuthEvents();
  
  // File Events
  static const file = _FileEvents();
  
  // Status Codes
  static const status = _StatusCodes();
  
  // Error Types
  static const errors = _ErrorTypes();
}

class _AuthEvents {
  const _AuthEvents();
  
  String get authenticate => 'authenticate';
  String get authenticated => 'authenticated';
  String get authError => 'auth_error';
  String get disconnect => 'disconnect';
  String get connect => 'connect';
  String get connectError => 'connect_error';
}

class _FileEvents {
  const _FileEvents();
  
  String get upload => 'file:upload';
  String get uploadStart => 'file:upload:start';
  String get uploadProgress => 'file:upload:progress';
  String get uploadSuccess => 'file:upload:success';
  String get uploadError => 'file:upload:error';
  String get uploadResponse => 'file:upload:response';
}

class _StatusCodes {
  const _StatusCodes();
  
  String get authenticated => 'authenticated';
  String get success => 'success';
  String get error => 'error';
}

class _ErrorTypes {
  const _ErrorTypes();
  
  String get tokenExpired => 'token_expired';
  String get unexpectedError => 'unexpected_error';
  String get authFailed => 'auth_failed';
  String get timeout => 'timeout';
}

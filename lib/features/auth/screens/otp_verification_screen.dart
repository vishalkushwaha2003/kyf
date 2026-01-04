import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kyf/app/routes/app_routes.dart';
import 'package:kyf/services/auth_service.dart';
import 'package:kyf/services/storage_service.dart';
import 'package:kyf/socket/socket_authentication.dart';
import 'package:kyf/utils/toast.dart';

/// OTP Verification Screen
/// User enters the OTP received on their phone

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String referenceId;
  
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.referenceId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _authService = AuthService();
  
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      AppToast.warning(context, 'Please enter all 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    final phoneNumber = '+91${widget.phoneNumber}';
    final response = await _authService.verifyOtp(
      referenceId: widget.referenceId,
      phoneNumber: phoneNumber,
      otp: _otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Print the response for debugging
    debugPrint('OTP Verification Response: ${response.data}');

    if (response.success) {
      AppToast.success(context, 'Verified successfully!');
      
      // Parse response data
      try {
        final bodyData = response.data['body'];
        Map<String, dynamic> parsedBody;
        
        if (bodyData is String) {
          parsedBody = Map<String, dynamic>.from(
            (const JsonDecoder().convert(bodyData)) as Map,
          );
        } else {
          parsedBody = bodyData as Map<String, dynamic>;
        }
        
        final data = parsedBody['data'] as Map<String, dynamic>?;
        final isAlreadyVerified = data?['isAlreadyVerified'] as bool? ?? false;
        final token = data?['token'] as String? ?? '';
        final fullName = data?['fullName'] as String? ?? '';
        
        // Save token to local storage
        final storage = await StorageService.getInstance();
        await storage.saveToken(token);
        await storage.setLoggedIn(true);
        debugPrint('Token saved to storage');
        
        // Connect socket immediately after login
        debugPrint('Connecting socket after login...');
        SocketAuthentication.ensureAuthenticated().then((authenticated) {
          debugPrint('Socket authenticated: $authenticated');
        }).catchError((e) {
          debugPrint('Socket authentication error: $e');
        });
        
        debugPrint('isAlreadyVerified: $isAlreadyVerified');
        
        if (isAlreadyVerified) {
          // Existing user - go directly to home
          context.go(AppRoutes.home);
        } else {
          // New user - go to complete profile
          context.go(
            AppRoutes.completeProfile,
            extra: {
              'token': token,
              'fullName': fullName,
            },
          );
        }
      } catch (e) {
        debugPrint('Error parsing response: $e');
        context.go(AppRoutes.home);
      }
    } else {
      AppToast.error(context, response.message ?? 'Invalid OTP');
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    
    final phoneNumber = '+91${widget.phoneNumber}';
    final response = await _authService.generateOtp(phoneNumber: phoneNumber);
    
    if (response.success) {
      AppToast.success(
        context,
        'OTP sent to +91 ${widget.phoneNumber}',
        title: 'Code Sent!',
      );
    } else {
      AppToast.error(context, response.message ?? 'Failed to resend OTP');
    }
    
    _startResendTimer();
  }

  void _onOtpDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-verify when all digits are entered
    if (_otp.length == 6) {
      _verifyOTP();
    }
  }

  void _onKeyPressed(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.message_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Verify OTP',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'We have sent a verification code to',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              Text(
                '+91 ${widget.phoneNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyPressed(event, index),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOtpDigitChanged(value, index),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _resendOTP : null,
                    child: Text(
                      _canResend ? 'Resend OTP' : 'Resend in ${_resendTimer}s',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _canResend
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

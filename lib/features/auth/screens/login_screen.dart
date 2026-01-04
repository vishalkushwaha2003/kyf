import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kyf/app/routes/app_routes.dart';
import 'package:kyf/services/auth_service.dart';
import 'package:kyf/utils/toast.dart';

/// Login Screen - Phone Number Input
/// User enters phone number to receive OTP

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = '+91${_phoneController.text}';
    final response = await _authService.generateOtp(phoneNumber: phoneNumber);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      AppToast.success(context, 'OTP sent successfully!');
      
      // Safely extract reference_id from response
      // Response structure: {body: "{\"data\": {\"reference_id\": \"xxx\"}}"}
      String referenceId = '';
      try {
        final body = response.data['body'];
        if (body != null && body is String) {
          // Body is a JSON string, parse it
          final bodyData = Map<String, dynamic>.from(
            (const JsonDecoder().convert(body)) as Map,
          );
          if (bodyData['data'] != null) {
            referenceId = bodyData['data']['reference_id']?.toString() ?? '';
          }
        } else if (body != null && body['data'] != null) {
          referenceId = body['data']['reference_id']?.toString() ?? '';
        }
      } catch (e) {
        debugPrint('Error extracting referenceId: $e');
      }
      
      debugPrint('Extracted referenceId: $referenceId');
      
      // Navigate to OTP verification screen with phone number and referenceId
      context.push(
        AppRoutes.verifyOtp,
        extra: {
          'phoneNumber': _phoneController.text,
          'referenceId': referenceId,
        },
      );
    } else {
      AppToast.error(context, response.message ?? 'Failed to send OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top - 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Logo & Welcome
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'Welcome to KYF',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your phone number to continue',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Phone Number Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Phone Number Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🇮🇳',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+91',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: theme.colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length != 10) {
                            return 'Please enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleSendOTP,
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
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get OTP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Terms & Privacy
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kyf/app/routes/app_routes.dart';
import 'package:kyf/components/feedback_bottom_sheet.dart';
import 'package:kyf/features/settings/settings_screen.dart';
import 'package:kyf/models/user_profile.dart';
import 'package:kyf/services/storage_service.dart';
import 'package:kyf/services/user_service.dart';
import 'package:kyf/socket/file_upload_service.dart';
import 'package:kyf/utils/toast.dart';

/// Profile Screen
/// Displays user profile organized into clickable sections

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;
  
  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await StorageService.getInstance();
      
      if (storage.hasProfile()) {
        final cachedData = storage.getProfile();
        if (cachedData != null) {
          debugPrint('Loading profile from cache');
          setState(() {
            _profile = UserProfile.fromJson(cachedData);
            _isLoading = false;
          });
          return;
        }
      }

      final token = storage.getToken();
      if (token == null) {
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Fetching profile from API');
      final response = await _userService.getProfile(token: token);
      debugPrint('Profile API Response: ${response.data}');

      if (response.success) {
        final bodyData = response.data['body'];
        Map<String, dynamic> parsedBody;

        if (bodyData is String) {
          parsedBody = jsonDecode(bodyData) as Map<String, dynamic>;
        } else {
          parsedBody = bodyData as Map<String, dynamic>;
        }

        final data = parsedBody['data'] as Map<String, dynamic>;
        await storage.saveProfile(data);
        
        setState(() {
          _profile = UserProfile.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _error = 'Error loading profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    final storage = await StorageService.getInstance();
    await storage.clearProfile();
    await _loadProfile();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final storage = await StorageService.getInstance();
      await storage.clearAll();
      context.go(AppRoutes.login);
    }
  }

  void _openSection(String section) {
    if (_profile == null) return;
    
    // Navigate to dedicated SettingsScreen for settings
    if (section == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SectionDetailPage(
          section: section,
          profile: _profile!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton(theme)
          : _error != null
              ? _buildError(theme)
              : _buildProfile(theme),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(ThemeData theme) {
    if (_profile == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _buildHeader(theme),
          const SizedBox(height: 32),
          
          // Section Cards
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Your Information',
            subtitle: 'Personal details and contact info',
            onTap: () => _openSection('information'),
          ),
          const SizedBox(height: 12),
          
          _SectionCard(
            icon: Icons.card_membership_rounded,
            title: 'Subscription & Payments',
            subtitle: '${_profile!.subscription.type} Plan',
            onTap: () => _openSection('subscription'),
          ),
          const SizedBox(height: 12),
          
          _SectionCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Notifications, privacy, appearance',
            onTap: () => _openSection('settings'),
          ),
          const SizedBox(height: 12),
          
          _SectionCard(
            icon: Icons.info_outline_rounded,
            title: 'Other Information',
            subtitle: 'Help, terms and about',
            onTap: () => _openSection('other'),
          ),
          const SizedBox(height: 32),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          // Avatar with upload button
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: _profile!.hasPhoto 
                        ? null 
                        : LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image: _profile!.hasPhoto && !_isUploading
                        ? DecorationImage(
                            image: NetworkImage(_profile!.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploading
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress / 100,
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                              Text(
                                '${_uploadProgress.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _profile!.hasPhoto
                          ? null
                          : Center(
                              child: Text(
                                _profile!.initials,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                ),
                // Camera icon
                if (!_isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Upload message
          if (_uploadMessage != null)
            Text(
              _uploadMessage!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _profile!.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '@${_profile!.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
        _uploadMessage = 'Preparing...';
      });

      final result = await FileUploadService.uploadAvatar(
        file: image,
        onProgress: (state) {
          if (mounted) {
            setState(() {
              _uploadProgress = state.progress;
              _uploadMessage = state.message;
            });
          }
        },
      );

      if (!mounted) return;

      if (result.status == UploadStatus.success) {
        AppToast.success(context, 'Profile photo updated!');
        debugPrint('Upload successful! URL: ${result.uploadedUrl}');
        // Refresh profile to show new photo
        await _refreshProfile();
      } else if (result.status == UploadStatus.error) {
        AppToast.error(context, result.error ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Image pick/upload error: $e');
      if (mounted) {
        AppToast.error(context, 'Failed to upload image');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadMessage = null;
        });
      }
    }
  }
}

// Section Card Widget
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.scrim, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section Detail Page
class _SectionDetailPage extends StatelessWidget {
  final String section;
  final UserProfile profile;

  const _SectionDetailPage({
    required this.section,
    required this.profile,
  });

  /// Handle item tap and open appropriate sheets/pages
  void _handleItemTap(BuildContext context, _InfoItem item) {
    switch (item.label) {
      case 'Send Feedback':
        FeedbackBottomSheet.show(context);
        break;
      // Add more cases here for other tappable items
      default:
        // For items without specific actions, do nothing or show a snackbar
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    List<_InfoItem> items;

    switch (section) {
      case 'information':
        title = 'Your Information';
        items = [
          _InfoItem(Icons.person_rounded, 'Full Name', profile.fullName),
          _InfoItem(Icons.alternate_email_rounded, 'Username', '@${profile.username}'),
          _InfoItem(Icons.phone_rounded, 'Phone Number', profile.phoneNumber, 
              badge: profile.isPhoneVerified ? 'Verified' : null),
          _InfoItem(Icons.email_rounded, 'Email', 'Not set', 
              badge: profile.isEmailVerified ? 'Verified' : 'Add'),
          _InfoItem(Icons.cake_rounded, 'Date of Birth', profile.formattedDob),
          _InfoItem(Icons.wc_rounded, 'Gender', profile.gender),
          _InfoItem(Icons.numbers_rounded, 'Age', '${profile.age} years'),
          _InfoItem(Icons.location_city_rounded, 'City', profile.city),
          _InfoItem(Icons.public_rounded, 'Country', profile.country),
        ];
        break;
      case 'subscription':
        title = 'Subscription & Payments';
        items = [
          _InfoItem(Icons.workspace_premium_rounded, 'Current Plan', profile.subscription.type),
          _InfoItem(Icons.verified_rounded, 'Status', profile.subscription.status),
          _InfoItem(Icons.star_rounded, 'Subscribed', profile.isSubscribed ? 'Yes' : 'No'),
          _InfoItem(Icons.history_rounded, 'Payment History', 'View all transactions'),
          _InfoItem(Icons.credit_card_rounded, 'Payment Methods', 'Manage your cards'),
          _InfoItem(Icons.receipt_long_rounded, 'Invoices', 'Download invoices'),
        ];
        break;
      case 'settings':
        title = 'Settings';
        items = [
          _InfoItem(Icons.notifications_rounded, 'Notifications', 'Manage preferences'),
          _InfoItem(Icons.lock_rounded, 'Privacy', 'Control your data'),
          _InfoItem(Icons.security_rounded, 'Security', 'Password & 2FA'),
          _InfoItem(Icons.palette_rounded, 'Appearance', 'Theme and display'),
          _InfoItem(Icons.language_rounded, 'Language', 'English'),
          _InfoItem(Icons.storage_rounded, 'Storage', 'Manage app data'),
        ];
        break;
      case 'other':
        title = 'Other Information';
        items = [
          _InfoItem(Icons.help_rounded, 'Help & Support', 'FAQs and contact'),
          _InfoItem(Icons.feedback_rounded, 'Send Feedback', 'Report issues'),
          _InfoItem(Icons.star_rate_rounded, 'Rate Us', 'On App Store'),
          _InfoItem(Icons.share_rounded, 'Share App', 'Invite friends'),
          _InfoItem(Icons.description_rounded, 'Terms of Service', 'Read our terms'),
          _InfoItem(Icons.privacy_tip_rounded, 'Privacy Policy', 'How we use data'),
          _InfoItem(Icons.info_rounded, 'About', 'Version 1.0.0'),
        ];
        break;
      default:
        title = 'Details';
        items = [];
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _handleItemTap(context, item),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: theme.colorScheme.scrim, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.badge == 'Verified'
                              ? Colors.green.withOpacity(0.1)
                              : theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: item.badge == 'Verified' 
                                ? Colors.green 
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final String? badge;

  _InfoItem(this.icon, this.label, this.value, {this.badge});
}

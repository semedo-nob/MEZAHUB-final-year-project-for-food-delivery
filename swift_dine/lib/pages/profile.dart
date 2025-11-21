import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:swift_dine/provider/theme_provider.dart' as main_theme;
import 'package:swift_dine/provider/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure user data is loaded on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<main_theme.ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Profile",
          style: textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(context, userProvider, themeProvider, colorScheme, textTheme),
              const SizedBox(height: 32),
              _buildSectionHeader("General", colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildProfileCard(
                context,
                themeProvider,
                colorScheme,
                children: [
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.person_outline_rounded,
                    title: "Personal Details",
                    subtitle: "Update your profile information",
                    onTap: () => _showEditNameDialog(context, userProvider, colorScheme, textTheme),
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.language_rounded,
                    title: "Language",
                    subtitle: "English (US)",
                    onTap: () {},
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.location_on_outlined,
                    title: "Saved Addresses",
                    subtitle: "Manage delivery locations",
                    onTap: () {},
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.payment_rounded,
                    title: "Payment Methods",
                    subtitle: "Cards, M-Pesa, etc.",
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Preferences", colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildProfileCard(
                context,
                themeProvider,
                colorScheme,
                children: [
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    subtitle: "Manage your alerts",
                    onTap: () {},
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    subtitle: "Appearance settings",
                    onTap: () {},
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                        _showThemeChangeSnackbar(context, value, colorScheme);
                      },
                    ),
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.favorite_border_rounded,
                    title: "Favorites",
                    subtitle: "Your liked restaurants & dishes",
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Support", colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildProfileCard(
                context,
                themeProvider,
                colorScheme,
                children: [
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.help_outline_rounded,
                    title: "Help & Support",
                    subtitle: "Get help with your account",
                    onTap: () {},
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.feedback_outlined,
                    title: "Send Feedback",
                    subtitle: "Share your experience",
                    onTap: () {},
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.description_outlined,
                    title: "Terms of Service",
                    subtitle: "Privacy policy & terms",
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildProfileCard(
                context,
                themeProvider,
                colorScheme,
                children: [
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.logout_rounded,
                    title: "Sign Out",
                    subtitle: "Log out of your account",
                    textColor: colorScheme.primary,
                    iconColor: colorScheme.primary,
                    onTap: () {
                      _showSignOutDialog(context, userProvider, colorScheme, textTheme);
                    },
                  ),
                  _profileItem(
                    context,
                    themeProvider,
                    colorScheme,
                    textTheme,
                    icon: Icons.delete_outline_rounded,
                    title: "Delete Account",
                    subtitle: "Permanently remove your account",
                    textColor: colorScheme.error,
                    iconColor: colorScheme.error,
                    onTap: () {
                      _showDeleteAccountDialog(context, colorScheme, textTheme);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context,
      UserProvider userProvider,
      main_theme.ThemeProvider themeProvider,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImagePickerDialog(context, userProvider, colorScheme, textTheme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primaryContainer.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // FIXED: Improved image display with cache busting
                  if (userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        '${userProvider.profileImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}', // Cache busting
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: colorScheme.primary,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // FIXED: Fallback to default avatar
                          return _buildDefaultAvatar(colorScheme);
                        },
                      ),
                    )
                  else
                    _buildDefaultAvatar(colorScheme),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showEditNameDialog(context, userProvider, colorScheme, textTheme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    userProvider.name,
                    style: textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showEditEmailDialog(context, userProvider, colorScheme, textTheme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    userProvider.emailDisplay,
                    style: textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_rounded,
                  size: 12,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showEditPhoneDialog(context, userProvider, colorScheme, textTheme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      userProvider.phone,
                      style: textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: 40,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: textTheme.titleMedium!.copyWith(
          color: colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context,
      main_theme.ThemeProvider themeProvider,
      ColorScheme colorScheme, {
        required List<Widget> children,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: _buildChildrenWithDividers(context, themeProvider, colorScheme, children),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(
      BuildContext context,
      main_theme.ThemeProvider themeProvider,
      ColorScheme colorScheme,
      List<Widget> children,
      ) {
    final List<Widget> result = [];

    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outline,
          ),
        );
      }
    }
    return result;
  }

  Widget _profileItem(
      BuildContext context,
      main_theme.ThemeProvider themeProvider,
      ColorScheme colorScheme,
      TextTheme textTheme, {
        required IconData icon,
        required String title,
        String? subtitle,
        Color? iconColor,
        Color? textColor,
        Widget? trailing,
        required VoidCallback onTap,
      }) {
    final defaultIconColor = iconColor ?? colorScheme.onSurfaceVariant;
    final defaultTextColor = textColor ?? colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: defaultIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: defaultIconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: defaultTextColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog(
      BuildContext context,
      UserProvider userProvider,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Update Profile Photo",
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        content: Text(
          "Choose a photo from your gallery",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog immediately

              try {
                // Show loading state
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Uploading image..."),
                    backgroundColor: colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5), // Longer duration for upload
                  ),
                );

                await userProvider.pickAndUpdateProfileImage();

                // Remove loading snackbar and show success
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Profile photo updated successfully!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                // Remove loading snackbar and show error
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to update photo: ${e.toString()}"),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              "Choose Photo",
              style: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(
      BuildContext context,
      UserProvider userProvider,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    final controller = TextEditingController(text: userProvider.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Name",
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter your name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await userProvider.updateName(controller.text.trim());
                  Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Name updated successfully"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to update name: $e"),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              "Save",
              style: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(
      BuildContext context,
      UserProvider userProvider,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    final controller = TextEditingController(text: userProvider.emailDisplay);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Email",
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter your email",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
          style: textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await userProvider.updateEmail(controller.text.trim());
                  Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email updated successfully"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to update email: $e"),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              "Save",
              style: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(
      BuildContext context,
      UserProvider userProvider,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    final controller = TextEditingController(text: userProvider.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Phone Number",
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter phone number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
          style: textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await userProvider.updatePhone(controller.text.trim());
                  Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Phone number updated"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to update phone: $e"),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              "Save",
              style: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(
      BuildContext context,
      UserProvider userProvider,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Sign Out",
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        content: Text(
          "Are you sure you want to sign out of your account?",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await userProvider.logout();
                Navigator.pop(context);
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Signed out successfully"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Sign out failed: $e"),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              "Sign Out",
              style: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Account",
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This action cannot be undone. This will permanently:",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "• Delete your account\n• Remove all your data\n• Cancel any active orders",
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account deletion requested"),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              "Delete Account",
              style: textTheme.labelLarge!.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeChangeSnackbar(BuildContext context, bool isDarkMode, ColorScheme colorScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Dark mode ${isDarkMode ? 'enabled' : 'disabled'}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
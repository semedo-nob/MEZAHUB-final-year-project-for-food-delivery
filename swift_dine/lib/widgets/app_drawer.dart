// lib/widgets/app_drawer.dart
// Complete animated AppDrawer with open/close transitions.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import '../provider/user_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_theme_toggle.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start open animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Animate close before popping
  void _animateCloseAndPop(BuildContext context, VoidCallback onTap) {
    _animationController.reverse().then((_) {
      onTap(); // Pop after animation completes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final displayName = userProvider.userName ?? 'User';
        final email = userProvider.userName != null
            ? '${displayName.toLowerCase()}@example.com'
            : 'No email';

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width * 0.8, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primaryContainer,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedOpacity(
                                opacity: _fadeAnimation.value,
                                duration: const Duration(milliseconds: 200),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: CachedNetworkImageProvider(
                                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=D35400&color=fff',
                                  ),
                                  child: userProvider.userName == null
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        ..._buildAnimatedListTiles([
                          _buildTile(Icons.home_outlined, 'Home', () => Navigator.pop(context)),
                          _buildTile(Icons.person_outlined, 'Profile', () => Navigator.pushNamed(context, '/profile')),
                          _buildTile(Icons.shopping_bag_outlined, 'Orders', () => Navigator.pushNamed(context, '/orders')),
                          _buildTile(Icons.favorite_outline, 'Favorites', () => Navigator.pushNamed(context, '/favourites')),
                          _buildTile(Icons.settings_outlined, 'Settings', () => Navigator.pop(context)),
                        ]),
                        const Divider(),
                        // Modern Theme Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THEME',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const ModernThemeToggle(),
                            ],
                          ),
                        ),
                        const Divider(),
                        _buildTile(Icons.logout_outlined, 'Logout', () {
                          Provider.of<UserProvider>(context, listen: false).setUserName(null);
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/');
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  AnimatedOpacity _buildTile(IconData icon, String title, VoidCallback onTap) {
    return AnimatedOpacity(
      opacity: _fadeAnimation.value,
      duration: Duration(milliseconds: 100 + (/* Simulate index */ 0 * 50)), // Staggered if needed
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () => _animateCloseAndPop(context, onTap), // Animate close on tap
      ),
    );
  }

  List<Widget> _buildAnimatedListTiles(List<Widget> tiles) {
    return List.generate(tiles.length, (index) {
      return AnimatedSlide(
        offset: Offset(0, _slideAnimation.value * 0.1), // Subtle slide for each tile
        duration: const Duration(milliseconds: 200),
        child: tiles[index],
      );
    });
  }
}
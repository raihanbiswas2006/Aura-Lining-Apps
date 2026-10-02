import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../blocs/wishlist/wishlist_cubit.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      // Parallel loading of session, catalog, cart, wishlist, and brand reveal
      await Future.wait([
        context.read<AuthCubit>().checkAuth().catchError((e) {
          debugPrint('Splash checkAuth fallback: $e');
        }),
        context.read<CatalogCubit>().loadCatalog().catchError((e) {
          debugPrint('Splash loadCatalog fallback: $e');
        }),
        context.read<CartCubit>().loadCart().catchError((e) {
          debugPrint('Splash loadCart fallback: $e');
        }),
        context.read<WishlistCubit>().loadWishlist().catchError((e) {
          debugPrint('Splash loadWishlist fallback: $e');
        }),
        Future.delayed(const Duration(milliseconds: 1400)), // Smooth brand reveal
      ]).timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('Splash preload timeout: proceeding immediately to MainShell.');
        return [];
      });
    } catch (e) {
      debugPrint('Splash initialization error: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Geometric brand emblem
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'AURA LIVING',
                style: AppTypography.displayLarge.copyWith(
                  letterSpacing: 4.0,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'MINDFUL LIVING • ENDURING CRAFT',
                style: AppTypography.overline.copyWith(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

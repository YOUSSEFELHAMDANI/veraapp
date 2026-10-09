import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/onboarding_hero_widget.dart';
import './widgets/onboarding_panel_widget.dart';

class _OnboardingSlide {
  final String imageUrl;
  final String semanticLabel;
  final String headlineKey;
  final String subheadlineKey;

  const _OnboardingSlide({
    required this.imageUrl,
    required this.semanticLabel,
    required this.headlineKey,
    required this.subheadlineKey,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _blobController;
  late Animation<double> _blobAnimation;

  static final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      imageUrl:
          'https://images.pexels.com/photos/5632402/pexels-photo-5632402.jpeg?auto=compress&cs=tinysrgb&w=800',
      semanticLabel:
          'Young woman in elegant abaya browsing luxury fashion items on smartphone in Dubai mall',
      headlineKey: 'onbEverythingOnePlace',
      subheadlineKey: 'onbDiscoverFashionRealEstate',
    ),
    _OnboardingSlide(
      imageUrl:
          'https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=800',
      semanticLabel:
          'Modern luxury apartment building exterior in Dubai with palm trees and blue sky',
      headlineKey: 'onbDreamProperty',
      subheadlineKey: 'onbBrowseVerifiedProperties',
    ),
    _OnboardingSlide(
      imageUrl:
          'https://images.pexels.com/photos/3985329/pexels-photo-3985329.jpeg?auto=compress&cs=tinysrgb&w=800',
      semanticLabel:
          'Professional female beauty therapist performing facial treatment on client in modern clinic',
      headlineKey: 'onbBookPremiumServices',
      subheadlineKey: 'onbScheduleTopRated',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // V3 Liquid Morph — AnimationController for blob animation LOCKED
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _blobAnimation = CurvedAnimation(
      parent: _blobController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.languageCountryScreen);
    }
  }

  void _skip() => context.go(AppRoutes.languageCountryScreen);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // V3 Liquid Morph — morphing blob background LOCKED
          AnimatedBuilder(
            animation: _blobAnimation,
            builder: (context, child) {
              return Positioned(
                top: -60 + (_blobAnimation.value * 30),
                right: -80 + (_blobAnimation.value * 20),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: AppTheme.splashGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(80 + _blobAnimation.value * 40),
                      topRight: Radius.circular(
                        120 + _blobAnimation.value * 30,
                      ),
                      bottomLeft: Radius.circular(
                        100 + _blobAnimation.value * 50,
                      ),
                      bottomRight: Radius.circular(
                        60 + _blobAnimation.value * 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _blobAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -40 + (_blobAnimation.value * 20),
                left: -60 + (_blobAnimation.value * 15),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPinkLight.withAlpha(153),
                        AppTheme.goldLight.withAlpha(102),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60 + _blobAnimation.value * 30),
                      topRight: Radius.circular(
                        100 + _blobAnimation.value * 20,
                      ),
                      bottomLeft: Radius.circular(
                        80 + _blobAnimation.value * 40,
                      ),
                      bottomRight: Radius.circular(
                        50 + _blobAnimation.value * 30,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(size),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                AppLocalizations.of(context).skip,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grayText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(Size size) {
    return Column(
      children: [
        // Hero image — top 62%
        Expanded(
          flex: 62,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, i) =>
                OnboardingHeroWidget(slide: _slides[i]),
          ),
        ),
        // Bottom panel — 38%
        Expanded(
          flex: 38,
          child: OnboardingPanelWidget(
            slide: _slides[_currentPage],
            currentPage: _currentPage,
            totalPages: _slides.length,
            onNext: _nextPage,
            isLast: _currentPage == _slides.length - 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          children: [
            Expanded(
              flex: 60,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: OnboardingHeroWidget(slide: _slides[i]),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 40,
              child: OnboardingPanelWidget(
                slide: _slides[_currentPage],
                currentPage: _currentPage,
                totalPages: _slides.length,
                onNext: _nextPage,
                isLast: _currentPage == _slides.length - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

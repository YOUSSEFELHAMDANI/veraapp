import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';

/// Full-width promotional banner that sits below the category grid.
/// Fetches `category_banner` type banners from the admin panel and displays
/// them as a horizontally auto-scrolling carousel.
class HomeCategoryBannerWidget extends StatefulWidget {
  const HomeCategoryBannerWidget({super.key});

  @override
  State<HomeCategoryBannerWidget> createState() =>
      _HomeCategoryBannerWidgetState();
}

class _HomeCategoryBannerWidgetState extends State<HomeCategoryBannerWidget> {
  final PageController _controller = PageController();
  int _current = 0;
  List<_CategoryBanner> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final allBanners = await VeraApiService.instance.fetchBannersByType('category_banner');
      if (!mounted) return;

      final banners = allBanners
          .where((b) => b.imageUrl.isNotEmpty)
          .map((b) => _CategoryBanner(
                imageUrl: b.imageUrl,
                title: b.title,
                targetRoute: b.targetRoute,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBannerTap(_CategoryBanner banner) {
    if (banner.targetRoute.isNotEmpty) {
      context.push(banner.targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () => _onBannerTap(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: AppTheme.grayLight,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _current
                      ? AppTheme.primaryPink
                      : AppTheme.grayLight.withAlpha(100),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryBanner {
  final String imageUrl;
  final String title;
  final String targetRoute;

  const _CategoryBanner({
    required this.imageUrl,
    required this.title,
    required this.targetRoute,
  });
}

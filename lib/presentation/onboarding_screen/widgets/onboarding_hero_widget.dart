import '../../../core/app_export.dart';

class OnboardingHeroWidget extends StatelessWidget {
  final dynamic slide; // _OnboardingSlide passed from parent

  const OnboardingHeroWidget({required this.slide, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed image — anatomy LOCKED
        CustomImageWidget(
          imageUrl: slide.imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          semanticLabel: slide.semanticLabel,
        ),
        // Gradient overlay for text readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withAlpha(38)],
              stops: const [0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vibes/core/theme/app_theme.dart';

class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.gradient});

  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          (gradient ??
                  const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ))
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: (style ?? Theme.of(context).textTheme.headlineMedium)?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.health_and_safety_outlined,
      size: 56,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/services/token_storage.dart';
import 'package:dental_gate/widgets/blue_circle_arrow_button.dart';

/// يقرأ التوكن المحفوظ في [SharedPreferences] ويُكمل الجلسة دون طلب تسجيل دخول جديد.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    // تأخير بسيط ليضمن اكتمال بناء الشجرة قبل التنقل.
    Future<void>.delayed(
      const Duration(milliseconds: 150),
      () => unawaited(_decideRoute()),
    );
  }

  Future<void> _decideRoute() async {
    if (_navigating) return;
    _navigating = true;
    try {
      final tokens = await TokenStorage.instance
          .readTokens()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final target =
          tokens != null ? Routes.main : Routes.onboarding;
      debugPrint('Splash -> $target');
      await Get.offAllNamed<void>(target);
    } on TimeoutException {
      debugPrint('Splash: readTokens timeout → onboarding');
      if (mounted) await Get.offAllNamed<void>(Routes.onboarding);
    } catch (e, st) {
      debugPrint('Splash navigation error: $e\n$st');
      if (mounted) await Get.offAllNamed<void>(Routes.onboarding);
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Image.asset(
                  'assets/logo/logodental1.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 48,
            child: Center(
              child: BlueCircleArrowButton(
                onTap: () => unawaited(_decideRoute()),
                arrowPointsLeft: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

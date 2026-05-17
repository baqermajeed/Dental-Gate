import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/controllers/settings_controller.dart';
import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/services/account_delete_cleanup_service.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/view/settings/delete_account_confirm_dialog.dart';
import 'package:dental_gate/view/settings/logout_confirm_dialog.dart';

abstract final class _StColors {
  static const Color bgWhite = Color(0xFFFFFFFF);
  /// كارت الملف الشخصي (Figma)
  static const Color profileCardFill = Color(0xFFFDFEFF);
  /// #040814 @ 16%، blur 6، offset 0
  static const Color profileCardShadow = Color(0x29040814);
  /// ظل صورة البروفايل: #000 @ 16%، blur 6، offset 0
  static const Color avatarShadow = Color(0x29000000);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF040814);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color sectionHeader = Color(0x80040814);
  static const Color blue = Color(0xFF2B76F1);
  /// لون التطبيق الأساسي (بطاقة البروفايل في الإعدادات)
  static const Color accent = Color(0xFF5993FF);
  static const Color accentSoft = Color(0xFF7FB2E4);
}

/// أبعاد وخط قوائم الإعدادات (معلومات المستخدم / حسابك داخل التطبيق)
abstract final class _SettingsListSpec {
  static double get iconSize => 34.w;
  static double get fontSize => 14.sp;
  static const FontWeight fontWeight = FontWeight.w800;
  static double get userInfoCardHeight => 216.h;
  static double get accountCardHeight => 116.h;
}

/// صفحة الإعدادات — مطابقة لتصميم RTL (بطاقة الملف، أقسام، قوائم).
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: _StColors.bgWhite,
      appBar: AppBar(
        backgroundColor: _StColors.bgWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        foregroundColor: _StColors.textPrimary,
        title: Text(
          'الإعدادات',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
            color: _StColors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            _ProfileCard(home: home),
            SizedBox(height: 22.h),
            Padding(
              padding: EdgeInsets.only(right: 5.w),
              child: const _SectionTitle(text: 'معلومات المستخدم'),
            ),
            SizedBox(height: 16.h),
            Center(
              child: SizedBox(
                width: 351.w,
                height: _SettingsListSpec.userInfoCardHeight,
                child: _Card(
                  backgroundColor: _StColors.profileCardFill,
                  borderRadius: 22.r,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  boxShadow: const [
                    BoxShadow(
                      color: _StColors.profileCardShadow,
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: Offset(0, 0),
                    ),
                  ],
                  border: BorderSide.none,
                  child: Column(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _NotificationTile(
                            notificationsEnabled:
                                controller.notificationsEnabled.value,
                            onChanged: controller.setNotifications,
                          ),
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _NavTile(
                          imageAsset: 'assets/icons/ask set.png',
                          label: 'سياسة الخصوصية',
                          horizontalPadding: 0,
                          fillVertical: true,
                          onTap: () => Get.toNamed(Routes.privacyPolicy),
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _NavTile(
                          imageAsset: 'assets/icons/call set.png',
                          label: 'تواصل معنا',
                          horizontalPadding: 0,
                          fillVertical: true,
                          onTap: () => Get.toNamed(Routes.contactUs),
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _NavTile(
                          imageAsset: 'assets/icons/view set.png',
                          label: 'لمحة عن التطبيق',
                          horizontalPadding: 0,
                          fillVertical: true,
                          onTap: () => Get.toNamed(Routes.aboutApp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 22.h),
            _SectionTitle(text: 'حسابك داخل التطبيق'),
            SizedBox(height: 10.h),
            Center(
              child: SizedBox(
                width: 351.w,
                height: _SettingsListSpec.accountCardHeight,
                child: _Card(
                  backgroundColor: _StColors.profileCardFill,
                  borderRadius: 22.r,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  boxShadow: const [
                    BoxShadow(
                      color: _StColors.profileCardShadow,
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: Offset(0, 0),
                    ),
                  ],
                  border: BorderSide.none,
                  child: Column(
                    children: [
                      Expanded(
                        child: _NavTile(
                          imageAsset: 'assets/icons/sign out.png',
                          label: 'تسجيل الخروج',
                          horizontalPadding: 0,
                          fillVertical: true,
                          onTap: () async {
                            final ok = await LogoutConfirmDialog.show();
                            if (ok == true) await home.logout();
                          },
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _NavTile(
                          imageAsset: 'assets/icons/delete account.png',
                          label: 'حذف الحساب',
                          horizontalPadding: 0,
                          fillVertical: true,
                          onTap: () => _confirmDeleteAccount(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: _StColors.border.withValues(alpha: 0.85),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok = await DeleteAccountConfirmDialog.show();
    if (ok != true) return;

    Get.dialog<void>(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      await ApiService.instance.deleteMyAccount();
      await AccountDeleteCleanup.runPostDeletionSweep();
      Get.back<void>();
      Get.offAllNamed<void>(Routes.signIn);
    } on ApiException catch (e) {
      Get.back<void>();
      Get.snackbar(
        'تعذر حذف الحساب',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
      );
    } catch (e) {
      Get.back<void>();
      Get.snackbar(
        'تعذر حذف الحساب',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: FontWeight.w900,
          fontSize: 16.sp,
          color: _StColors.sectionHeader,
          height: 1.5,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.boxShadow,
    this.border,
  });

  final Widget child;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? _StColors.bgWhite,
        borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
        border: Border.fromBorderSide(
          border ?? BorderSide(color: _StColors.border, width: 1),
        ),
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.home});

  final HomeController home;

  static double get _radius => 24.r;
  static double get _avatarOuter => 56.w;
  static double get _ring => 2.5.w;
  static double get _innerWhite => 2.w;
  /// فراغ بين الصورة والنص
  static double get _gapAvatarToText => 14.w;
  /// فراغ بين مجموعة البروفايل والسهم
  static double get _gapMain => 10.w;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
    final p = home.profile.value;
    final loading = home.isProfileLoading.value;

    final name = loading
        ? '…'
        : (p?.name?.trim().isNotEmpty == true ? p!.name! : 'مستخدم');
    final specRaw = home.profileSpecialty.value?.trim();
    final hasSpec = specRaw != null && specRaw.isNotEmpty;
    final subtitle = loading
        ? '…'
        : (hasSpec ? specRaw : 'أضف تخصصك من البروفايل');

    final innerD = _avatarOuter - 2 * _ring - 2 * _innerWhite;
    final avatarR = innerD / 2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child: InkWell(
          onTap: () => Get.toNamed(Routes.professionalProfile),
          borderRadius: BorderRadius.circular(_radius),
          // DecoratedBox بدل Ink: ظل BoxDecoration على Ink أحياناً يُقصّ مع Material
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFFDFEFF),
                  Color(0xFFEEF4FF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _StColors.accent.withValues(alpha: 0.08),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: Offset(0, 8.h),
                ),
                const BoxShadow(
                  color: _StColors.profileCardShadow,
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: _avatarOuter,
                          height: _avatarOuter,
                          padding: EdgeInsets.all(_ring),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                _StColors.accent,
                                _StColors.accentSoft,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _StColors.accent.withValues(alpha: 0.28),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: Offset(0, 5.h),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(_innerWhite),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _Avatar(
                              imageUrl: p?.imageUrl,
                              radius: avatarR,
                              embeddedInCard: true,
                            ),
                          ),
                        ),
                        SizedBox(width: _gapAvatarToText),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ملفي المهني',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.sp,
                                  letterSpacing: 0.2,
                                  color: _StColors.accent.withValues(alpha: 0.85),
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17.sp,
                                  color: _StColors.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5.sp,
                                  color: hasSpec
                                      ? _StColors.textSecondary
                                      : _StColors.textSecondary.withValues(alpha: 0.72),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: _gapMain),
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _StColors.accent.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _StColors.accent.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 24.sp,
                        color: _StColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    });
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    this.imageUrl,
    this.radius,
    this.embeddedInCard = false,
  });

  final String? imageUrl;
  final double? radius;
  /// داخل حلقة بيضاء في بطاقة — بدون ظل خارجي إضافي
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? 28.r;
    final src = resolveMediaUrl(imageUrl);
    if (src.isNotEmpty) {
      final image = ClipOval(
        child: Image.network(
          src,
          width: r * 2,
          height: r * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(r),
        ),
      );
      if (embeddedInCard) {
        return SizedBox(width: r * 2, height: r * 2, child: image);
      }
      return Container(
        width: r * 2,
        height: r * 2,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _StColors.avatarShadow,
              blurRadius: 6,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: image,
      );
    }
    return _placeholder(r);
  }

  Widget _placeholder(double r) {
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFE8E8EA),
      border: Border.all(color: _StColors.border, width: 1),
      boxShadow: embeddedInCard
          ? null
          : const [
              BoxShadow(
                color: _StColors.avatarShadow,
                blurRadius: 6,
                spreadRadius: 0,
                offset: Offset(0, 0),
              ),
            ],
    );
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: decoration,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 28.sp,
        color: _StColors.textSecondary,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notificationsEnabled,
    required this.onChanged,
  });

  final bool notificationsEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final icon = _SettingsListSpec.iconSize;
    const toggleW = 33.00048828125;
    const toggleH = 16.13357162475586;

    final row = Row(
      textDirection: TextDirection.rtl,
      children: [
        Image.asset(
          'assets/icons/notification set.png',
          width: icon,
          height: icon,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'الأشعارات',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: _SettingsListSpec.fontWeight,
              fontSize: _SettingsListSpec.fontSize,
              color: _StColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(
          width: toggleW.w,
          height: toggleH.h,
          child: Transform.rotate(
            angle: math.pi,
            child: GestureDetector(
              onTap: () => onChanged(!notificationsEnabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: notificationsEnabled
                      ? _StColors.blue
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(toggleH.h / 2),
                ),
                child: Align(
                  alignment: notificationsEnabled
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: (toggleH.h - 2),
                    height: (toggleH.h - 2),
                    margin: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return SizedBox.expand(
      child: Align(
        alignment: Alignment.center,
        child: row,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.imageAsset,
    required this.label,
    required this.onTap,
    this.horizontalPadding,
    this.fillVertical = false,
  });

  final String imageAsset;
  final String label;
  final double? horizontalPadding;
  final VoidCallback onTap;
  /// يملأ ارتفاع [Expanded] في كروت الإعدادات الثابتة الارتفاع
  final bool fillVertical;

  @override
  Widget build(BuildContext context) {
    final icon = _SettingsListSpec.iconSize;
    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (horizontalPadding ?? 12).w,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Image.asset(
            imageAsset,
            width: icon,
            height: icon,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: _SettingsListSpec.fontWeight,
                fontSize: _SettingsListSpec.fontSize,
                color: _StColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          Transform.rotate(
            angle: math.pi,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 22.sp,
              color: _StColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    final inkChild = fillVertical
        ? SizedBox.expand(
            child: Align(
              alignment: Alignment.center,
              child: row,
            ),
          )
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: row,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: inkChild,
      ),
    );
  }
}

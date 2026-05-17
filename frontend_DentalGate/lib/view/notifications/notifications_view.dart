import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/notifications_controller.dart';
import 'package:dental_gate/models/app_notification.dart';
import 'package:dental_gate/utils/relative_time_ar.dart';
import 'package:dental_gate/widgets/app_back_button.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  static const _bg = Color(0xFFF5F7FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _primaryText = Color(0xFF101828);
  static const _secondaryText = Color(0xFF667085);
  static const _chipSelectedBg = Color(0xFF377DFF);
  static const _chipBorder = Color(0xFFD7DEEA);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Obx(() {
                  final tab = controller.selectedTab.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF101828).withValues(alpha: 0.06),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            AppBackButton(
                              size: 40.w,
                              iconSize: 24.sp,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            Expanded(
                              child: Text(
                                'الإشعارات',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 23.sp,
                                  height: 1.3,
                                  color: _primaryText,
                                ),
                              ),
                            ),
                            SizedBox(width: 40.w),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 42.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _FilterChip(
                                label: 'الكل',
                                icon: Icons.grid_view_rounded,
                                selected: tab == NotificationFilterTab.all,
                                onTap: () =>
                                    controller.setTab(NotificationFilterTab.all),
                              ),
                              SizedBox(width: 8.w),
                              _FilterChip(
                                label: 'طلبات الوظائف',
                                icon: Icons.business_center_rounded,
                                selected:
                                    tab == NotificationFilterTab.jobPostingApplications,
                                onTap: () => controller.setTab(
                                  NotificationFilterTab.jobPostingApplications,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _FilterChip(
                                label: 'طلبات التوظيف',
                                icon: Icons.badge_rounded,
                                selected:
                                    tab == NotificationFilterTab.myApplicationStatuses,
                                onTap: () => controller.setTab(
                                  NotificationFilterTab.myApplicationStatuses,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _FilterChip(
                                label: 'إشعارات التطبيق',
                                icon: Icons.campaign_rounded,
                                selected: tab == NotificationFilterTab.appAnnouncements,
                                onTap: () => controller.setTab(
                                  NotificationFilterTab.appAnnouncements,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(height: 14.h),
              Expanded(
                child: Obx(() {
                  final err = controller.streamError.value;
                  if (err != null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          err,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 14.sp,
                            color: _secondaryText,
                          ),
                        ),
                      ),
                    );
                  }
                  if (controller.isLoading.value && controller.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = controller.filteredItems;
                  if (list.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFF5B8EF7),
                      onRefresh: controller.loadNotifications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 80.h),
                          const _EmptyNotifications(),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: const Color(0xFF5B8EF7),
                    onRefresh: controller.loadNotifications,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 24.h),
                      itemCount: list.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final n = list[index];
                        return _NotificationTile(
                          item: n,
                          onTap: () => controller.onTileTap(n),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF4D8CFF), Color(0xFF2F74FA)],
                  )
                : null,
            color: selected ? null : NotificationsView._surface,
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(
              color: selected
                  ? NotificationsView._chipSelectedBg
                  : NotificationsView._chipBorder,
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2F74FA).withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15.sp,
                color: selected
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF7B8BA8),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.6.sp,
                  height: 1.3,
                  color: selected
                      ? const Color(0xFFFFFFFF)
                      : NotificationsView._secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/لم يتقدم الى الي طلب بعد.png',
              width: 220.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 28.h),
            Text(
              'لا توجد إشعارات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                height: 1.4,
                color: NotificationsView._secondaryText,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'ابدأ باختيار وظيفة والتقديم عليها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
                height: 1.5,
                color: NotificationsView._secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotificationItem item;
  final VoidCallback onTap;

  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFEEF2F6);
  static const _titleColor = Color(0xFF1D2939);
  static const _bodyColor = Color(0xFF667085);
  static const _timeColor = Color(0xFF98A2B3);
  static const _linkColor = Color(0xFF5B8EF7);

  @override
  Widget build(BuildContext context) {
    final title = item.displayTitle;
    final body = item.displayBody;
    final time = item.createdAt != null
        ? relativeTimeAr(item.createdAt!.toUtc())
        : '';
    final visual = _visualConfig(item);
    final isJobNotification =
        item.type == AppNotificationType.jobPostingApplication ||
        item.type == AppNotificationType.myApplicationStatus;
    final unread = !item.read;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        splashColor: const Color(0xFF5B8EF7).withValues(alpha: 0.06),
        highlightColor: const Color(0xFF5B8EF7).withValues(alpha: 0.03),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: unread
                  ? visual.iconColor.withValues(alpha: 0.22)
                  : _border,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(visual: visual),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (unread) ...[
                          Container(
                            width: 6.w,
                            height: 6.w,
                            margin: EdgeInsets.only(left: 6.w),
                            decoration: BoxDecoration(
                              color: visual.iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14.sp,
                              height: 1.25,
                              color: _titleColor,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Text(
                            time,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontWeight: FontWeight.w500,
                              fontSize: 10.5.sp,
                              height: 1.2,
                              color: _timeColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5.sp,
                          height: 1.4,
                          color: _bodyColor,
                        ),
                      ),
                    ],
                    if (isJobNotification) ...[
                      SizedBox(height: 5.h),
                      Text(
                        'عرض الوظيفة ›',
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5.sp,
                          height: 1.2,
                          color: _linkColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationVisual _visualConfig(AppNotificationItem n) {
    switch (n.type) {
      case AppNotificationType.jobPostingApplication:
        return const _NotificationVisual(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: Color(0xFF4F7FD9),
          iconBg: Color(0xFFF0F5FF),
        );
      case AppNotificationType.myApplicationStatus:
        final st = n.applicationStatus?.toLowerCase();
        if (st == 'accepted') {
          return const _NotificationVisual(
            icon: Icons.verified_rounded,
            iconColor: Color(0xFF3D9A5C),
            iconBg: Color(0xFFF0FAF3),
          );
        }
        if (st == 'rejected') {
          return const _NotificationVisual(
            icon: Icons.cancel_rounded,
            iconColor: Color(0xFFC94C4C),
            iconBg: Color(0xFFFFF5F5),
          );
        }
        return const _NotificationVisual(
          icon: Icons.pending_actions_rounded,
          iconColor: Color(0xFFC98A2E),
          iconBg: Color(0xFFFFFAF0),
        );
      case AppNotificationType.appAnnouncement:
        return const _NotificationVisual(
          icon: Icons.campaign_rounded,
          iconColor: Color(0xFF7B6BB5),
          iconBg: Color(0xFFF6F3FC),
        );
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.visual});

  final _NotificationVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: visual.iconBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        visual.icon,
        color: visual.iconColor,
        size: 18.sp,
      ),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

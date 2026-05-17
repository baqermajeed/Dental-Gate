import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ألوان مطابقة لتصميم شريط التنقل السفلي (pill bar).
abstract final class PillNavDesign {
  static const Color activeBlue = Color(0xFF2B76F1);
  static const Color inactiveIcon = Color(0xFF8EADF7);
  static const Color barSurface = Color(0xFFFDFEFF);
  static const Color badgeRed = Color(0xFFE53935);
}

/// خلفية الشاشة العامة مطابقة للناف بار.
const Color kShellBackgroundColor = Color(0xFFFDFEFF);

class PillBottomNavBar extends StatelessWidget {
  const PillBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showOrdersBadge = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showOrdersBadge;

  static const List<_PillNavSpec> _items = [
    _PillNavSpec(
      label: 'الرئيسية',
      icon: Icons.home_rounded,
      inactiveAsset: 'assets/icons/home.png',
      activeAsset: 'assets/icons/home select.png',
      selectedFlex: 5,
    ),
    _PillNavSpec(
      label: 'الطلبات',
      icon: Icons.mail_outline_rounded,
      inactiveAsset: 'assets/icons/talabat.png',
      activeAsset: 'assets/icons/talabat select.png',
      selectedFlex: 5,
    ),
    _PillNavSpec(
      label: 'المحفوظات',
      icon: Icons.bookmark_border_rounded,
      inactiveAsset: 'assets/icons/saved.png',
      activeAsset: 'assets/icons/saved select.png',
      selectedFlex: 7,
    ),
    _PillNavSpec(
      label: 'الإعدادات',
      icon: Icons.settings_rounded,
      inactiveAsset: 'assets/icons/setting.png',
      activeAsset: 'assets/icons/setting select.png',
      selectedFlex: 7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72.h,
      child: Container(
        // Tuned so edge icons sit ~36px from screen sides on 393px artboard.
        padding: EdgeInsets.fromLTRB(9.17.w, 18.h, 9.17.w, 18.h),
      decoration: BoxDecoration(
        color: PillNavDesign.barSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26.r),
            topRight: Radius.circular(26.r),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          boxShadow: const [
          BoxShadow(
              color: Color(0x29000000),
              blurRadius: 16.1,
              spreadRadius: 0,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (i) {
            final spec = _items[i];
            final selected = currentIndex == i;
            final showBadge = i == 1 && showOrdersBadge;
            return Flexible(
              flex: selected ? spec.selectedFlex : 4,
              fit: FlexFit.tight,
              child: _PillNavItem(
                spec: spec,
                selected: selected,
                showBadge: showBadge,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PillNavSpec {
  const _PillNavSpec({
    required this.label,
    required this.icon,
    required this.inactiveAsset,
    required this.activeAsset,
    required this.selectedFlex,
  });

  final String label;
  final IconData icon;
  final String inactiveAsset;
  final String activeAsset;
  final int selectedFlex;
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.spec,
    required this.selected,
    required this.showBadge,
    required this.onTap,
  });

  final _PillNavSpec spec;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: PillNavDesign.activeBlue.withValues(alpha: 0.12),
        highlightColor: PillNavDesign.activeBlue.withValues(alpha: 0.08),
        child: Align(
          alignment: selected ? Alignment.centerRight : Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.zero,
            width: selected ? 100.w : null,
            height: selected ? 35.h : null,
            padding: selected
                ? EdgeInsets.fromLTRB(8.w, 4.h, 7.w, 5.h)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: selected ? PillNavDesign.activeBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: selected
                ? Row(
                    mainAxisSize: MainAxisSize.max,
                    textDirection: TextDirection.rtl,
                    children: [
                      _NavIconLayer(
                        icon: spec.icon,
                        inactiveAsset: spec.inactiveAsset,
                        activeAsset: spec.activeAsset,
                        active: true,
                        showBadge: showBadge,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            spec.label,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                              height: 1.5,
                              color: const Color(0xFFFDFEFF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _NavIconLayer(
                    icon: spec.icon,
                    inactiveAsset: spec.inactiveAsset,
                    activeAsset: spec.activeAsset,
                    active: false,
                    showBadge: showBadge,
                  ),
          ),
        ),
      ),
    );
  }
}

class _NavIconLayer extends StatelessWidget {
  static const double _activeIconSize = 22;
  static const double _inactiveIconSize = 26;

  const _NavIconLayer({
    required this.icon,
    required this.inactiveAsset,
    required this.activeAsset,
    required this.active,
    required this.showBadge,
  });

  final IconData icon;
  final String inactiveAsset;
  final String activeAsset;
  final bool active;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final iconSize = active ? _activeIconSize : _inactiveIconSize;
    final iconW = iconSize.w;
    final iconH = iconSize.h;
    return SizedBox(
      width: iconW,
      height: iconH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          active
              ? Image.asset(
                  activeAsset,
                  width: _activeIconSize.w,
                  height: _activeIconSize.h,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  inactiveAsset,
                  width: _inactiveIconSize.w,
                  height: _inactiveIconSize.h,
                  fit: BoxFit.contain,
                ),
          if (showBadge)
            Positioned(
              right: active ? 2.w : 1.w,
              top: active ? 2.h : 1.h,
              child: Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: PillNavDesign.badgeRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

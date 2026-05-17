import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/models/doctor_search_item.dart';

const Color _kAccent = Color(0xFF5993FF);
const Color _kAccentSoft = Color(0xFF7FB2E4);
const Color _kInk = Color(0xFF040814);
const Color _kMuted = Color(0xFF64748B);

/// بطاقة طبيب في الشبكة (بحث / محفوظات) — تصميم حديث بألوان التطبيق.
class DoctorSearchGridCard extends StatelessWidget {
  const DoctorSearchGridCard({
    super.key,
    required this.doctor,
    required this.isSaved,
    required this.onViewProfile,
    required this.onToggleSaved,
  });

  final DoctorSearchItem doctor;
  final bool isSaved;
  final VoidCallback onViewProfile;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(doctor.imageUrl);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFDFEFF),
            Color(0xFFEEF4FF),
          ],
        ),
        border: Border.all(
          color: _kAccent.withValues(alpha: 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: Offset(0, 7.h),
          ),
          BoxShadow(
            color: const Color(0xFF040814).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarRing(imageUrl: imageUrl),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      doctor.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 13.sp,
                        height: 1.2,
                        color: _kInk,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: _kAccent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          doctor.specialtyLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 10.sp,
                            height: 1.2,
                            color: _kAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _InfoChip(
            icon: Icons.workspace_premium_rounded,
            label: doctor.experienceLine,
          ),
          SizedBox(height: 4.h),
          _InfoChip(
            icon: Icons.location_on_rounded,
            label: doctor.locationLine,
          ),
          SizedBox(height: 8.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: SizedBox(
                  height: 34.h,
                  child: ElevatedButton(
                    onPressed: onViewProfile,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'عرض البروفايل',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 11.sp,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: _kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onToggleSaved,
                  child: SizedBox(
                    width: 34.w,
                    height: 34.h,
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                      size: 22.sp,
                      color: isSaved ? _kAccent : _kMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// عمودان بعرض الشاشة؛ ارتفاع كل صف يتبع محتوى البطاقات (بدون فرض نسبة ثابتة).
class DoctorSearchTwoColumnList extends StatelessWidget {
  const DoctorSearchTwoColumnList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.physics,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) {
      return const SizedBox.shrink();
    }
    final gapW = crossAxisSpacing ?? 12.w;
    final gapH = mainAxisSpacing ?? 12.h;
    final rows = (itemCount + 1) ~/ 2;
    return ListView.separated(
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: rows,
      separatorBuilder: (_, _) => SizedBox(height: gapH),
      itemBuilder: (context, row) {
        final i = row * 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: i < itemCount
                  ? itemBuilder(context, i)
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: gapW),
            Expanded(
              child: i + 1 < itemCount
                  ? itemBuilder(context, i + 1)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final outer = 48.w;
    final inner = 39.w;
    return Container(
      width: outer,
      height: outer,
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_kAccent, _kAccentSoft],
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: EdgeInsets.all(1.5.w),
        child: ClipOval(
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: inner,
                  height: inner,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarPlaceholder(inner),
                )
              : _avatarPlaceholder(inner),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(double side) {
    return SizedBox(
      width: side,
      height: side,
      child: ColoredBox(
        color: const Color(0xFFE8ECF4),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            color: _kMuted,
            size: 22.sp,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color: _kAccent.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 12.sp,
                color: _kAccent,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5.sp,
                  height: 1.25,
                  color: _kInk.withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shows the employee's photo when available, otherwise their initials —
/// also falls back to initials if the photo fails to load (a missing/404'd
/// file), rather than staying blank forever.
class EmployeeAvatar extends StatefulWidget {
  const EmployeeAvatar({
    super.key,
    required this.fullName,
    this.photoUrl,
    this.radius = 20,
  });

  final String fullName;
  final String? photoUrl;
  final double radius;

  @override
  State<EmployeeAvatar> createState() => _EmployeeAvatarState();
}

class _EmployeeAvatarState extends State<EmployeeAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(EmployeeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) _imageFailed = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrl != null && !_imageFailed) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(widget.photoUrl!),
        onBackgroundImageError: (_, _) {
          // This can fire synchronously during paint (e.g. an already-
          // cached 404 resolves immediately) — setState right here trips
          // Flutter's "Build scheduled during frame" assertion. Defer to
          // the next frame instead.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _imageFailed = true);
          });
        },
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        _initials(widget.fullName),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: widget.radius * 0.7,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

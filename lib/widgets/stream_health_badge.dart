import 'package:flutter/material.dart';

import '../models/stream_health.dart';
import '../theme/app_theme.dart';

class StreamHealthBadge extends StatelessWidget {
  const StreamHealthBadge({
    super.key,
    required this.health,
    this.snapshotHint,
  });

  final StreamHealth health;
  final String? snapshotHint;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (health) {
      StreamHealth.loading => ('Loading', AppColors.onSurfaceMuted),
      StreamHealth.live => ('Live', AppColors.success),
      StreamHealth.snapshot => ('Snapshot', AppColors.accent),
      StreamHealth.youtube => ('YouTube', AppColors.accent),
      StreamHealth.embed => ('Embed', AppColors.onSurfaceMuted),
      StreamHealth.error => ('Unavailable', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: health == StreamHealth.live
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (snapshotHint != null) ...[
            const SizedBox(width: 6),
            Text(
              snapshotHint!,
              style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

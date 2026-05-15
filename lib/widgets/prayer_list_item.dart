import 'package:flutter/material.dart';
import '../models/prayer_time.dart';
import '../theme/app_theme.dart';

class PrayerListItem extends StatelessWidget {
  final PrayerTime prayer;

  const PrayerListItem({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: prayer.isNext
            ? prayer.color.withOpacity(0.08)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: prayer.isNext ? prayer.color : AppTheme.divider,
          width: prayer.isNext ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon lingkaran berwarna
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: prayer.isPassed
                    ? AppTheme.divider
                    : prayer.color.withOpacity(0.12),
              ),
              child: Center(
                child: Text(
                  prayer.icon,
                  style: TextStyle(
                    fontSize: 18,
                    color: prayer.isPassed ? Colors.transparent : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nama salat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: prayer.isNext ? FontWeight.w700 : FontWeight.w500,
                      color: prayer.isPassed
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (prayer.isNext)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: prayer.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Berikutnya',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (prayer.isPassed && !prayer.isNext)
                    const Text(
                      'Sudah lewat',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),

            // Waktu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  prayer.timeString,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: prayer.isPassed
                        ? AppTheme.textSecondary
                        : prayer.isNext
                            ? prayer.color
                            : AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (prayer.isPassed)
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

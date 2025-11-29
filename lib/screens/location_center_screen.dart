import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import 'gps_location_screen.dart';
import 'network_location_screen.dart';
import '../bindings/gps_location_binding.dart';
import '../bindings/network_location_binding.dart';

class LocationCenterScreen extends StatelessWidget {
  const LocationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget buildCard({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: theme.brightness == Brightness.dark
                  ? null
                  : AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.lavender,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.softGray),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.softGray,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // TITLE
            Text(
              'Location Features',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // KARTU 1 - GPS
            buildCard(
              icon: Icons.gps_fixed,
              iconColor: Colors.green,
              title: 'GPS Location',
              subtitle: 'Akurasi tinggi (GPS)',
              onTap: () => Get.to(
                () => const GpsLocationView(),
                binding: GpsLocationBinding(),
              ),
            ),

            const SizedBox(height: 12),

            // KARTU 2 - NETWORK
            buildCard(
              icon: Icons.network_cell,
              iconColor: Colors.blue,
              title: 'Network Location',
              subtitle: 'Akurasi rendah (Network Provider)',
              onTap: () => Get.to(
                () => const NetworkLocationView(),
                binding: NetworkLocationBinding(),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 32),

            // FOOTER / INFO TAMBAHAN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Pastikan GPS & jaringan aktif agar lokasi lebih akurat.',
                style: TextStyle(color: AppColors.softGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

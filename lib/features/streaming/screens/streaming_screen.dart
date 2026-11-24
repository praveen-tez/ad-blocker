import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Screen providing transparent technical breakdown of streaming ad blocking capabilities.
class StreamingScreen extends StatelessWidget {
  const StreamingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming Compatibility'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Transparency Hero
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.live_tv,
                        color: AppColors.warningAmber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Realistic Streaming Expectations',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Technical disclosure on video platform ad delivery',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.streamingDisclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'HOW AD DELIVERY WORKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          _buildPlatformCard(
            title: 'Third-Party Web & Mobile Ads',
            compatibility: 'Fully Blocked (95%+)',
            badgeColor: AppColors.activeGreen,
            description:
                'Standard banner ads, interstitial ad networks, app telemetry, and tracking beacons reside on distinct hostnames (e.g., ads.example.com) that DNS filters sinkhole effortlessly.',
          ),
          const SizedBox(height: 10),
          _buildPlatformCard(
            title: 'Server-Side Ad Insertion (SSAI)',
            compatibility: 'Partially Limited / Incompatible',
            badgeColor: AppColors.warningAmber,
            description:
                'Platforms like YouTube, Hulu, and Twitch increasingly inject video ads into the exact same media stream and IP hostname as the video content itself. Blocking the ad domain would terminate video playback entirely.',
          ),
          const SizedBox(height: 10),
          _buildPlatformCard(
            title: 'Audio Streaming Services',
            compatibility: 'Moderate (Tracking Blocked)',
            badgeColor: AppColors.secondary,
            description:
                'Companion banners and telemetry can be filtered. In-stream promotional audio fragments delivered via primary CDN nodes require specialized web extensions rather than DNS sinks.',
          ),
          const SizedBox(height: 20),
          // Privacy verification notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppColors.textAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Why CLEARWAVE never attempts HTTPS stream decryption: Breaking TLS encryption by installing fake root certificates exposes your private banking and passwords. CLEARWAVE adheres strictly to non-invasive DNS filtering.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required String title,
    required String compatibility,
    required Color badgeColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  compatibility,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

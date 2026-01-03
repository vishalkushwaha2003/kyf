import 'package:flutter/material.dart';

/// Reel Tab
/// Short video reels screen (like Instagram/TikTok)

class ReelTab extends StatelessWidget {
  const ReelTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Reels'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            onPressed: () {
              // TODO: Create reel
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_rounded,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reels Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Watch fashion reels from creators\nand get inspired',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Explore reels
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Reels'),
            ),
          ],
        ),
      ),
    );
  }
}

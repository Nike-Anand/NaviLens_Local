import 'package:flutter/material.dart';
import 'package:navilens_local/ui/medicine/medicine_screen.dart';
import 'package:navilens_local/ui/physio/physio_screen.dart';
import 'package:navilens_local/ui/environment/environment_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NaviLens Local', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('● OFFLINE', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 32),
            onPressed: () {
              // Navigate to settings
            },
            tooltip: 'Accessibility and device settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeatureCard(
              context: context,
              icon: Icons.medication,
              title: 'Medicine Reader',
              subtitle: 'Read medicine labels',
              color: Colors.blue.shade800,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineScreen())),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context: context,
              icon: Icons.accessibility_new,
              title: 'Physio Coach',
              subtitle: 'Check exercise posture',
              color: Colors.green.shade800,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhysioScreen())),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context: context,
              icon: Icons.visibility,
              title: 'Environment Assistant',
              subtitle: 'Understand surroundings',
              color: Colors.orange.shade800,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnvironmentScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        label: '$title. $subtitle',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, size: 64, color: Colors.white),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

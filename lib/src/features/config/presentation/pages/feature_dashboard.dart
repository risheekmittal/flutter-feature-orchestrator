```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Note: These imports assume standard Clean Architecture naming conventions 
// within the 'config' feature. 
// - Entity: FeatureFlag (name, key, isEnabled, description)
// - Bloc: ConfigBloc (Events: LoadConfigs, ToggleFeature; States: ConfigLoading, ConfigLoaded)

/// FeatureDashboard provides a specialized UI for developers and QA to 
/// manipulate feature flags and local configurations at runtime.
/// 
/// This page follows the Clean Architecture presentation layer pattern,
/// delegating business logic to a Bloc and keeping the UI declarative.
class FeatureDashboard extends StatelessWidget {
  const FeatureDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Configuration',
            onPressed: () {
              // Trigger a fresh fetch from the remote or local source
              // context.read<ConfigBloc>().add(const LoadConfigsEvent());
            },
          ),
        ],
      ),
      body: const _FeatureListSection(),
      bottomNavigationBar: _DashboardFooter(),
    );
  }
}

class _FeatureListSection extends StatelessWidget {
  const _FeatureListSection();

  @override
  Widget build(BuildContext context) {
    // In a production app, we use BlocBuilder to handle different UI states
    // based on the ConfigBloc state.
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSectionHeader(context, 'Feature Toggles'),
        const _FeatureToggleTile(
          title: 'Enable New Onboarding',
          description: 'Uses the redesigned 2024 onboarding flow.',
          featureKey: 'new_onboarding_enabled',
          isEnabled: true,
        ),
        const _FeatureToggleTile(
          title: 'Dark Mode Beta',
          description: 'Enables experimental high-contrast dark theme.',
          featureKey: 'dark_mode_beta',
          isEnabled: false,
        ),
        const Divider(),
        _buildSectionHeader(context, 'System Overrides'),
        _buildActionTile(
          context,
          title: 'Clear Local Cache',
          subtitle: 'Wipes all persisted feature flag overrides.',
          icon: Icons.delete_forever_outlined,
          onTap: () => _confirmReset(context),
        ),
        _buildActionTile(
          context,
          title: 'Export Config State',
          subtitle: 'Copy current JSON config to clipboard.',
          icon: Icons.copy_all_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Config copied to clipboard')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Overrides?'),
        content: const Text('This will revert all flags to their server-defined defaults.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              // context.read<ConfigBloc>().add(const ResetToDefaultEvent());
              Navigator.pop(context);
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
}

class _FeatureToggleTile extends StatelessWidget {
  final String title;
  final String description;
  final String featureKey;
  final bool isEnabled;

  const _FeatureToggleTile({
    required this.title,
    required this.description,
    required this.featureKey,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(description),
      value: isEnabled,
      onChanged: (bool value) {
        // Architectural Intent: Events are dispatched to the Bloc, 
        // which interacts with the UseCase to persist state.
        // context.read<ConfigBloc>().add(ToggleFeatureEvent(key: featureKey, value: value));
      },
      secondary: CircleAvatar(
        backgroundColor: isEnabled 
            ? Theme.of(context).colorScheme.primaryContainer 
            : Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.settings_input_component,
          size: 20,
          color: isEnabled 
              ? Theme.of(context).colorScheme.onPrimaryContainer 
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DashboardFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environment: Production-Mirror',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'App Version: 1.2.0 (Build 42)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
```
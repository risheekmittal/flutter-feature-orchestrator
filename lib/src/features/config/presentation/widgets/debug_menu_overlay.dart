```dart
import 'package:flutter/material.dart';

/// A production-grade Debug Menu Overlay for real-time feature toggling.
/// 
/// Following Clean Architecture, this widget resides in the Presentation layer.
/// In a full implementation, this widget would interact with a `ConfigBloc` or 
/// `FeatureToggleController` which communicates with a `ToggleRepository`.
/// 
/// This implementation uses a local state to demonstrate UI behavior while 
/// providing hooks for architectural integration.
class DebugMenuOverlay extends StatefulWidget {
  const DebugMenuOverlay({super.key});

  /// Static helper to show the debug menu from anywhere in the app.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DebugMenuOverlay(),
    );
  }

  @override
  State<DebugMenuOverlay> createState() => _DebugMenuOverlayState();
}

class _DebugMenuOverlayState extends State<DebugMenuOverlay> {
  // Mock data representing Domain Entities (FeatureFlag)
  // In production, these would be streamed from a Bloc/Provider
  final List<_FeatureFlag> _flags = [
    _FeatureFlag(key: 'enable_new_onboarding', label: 'New Onboarding Flow', isEnabled: true),
    _FeatureFlag(key: 'use_mock_api', label: 'Use Mock API', isEnabled: false),
    _FeatureFlag(key: 'show_beta_badge', label: 'Show Beta Badge', isEnabled: true),
    _FeatureFlag(key: 'experiment_dark_mode_v2', label: 'Dark Mode V2', isEnabled: false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          Expanded(
            child: _buildFlagList(theme),
          ),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Developer Tools',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Feature Toggles & Configurations',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _flags.length,
      separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final flag = _flags[index];
        return SwitchListTile.adaptive(
          title: Text(flag.label, style: theme.textTheme.bodyLarge),
          subtitle: Text('Key: ${flag.key}', style: theme.textTheme.labelSmall),
          value: flag.isEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) => _handleToggle(index, value),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetToDefaults,
                child: const Text('Reset Defaults'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveAndRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
                child: const Text('Apply & Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Architectural Note: 
  /// In a production scenario, this would dispatch an event to the Data layer
  /// via a UseCase or Repository. Local state is kept here for UI responsiveness.
  void _handleToggle(int index, bool value) {
    setState(() {
      _flags[index] = _flags[index].copyWith(isEnabled: value);
    });
    
    // Logic to update local persistence (SharedPrefs/Hive) would go here
    debugPrint('Toggle ${active_flag_id: _flags[index].key} to $value');
  }

  void _resetToDefaults() {
    // Logic to clear overrides in LocalDataSource
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration reset to remote defaults.')),
    );
  }

  void _saveAndRestart() {
    // In a real app, you might trigger a hot-restart or rebuild the widget tree
    // to ensure feature toggles are applied globally.
    Navigator.pop(context);
  }
}

/// Private model for the UI layer. 
/// Mirrors the Domain Entity but allows for easy local mutations.
class _FeatureFlag {
  final String key;
  final String label;
  final bool isEnabled;

  _FeatureFlag({
    required this.key,
    required this.label,
    required this.isEnabled,
  });

  _FeatureFlag copyWith({bool? isEnabled}) {
    return _FeatureFlag(
      key: key,
      label: label,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

```
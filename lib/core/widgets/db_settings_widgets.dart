import 'package:flutter/material.dart';
import 'package:banksync_app/core/theme/app_colors.dart';

class DbSettingsGroup extends StatelessWidget {
  const DbSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withDividers(children),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    if (items.isEmpty) return items;
    final result = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      result.add(const Divider(height: 1, indent: 56));
      result.add(items[i]);
    }
    return result;
  }
}

class DbSettingsTile extends StatelessWidget {
  const DbSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final primary = iconColor ?? Theme.of(context).colorScheme.primary;
    final chevron = onTap != null && trailing == null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (chevron)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
          ],
        ),
      ),
    );
  }
}

class DbThemeModeSelector extends StatelessWidget {
  const DbThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.lightLabel = 'Light',
    this.darkLabel = 'Dark',
    this.systemLabel = 'System',
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;
  final String lightLabel;
  final String darkLabel;
  final String systemLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeModeChip(
            label: lightLabel,
            icon: Icons.light_mode_outlined,
            selected: selected == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ThemeModeChip(
            label: darkLabel,
            icon: Icons.dark_mode_outlined,
            selected: selected == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ThemeModeChip(
            label: systemLabel,
            icon: Icons.brightness_auto_outlined,
            selected: selected == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

class DbLanguageSelector extends StatelessWidget {
  const DbLanguageSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.englishLabel,
    required this.arabicLabel,
    required this.chineseLabel,
  });

  final Locale selected;
  final ValueChanged<Locale> onChanged;
  final String englishLabel;
  final String arabicLabel;
  final String chineseLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LanguageChip(
            label: englishLabel,
            icon: Icons.language,
            selected: selected.languageCode == 'en',
            onTap: () => onChanged(const Locale('en')),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _LanguageChip(
            label: arabicLabel,
            icon: Icons.language_outlined,
            selected: selected.languageCode == 'ar',
            onTap: () => onChanged(const Locale('ar')),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _LanguageChip(
            label: chineseLabel,
            icon: Icons.language_outlined,
            selected: selected.languageCode == 'zh',
            onTap: () => onChanged(const Locale('zh')),
          ),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final outline = Theme.of(context).colorScheme.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGreen.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(
              color: selected ? AppColors.accentGreen : outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accentGreen : onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.accentGreen : onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final outline = Theme.of(context).colorScheme.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGreen.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(
              color: selected ? AppColors.accentGreen : outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accentGreen : onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.accentGreen : onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DbSettingsSectionLabel extends StatelessWidget {
  const DbSettingsSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: onSurfaceVariant,
            ),
      ),
    );
  }
}

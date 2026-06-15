import 'package:flutter/material.dart';

import 'legal_content.dart';

/// Reusable, scrollable in-app legal screen (Privacy Policy / Terms of Use).
///
/// Shows [title] in an [AppBar] with an automatic back button, the shared
/// "Last updated" stamp, then each [LegalSection] as an optional heading +
/// body paragraphs. Content is English-only Dart (see [legal_content.dart]).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                legalLastUpdated,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              for (final section in sections) ...[
                if (section.heading != null) ...[
                  Text(section.heading!, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
                for (final paragraph in section.paragraphs) ...[
                  Text(paragraph, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

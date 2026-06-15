/// English-only legal copy for the in-app Privacy Policy and Terms of Use
/// screens. Long-form legal text is treated like quote content — it is NOT
/// routed through ARB / gen_l10n (per the locked content-localization
/// decision); it ships as Dart constants and is rendered by [LegalScreen].
library;

/// One block of legal copy: an optional [heading] followed by one or more
/// [paragraphs]. A null/empty [heading] renders as an intro/lead paragraph
/// with no title.
class LegalSection {
  const LegalSection({this.heading, required this.paragraphs});

  /// Section title, e.g. "1. Who we are". Null for the intro block.
  final String? heading;

  /// Body paragraphs, rendered with spacing between them.
  final List<String> paragraphs;
}

/// Last-updated stamp shown at the top of both documents.
const String legalLastUpdated = 'Last updated: 13 June 2026';

/// Privacy Policy — verbatim from the VeganKit website (Appendix A).
const List<LegalSection> privacyPolicySections = [
  LegalSection(
    paragraphs: [
      'The short version: VeganKit does not collect, store, or transmit any '
          'personal data. There is no account, no analytics, and no '
          'third-party tracking. Everything stays on your device.',
    ],
  ),
  LegalSection(
    heading: '1. Who we are',
    paragraphs: [
      'VeganKit ("the app", "we", "us") is a mobile application that provides '
          'daily vegan motivation, gentle habit tracking, and an estimated '
          'impact journey. This policy explains how the app handles '
          'information. If you have any questions, contact us at '
          'contact@develooper.io.',
    ],
  ),
  LegalSection(
    heading: '2. Data we collect',
    paragraphs: [
      'None. VeganKit is designed to work entirely on your device, fully '
          'offline. We do not ask you to create an account, we do not request '
          'your name, email, or location, and we do not operate a server that '
          'receives your information.',
    ],
  ),
  LegalSection(
    heading: '3. Data stored on your device',
    paragraphs: [
      'To make the app work, certain information is saved locally on your '
          'device only. This includes: your saved or favorited quotes; your '
          'habits, streaks, and check-in history; your impact journey (start '
          'date and days vegan); and your settings, such as chosen categories, '
          'theme, and notification preferences.',
      'This data never leaves your device. We cannot see it, and it is not '
          'backed up to any server we control. If you delete the app or use '
          '"Reset all data," this information is removed.',
    ],
  ),
  LegalSection(
    heading: '4. Notifications',
    paragraphs: [
      "If you enable daily reminders, notifications are scheduled locally by "
          "your device's operating system. The quote text is included in the "
          "notification so it can mirror to a paired watch. We do not use push "
          "servers and we do not track whether notifications are opened.",
    ],
  ),
  LegalSection(
    heading: '5. Analytics, advertising & tracking',
    paragraphs: [
      "VeganKit contains no analytics SDKs, no advertising, and no third-party "
          "trackers. We do not build a profile of you and we do not sell or "
          "share any information, because we don't collect any.",
    ],
  ),
  LegalSection(
    heading: "6. Children's privacy",
    paragraphs: [
      'VeganKit is suitable for general audiences and does not knowingly '
          'collect any information from anyone, including children. Because no '
          'data is collected, there is nothing to request, correct, or delete '
          'on our servers.',
    ],
  ),
  LegalSection(
    heading: '7. App stores',
    paragraphs: [
      "When you download VeganKit, the Apple App Store or Google Play may "
          "collect information under their own privacy policies as part of the "
          "download and payment process. That activity is governed by Apple's "
          "and Google's policies, not ours.",
    ],
  ),
  LegalSection(
    heading: '8. Your rights & control',
    paragraphs: [
      'Because all of your data lives on your device, you are always in full '
          'control. You can clear your favorites and habits within the app, '
          'use "Reset all data" in Settings, or delete the app to remove '
          'everything.',
    ],
  ),
  LegalSection(
    heading: '9. Changes to this policy',
    paragraphs: [
      'If we update this policy, we\'ll revise the "Last updated" date above '
          'and post the new version on this page. Material changes will be '
          'reflected here before they take effect.',
    ],
  ),
  LegalSection(
    heading: '10. Contact',
    paragraphs: [
      'Questions about this policy or your privacy? Email '
          'contact@develooper.io and we\'ll be happy to help.',
    ],
  ),
];

/// Terms of Use — verbatim from the VeganKit website (Appendix B).
const List<LegalSection> termsOfUseSections = [
  LegalSection(
    paragraphs: [
      "Welcome to VeganKit. By downloading or using the app, you agree to "
          "these Terms of Use. Please read them carefully. If you don't agree, "
          "please don't use the app.",
    ],
  ),
  LegalSection(
    heading: '1. The app',
    paragraphs: [
      'VeganKit provides daily vegan motivational content, optional habit '
          'tracking, and an estimated impact journey. The app is provided free '
          'of charge and is intended for personal, non-commercial use.',
    ],
  ),
  LegalSection(
    heading: '2. License',
    paragraphs: [
      'We grant you a personal, non-exclusive, non-transferable, revocable '
          'license to use VeganKit on devices you own or control, for your own '
          'personal use, in accordance with these terms and the rules of the '
          'app store you downloaded it from.',
    ],
  ),
  LegalSection(
    heading: '3. Acceptable use',
    paragraphs: [
      'You agree not to: reverse-engineer, decompile, or attempt to extract '
          'the source code of the app except where permitted by law; '
          'redistribute, resell, or sublicense the app or its content; or use '
          'the app in any unlawful way or in violation of these terms.',
    ],
  ),
  LegalSection(
    heading: '4. Content & quotes',
    paragraphs: [
      'The motivational quotes, tips, and other content in VeganKit are '
          'provided for inspiration and general information only. They are not '
          'professional, medical, nutritional, or dietary advice. Always '
          'consult a qualified professional before making significant changes '
          'to your diet or lifestyle.',
    ],
  ),
  LegalSection(
    heading: '5. Impact estimates',
    paragraphs: [
      'The "impact journey" figures (such as animals, water, CO₂e, grain, and '
          'forest) are estimates based on published averages. They are intended '
          'to be motivational and illustrative, not exact measurements, and '
          'should not be relied upon as precise scientific or factual claims.',
    ],
  ),
  LegalSection(
    heading: '6. Intellectual property',
    paragraphs: [
      'The app, its design, branding, illustrations, and original content are '
          'owned by VeganKit and protected by applicable intellectual property '
          'laws. These terms do not transfer any ownership rights to you.',
    ],
  ),
  LegalSection(
    heading: '7. Disclaimer of warranties',
    paragraphs: [
      'VeganKit is provided "as is" and "as available," without warranties of '
          'any kind, express or implied, including fitness for a particular '
          'purpose. We do not guarantee that the app will be uninterrupted, '
          'error-free, or available at all times.',
    ],
  ),
  LegalSection(
    heading: '8. Limitation of liability',
    paragraphs: [
      'To the maximum extent permitted by law, VeganKit and its creators will '
          'not be liable for any indirect, incidental, special, or '
          'consequential damages arising from your use of, or inability to '
          'use, the app.',
    ],
  ),
  LegalSection(
    heading: '9. Changes to the app and terms',
    paragraphs: [
      'We may update, change, or discontinue the app or any of its features at '
          'any time. We may also update these terms; when we do, we\'ll revise '
          'the "Last updated" date above. Continued use of the app after '
          'changes means you accept the revised terms.',
    ],
  ),
  LegalSection(
    heading: '10. Governing terms of the app stores',
    paragraphs: [
      "Your use of VeganKit obtained through the Apple App Store or Google "
          "Play is also subject to that store's terms and policies, which apply "
          "in addition to these terms.",
    ],
  ),
  LegalSection(
    heading: '11. Contact',
    paragraphs: ['Questions about these terms? Email contact@develooper.io.'],
  ),
];

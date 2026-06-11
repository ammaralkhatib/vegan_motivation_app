import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/database.dart';
import 'share_card.dart';

/// Captures the rendered [ShareCard] (via its RepaintBoundary key) at 3x and
/// hands the PNG to the platform share sheet.
Future<void> shareCardImage({
  required GlobalKey boundaryKey,
  required Quote quote,
  required Rect sharePositionOrigin,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/veggie_quote_${quote.id}.png');
  await file.writeAsBytes(byteData.buffer.asUint8List());

  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'image/png')],
    subject: 'A little plant-powered motivation',
    sharePositionOrigin: sharePositionOrigin, // iPad popover anchor
  ));
}

/// Bottom sheet: card preview, style switcher, share button.
Future<void> showShareSheet(BuildContext context, Quote quote) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ShareSheet(quote: quote),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.quote});

  final Quote quote;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _boundaryKey = GlobalKey();
  ShareCardStyle _style = ShareCardStyle.cream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final previewWidth =
        (media.size.width - 96).clamp(180.0, ShareCard.designSize.width);
    final scale = previewWidth / ShareCard.designSize.width;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this quote', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            // Live preview — also the capture source.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: ShareCard.designSize.width * scale,
                height: ShareCard.designSize.height * scale,
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: ShareCard(quote: widget.quote, style: _style),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ShareCardStyle>(
              segments: const [
                ButtonSegment(
                  value: ShareCardStyle.cream,
                  label: Text('Cream'),
                ),
                ButtonSegment(
                  value: ShareCardStyle.forest,
                  label: Text('Forest'),
                ),
                ButtonSegment(
                  value: ShareCardStyle.coral,
                  label: Text('Coral'),
                ),
              ],
              selected: {_style},
              onSelectionChanged: (selection) =>
                  setState(() => _style = selection.first),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final box = context.findRenderObject() as RenderBox?;
                    final origin = box == null
                        ? Rect.zero
                        : box.localToGlobal(Offset.zero) & box.size;
                    await shareCardImage(
                      boundaryKey: _boundaryKey,
                      quote: widget.quote,
                      sharePositionOrigin: origin,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

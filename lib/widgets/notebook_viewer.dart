import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

import '../models/diary_entry.dart';
import 'notebook_page_scaffold.dart';

class NotebookViewer extends StatefulWidget {
  const NotebookViewer({
    super.key,
    required this.spreads,
    required this.appearance,
  });

  final List<NotebookSpread> spreads;
  final NotebookAppearance? appearance;

  @override
  State<NotebookViewer> createState() => _NotebookViewerState();
}

class _NotebookViewerState extends State<NotebookViewer> {
  late final PageController _controller;
  late final NotebookAppearance _appearance;
  late final List<NotebookSpread> _spreads;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _spreads = widget.spreads.isEmpty
        ? <NotebookSpread>[NotebookSpread()]
        : widget.spreads;
    _appearance = widget.appearance ?? NotebookAppearance.defaults();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage() {
    final controller =
        TextEditingController(text: (_currentPage + 1).toString());
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Page number'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page == null ||
                    page < 1 ||
                    page > _spreads.length ||
                    !mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid page number.')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _controller.animateToPage(
                  page - 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoverPreview(double width, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _appearance.coverColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _appearance.coverImagePath == null
                  ? Center(
                      child: Text(
                        'Notebook cover',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    )
                  : Image.file(
                      File(_appearance.coverImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) {
                        return Center(
                          child: Text(
                            'Cover photo missing',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveNotebookTextColor() {
    final brightness =
        ThemeData.estimateBrightnessForColor(_appearance.pageColor);
    if (brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.92);
    }
    return Colors.black.withValues(alpha: 0.88);
  }

  Widget _buildAttachment(NotebookAttachment attachment) {
    switch (attachment.type) {
      case NotebookAttachmentType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(attachment.path),
            width: 140,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) {
              return Container(
                width: 140,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.broken_image_rounded),
              );
            },
          ),
        );
      case NotebookAttachmentType.audio:
        return Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.audiotrack_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.basename(attachment.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSpread(int index) {
    final spread = _spreads[index];
    final font = GoogleFonts.getFont(
      _appearance.fontFamily,
      fontSize: 18,
      height: 1.6,
    );
    final textColor = _resolveNotebookTextColor();
    final lineSpacing =
        ((font.fontSize ?? 18) * (font.height ?? 1.6)).clamp(20, 64).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.black.withValues(alpha: 0.02),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: NotebookPlainPage(
                        backgroundColor: _appearance.pageColor,
                        child: spread.attachments.isEmpty
                            ? const SizedBox.expand()
                            : SingleChildScrollView(
                                padding: const EdgeInsets.only(right: 8),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: spread.attachments
                                      .map(_buildAttachment)
                                      .toList(),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NotebookLinedPage(
                        backgroundColor: _appearance.pageColor,
                        lineColor: _appearance.lineColor,
                        lineSpacing: lineSpacing,
                        child: Text(
                          spread.text.isEmpty
                              ? 'Nothing written on this page yet.'
                              : spread.text,
                          style: font.copyWith(
                            color: spread.text.isEmpty
                                ? textColor.withValues(alpha: 0.6)
                                : textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(double width) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final disabledColor = onSurface.withValues(alpha: 0.32);
    final outlineColor = onSurface.withValues(alpha: 0.28);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous page',
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: onSurface,
                disabledColor: disabledColor,
                onPressed: _currentPage > 0
                    ? () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              IconButton(
                tooltip: 'Next page',
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                color: onSurface,
                disabledColor: disabledColor,
                onPressed: _currentPage < _spreads.length - 1
                    ? () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _goToPage,
                icon: const Icon(Icons.menu_book_rounded),
                label: Text('Page ${_currentPage + 1}/${_spreads.length}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                  side: BorderSide(color: outlineColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPager(double width, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: width,
          height: height,
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            physics: const BouncingScrollPhysics(),
            itemCount: _spreads.length,
            itemBuilder: (context, index) => _buildSpread(index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final hasFiniteHeight = constraints.maxHeight.isFinite;
        final media = MediaQuery.of(context);
        final double viewportWidth = hasFiniteWidth && constraints.maxWidth > 0
            ? constraints.maxWidth
            : media.size.width;
        final double maxAllowedWidth =
            math.min(viewportWidth, 1200.0); // allow larger spreads
        final double minAllowedWidth = math.min(360.0, maxAllowedWidth);
        double spreadWidth = viewportWidth - 72;
        if (hasFiniteWidth && constraints.maxWidth <= 500) {
          spreadWidth = viewportWidth - 24;
        }
        spreadWidth = spreadWidth.clamp(minAllowedWidth, maxAllowedWidth);
        final double spreadHeight = spreadWidth * (2 / 3);
        final double coverHeight =
            (spreadHeight * 0.45).clamp(110.0, hasFiniteHeight ? 200.0 : 220.0);
        final double pagerHeight = spreadHeight + 32;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCoverPreview(spreadWidth, coverHeight),
            _buildPager(spreadWidth, pagerHeight),
            _buildControls(spreadWidth),
            const SizedBox(height: 24),
          ],
        );

        if (!hasFiniteHeight) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: content,
          );
        }

        final double estimatedHeight =
            coverHeight + pagerHeight + 24 + 72; // padding and controls
        if (estimatedHeight > constraints.maxHeight) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: content,
          );
        }

        return content;
      },
    );
  }
}

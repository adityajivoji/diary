import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
  static final List<NotebookSpread> _fallbackSpreads =
      List<NotebookSpread>.unmodifiable(<NotebookSpread>[NotebookSpread()]);
  int _currentPage = 0;
  late final AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _audioPositionSubscription;
  StreamSubscription<Duration>? _audioDurationSubscription;
  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;
  String? _activeAudioAttachmentId;
  Duration _audioPosition = Duration.zero;
  Duration? _audioDuration;
  bool _isAudioLoading = false;
  bool _isAudioPlaying = false;
  bool _isUserSeekingAudio = false;
  Duration? _seekPreviewPosition;
  final Map<String, double> _attachmentAspectRatios = <String, double>{};
  final Set<String> _resolvingAspectRatioIds = <String>{};
  static const double _baseImageWidth = 220.0;
  static const double _minImageWidth = 140.0;
  static const double _maxImageWidth = 360.0;
  static const double _maxImageHeight = 260.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _audioPlayer = AudioPlayer();
    _audioPositionSubscription =
        _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted || _activeAudioAttachmentId == null) return;
      if (_isUserSeekingAudio) return;
      setState(() => _audioPosition = position);
    });
    _audioDurationSubscription =
        _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted || _activeAudioAttachmentId == null) return;
      setState(() => _audioDuration = duration);
    });
    _audioPlayerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted || _activeAudioAttachmentId == null) return;
      if (state == PlayerState.completed) {
        _audioPlayer.stop();
      }
      setState(() {
        _isAudioLoading = false;
        _isAudioPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _audioPosition = _audioDuration ?? Duration.zero;
          _isAudioPlaying = false;
          _activeAudioAttachmentId = null;
        }
      });
    });
    _syncImageAttachmentRatios();
  }

  @override
  void didUpdateWidget(covariant NotebookViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeAudioAttachmentId != null &&
        !_spreadContainsAttachment(_activeAudioAttachmentId!)) {
      unawaited(_stopAudioPlayback());
    }
    final lastIndex = _effectiveSpreads.length - 1;
    final shouldClampPage = _currentPage > lastIndex;
    if (shouldClampPage) {
      _currentPage = lastIndex;
    }
    _syncImageAttachmentRatios();

    if (shouldClampPage && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(_currentPage);
        }
      });
    }
  }

  Widget _buildImageWidget(
    NotebookAttachment attachment, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color placeholderColor = Colors.black12,
    Color placeholderIconColor = Colors.black45,
  }) {
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: placeholderColor,
      child: Icon(
        Icons.broken_image_rounded,
        color: placeholderIconColor,
      ),
    );
    if (kIsWeb) {
      return Image.network(
        attachment.path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, _, __) => placeholder,
      );
    }
    return Image.file(
      File(attachment.path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, _, __) => placeholder,
    );
  }

  Future<void> _showImagePreview(NotebookAttachment attachment) async {
    if (!mounted) return;
    final image = _buildImageWidget(
      attachment,
      fit: BoxFit.contain,
      placeholderColor: Colors.black.withValues(alpha: 0.4),
      placeholderIconColor: Colors.white.withValues(alpha: 0.8),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
                maxHeight: 720,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        maxScale: 4,
                        minScale: 1,
                        child: image,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.7),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAudioAttachmentPressed(
    NotebookAttachment attachment,
  ) async {
    if (_activeAudioAttachmentId == attachment.id) {
      if (_isAudioPlaying) {
        try {
          await _audioPlayer.pause();
          if (!mounted) return;
          setState(() => _isAudioPlaying = false);
        } catch (error, stackTrace) {
          debugPrint('Audio pause error: $error');
          debugPrint('$stackTrace');
          await _stopAudioPlayback();
        }
        return;
      }
      if (_audioDuration != null &&
          _audioPosition >= _audioDuration! &&
          _audioDuration != Duration.zero) {
        try {
          await _audioPlayer.seek(Duration.zero);
        } catch (_) {}
        if (mounted) {
          setState(() => _audioPosition = Duration.zero);
        }
      }
      try {
        final resumeFrom = _seekPreviewPosition ?? _audioPosition;
        if (resumeFrom > Duration.zero) {
          try {
            await _audioPlayer.seek(resumeFrom);
          } catch (error, stackTrace) {
            debugPrint('Audio seek before resume failed: $error');
            debugPrint('$stackTrace');
          }
        }
        await _audioPlayer.resume();
        if (mounted) {
          setState(() {
            _isAudioPlaying = true;
            _isUserSeekingAudio = false;
            _seekPreviewPosition = null;
          });
        }
      } catch (error, stackTrace) {
        debugPrint('Audio resume error: $error');
        debugPrint('$stackTrace');
        if (!mounted) return;
        setState(() {
          _activeAudioAttachmentId = null;
          _isAudioPlaying = false;
        });
        _showSnackbar('Unable to resume audio playback.');
      }
      return;
    }

    if (_activeAudioAttachmentId != null) {
      await _stopAudioPlayback();
    }

    await _playAudioAttachment(attachment);
  }

  Future<void> _playAudioAttachment(NotebookAttachment attachment) async {
    if (attachment.path.isEmpty) {
      _showSnackbar('Audio file missing.');
      return;
    }

    final uri = _resolveAttachmentUri(attachment.path);
    String? filePath;
    if (!kIsWeb && (uri.scheme == 'file' || uri.scheme.isEmpty)) {
      try {
        filePath = uri.toFilePath();
      } catch (_) {
        filePath = null;
      }
      if (filePath == null || !File(filePath).existsSync()) {
        debugPrint('Missing audio file at path: ${attachment.path}');
        if (filePath != null) {
          debugPrint('Resolved file path: $filePath');
        }
        _showSnackbar('Audio file could not be found on disk.');
        return;
      }
    }

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (!mounted) return;

    setState(() {
      _activeAudioAttachmentId = attachment.id;
      _isAudioLoading = true;
      _isAudioPlaying = false;
      _isUserSeekingAudio = false;
      _seekPreviewPosition = null;
      _audioPosition = Duration.zero;
      _audioDuration = null;
    });

    try {
      late final Source source;
      if (!kIsWeb && filePath != null) {
        source = DeviceFileSource(filePath);
      } else {
        source = UrlSource(uri.toString());
      }

      await _audioPlayer.setSource(source);
      final duration = await _audioPlayer.getDuration();
      if (!mounted) return;
      setState(() {
        _audioDuration = duration;
      });
      await _audioPlayer.resume();
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = true;
        _isUserSeekingAudio = false;
        _seekPreviewPosition = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Audio playback error: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _activeAudioAttachmentId = null;
        _audioPosition = Duration.zero;
        _audioDuration = null;
        _isAudioPlaying = false;
      });
      _showSnackbar('Unable to play audio file.');
    } finally {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _stopAudioPlayback() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _activeAudioAttachmentId = null;
      _audioPosition = Duration.zero;
      _audioDuration = null;
      _isAudioPlaying = false;
      _isAudioLoading = false;
      _isUserSeekingAudio = false;
      _seekPreviewPosition = null;
    });
  }

  Future<void> _seekAudioTo(Duration target) async {
    if (_activeAudioAttachmentId == null) return;
    var targetMs = target.inMilliseconds;
    if (targetMs < 0) {
      targetMs = 0;
    }
    final maxMs = _audioDuration?.inMilliseconds;
    if (maxMs != null && targetMs > maxMs) {
      targetMs = maxMs;
    }
    final normalized = Duration(milliseconds: targetMs);
    try {
      await _audioPlayer.seek(normalized);
      if (!mounted) return;
      setState(() {
        _audioPosition = normalized;
        _seekPreviewPosition = null;
        _isUserSeekingAudio = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Audio seek error: $error');
      debugPrint('$stackTrace');
    }
  }

  Uri _resolveAttachmentUri(String path) {
    if (path.contains('://')) {
      try {
        final uri = Uri.parse(path);
        if (uri.scheme.isEmpty) {
          return Uri.file(path);
        }
        return uri;
      } catch (_) {
        return Uri.file(path);
      }
    }
    return Uri.file(path);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final buffer = StringBuffer();
    if (hours > 0) {
      buffer
        ..write(hours.toString().padLeft(2, '0'))
        ..write(':')
        ..write(minutes.toString().padLeft(2, '0'))
        ..write(':')
        ..write(seconds.toString().padLeft(2, '0'));
    } else {
      buffer
        ..write(minutes.toString().padLeft(2, '0'))
        ..write(':')
        ..write(seconds.toString().padLeft(2, '0'));
    }
    return buffer.toString();
  }

  void _showSnackbar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    unawaited(_audioPlayer.stop());
    _audioPositionSubscription?.cancel();
    _audioDurationSubscription?.cancel();
    _audioPlayerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<NotebookSpread> get _effectiveSpreads {
    if (widget.spreads.isEmpty) {
      return _fallbackSpreads;
    }
    return widget.spreads;
  }

  NotebookAppearance get _effectiveAppearance =>
      widget.appearance ?? NotebookAppearance.defaults();

  bool _spreadContainsAttachment(String attachmentId) {
    for (final spread in _effectiveSpreads) {
      if (spread.attachments
          .any((attachment) => attachment.id == attachmentId)) {
        return true;
      }
    }
    return false;
  }

  void _goToPage() {
    final totalPages = _effectiveSpreads.length + 1;
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
                if (page == null || page < 1 || page > totalPages || !mounted) {
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

  Widget _buildCoverPage(NotebookAppearance appearance) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : math.min(MediaQuery.of(context).size.width, 1600.0);
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: availableWidth,
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
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.62,
                      heightFactor: 0.78,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: appearance.coverColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: appearance.coverImagePath == null
                              ? Center(
                                  child: Text(
                                    'Notebook cover',
                                    style: textTheme.titleMedium?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : kIsWeb
                                  ? Image.network(
                                      appearance.coverImagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) {
                                        return Center(
                                          child: Text(
                                            'Cover photo missing',
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.92),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(appearance.coverImagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) {
                                        return Center(
                                          child: Text(
                                            'Cover photo missing',
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.92),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _resolveNotebookTextColor(NotebookAppearance appearance) {
    final brightness =
        ThemeData.estimateBrightnessForColor(appearance.pageColor);
    if (brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.92);
    }
    return Colors.black.withValues(alpha: 0.88);
  }

  void _syncImageAttachmentRatios() {
    final validIds = <String>{};
    for (final spread in _effectiveSpreads) {
      for (final attachment in spread.attachments) {
        validIds.add(attachment.id);
        if (attachment.type == NotebookAttachmentType.image &&
            !_attachmentAspectRatios.containsKey(attachment.id) &&
            !_resolvingAspectRatioIds.contains(attachment.id)) {
          _loadImageAspectRatio(attachment);
        }
      }
    }
    _attachmentAspectRatios.removeWhere(
      (id, _) => !validIds.contains(id),
    );
    _resolvingAspectRatioIds.removeWhere(
      (id) => !validIds.contains(id),
    );
  }

  Future<void> _loadImageAspectRatio(NotebookAttachment attachment) async {
    final provider = _createAttachmentImageProvider(attachment.path);
    if (provider == null) return;
    _resolvingAspectRatioIds.add(attachment.id);
    try {
      final ratio = await _resolveImageAspectRatio(provider);
      if (!mounted) return;
      if (ratio != null &&
          ratio.isFinite &&
          ratio > 0 &&
          !_attachmentAspectRatios.containsKey(attachment.id)) {
        setState(() {
          _attachmentAspectRatios[attachment.id] = ratio;
        });
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to resolve image ratio for ${attachment.path}: $error',
      );
      debugPrint('$stackTrace');
    } finally {
      _resolvingAspectRatioIds.remove(attachment.id);
    }
  }

  Future<double?> _resolveImageAspectRatio(ImageProvider provider) async {
    final completer = Completer<double>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (height == 0) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Image has zero height'));
          }
        } else if (!completer.isCompleted) {
          completer.complete(width / height);
        }
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    try {
      final ratio = await completer.future;
      if (ratio.isFinite && ratio > 0) {
        return ratio;
      }
    } catch (error, stackTrace) {
      debugPrint('Image ratio resolution error: $error');
      debugPrint('$stackTrace');
    }
    return null;
  }

  ImageProvider<Object>? _createAttachmentImageProvider(String path) {
    try {
      final uri = _resolveAttachmentUri(path);
      if (kIsWeb) {
        return NetworkImage(uri.toString());
      }
      if (uri.scheme.isEmpty || uri.scheme == 'file') {
        final normalized = uri.toFilePath();
        final file = File(normalized);
        if (file.existsSync()) {
          return FileImage(file);
        }
        return null;
      }
      return NetworkImage(uri.toString());
    } catch (error, stackTrace) {
      debugPrint('Unable to resolve image provider for $path: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  double _computeImageDisplayWidth(double? aspectRatio) {
    if (aspectRatio == null || !aspectRatio.isFinite || aspectRatio <= 0) {
      return _baseImageWidth;
    }
    var width = _baseImageWidth;
    var height = width / aspectRatio;
    if (height > _maxImageHeight) {
      height = _maxImageHeight;
      width = height * aspectRatio;
    }
    if (width > _maxImageWidth) {
      width = _maxImageWidth;
      height = width / aspectRatio;
    }
    if (width < _minImageWidth) {
      width = _minImageWidth;
    }
    return width.clamp(_minImageWidth, _maxImageWidth);
  }

  Widget _buildAttachment(NotebookAttachment attachment) {
    switch (attachment.type) {
      case NotebookAttachmentType.image:
        final borderRadius = BorderRadius.circular(16);
        final ratio = _attachmentAspectRatios[attachment.id];
        final displayWidth = _computeImageDisplayWidth(ratio);
        final theme = Theme.of(context);
        final backgroundColor =
            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08);
        final placeholderIconColor =
            theme.colorScheme.onSurface.withValues(alpha: 0.5);

        return GestureDetector(
          onTap: () => _showImagePreview(attachment),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minImageWidth,
              maxWidth: _maxImageWidth,
              maxHeight: _maxImageHeight,
            ),
            child: Container(
              width: displayWidth,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: ratio != null && ratio.isFinite && ratio > 0
                    ? ratio
                    : (4 / 3),
                child: _buildImageWidget(
                  attachment,
                  fit: BoxFit.contain,
                  placeholderColor: backgroundColor,
                  placeholderIconColor: placeholderIconColor,
                ),
              ),
            ),
          ),
        );
      case NotebookAttachmentType.audio:
        final displayName = (attachment.caption?.trim().isNotEmpty ?? false)
            ? attachment.caption!.trim()
            : p.basename(attachment.path);
        final isActive = attachment.id == _activeAudioAttachmentId;
        final position =
            isActive ? (_seekPreviewPosition ?? _audioPosition) : Duration.zero;
        final duration = isActive ? _audioDuration : null;
        final durationMs = duration?.inMilliseconds ?? 0;
        final positionMs = position.inMilliseconds;
        final sliderMax = durationMs > 0 ? durationMs.toDouble() : 1.0;
        final sliderValue =
            durationMs > 0 ? positionMs.clamp(0, durationMs).toDouble() : 0.0;
        final progress =
            durationMs > 0 && sliderMax > 0 ? sliderValue / sliderMax : 0.0;
        final theme = Theme.of(context);
        final controlColor = _effectiveAppearance.attachmentIconColor;
        final disabledControlColor = controlColor.withValues(alpha: 0.4);
        final textColor = controlColor;
        final durationLabel =
            duration != null ? _formatDuration(duration) : '--:--';
        final positionLabel = _formatDuration(position);
        final timeLabelStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
        );
        final controlsDisabled = _isAudioLoading && isActive;

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0.6,
            color: _effectiveAppearance.attachmentBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: _isAudioLoading && isActive
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                iconSize: 36,
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  foregroundColor: controlColor,
                                  disabledForegroundColor: disabledControlColor,
                                ),
                                onPressed: controlsDisabled
                                    ? null
                                    : () => _handleAudioAttachmentPressed(
                                          attachment,
                                        ),
                                icon: Icon(
                                  isActive && _isAudioPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              durationLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.labelSmall?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    if (durationMs > 0)
                      Slider(
                        value: sliderValue,
                        min: 0,
                        max: sliderMax,
                        onChangeStart: controlsDisabled
                            ? null
                            : (_) {
                                setState(() {
                                  _isUserSeekingAudio = true;
                                  _seekPreviewPosition = position;
                                });
                              },
                        onChanged: controlsDisabled
                            ? null
                            : (value) {
                                setState(() {
                                  _seekPreviewPosition =
                                      Duration(milliseconds: value.round());
                                });
                              },
                        onChangeEnd: controlsDisabled
                            ? null
                            : (value) => _seekAudioTo(
                                  Duration(milliseconds: value.round()),
                                ),
                      )
                    else
                      LinearProgressIndicator(
                        value: _isAudioPlaying ? null : progress,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          positionLabel,
                          style: timeLabelStyle,
                        ),
                        Text(
                          durationLabel,
                          style: timeLabelStyle,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildSpread(NotebookSpread spread, NotebookAppearance appearance) {
    final font = GoogleFonts.getFont(
      appearance.fontFamily,
      fontSize: 18,
      height: 1.6,
    );
    final textColor = _resolveNotebookTextColor(appearance);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : math.min(MediaQuery.of(context).size.width, 1600.0);
          const int targetLineCount = 21;
          final double pageHeight = availableWidth * (2 / 3);
          final double innerHeight = math.max(0, pageHeight - 48);
          final double drawableHeight = math.max(0, innerHeight - 32);
          final double fallbackSpacing =
              ((font.fontSize ?? 18) * (font.height ?? 1.6)).clamp(12, 96);
          final double lineSpacing = (targetLineCount > 1 && drawableHeight > 0)
              ? drawableHeight / (targetLineCount - 1)
              : fallbackSpacing;
          final double textHeightFactor = (font.fontSize ?? 18) > 0
              ? lineSpacing / (font.fontSize ?? 18)
              : (font.height ?? 1.6);
          final textStyle = font.copyWith(
            color: spread.text.isEmpty
                ? textColor.withValues(alpha: 0.6)
                : textColor,
            height: textHeightFactor,
          );
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: availableWidth,
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
                            backgroundColor: appearance.pageColor,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (spread.attachments.isEmpty) {
                                  return const SizedBox.expand();
                                }
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: spread.attachments
                                            .map(_buildAttachment)
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NotebookLinedPage(
                            backgroundColor: appearance.pageColor,
                            lineColor: appearance.lineColor,
                            lineSpacing: lineSpacing,
                            lineCount: targetLineCount,
                            child: Text(
                              spread.text.isEmpty
                                  ? ''
                                  : spread.text,
                              style: textStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildViewerControlButtons({
    required int totalPages,
    required Color onSurface,
    required Color disabledColor,
    required Color outlineColor,
  }) {
    return [
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
        onPressed: _currentPage < totalPages - 1
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
        onPressed: totalPages > 1 ? _goToPage : null,
        icon: const Icon(Icons.menu_book_rounded),
        label: Text('Page ${_currentPage + 1}/$totalPages'),
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outlineColor),
        ),
      ),
    ];
  }

  Widget _buildControls(int totalPages, double width) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final disabledColor = onSurface.withValues(alpha: 0.32);
    final outlineColor = onSurface.withValues(alpha: 0.28);
    final controls = _buildViewerControlButtons(
      totalPages: totalPages,
      onSurface: onSurface,
      disabledColor: disabledColor,
      outlineColor: outlineColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Row(children: controls),
        ),
      ),
    );
  }

  Widget _buildPager(
    List<NotebookSpread> spreads,
    NotebookAppearance appearance,
    double width,
    double height,
  ) {
    final totalPages = spreads.length + 1;
    return SizedBox(
      width: width,
      height: height,
      child: PageView.builder(
        controller: _controller,
        clipBehavior: Clip.none,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalPages,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCoverPage(appearance);
          }
          return _buildSpread(spreads[index - 1], appearance);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spreads = _effectiveSpreads;
    final appearance = _effectiveAppearance;
    final totalPages = spreads.length + 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final media = MediaQuery.of(context);
        final double viewportWidth = media.size.width;
        final double availableWidth = hasFiniteWidth && constraints.maxWidth > 0
            ? constraints.maxWidth
            : viewportWidth;
        final double maxAllowedWidth =
            math.min(availableWidth, 1400.0); // allow larger spreads
        final double minAllowedWidth = math.min(360.0, maxAllowedWidth);
        final bool assumeSidePanel = availableWidth >= 960;
        double spreadWidth;
        if (assumeSidePanel) {
          final double panelWidth = math.min(360.0, availableWidth * 0.28);
          spreadWidth = availableWidth - (panelWidth + 48);
        } else {
          spreadWidth = availableWidth - 32;
          if (availableWidth <= 500) {
            spreadWidth = availableWidth - 16;
          }
        }
        spreadWidth = spreadWidth.clamp(minAllowedWidth, maxAllowedWidth);
        final double spreadHeight = spreadWidth * (2 / 3);
        final double pagerHeight = spreadHeight + 32;
        final pager =
            _buildPager(spreads, appearance, spreadWidth, pagerHeight);

        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Align(
                alignment: Alignment.center,
                child: pager,
              ),
            ),
            SizedBox(
              width: spreadWidth,
              child: _buildControls(totalPages, spreadWidth),
            ),
            const SizedBox(height: 12),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: column,
        );
      },
    );
  }
}

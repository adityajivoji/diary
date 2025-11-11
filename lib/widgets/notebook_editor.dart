import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/diary_entry.dart';
import 'notebook_page_scaffold.dart';
import 'collapsible_section.dart';

class NotebookEditorValue {
  const NotebookEditorValue({
    required this.spreads,
    required this.appearance,
  });

  final List<NotebookSpread> spreads;
  final NotebookAppearance appearance;
}

typedef NotebookEditorChanged = void Function(NotebookEditorValue value);

class NotebookEditor extends StatefulWidget {
  const NotebookEditor({
    super.key,
    required this.initialSpreads,
    required this.initialAppearance,
    required this.onChanged,
  });

  final List<NotebookSpread> initialSpreads;
  final NotebookAppearance initialAppearance;
  final NotebookEditorChanged onChanged;

  @override
  State<NotebookEditor> createState() => _NotebookEditorState();
}

class _NotebookEditorState extends State<NotebookEditor> {
  static const _colorChoices = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFFDF6EC),
    Color(0xFFF3F4F6),
    Color(0xFFE0F2F1),
    Color(0xFFFFF3E0),
    Color(0xFFFFEBEE),
    Color(0xFFFAF5FF),
    Color(0xFFE8EAF6),
    Color(0xFFECEFF1),
    Color(0xFF000000),
    Color(0xFF37474F),
    Color(0xFF212121),
  ];

  static const _fontChoices = <String>[
    'Roboto',
    'Merriweather',
    'Caveat',
    'Indie Flower',
    'Playfair Display',
    'Patrick Hand',
    'Raleway',
  ];
  static const int _maxAmplitudeSamples = 40;
  static const int _defaultSampleRate = 44100;
  static const int _defaultBitRate = 128000;

  late final ImagePicker _imagePicker;
  final AudioRecorder _recorder = AudioRecorder();
  late PageController _pageController;
  late List<NotebookSpread> _spreads;
  late NotebookAppearance _appearance;
  late List<TextEditingController> _textControllers;

  bool _isRecording = false;
  Timer? _recordTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  DateTime? _recordStart;
  Duration _recordDuration = Duration.zero;
  List<double> _amplitudeHistory = <double>[];
  late final AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _audioPositionSubscription;
  StreamSubscription<Duration>? _audioDurationSubscription;
  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;
  bool _hasCheckedRecordingDependencies = false;
  bool _recordDependenciesAvailable = true;
  String? _activeAttachmentId;
  Duration _audioPosition = Duration.zero;
  Duration? _audioDuration;
  bool _isAudioLoading = false;
  bool _isAudioPlaying = false;
  bool _isUserSeekingAudio = false;
  Duration? _seekPreviewPosition;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    _spreads = widget.initialSpreads.isEmpty
        ? [NotebookSpread()]
        : widget.initialSpreads
            .map(
              (spread) => NotebookSpread(
                attachments: List<NotebookAttachment>.from(spread.attachments),
                text: spread.text,
              ),
            )
            .toList();
    _appearance = widget.initialAppearance;
    _pageController = PageController();
    _textControllers = [];
    for (var i = 0; i < _spreads.length; i++) {
      _textControllers.add(TextEditingController(text: _spreads[i].text));
    }
    _audioPlayer = AudioPlayer();
    _audioPositionSubscription =
        _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted || _activeAttachmentId == null) return;
      if (_isUserSeekingAudio) return;
      setState(() => _audioPosition = position);
    });
    _audioDurationSubscription =
        _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted || _activeAttachmentId == null) return;
      setState(() => _audioDuration = duration);
    });
    _audioPlayerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted || _activeAttachmentId == null) return;
      if (state == PlayerState.completed) {
        _audioPlayer.stop();
      }
      setState(() {
        _isAudioLoading = false;
        _isAudioPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _audioPosition = _audioDuration ?? Duration.zero;
          _isAudioPlaying = false;
          _activeAttachmentId = null;
          return;
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  @override
  void dispose() {
    for (final controller in _textControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _recordTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioPositionSubscription?.cancel();
    _audioDurationSubscription?.cancel();
    _audioPlayerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _handleAddImage(int spreadIndex, ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;
    final attachment = NotebookAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: NotebookAttachmentType.image,
      path: file.path,
    );
    _updateAttachments(spreadIndex, (list) => list..add(attachment));
  }

  Future<void> _handleAddAudio(int spreadIndex) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Audio',
          mimeTypes: ['audio/*'],
          extensions: ['m4a', 'mp3', 'aac', 'wav', 'webm'],
        ),
      ],
    );
    if (file == null) return;
    final path = file.path;
    if (path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to use the selected audio file.'),
          ),
        );
      }
      return;
    }
    String importPath;
    try {
      if (kIsWeb) {
        importPath = path;
      } else {
        importPath = await _copyToAudioStorage(path);
      }
    } catch (error) {
      debugPrint('Failed to import audio file: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to import the selected audio file.'),
          ),
        );
      }
      return;
    }

    final attachment = NotebookAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: NotebookAttachmentType.audio,
      path: importPath,
    );
    _updateAttachments(spreadIndex, (list) => list..add(attachment));
  }

  Future<void> _handleAudioAttachmentPressed(
    NotebookAttachment attachment,
  ) async {
    if (_activeAttachmentId == attachment.id) {
      if (_isAudioPlaying) {
        try {
          await _audioPlayer.pause();
          if (mounted) {
            setState(() => _isAudioPlaying = false);
          }
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
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to resume audio playback.'),
            ),
          );
        }
      }
      return;
    }

    if (_activeAttachmentId != null) {
      await _stopAudioPlayback();
    }

    await _playAudioAttachment(attachment);
  }

  Future<void> _playAudioAttachment(NotebookAttachment attachment) async {
    if (attachment.path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio file missing.'),
          ),
        );
      }
      return;
    }

    final uri = _resolveAttachmentUri(attachment.path);
    String? filePath;
    if (uri.scheme == 'file' || uri.scheme.isEmpty) {
      try {
        filePath = uri.toFilePath();
      } catch (_) {
        filePath = null;
      }
      if (filePath == null || !File(filePath).existsSync()) {
        final recovery = await _tryRecoverAudioFile(attachment);
        if (recovery != null) {
          filePath = recovery;
        }
      }
      if (filePath == null || !File(filePath).existsSync()) {
        debugPrint('Missing audio file at path: ${attachment.path}');
        if (filePath != null) {
          debugPrint('Resolved file path: $filePath');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file could not be found on disk.'),
            ),
          );
        }
        return;
      }
    }

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (!mounted) return;

    setState(() {
      _activeAttachmentId = attachment.id;
      _isAudioLoading = true;
      _isAudioPlaying = false;
      _isUserSeekingAudio = false;
      _seekPreviewPosition = null;
      _audioPosition = Duration.zero;
      _audioDuration = null;
    });

    try {
      Source source;
      if (filePath != null) {
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
        _activeAttachmentId = null;
        _audioPosition = Duration.zero;
        _audioDuration = null;
        _isAudioPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play audio file.'),
        ),
      );
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
      _activeAttachmentId = null;
      _isAudioPlaying = false;
      _isAudioLoading = false;
      _isUserSeekingAudio = false;
      _seekPreviewPosition = null;
      _audioPosition = Duration.zero;
      _audioDuration = null;
    });
  }

  Future<void> _seekAudioTo(Duration target) async {
    if (_activeAttachmentId == null) return;
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

  Future<void> _seekAudioBy(Duration offset) async {
    final current =
        _seekPreviewPosition ?? _audioPosition;
    await _seekAudioTo(current + offset);
  }

  Future<void> _toggleRecording(int spreadIndex) async {
    if (_isRecording) {
      await _stopRecording(spreadIndex);
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_activeAttachmentId != null) {
      await _stopAudioPlayback();
    }

    if (!await _ensureRecordingDependencies()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recording on Linux requires ffmpeg. Please install it (e.g. sudo apt install ffmpeg).',
            ),
          ),
        );
      }
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio.'),
          ),
        );
      }
      return;
    }
    final recordingSetup = await _prepareRecordingSetup();
    if (recordingSetup == null) {
      debugPrint('No supported audio encoder available for this platform.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recording is not supported on this device or browser.',
            ),
          ),
        );
      }
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    late final String filePath;
    if (kIsWeb) {
      filePath =
          _buildWebRecordingPath(timestamp, recordingSetup.fileExtension);
    } else {
      final directory = await _getAudioStorageDirectory();
      final fileName =
          'notebook_audio_$timestamp.${recordingSetup.fileExtension}';
      filePath = p.join(directory.path, fileName);
    }
    final config = recordingSetup.config;

    try {
      await _recorder.start(config, path: filePath);
    } catch (error, stackTrace) {
      debugPrint('Audio record error: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        final message = error is ProcessException &&
                error.executable == 'ffmpeg'
            ? 'Recording on Linux requires ffmpeg. Install it and try again.'
            : 'Unable to start recording. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
      return;
    }

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    final startTime = DateTime.now();
    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording = true;
      _recordStart = startTime;
      _recordDuration = Duration.zero;
      _amplitudeHistory = <double>[];
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        if (!mounted || _recordStart == null) return;
        setState(() {
          _recordDuration = DateTime.now().difference(_recordStart!);
        });
      },
    );

    _amplitudeSubscription =
        _recorder.onAmplitudeChanged(const Duration(milliseconds: 120)).listen(
      (amplitude) {
        if (!mounted) return;
        setState(() {
          final normalized = _normalizeAmplitude(amplitude.current);
          _amplitudeHistory.add(normalized);
          while (_amplitudeHistory.length > _maxAmplitudeSamples) {
            _amplitudeHistory.removeAt(0);
          }
        });
      },
    );
  }

  Future<void> _stopRecording(int spreadIndex) async {
    final path = await _recorder.stop();

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    _recordTimer?.cancel();
    _recordTimer = null;

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordStart = null;
        _recordDuration = Duration.zero;
        _amplitudeHistory = <double>[];
      });
    }

    if (path == null) return;

    late final String finalPath;
    if (kIsWeb) {
      finalPath = path;
    } else {
      var normalizedPath = _expandUserPath(path);
      final storageDir = await _getAudioStorageDirectory();
      if (!p.isWithin(storageDir.path, normalizedPath)) {
        final file = File(normalizedPath);
        if (await file.exists()) {
          try {
            normalizedPath = await _copyToAudioStorage(normalizedPath);
          } catch (error, stackTrace) {
            debugPrint('Failed to move audio file: $error');
            debugPrint('$stackTrace');
          }
        }
      }
      finalPath = normalizedPath;
    }

    final attachment = NotebookAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: NotebookAttachmentType.audio,
      path: finalPath,
    );
    _updateAttachments(spreadIndex, (list) => list..add(attachment));
  }

  double _normalizeAmplitude(double decibels) {
    const minDb = -60.0;
    final double clamped =
        decibels.isFinite ? decibels.clamp(minDb, 0.0).toDouble() : minDb;
    return (((clamped - minDb) / -minDb).clamp(0.0, 1.0)).toDouble();
  }

  Future<Directory> _getAudioStorageDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'pastel_diary_audio'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> _copyToAudioStorage(String sourcePath) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Audio storage copying is not supported on the web platform.',
      );
    }
    final normalizedSource = _expandUserPath(sourcePath);
    final file = File(normalizedSource);
    if (!await file.exists()) {
      throw FileSystemException(
          'Source audio file does not exist.', sourcePath);
    }

    final directory = await _getAudioStorageDirectory();
    if (p.isWithin(directory.path, file.path)) {
      return file.path;
    }

    final baseName = p.basename(file.path);
    final name = p.basenameWithoutExtension(baseName);
    final extension = p.extension(baseName);

    var destination = p.join(directory.path, baseName);
    var counter = 1;
    while (await File(destination).exists()) {
      destination = p.join(directory.path, '${name}_$counter$extension');
      counter++;
    }

    await file.copy(destination);
    return destination;
  }

  Future<String?> _tryRecoverAudioFile(NotebookAttachment attachment) async {
    if (kIsWeb) {
      return null;
    }
    final normalized = _expandUserPath(attachment.path);
    final existing = File(normalized);
    if (await existing.exists()) {
      final storedPath = await _copyToAudioStorage(normalized);
      await _updateAttachmentPath(attachment.id, storedPath);
      return storedPath;
    }

    final audioDir = await _getAudioStorageDirectory();
    final candidate = p.join(audioDir.path, p.basename(attachment.path));
    if (await File(candidate).exists()) {
      await _updateAttachmentPath(attachment.id, candidate);
      return candidate;
    }

    return null;
  }

  Future<void> _updateAttachmentPath(
      String attachmentId, String newPath) async {
    for (var i = 0; i < _spreads.length; i++) {
      final index = _spreads[i]
          .attachments
          .indexWhere((attachment) => attachment.id == attachmentId);
      if (index != -1) {
        _updateAttachments(
          i,
          (list) {
            final updated = list[index].copyWith(path: newPath);
            list[index] = updated;
            return list;
          },
        );
        break;
      }
    }
  }

  String _expandUserPath(String path) {
    if (kIsWeb) {
      return path;
    }
    if (path.startsWith('~')) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        if (path == '~') {
          return home;
        }
        if (path.startsWith('~/')) {
          return p.join(home, path.substring(2));
        }
        return path.replaceFirst('~', home);
      }
    }
    return path;
  }

  Future<bool> _ensureRecordingDependencies() async {
    if (_hasCheckedRecordingDependencies) {
      return _recordDependenciesAvailable;
    }
    _hasCheckedRecordingDependencies = true;
    _recordDependenciesAvailable = true;

    if (kIsWeb) {
      return true;
    }

    if (!Platform.isLinux) {
      return true;
    }

    try {
      final result = await Process.run('ffmpeg', ['-version']);
      _recordDependenciesAvailable = result.exitCode == 0;
    } catch (_) {
      _recordDependenciesAvailable = false;
    }
    return _recordDependenciesAvailable;
  }

  Future<_RecorderSetup?> _prepareRecordingSetup() async {
    const encoderOptions = <_RecorderEncoderOption>[
      _RecorderEncoderOption(
        encoder: AudioEncoder.aacLc,
        fileExtension: 'm4a',
      ),
      _RecorderEncoderOption(
        encoder: AudioEncoder.opus,
        fileExtension: 'webm',
        sampleRate: 48000,
      ),
      _RecorderEncoderOption(
        encoder: AudioEncoder.wav,
        fileExtension: 'wav',
        bitRate: 1411200,
      ),
    ];

    for (final option in encoderOptions) {
      try {
        final supported = await _recorder.isEncoderSupported(option.encoder);
        if (!supported) continue;

        final config = RecordConfig(
          encoder: option.encoder,
          bitRate: option.bitRate ?? _defaultBitRate,
          sampleRate: option.sampleRate ?? _defaultSampleRate,
        );
        return _RecorderSetup(
          config: config,
          fileExtension: option.fileExtension,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to check encoder support for ${option.encoder}: $error',
        );
        debugPrint('$stackTrace');
      }
    }

    return null;
  }

  String _buildWebRecordingPath(int timestamp, String extension) {
    return 'web_recording_$timestamp.$extension';
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

  void _updateAttachments(
    int spreadIndex,
    List<NotebookAttachment> Function(List<NotebookAttachment>) transform,
  ) {
    setState(() {
      final current = List<NotebookAttachment>.from(
        _spreads[spreadIndex].attachments,
      );
      final updated = transform(current);
      _spreads[spreadIndex] = _spreads[spreadIndex].copyWith(
        attachments: updated,
      );
    });
    _notifyChanged();
  }

  Future<void> _removeAttachment(int spreadIndex, String attachmentId) async {
    if (_activeAttachmentId == attachmentId) {
      await _stopAudioPlayback();
    }
    _updateAttachments(
      spreadIndex,
      (list) => list..removeWhere((item) => item.id == attachmentId),
    );
  }

  void _handleTextChanged(int spreadIndex, String value) {
    _spreads[spreadIndex] = _spreads[spreadIndex].copyWith(
      text: value,
    );
    _notifyChanged();
  }

  void _addPageAfter(int index) {
    setState(() {
      _spreads.insert(index + 1, NotebookSpread());
      _textControllers.insert(index + 1, TextEditingController());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChanged();
      _pageController.animateToPage(
        index + 1,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 400),
      );
    });
  }

  void _deletePage(int index) {
    if (_spreads.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The notebook needs at least one page.'),
        ),
      );
      return;
    }
    setState(() {
      _spreads.removeAt(index);
      _textControllers[index].dispose();
      _textControllers.removeAt(index);
      if (_currentPage >= _spreads.length) {
        _currentPage = _spreads.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChanged();
      _pageController.animateToPage(
        _currentPage,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  void _notifyChanged() {
    widget.onChanged(
      NotebookEditorValue(
        spreads: List<NotebookSpread>.from(_spreads),
        appearance: _appearance,
      ),
    );
  }

  void _goToPage() {
    final controller = TextEditingController(
      text: (_currentPage + 1).toString(),
    );
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter page number',
            ),
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
                _pageController.animateToPage(
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

  void _updateAppearance({
    Color? pageColor,
    Color? lineColor,
    Color? coverColor,
    String? fontFamily,
    String? coverImagePath,
  }) {
    setState(() {
      _appearance = _appearance.copyWith(
        pageColorValue: pageColor?.toARGB32(),
        lineColorValue: lineColor?.toARGB32(),
        coverColorValue: coverColor?.toARGB32(),
        fontFamily: fontFamily,
        coverImagePath: coverImagePath,
      );
    });
    _notifyChanged();
  }

  String _colorHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String get _styleSummary =>
      'Font ${_appearance.fontFamily} • Page ${_colorHex(_appearance.pageColor)}';

  Color _resolveNotebookTextColor(ThemeData theme) {
    final brightness =
        ThemeData.estimateBrightnessForColor(_appearance.pageColor);
    if (brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.92);
    }
    return Colors.black.withValues(alpha: 0.88);
  }

  Future<void> _pickCoverPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;
    _updateAppearance(coverImagePath: file.path);
  }

  Widget _buildColorPicker({
    required String label,
    required Color selected,
    required ValueChanged<Color> onColorSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorChoices.map((color) {
            final isSelected = color == selected;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black12,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAppearanceControls(double width) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final outlineColor = onSurface.withValues(alpha: 0.28);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: CollapsibleSection(
          title: 'Notebook style',
          subtitle: _styleSummary,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColorPicker(
                label: 'Page color',
                selected: _appearance.pageColor,
                onColorSelected: (color) => _updateAppearance(pageColor: color),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(
                label: 'Line color',
                selected: _appearance.lineColor,
                onColorSelected: (color) => _updateAppearance(lineColor: color),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(
                label: 'Cover color',
                selected: _appearance.coverColor,
                onColorSelected: (color) =>
                    _updateAppearance(coverColor: color),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_appearance.fontFamily),
                initialValue: _appearance.fontFamily,
                decoration: const InputDecoration(
                  labelText: 'Notebook font',
                  border: OutlineInputBorder(),
                ),
                items: _fontChoices.map((font) {
                  return DropdownMenuItem<String>(
                    value: font,
                    child: Text(
                      font,
                      style: GoogleFonts.getFont(font),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateAppearance(fontFamily: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCoverPhoto,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose cover photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onSurface,
                        side: BorderSide(color: outlineColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_appearance.coverImagePath != null)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_appearance.coverImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) {
                            return Container(
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Icon(Icons.photo_rounded),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(
    NotebookAttachment attachment,
    int spreadIndex,
  ) {
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    switch (attachment.type) {
      case NotebookAttachmentType.image:
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0.8,
          shape: border,
          child: Stack(
            children: [
              SizedBox(
                width: 140,
                height: 120,
                child: Image.file(
                  File(attachment.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) {
                    return Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_rounded),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.48),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(28),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () =>
                      _removeAttachment(spreadIndex, attachment.id),
                ),
              ),
            ],
          ),
        );
      case NotebookAttachmentType.audio:
        final isActive = attachment.id == _activeAttachmentId;
        final position =
            isActive ? (_seekPreviewPosition ?? _audioPosition) : Duration.zero;
        final duration = isActive ? _audioDuration : null;
        final durationMs = duration?.inMilliseconds ?? 0;
        final positionMs = position.inMilliseconds;
        final sliderMax = durationMs > 0 ? durationMs.toDouble() : 1.0;
        final sliderValue = durationMs > 0
            ? positionMs.clamp(0, durationMs).toDouble()
            : 0.0;
        final progress =
            durationMs > 0 && sliderMax > 0 ? sliderValue / sliderMax : 0.0;
        final titleStyle = Theme.of(context).textTheme.bodyMedium;
        final durationLabel =
            duration != null ? _formatDuration(duration) : '--:--';
        final positionLabel = _formatDuration(position);
        final timeLabelStyle =
            Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                );
        final controlsDisabled = _isAudioLoading;

        return Card(
          elevation: 0.8,
          shape: border,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: _isAudioLoading && isActive
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              iconSize: 36,
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  _handleAudioAttachmentPressed(attachment),
                              icon: Icon(
                                isActive && _isAudioPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.basename(attachment.path),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _removeAttachment(
                        spreadIndex,
                        attachment.id,
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
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
                          : (value) {
                              _seekAudioTo(Duration(milliseconds: value.round()));
                            },
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Rewind 5 seconds',
                        child: IconButton(
                          icon: const Icon(Icons.replay_5_rounded),
                          onPressed: controlsDisabled
                              ? null
                              : () => _seekAudioBy(
                                    const Duration(seconds: -5),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: _isAudioPlaying ? 'Pause' : 'Play',
                        child: IconButton.filled(
                          iconSize: 32,
                          onPressed: controlsDisabled
                              ? null
                              : () => _handleAudioAttachmentPressed(attachment),
                          icon: Icon(
                            _isAudioPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Stop playback',
                        child: IconButton(
                          icon: const Icon(Icons.stop_rounded),
                          onPressed: controlsDisabled
                              ? null
                              : () => _stopAudioPlayback(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Skip forward 5 seconds',
                        child: IconButton(
                          icon: const Icon(Icons.forward_5_rounded),
                          onPressed: controlsDisabled
                              ? null
                              : () => _seekAudioBy(
                                    const Duration(seconds: 5),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  Widget _buildSpread(int index) {
    final spread = _spreads[index];
    final controller = _textControllers[index];
    final theme = Theme.of(context);
    final font = GoogleFonts.getFont(
      _appearance.fontFamily,
      fontSize: 18,
      height: 1.6,
    );
    final textColor = _resolveNotebookTextColor(theme);
    final double fontSize = font.fontSize ?? 18;
    final double fontHeight = font.height ?? 1.6;
    final double lineSpacing = (fontSize * fontHeight).clamp(20, 64).toDouble();
    final inputDecoration = InputDecoration(
      border: InputBorder.none,
      hintText: 'Your story goes here...',
      hintStyle: font.copyWith(
        color: textColor.withValues(alpha: 0.5),
      ),
      filled: false,
      fillColor: Colors.transparent,
      isCollapsed: true,
      contentPadding: EdgeInsets.zero,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
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
                                ? Center(
                                    child: Text(
                                      'Add drawings, photos or audio memories.',
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            textColor.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.only(right: 8),
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: spread.attachments
                                            .map(
                                              (attachment) =>
                                                  _buildAttachmentCard(
                                                attachment,
                                                index,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NotebookLinedPage(
                            backgroundColor: _appearance.pageColor,
                            lineColor: _appearance.lineColor,
                            lineSpacing: lineSpacing,
                            child: TextField(
                              controller: controller,
                              onChanged: (value) =>
                                  _handleTextChanged(index, value),
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              keyboardType: TextInputType.multiline,
                              cursorColor: textColor,
                              decoration: inputDecoration,
                              style: font.copyWith(color: textColor),
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

  Widget _buildRecordingStatus(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final onContainer = colorScheme.onPrimaryContainer;
    final waveformColor = colorScheme.primary.withValues(alpha: 0.85);
    final samples = _amplitudeHistory.isEmpty
        ? <double>[]
        : List<double>.from(_amplitudeHistory);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recording',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: onContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_recordDuration),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onContainer.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 32,
              child: CustomPaint(
                painter: _WaveformPainter(
                  amplitudes: samples,
                  color: waveformColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageControls(double width) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final disabledColor = onSurface.withValues(alpha: 0.32);
    final outlineColor = onSurface.withValues(alpha: 0.28);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    tooltip: 'Previous page',
                    style: IconButton.styleFrom(
                      foregroundColor: onSurface,
                      disabledForegroundColor: disabledColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _currentPage < _spreads.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    tooltip: 'Next page',
                    style: IconButton.styleFrom(
                      foregroundColor: onSurface,
                      disabledForegroundColor: disabledColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _addPageAfter(_currentPage),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add page'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.secondary,
                    ),
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
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _deletePage(_currentPage),
                    tooltip: 'Delete page',
                    icon: Icon(
                      Icons.delete_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _handleAddImage(_currentPage, ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Camera'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _handleAddImage(_currentPage, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _handleAddAudio(_currentPage),
                    icon: const Icon(Icons.audiotrack_rounded),
                    label: const Text('Audio'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _toggleRecording(_currentPage),
                    icon: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                    label: Text(_isRecording ? 'Stop' : 'Record'),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isRecording
                    ? Padding(
                        key: const ValueKey('recording-indicator'),
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildRecordingStatus(theme),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final availableWidth = hasFiniteWidth && constraints.maxWidth > 0
            ? constraints.maxWidth
            : media.size.width;
        final double maxAllowedWidth = math.min(
            availableWidth, 1200.0); // larger workspace on wide screens
        final double minAllowedWidth = math.min(360.0, maxAllowedWidth);
        double spreadWidth = availableWidth - 72;
        if (hasFiniteWidth && constraints.maxWidth <= 520) {
          spreadWidth = availableWidth - 24;
        }
        spreadWidth = spreadWidth.clamp(minAllowedWidth, maxAllowedWidth);
        final spreadHeight = spreadWidth * (2 / 3);
        final pagerHeight = spreadHeight + 32;

        final pageView = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: spreadWidth,
              height: pagerHeight,
              child: PageView.builder(
                controller: _pageController,
                clipBehavior: Clip.none,
                onPageChanged: (value) {
                  setState(() => _currentPage = value);
                },
                physics: const BouncingScrollPhysics(),
                itemCount: _spreads.length,
                itemBuilder: (context, index) => _buildSpread(index),
              ),
            ),
          ),
        );

        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            pageView,
            const SizedBox(height: 8),
            _buildPageControls(spreadWidth),
            const SizedBox(height: 16),
            _buildAppearanceControls(spreadWidth),
          ],
        );

        if (!constraints.hasBoundedHeight) {
          return column;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: column,
          ),
        );
      },
    );
  }
}

class _RecorderEncoderOption {
  const _RecorderEncoderOption({
    required this.encoder,
    required this.fileExtension,
    this.bitRate,
    this.sampleRate,
  });

  final AudioEncoder encoder;
  final String fileExtension;
  final int? bitRate;
  final int? sampleRate;
}

class _RecorderSetup {
  const _RecorderSetup({
    required this.config,
    required this.fileExtension,
  });

  final RecordConfig config;
  final String fileExtension;
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  final List<double> amplitudes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      final centerPaint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        centerPaint,
      );
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    const double spacing = 2.0;
    final barCount = amplitudes.length;
    final double maxAvailableWidth =
        math.max(0, size.width - spacing * (barCount - 1));
    final double barWidth = math.max(2.0, maxAvailableWidth / barCount);
    final double minBarHeight = size.height * 0.08;

    var x = 0.0;
    for (final value in amplitudes) {
      final double normalized = value.clamp(0.0, 1.0);
      final double targetHeight =
          math.max(minBarHeight, normalized * size.height);
      final double top = (size.height - targetHeight) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, targetHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
      x += barWidth + spacing;
      if (x > size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes || oldDelegate.color != color;
  }
}

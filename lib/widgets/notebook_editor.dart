import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:file_selector/file_selector.dart';

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

  late final ImagePicker _imagePicker;
  final AudioRecorder _recorder = AudioRecorder();
  late PageController _pageController;
  late List<NotebookSpread> _spreads;
  late NotebookAppearance _appearance;
  late List<TextEditingController> _textControllers;

  bool _isRecording = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  @override
  void dispose() {
    for (final controller in _textControllers) {
      controller.dispose();
    }
    _pageController.dispose();
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
          extensions: ['m4a', 'mp3', 'aac', 'wav'],
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
    final attachment = NotebookAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: NotebookAttachmentType.audio,
      path: path,
    );
    _updateAttachments(spreadIndex, (list) => list..add(attachment));
  }

  Future<void> _toggleRecording(int spreadIndex) async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;
      final attachment = NotebookAttachment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: NotebookAttachmentType.audio,
        path: path,
      );
      _updateAttachments(spreadIndex, (list) => list..add(attachment));
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
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'notebook_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final filePath = p.join(directory.path, fileName);
    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );
    await _recorder.start(config, path: filePath);
    setState(() => _isRecording = true);
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

  void _removeAttachment(int spreadIndex, String attachmentId) {
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
        return Card(
          elevation: 0.8,
          shape: border,
          child: ListTile(
            leading: const Icon(Icons.audiotrack_rounded),
            title: Text(
              p.basename(attachment.path),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _removeAttachment(spreadIndex, attachment.id),
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
          child: Row(
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
                icon:
                    Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(_isRecording ? 'Stop' : 'Record'),
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

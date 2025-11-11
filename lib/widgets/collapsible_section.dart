import 'package:flutter/material.dart';

/// Card-like panel that can be expanded or collapsed to reveal its contents.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
    this.margin,
    this.headerPadding,
    this.contentPadding,
    this.elevation = 0,
    this.backgroundColor,
    this.shadowColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? contentPadding;
  final double elevation;
  final Color? backgroundColor;
  final Color? shadowColor;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = widget.subtitle;

    final header = ListTile(
      contentPadding:
          widget.headerPadding ?? const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        widget.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          : null,
      trailing: Icon(
        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onTap: _toggleExpanded,
    );

    final content = ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        heightFactor: _isExpanded ? 1 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isExpanded ? 1 : 0,
          curve: Curves.easeInOut,
          child: Padding(
            padding: widget.contentPadding ??
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: widget.child,
          ),
        ),
      ),
    );

    return Card(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      elevation: widget.elevation,
      color: widget.backgroundColor,
      shadowColor: widget.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          content,
        ],
      ),
    );
  }
}

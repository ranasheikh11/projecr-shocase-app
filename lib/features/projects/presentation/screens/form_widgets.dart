import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Shared app bar ──────────────────────────────────────────────────────────
AppBar buildFormAppBar(
  BuildContext context,
  String title, {
  bool hasUnsavedChanges = false,
  VoidCallback? onBackOverride,
}) {
  return AppBar(
    backgroundColor: AppTheme.bgDark,
    surfaceTintColor: Colors.transparent,
    leading: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onBackOverride != null) {
          onBackOverride();
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 15, color: AppTheme.textPrimary),
      ),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        if (hasUnsavedChanges) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Unsaved',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppTheme.dividerColor),
    ),
  );
}

// ─── Section header ──────────────────────────────────────────────────────────
class FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconBgColor;

  const FormSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (iconBgColor ?? AppTheme.primaryColor).withValues(alpha: 0.22),
                (iconBgColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: (iconBgColor ?? AppTheme.primaryColor).withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Icon(icon,
                color: iconBgColor ?? AppTheme.primaryLight, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── App text field (stateful for focus animation + URL validation) ───────────
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final bool showCounter;
  final bool isUrlField;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLength,
    this.showCounter = false,
    this.isUrlField = false,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  bool _isFocused = false;
  bool _urlValid = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.012).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      if (_focus.hasFocus) {
        _scaleCtrl.forward();
      } else {
        _scaleCtrl.reverse();
      }
    });
    if (widget.isUrlField) {
      _urlValid = _isValidUrl(widget.controller.text);
      widget.controller.addListener(_onUrlChanged);
    }
  }

  void _onUrlChanged() {
    final val = _isValidUrl(widget.controller.text);
    if (val != _urlValid) setState(() => _urlValid = val);
  }

  bool _isValidUrl(String text) {
    if (text.trim().isEmpty) return false;
    return text.startsWith('http://') || text.startsWith('https://');
  }

  @override
  void dispose() {
    _focus.dispose();
    _scaleCtrl.dispose();
    if (widget.isUrlField) {
      widget.controller.removeListener(_onUrlChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            validator: widget.validator,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              counterText: '',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  widget.icon,
                  color: _isFocused ? AppTheme.primaryLight : AppTheme.textHint,
                  size: 20,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: widget.isUrlField && widget.controller.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        _urlValid
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _urlValid
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 18,
                      ),
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              filled: true,
              fillColor: _isFocused
                  ? AppTheme.primaryColor.withValues(alpha: 0.04)
                  : AppTheme.bgCardLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.errorColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.errorColor, width: 1.8),
              ),
              labelStyle: TextStyle(
                color: _isFocused ? AppTheme.primaryLight : AppTheme.textSecondary,
                fontSize: 14,
              ),
              hintStyle:
                  const TextStyle(color: AppTheme.textHint, fontSize: 14),
            ),
          ),
          if (widget.showCounter && widget.maxLength != null) ...[
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (ctx, child) {
                final len = widget.controller.text.length;
                final max = widget.maxLength!;
                final nearLimit = len > max * 0.85;
                return Text(
                  '$len / $max',
                  style: TextStyle(
                    color: nearLimit ? const Color(0xFFF59E0B) : AppTheme.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Image picker section ────────────────────────────────────────────────────
class ImagePickerSection extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const ImagePickerSection({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (_, i) => ImageThumb(
                file: images[i],
                onRemove: () => onRemove(i),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _PickerDropZone(
          imageCount: images.length,
          onTap: onAdd,
        ),
      ],
    );
  }
}

// ─── Picker drop zone (animated) ─────────────────────────────────────────────
class _PickerDropZone extends StatefulWidget {
  final int imageCount;
  final VoidCallback onTap;

  const _PickerDropZone({required this.imageCount, required this.onTap});

  @override
  State<_PickerDropZone> createState() => _PickerDropZoneState();
}

class _PickerDropZoneState extends State<_PickerDropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor
                .withValues(alpha: 0.04 + _pulse.value * 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor
                  .withValues(alpha: 0.25 + _pulse.value * 0.2),
              width: 1.6,
            ),
          ),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                      AppTheme.primaryColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.primaryLight, size: 24),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.imageCount == 0
                    ? 'Tap to pick screenshots'
                    : '+ Add more  •  ${widget.imageCount} selected',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.imageCount == 0) ...[
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG up to 10 MB each',
                  style: TextStyle(
                    color: AppTheme.textHint.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single image thumbnail ───────────────────────────────────────────────────
class ImageThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const ImageThumb({super.key, required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.file(
              file,
              width: 108,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Submit button ────────────────────────────────────────────────────────────
class SubmitButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const SubmitButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppTheme.primaryGradient,
          color: isLoading ? AppTheme.bgCard : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryLight),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loadingLabel,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

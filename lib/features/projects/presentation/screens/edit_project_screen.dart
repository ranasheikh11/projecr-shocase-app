import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import 'form_widgets.dart';

class EditProjectScreen extends StatelessWidget {
  final ProjectEntity project;

  const EditProjectScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectUpdated) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Changes saved!',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        } else if (state is ProjectError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: _EditForm(project: project),
    );
  }
}

class _EditForm extends StatefulWidget {
  final ProjectEntity project;

  const _EditForm({required this.project});

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _detailsCtrl;
  late final TextEditingController _playStoreCtrl;
  late final TextEditingController _appStoreCtrl;
  late final TextEditingController _githubCtrl;
  final List<File> _newImages = [];
  final _picker = ImagePicker();

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _detailsCtrl = TextEditingController(text: widget.project.details);
    _playStoreCtrl =
        TextEditingController(text: widget.project.googlePlayStore);
    _appStoreCtrl = TextEditingController(text: widget.project.appleAppStore);
    _githubCtrl = TextEditingController(text: widget.project.github);

    // Listen for changes
    for (final c in [
      _nameCtrl,
      _detailsCtrl,
      _playStoreCtrl,
      _appStoreCtrl,
      _githubCtrl
    ]) {
      c.addListener(_checkChanges);
    }
  }

  void _checkChanges() {
    final changed = _nameCtrl.text != widget.project.name ||
        _detailsCtrl.text != widget.project.details ||
        _playStoreCtrl.text != widget.project.googlePlayStore ||
        _appStoreCtrl.text != widget.project.appleAppStore ||
        _githubCtrl.text != widget.project.github ||
        _newImages.isNotEmpty;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _detailsCtrl,
      _playStoreCtrl,
      _appStoreCtrl,
      _githubCtrl
    ]) {
      c.removeListener(_checkChanges);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() {
        _newImages.addAll(files.map((f) => File(f.path)));
        _checkChanges();
      });
      HapticFeedback.selectionClick();
    }
  }

  void _removeNewImage(int i) {
    HapticFeedback.lightImpact();
    setState(() {
      _newImages.removeAt(i);
      _checkChanges();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<ProjectBloc>().add(
          UpdateProjectEvent(
            id: widget.project.id,
            name: _nameCtrl.text.trim(),
            details: _detailsCtrl.text.trim(),
            googlePlayStore: _playStoreCtrl.text.trim(),
            appleAppStore: _appStoreCtrl.text.trim(),
            github: _githubCtrl.text.trim(),
            newImages: _newImages.isNotEmpty ? _newImages : null,
          ),
        );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    HapticFeedback.lightImpact();
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 10),
            Text('Discard changes?',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
          ],
        ),
        content: const Text(
          "You have unsaved edits. If you go back now, your changes will be lost.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing',
                style: TextStyle(color: AppTheme.primaryLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Discard',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: buildFormAppBar(
          context,
          'Edit Project',
          hasUnsavedChanges: _hasChanges,
          onBackOverride: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) Navigator.pop(context);
          },
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              // ── ID + Meta ──────────────────────────────────────────
              _IdBadge(
                id: widget.project.id,
                updatedAt: widget.project.updatedAt,
              ),
              const SizedBox(height: 28),

              // ── Project Info ───────────────────────────────────────
              FormSectionHeader(
                icon: Icons.edit_note_rounded,
                title: 'Project Info',
                subtitle: 'Update the name or description',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameCtrl,
                label: 'Project Name',
                hint: 'e.g. Sable Dreams App',
                icon: Icons.title_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _detailsCtrl,
                label: 'Description',
                hint: 'What does this project do?',
                icon: Icons.notes_rounded,
                maxLines: 5,
                maxLength: 500,
                showCounter: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Description is required'
                        : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // ── Links ──────────────────────────────────────────────
              FormSectionHeader(
                icon: Icons.link_rounded,
                title: 'Store & Repo Links',
                subtitle: 'Update any store or repository links',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _playStoreCtrl,
                label: 'Google Play Store',
                hint: 'https://play.google.com/...',
                icon: Icons.shop_rounded,
                keyboardType: TextInputType.url,
                isUrlField: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _appStoreCtrl,
                label: 'Apple App Store',
                hint: 'https://apps.apple.com/...',
                icon: Icons.apple_rounded,
                keyboardType: TextInputType.url,
                isUrlField: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _githubCtrl,
                label: 'GitHub Repository',
                hint: 'https://github.com/username/repo',
                icon: Icons.code_rounded,
                keyboardType: TextInputType.url,
                isUrlField: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // ── Current Images ─────────────────────────────────────
              if (widget.project.images.isNotEmpty) ...[
                FormSectionHeader(
                  icon: Icons.photo_library_rounded,
                  title: 'Current Images',
                  subtitle: 'These are live in your portfolio',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 128,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.project.images.length,
                    itemBuilder: (_, i) => _ExistingImageThumb(
                      url: widget.project.images[i],
                      index: i + 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Info banner about replacement
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                          size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Uploading new images will replace all current ones.',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── New Images ─────────────────────────────────────────
              FormSectionHeader(
                icon: Icons.upload_rounded,
                title: widget.project.images.isEmpty
                    ? 'Project Images'
                    : 'Upload New Images',
                subtitle: widget.project.images.isEmpty
                    ? 'Upload at least one screenshot'
                    : 'Optional — skip to keep existing images',
              ),
              const SizedBox(height: 14),

              if (_newImages.isNotEmpty) ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    itemBuilder: (_, i) => ImageThumb(
                      file: _newImages[i],
                      onRemove: () => _removeNewImage(i),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.upload_rounded,
                                color: AppTheme.primaryLight, size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _newImages.isEmpty
                              ? 'Tap to upload new images'
                              : '${_newImages.length} new image(s)  •  Tap to add more',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              BlocBuilder<ProjectBloc, ProjectState>(
                builder: (context, state) {
                  return SubmitButton(
                    label: 'Save Changes',
                    loadingLabel: 'Saving...',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: state is ProjectActionLoading,
                    onTap: _submit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ID badge with last-edited date ──────────────────────────────────────────
class _IdBadge extends StatelessWidget {
  final String id;
  final DateTime updatedAt;

  const _IdBadge({required this.id, required this.updatedAt});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: const Center(
              child: Icon(Icons.tag_rounded, color: AppTheme.textHint, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROJECT ID',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  id,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'LAST EDITED',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(updatedAt),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Existing image thumbnail (read-only, live badge) ────────────────────────
class _ExistingImageThumb extends StatelessWidget {
  final String url;
  final int index;

  const _ExistingImageThumb({required this.url, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 108,
              height: 128,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(
                width: 108,
                height: 128,
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryLight),
                  ),
                ),
              ),
              errorWidget: (ctx, url, err) => Container(
                width: 108,
                height: 128,
                color: AppTheme.bgCardLight,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppTheme.textHint),
                ),
              ),
            ),
          ),
          // Dark gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(13)),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Index badge
          Positioned(
            bottom: 7,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // "Live" badge
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Live',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

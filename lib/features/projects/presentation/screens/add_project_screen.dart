import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import 'form_widgets.dart';

class AddProjectScreen extends StatelessWidget {
  const AddProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectCreated) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Project published to your portfolio!',
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
      child: const _AddProjectForm(),
    );
  }
}

class _AddProjectForm extends StatefulWidget {
  const _AddProjectForm();

  @override
  State<_AddProjectForm> createState() => _AddProjectFormState();
}

class _AddProjectFormState extends State<_AddProjectForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _playStoreCtrl = TextEditingController();
  final _appStoreCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final List<File> _images = [];
  final _picker = ImagePicker();

  late final List<AnimationController> _sectionCtrl;
  late final List<Animation<Offset>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    // 4 sections: Info, Links, Images, Button
    _sectionCtrl = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _slideAnims = _sectionCtrl
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _fadeAnims = _sectionCtrl
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();

    // Staggered entry — each section 110ms after the previous
    for (int i = 0; i < _sectionCtrl.length; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 110), () {
        if (mounted) _sectionCtrl[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _detailsCtrl.dispose();
    _playStoreCtrl.dispose();
    _appStoreCtrl.dispose();
    _githubCtrl.dispose();
    for (final c in _sectionCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() => _images.addAll(files.map((f) => File(f.path))));
      HapticFeedback.selectionClick();
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() => _images.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }
    if (_images.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Please add at least one screenshot',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<ProjectBloc>().add(
          CreateProjectEvent(
            name: _nameCtrl.text.trim(),
            details: _detailsCtrl.text.trim(),
            googlePlayStore: _playStoreCtrl.text.trim(),
            appleAppStore: _appStoreCtrl.text.trim(),
            github: _githubCtrl.text.trim(),
            images: _images,
          ),
        );
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: buildFormAppBar(context, 'New Project'),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Progress stepper ─────────────────────────────────────
            _animated(0, const _StepProgressBar()),
            const SizedBox(height: 28),

            // ── Project Info ──────────────────────────────────────────
            _animated(
              0,
              FormSectionHeader(
                icon: Icons.edit_note_rounded,
                title: 'Project Info',
                subtitle: 'Give your project a name and a good description',
              ),
            ),
            const SizedBox(height: 16),
            _animated(
              0,
              AppTextField(
                controller: _nameCtrl,
                label: 'Project Name',
                hint: 'e.g. Sable Dreams App',
                icon: Icons.title_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              0,
              AppTextField(
                controller: _detailsCtrl,
                label: 'Description',
                hint: 'What does this project do? Who is it for?',
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
            ),
            const SizedBox(height: 32),

            // ── Links ─────────────────────────────────────────────────
            _animated(
              1,
              FormSectionHeader(
                icon: Icons.link_rounded,
                title: 'Store & Repo Links',
                subtitle: 'At least one link helps recruiters find your work',
              ),
            ),
            const SizedBox(height: 16),
            _animated(
              1,
              AppTextField(
                controller: _playStoreCtrl,
                label: 'Google Play Store',
                hint: 'https://play.google.com/...',
                icon: Icons.shop_rounded,
                keyboardType: TextInputType.url,
                isUrlField: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              1,
              AppTextField(
                controller: _appStoreCtrl,
                label: 'Apple App Store',
                hint: 'https://apps.apple.com/...',
                icon: Icons.apple_rounded,
                keyboardType: TextInputType.url,
                isUrlField: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              1,
              AppTextField(
                controller: _githubCtrl,
                label: 'GitHub Repository',
                hint: 'https://github.com/username/repo',
                icon: Icons.code_rounded,
                keyboardType: TextInputType.url,
                isUrlField: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 32),

            // ── Images ────────────────────────────────────────────────
            _animated(
              2,
              FormSectionHeader(
                icon: Icons.photo_library_rounded,
                title: 'Screenshots',
                subtitle: 'Upload at least one screenshot — more is better!',
              ),
            ),
            const SizedBox(height: 16),
            _animated(
              2,
              ImagePickerSection(
                images: _images,
                onAdd: _pickImages,
                onRemove: _removeImage,
              ),
            ),
            const SizedBox(height: 28),

            // ── Warm hint ─────────────────────────────────────────────
            _animated(
              3,
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.primaryLight.withValues(alpha: 0.8),
                        size: 16),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your project will appear in your portfolio right away after publishing.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Submit ────────────────────────────────────────────────
            _animated(
              3,
              BlocBuilder<ProjectBloc, ProjectState>(
                builder: (context, state) {
                  return SubmitButton(
                    label: 'Publish to Portfolio',
                    loadingLabel: 'Publishing...',
                    icon: Icons.rocket_launch_rounded,
                    isLoading: state is ProjectActionLoading,
                    onTap: _submit,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step progress bar ────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.edit_note_rounded, 'Info'),
      (Icons.link_rounded, 'Links'),
      (Icons.photo_library_rounded, 'Images'),
      (Icons.rocket_launch_rounded, 'Publish'),
    ];
    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(step.$1, color: Colors.white, size: 15),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      step.$2,
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.5),
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

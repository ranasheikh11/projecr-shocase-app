import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import 'edit_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectEntity project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.72);
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectDeleted) {
          _showSnack(context, 'Project deleted', isError: false);
          Navigator.of(context).pop();
        } else if (state is ProjectError) {
          _showSnack(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  // ─── Slim pinned app bar ───────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.bgDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 15),
          ),
        ),
      ),
      title: Text(
        widget.project.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Edit
        Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProjectScreen(project: widget.project),
                ),
              );
              if (context.mounted) {
                context.read<ProjectBloc>().add(const LoadAllProjectsEvent());
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: const Icon(Icons.edit_rounded,
                  color: AppTheme.textSecondary, size: 16),
            ),
          ),
        ),
        // Delete
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showDeleteDialog(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorColor, size: 16),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.dividerColor),
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Phone mockup carousel ──────────────────────────────────────────
        if (widget.project.images.isNotEmpty) ...[
          _PhoneMockupCarousel(
            images: widget.project.images,
            pageController: _pageController,
            currentIndex: _currentImageIndex,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
          ),
        ] else
          _NoImagePlaceholder(),

        // ── Content ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.project.name,
                style:
                    Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
              ),

              const SizedBox(height: 28),

              // ── About ─────────────────────────────────────────────────
              _SectionCard(
                icon: Icons.notes_rounded,
                title: 'About',
                child: Text(
                  widget.project.details,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.7,
                        fontSize: 15,
                      ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Links ──────────────────────────────────────────────────
              if (widget.project.googlePlayStore.isNotEmpty ||
                  widget.project.appleAppStore.isNotEmpty ||
                  widget.project.github.isNotEmpty)
                _SectionCard(
                  icon: Icons.link_rounded,
                  title: 'Links',
                  child: Column(
                    children: [
                      if (widget.project.googlePlayStore.isNotEmpty)
                        _LinkRow(
                          icon: Icons.shop_rounded,
                          label: 'Google Play Store',
                          url: widget.project.googlePlayStore,
                          color: AppTheme.successColor,
                        ),
                      if (widget.project.appleAppStore.isNotEmpty)
                        _LinkRow(
                          icon: Icons.apple_rounded,
                          label: 'Apple App Store',
                          url: widget.project.appleAppStore,
                          color: const Color(0xFF60A5FA),
                        ),
                      if (widget.project.github.isNotEmpty)
                        _LinkRow(
                          icon: Icons.code_rounded,
                          label: 'GitHub Repository',
                          url: widget.project.github,
                          color: AppTheme.secondaryColor,
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // ── Details ────────────────────────────────────────────────
              _SectionCard(
                icon: Icons.info_outline_rounded,
                title: 'Project Details',
                child: Column(
                  children: [
                    _MetaRow(
                        label: 'Project ID', value: widget.project.id),
                    const SizedBox(height: 10),
                    _MetaRow(
                        label: 'Created',
                        value: _formatDate(widget.project.createdAt)),
                    const SizedBox(height: 10),
                    _MetaRow(
                        label: 'Last Updated',
                        value: _formatDate(widget.project.updatedAt)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Action buttons ─────────────────────────────────────────
              BlocBuilder<ProjectBloc, ProjectState>(
                builder: (context, state) {
                  final isLoading = state is ProjectActionLoading;
                  return Row(
                    children: [
                      Expanded(
                        child: _OutlineBtn(
                          onTap: isLoading
                              ? null
                              : () => _showDeleteDialog(context),
                          label: 'Delete',
                          icon: Icons.delete_outline_rounded,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: _GradientBtn(
                          onTap: isLoading
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProjectScreen(
                                          project: widget.project),
                                    ),
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<ProjectBloc>()
                                        .add(const LoadAllProjectsEvent());
                                  }
                                },
                          label: 'Edit Project',
                          icon: Icons.edit_rounded,
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.6)),
        ),
        title: const Text('Delete Project'),
        content: Text(
            'Are you sure you want to delete "${widget.project.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              context
                  .read<ProjectBloc>()
                  .add(DeleteProjectEvent(widget.project.id));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ════════════════════════════════════════════════════════════════════
//  PHONE MOCKUP CAROUSEL
// ════════════════════════════════════════════════════════════════════
class _PhoneMockupCarousel extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _PhoneMockupCarousel({
    required this.images,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D18),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // ── Swipe hint ──────────────────────────────────────────────
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_rounded,
                      color: AppTheme.textHint.withValues(alpha: 0.6),
                      size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe to browse  •  ${images.length} screenshots',
                    style: TextStyle(
                      color: AppTheme.textHint.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

          // ── Phone frames ────────────────────────────────────────────
          SizedBox(
            height: 480,
            child: PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (_, index) {
                final isActive = index == currentIndex;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _PhoneFrame(imageUrl: images[index]),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Dot indicators ───────────────────────────────────────────
          if (images.length > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.primaryLight
                        : AppTheme.textHint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 24),

          // ── Bottom fade divider into content ──────────────────────────
          Container(
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D0D18),
                  AppTheme.bgDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single phone frame widget ───────────────────────────────────────────────
class _PhoneFrame extends StatelessWidget {
  final String imageUrl;

  const _PhoneFrame({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 210,
        height: 440,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF3A3A5C),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            children: [
              // Screenshot — full image, no crop
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFF13131A),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF13131A),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppTheme.textHint, size: 32),
                  ),
                ),
              ),

              // Top notch bar (decorative — makes it look like a real phone)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── No image placeholder ────────────────────────────────────────────────────
class _NoImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: const Color(0xFF0D0D18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android_rounded,
                color: AppTheme.textHint.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 10),
            Text(
              'No screenshots uploaded',
              style: TextStyle(
                color: AppTheme.textHint.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child:
                    Center(child: Icon(icon, color: AppTheme.primaryLight, size: 16)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppTheme.dividerColor.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Link row ────────────────────────────────────────────────────────────────
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Icon(icon, color: color, size: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(url,
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded,
              color: color.withValues(alpha: 0.7), size: 16),
        ],
      ),
    );
  }
}

// ─── Meta row ────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style:
                  const TextStyle(color: AppTheme.textHint, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─── Outline button ──────────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final IconData icon;
  final Color color;

  const _OutlineBtn({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient button ─────────────────────────────────────────────────────────
class _GradientBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final IconData? icon;
  final bool isLoading;

  const _GradientBtn({
    required this.onTap,
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: onTap != null ? AppTheme.primaryGradient : null,
          color: onTap == null ? AppTheme.bgCard : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else if (icon != null)
              Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

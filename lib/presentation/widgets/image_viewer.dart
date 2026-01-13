import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/ui_util.dart';
import '../theme/app_dimens.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const ImageViewer({super.key, required this.imageUrl, required this.heroTag});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController =
        AnimationController(vsync: this, duration: AppDimens.durationFast)
          ..addListener(() {
            _transformationController.value = _animation!.value;
          });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _zoom(bool zoomIn) {
    final double scale = zoomIn ? 1.5 : 0.8;
    final Matrix4 matrix = _transformationController.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * scale).clamp(1.0, 4.0);

    if (currentScale == targetScale) return;

    final Matrix4 endMatrix = Matrix4.diagonal3Values(
      targetScale,
      targetScale,
      targetScale,
    );
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.primary,
      body: Stack(
        children: [
          Center(
            child: RepaintBoundary(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.heroTag,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    memCacheHeight: UiUtil.cacheSize(context, context.height),
                    placeholder: (context, url) => const SizedBox.shrink(),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image,
                      color: colors.onPrimary,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppDimens.viewerButtonMargin,
            right: AppDimens.viewerButtonRight,
            child: _ViewerButton(icon: Icons.close, onTap: () => context.pop()),
          ),
          Positioned(
            bottom: AppDimens.viewerButtonMargin,
            left: AppDimens.zero,
            right: AppDimens.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ViewerButton(
                  icon: Icons.remove,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _zoom(false);
                  },
                ),
                const SizedBox(width: AppDimens.lg),
                _ViewerButton(
                  icon: Icons.add,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _zoom(true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ViewerButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.onPrimary.withValues(alpha: AppDimens.opacityLow),
      borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
      elevation: AppDimens.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.sm),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: colors.onPrimary, size: AppDimens.iconXxl),
        ),
      ),
    );
  }
}

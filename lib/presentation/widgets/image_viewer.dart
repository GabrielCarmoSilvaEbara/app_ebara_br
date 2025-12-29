import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

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
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
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
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              child: Hero(
                tag: widget.heroTag,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: _buildButton(
              icon: Icons.close,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  icon: Icons.remove,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _zoom(false);
                  },
                ),
                const SizedBox(width: 20),
                _buildButton(
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

  Widget _buildButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

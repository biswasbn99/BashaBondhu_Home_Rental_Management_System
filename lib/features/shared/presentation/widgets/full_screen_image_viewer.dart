import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import 'app_network_image.dart';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title,
  });

  final List<String> images;
  final int initialIndex;
  final String? title;

  static void show(BuildContext context, {required List<String> images, int initialIndex = 0, String? title}) {
    if (images.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (ctx, anim1, anim2) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          title: title,
        ),
        transitionsBuilder: (ctx, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int _currentIndex;
  late PageController _pageController;
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.identity()
        ..setEntry(0, 0, 2.5)
        ..setEntry(1, 1, 2.5)
        ..setEntry(0, 3, -position.dx * 1.5)
        ..setEntry(1, 3, -position.dy * 1.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';
    final total = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.96),
      body: SafeArea(
        child: Stack(
          children: [
            // --- Center Image Viewer with Pinch / Double-Tap Zoom ---
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _transformationController.value = Matrix4.identity();
                });
              },
              itemBuilder: (context, index) {
                final imageSource = widget.images[index];
                return GestureDetector(
                  onDoubleTapDown: (details) => _doubleTapDetails = details,
                  onDoubleTap: _handleDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.8,
                    maxScale: 4.5,
                    panEnabled: true,
                    scaleEnabled: true,
                    clipBehavior: Clip.none,
                    child: Center(
                      child: AppImageWidget(
                        imageSource: imageSource,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: null,
                        cacheHeight: null,
                      ),
                    ),
                  ),
                );
              },
            ),

            // --- Top App Bar ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    Material(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),

                    // Title & Counter
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentIndex == 0
                                ? (isBn ? 'প্রধান টেমপ্লেট ছবি' : 'Main Template Photo')
                                : (isBn
                                    ? 'অতিরিক্ত ছবি #${_currentIndex.toString().toLocalizedDigits("bn")}'
                                    : 'Additional Photo #$_currentIndex'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.themeColor),
                              const SizedBox(width: 4),
                              Text(
                                isBn ? 'জুম ইন/আউট করুন' : 'Pinch / Double-Tap to Zoom',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Page Badge Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(_currentIndex + 1).toLocalizedDigits(languageCode)} / ${total.toLocalizedDigits(languageCode)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Bottom Thumbnail Navigation Strip (if multiple photos) ---
            if (total > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 60,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: total,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final isSelected = idx == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 60 : 50,
                          height: isSelected ? 60 : 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.themeColor : Colors.white24,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppImageWidget(
                              imageSource: widget.images[idx],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

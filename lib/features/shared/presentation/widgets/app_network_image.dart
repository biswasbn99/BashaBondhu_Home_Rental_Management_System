import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';

class AppImageWidget extends StatelessWidget {
  const AppImageWidget({
    super.key,
    required this.imageSource,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIconSize = 48,
    this.cacheWidth = 200,
    this.cacheHeight = 200,
  });

  final dynamic imageSource; // String (URL, base64, path) or File or null
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double placeholderIconSize;
  final int? cacheWidth;
  final int? cacheHeight;

  static final Map<String, Uint8List> _base64Cache = {};

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildRawImage(context);

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }

  Widget _buildRawImage(BuildContext context) {
    if (imageSource == null) {
      return _buildPlaceholder(context);
    }

    if (imageSource is File) {
      return Image.file(
        imageSource as File,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
      );
    }

    if (imageSource is String) {
      final str = (imageSource as String).trim();
      if (str.isEmpty) return _buildPlaceholder(context);

      // Base64 Data URI or Raw Base64
      if (str.startsWith('data:image') || str.startsWith('/9j/') || str.startsWith('iVBOR') || str.length > 255) {
        try {
          // Fast key using length + substring prefix to avoid hashing megabytes
          final cacheKey = "${str.length}_${str.substring(0, str.length > 40 ? 40 : str.length)}";
          final Uint8List bytes = _base64Cache.putIfAbsent(cacheKey, () {
            final base64Content = str.contains(',') ? str.split(',').last : str;
            return base64Decode(base64Content.trim());
          });

          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            gaplessPlayback: true,
            errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
          );
        } catch (_) {
          return _buildPlaceholder(context);
        }
      }

      // Network URL
      if (str.startsWith('http://') || str.startsWith('https://')) {
        return Image.network(
          str,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          gaplessPlayback: true,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: AppColors.themeColor,
                ),
              ),
            );
          },
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
        );
      }

      // Local File Path (only if valid short path)
      if (str.length <= 255 && !kIsWeb) {
        try {
          final cleanPath = str.replaceFirst('file://', '');
          final file = File(cleanPath);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: fit,
              width: width,
              height: height,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              gaplessPlayback: true,
              errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
            );
          }
        } catch (_) {}
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? Colors.grey[850] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: placeholderIconSize,
          color: Colors.grey,
        ),
      ),
    );
  }
}

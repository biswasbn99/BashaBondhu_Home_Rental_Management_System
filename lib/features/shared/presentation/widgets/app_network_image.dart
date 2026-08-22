import 'dart:convert';
import 'dart:io';
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
  });

  final dynamic imageSource; // String (URL, base64, path) or File or null
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double placeholderIconSize;

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
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
      );
    }

    if (imageSource is String) {
      final str = (imageSource as String).trim();
      if (str.isEmpty) return _buildPlaceholder(context);

      // Base64 Data URI
      if (str.startsWith('data:image')) {
        try {
          final base64Content = str.split(',').last;
          final bytes = base64Decode(base64Content);
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
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
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.themeColor,
              ),
            );
          },
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
        );
      }

      // Local File Path
      try {
        final cleanPath = str.replaceFirst('file://', '');
        final file = File(cleanPath);
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
        );
      } catch (_) {
        return _buildPlaceholder(context);
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


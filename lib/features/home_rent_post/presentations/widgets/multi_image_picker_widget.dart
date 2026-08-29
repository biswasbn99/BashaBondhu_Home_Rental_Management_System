import 'dart:io';
import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MultiImagePickerWidget extends StatelessWidget {
  const MultiImagePickerWidget({
    super.key,
    required this.images,
    required this.onImageAdded,
    this.onMultipleImagesAdded,
    this.onThumbnailSet,
    this.onImageReplaced,
    required this.onImageRemoved,
  });

  final List<File> images;
  final Function(File) onImageAdded;
  final Function(List<File>)? onMultipleImagesAdded;
  final Function(File)? onThumbnailSet;
  final Function(int, File)? onImageReplaced;
  final Function(int) onImageRemoved;

  static const int maxTotalImages = 10;
  static const int maxAdditionalImages = 9;

  Future<void> _pickImage(BuildContext context, {bool isThumbnail = false, int? replaceIndex}) async {
    final picker = ImagePicker();
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isThumbnail ? l10n.mainThumbnailTitle : l10n.additionalPhotosTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isThumbnail ? l10n.mainThumbnailSubtitle : l10n.additionalPhotosSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.themeColor),
                ),
                title: Text(
                  l10n.galleryOption,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isThumbnail) {
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 70,
                    );
                    if (pickedFile != null) {
                      if (onThumbnailSet != null) {
                        onThumbnailSet!(File(pickedFile.path));
                      } else {
                        onImageAdded(File(pickedFile.path));
                      }
                    }
                  } else if (replaceIndex != null) {
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 70,
                    );
                    if (pickedFile != null && onImageReplaced != null) {
                      onImageReplaced!(replaceIndex, File(pickedFile.path));
                    }
                  } else {
                    final pickedFiles = await picker.pickMultiImage(
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 70,
                      limit: maxTotalImages - images.length,
                    );
                    if (pickedFiles.isNotEmpty) {
                      if (onMultipleImagesAdded != null) {
                        onMultipleImagesAdded!(pickedFiles.map((x) => File(x.path)).toList());
                      } else {
                        for (final x in pickedFiles) {
                          onImageAdded(File(x.path));
                        }
                      }
                    }
                  }
                },
              ),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.orange),
                ),
                title: Text(
                  l10n.cameraOption,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                onTap: () async {
                  Navigator.pop(ctx);
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    if (isThumbnail) {
                      if (onThumbnailSet != null) {
                        onThumbnailSet!(File(pickedFile.path));
                      } else {
                        onImageAdded(File(pickedFile.path));
                      }
                    } else if (replaceIndex != null && onImageReplaced != null) {
                      onImageReplaced!(replaceIndex, File(pickedFile.path));
                    } else {
                      onImageAdded(File(pickedFile.path));
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasThumbnail = images.isNotEmpty;
    final thumbnailFile = hasThumbnail ? images.first : null;
    final additionalImages = images.length > 1 ? images.sublist(1) : <File>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header with Photo Count Badge ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.addPhotos,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: images.isEmpty
                    ? (isDark ? Colors.grey[800] : Colors.grey.withValues(alpha: 0.12))
                    : AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: images.isEmpty
                      ? (isDark ? Colors.grey[700]! : Colors.grey.withValues(alpha: 0.3))
                      : AppColors.themeColor.withValues(alpha: isDark ? 0.6 : 0.4),
                ),
              ),
              child: Text(
                '${images.length} / $maxTotalImages',
                style: TextStyle(
                  color: images.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : AppColors.themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // --- 1. MAIN THUMBNAIL FRAME (Top Prominent Card) ---
        if (!hasThumbnail)
          _MainThumbnailPlaceholder(
            onTap: () => _pickImage(context, isThumbnail: true),
            title: l10n.mainThumbnailTitle,
            subtitle: l10n.mainThumbnailSubtitle,
            isDark: isDark,
          )
        else
          _MainThumbnailPreview(
            file: thumbnailFile!,
            badgeLabel: l10n.mainThumbnailBadge,
            onChange: () => _pickImage(context, isThumbnail: true),
            onRemove: () => onImageRemoved(0),
          ),

        const SizedBox(height: 18),

        // --- 2. ADDITIONAL PHOTOS SECTION (Horizontal Slots) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.additionalPhotosTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${additionalImages.length} / $maxAdditionalImages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _buildAdditionalSlotsRow(context, additionalImages, isDark),
      ],
    );
  }

  Widget _buildAdditionalSlotsRow(BuildContext context, List<File> additionalImages, bool isDark) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: maxAdditionalImages,
        separatorBuilder: (c, i) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index < additionalImages.length) {
            // Filled slot
            final file = additionalImages[index];
            final actualMainIndex = index + 1;
            return _AdditionalImageSlot(
              file: file,
              slotIndex: index + 1,
              onTap: () => _pickImage(context, replaceIndex: actualMainIndex),
              onRemove: () => onImageRemoved(actualMainIndex),
            );
          } else if (index == additionalImages.length) {
            // Next active add slot
            return _AdditionalEmptySlot(
              isActive: true,
              isDark: isDark,
              onTap: () {
                if (images.isEmpty) {
                  _pickImage(context, isThumbnail: true);
                } else {
                  _pickImage(context, isThumbnail: false);
                }
              },
            );
          } else {
            // Subsequent placeholder slots
            return _AdditionalEmptySlot(
              isActive: false,
              isDark: isDark,
              onTap: () {
                if (images.isEmpty) {
                  _pickImage(context, isThumbnail: true);
                } else {
                  _pickImage(context, isThumbnail: false);
                }
              },
            );
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUB-WIDGETS: MAIN THUMBNAIL & ADDITIONAL PHOTO SLOTS
// -----------------------------------------------------------------------------

/// The Top Prominent Frame with dynamic Light & Dark mode styling
class _MainThumbnailPlaceholder extends StatelessWidget {
  const _MainThumbnailPlaceholder({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.themeColor.withValues(alpha: 0.12),
        highlightColor: AppColors.themeColor.withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          height: 195,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : AppColors.themeColor.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.themeColor.withValues(alpha: 0.85)
                  : AppColors.themeColor,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.themeColor.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular solid teal button matching the user's screenshot
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.themeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.5 : 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main Thumbnail image preview card when picked
class _MainThumbnailPreview extends StatelessWidget {
  const _MainThumbnailPreview({
    required this.file,
    required this.badgeLabel,
    required this.onChange,
    required this.onRemove,
  });

  final File file;
  final String badgeLabel;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 195,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.themeColor, width: 1.8),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),

        // Main Thumbnail Badge on Top-Left
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons on Top-Right (Change & Delete)
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              // Change Button
              GestureDetector(
                onTap: onChange,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// An empty additional photo slot with Light & Dark mode support
class _AdditionalEmptySlot extends StatelessWidget {
  const _AdditionalEmptySlot({
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.themeColor.withValues(alpha: 0.1),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : AppColors.themeColor.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? (isDark ? AppColors.themeColor : AppColors.themeColor.withValues(alpha: 0.75))
                  : (isDark ? AppColors.themeColor.withValues(alpha: 0.45) : AppColors.themeColor.withValues(alpha: 0.35)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.themeColor
                    : AppColors.themeColor.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeColor.withValues(alpha: isDark ? 0.4 : 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled additional photo slot preview
class _AdditionalImageSlot extends StatelessWidget {
  const _AdditionalImageSlot({
    required this.file,
    required this.slotIndex,
    required this.onTap,
    required this.onRemove,
  });

  final File file;
  final int slotIndex;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.themeColor, width: 1.5),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),

        // Index tag on bottom-left
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$slotIndex',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),

        // Delete button on top-right
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

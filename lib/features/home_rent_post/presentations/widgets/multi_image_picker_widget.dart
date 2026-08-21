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
    required this.onImageRemoved,
  });

  final List<File> images;
  final Function(File) onImageAdded;
  final Function(int) onImageRemoved;

  Future<void> _pickImage(BuildContext context) async {
    if (images.length >= 10) return;

    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.localizations.addPhotos,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListSourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              onTap: () async {
                Navigator.pop(ctx);
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (pickedFile != null) onImageAdded(File(pickedFile.path));
              },
            ),
            ListSourceTile(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              onTap: () async {
                Navigator.pop(ctx);
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (pickedFile != null) onImageAdded(File(pickedFile.path));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Text(
              '${images.length} / 10',
              style: TextStyle(
                color: images.length == 10 ? Colors.red : AppColors.themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // --- Thumbnail Slot ---
        if (images.isEmpty)
          _ThumbnailPlaceholder(
            onTap: () => _pickImage(context),
            hint: l10n.thumbnailHint,
          )
        else
          _ThumbnailPreview(
            file: images[0],
            onRemove: () => onImageRemoved(0),
            label: l10n.thumbnailLabel,
          ),
        
        const SizedBox(height: 12),

        // --- Additional Photos Row ---
        _buildAdditionalPhotosRow(context),
      ],
    );
  }

  Widget _buildAdditionalPhotosRow(BuildContext context) {
    final l10n = context.localizations;
    
    // Additional images are from index 1 onwards
    final additionalImages = images.length > 1 ? images.sublist(1) : <File>[];

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...additionalImages.asMap().entries.map((entry) {
            final idx = entry.key + 1; // Actual index in main list
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _SmallImageItem(
                file: entry.value,
                onRemove: () => onImageRemoved(idx),
              ),
            );
          }),
          if (images.isNotEmpty && images.length < 10)
            _AddSmallPlaceholder(
              onTap: () => _pickImage(context),
              hint: l10n.anotherPhotosHint,
            ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({required this.onTap, required this.hint});
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.themeColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.themeColor.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid, // Could be dashed if we had a painter
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.themeColor, size: 48),
            const SizedBox(height: 8),
            Text(
              hint,
              style: const TextStyle(
                color: AppColors.themeColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({required this.file, required this.onRemove, required this.label});
  final File file;
  final VoidCallback onRemove;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallImageItem extends StatelessWidget {
  const _SmallImageItem({required this.file, required this.onRemove});
  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddSmallPlaceholder extends StatelessWidget {
  const _AddSmallPlaceholder({required this.onTap, required this.hint});
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.themeColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.themeColor, size: 24),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.themeColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class ListSourceTile extends StatelessWidget {
  const ListSourceTile({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.themeColor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

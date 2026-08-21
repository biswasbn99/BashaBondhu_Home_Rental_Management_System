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
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListSourceTile(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: () async {
                Navigator.pop(ctx);
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) onImageAdded(File(pickedFile.path));
              },
            ),
            ListSourceTile(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: () async {
                Navigator.pop(ctx);
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) onImageAdded(File(pickedFile.path));
              },
            ),
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
        Text(
          l10n.photoSubtitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length < 10 ? images.length + 1 : 10,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == images.length && images.length < 10) {
                return _AddImagePlaceholder(onTap: () => _pickImage(context));
              }
              return _ImageItem(
                file: images[index],
                isThumbnail: index == 0,
                onRemove: () => onImageRemoved(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddImagePlaceholder extends StatelessWidget {
  const _AddImagePlaceholder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.themeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.themeColor, size: 30),
      ),
    );
  }
}

class _ImageItem extends StatelessWidget {
  const _ImageItem({required this.file, required this.isThumbnail, required this.onRemove});
  final File file;
  final bool isThumbnail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            border: isThumbnail ? Border.all(color: AppColors.themeColor, width: 2) : null,
          ),
        ),
        if (isThumbnail)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: const Text(
                'Thumbnail',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
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
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
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
      title: Text(label),
      onTap: onTap,
    );
  }
}

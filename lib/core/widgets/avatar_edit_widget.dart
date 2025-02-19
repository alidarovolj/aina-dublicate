import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/auth/profile.dart';
import 'dart:io';

class AvatarEditWidget extends ConsumerStatefulWidget {
  final String? avatarUrl;
  final Function(File) onAvatarPicked;
  final VoidCallback onAvatarRemoved;
  final bool isLoading;
  final File? temporaryImage;

  const AvatarEditWidget({
    super.key,
    this.avatarUrl,
    this.temporaryImage,
    required this.onAvatarPicked,
    required this.onAvatarRemoved,
    this.isLoading = false,
  });

  @override
  ConsumerState<AvatarEditWidget> createState() => _AvatarEditWidgetState();
}

class _AvatarEditWidgetState extends ConsumerState<AvatarEditWidget> {
  String? _currentAvatarUrl;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.avatarUrl;
    _localImage = widget.temporaryImage;
  }

  @override
  void didUpdateWidget(AvatarEditWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      if (oldWidget.avatarUrl != null) {
        imageCache.evict(NetworkImage(oldWidget.avatarUrl!));
      }
      setState(() {
        _currentAvatarUrl = widget.avatarUrl;
      });
    }
    if (oldWidget.temporaryImage != widget.temporaryImage) {
      setState(() {
        _localImage = widget.temporaryImage;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final imageFile = File(image.path);
      setState(() {
        _localImage = imageFile;
      });
      if (_currentAvatarUrl != null) {
        imageCache.evict(NetworkImage(_currentAvatarUrl!));
      }
      widget.onAvatarPicked(imageFile);
      ref.read(profileCacheKeyProvider.notifier).state++;
    }
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(_currentAvatarUrl != null || _localImage != null
                ? 'profile.settings.edit.change_avatar'.tr()
                : 'profile.settings.edit.add_avatar'.tr()),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
          if (_currentAvatarUrl != null || _localImage != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'profile.settings.edit.remove_avatar'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (_currentAvatarUrl != null) {
                  imageCache.evict(NetworkImage(_currentAvatarUrl!));
                }
                setState(() {
                  _localImage = null;
                  _currentAvatarUrl = null;
                });
                widget.onAvatarRemoved();
                ref.read(profileCacheKeyProvider.notifier).state++;
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : _showOptionsModal,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: _localImage == null && _currentAvatarUrl == null
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8DB9A), Color(0xFFCCB861)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _localImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _localImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : _currentAvatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$_currentAvatarUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                          fit: BoxFit.cover,
                          cacheWidth: null,
                          cacheHeight: null,
                          headers: {
                            'cache-control':
                                'no-cache, no-store, must-revalidate',
                            'pragma': 'no-cache',
                            'expires': '0',
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            if (error.toString().contains('404')) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              );
                            }
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
          ),
          if (widget.isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (!widget.isLoading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

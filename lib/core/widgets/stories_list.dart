import 'package:aina_flutter/core/types/stories_type.dart'
    show Story, StoryItem;
import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/stories_provider.dart';
import 'package:aina_flutter/core/providers/requests/stories/detail.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart'
    show CustomButton, ButtonType;
import 'package:aina_flutter/core/utils/button_navigation_handler.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class StoryList extends ConsumerStatefulWidget {
  const StoryList({super.key});

  @override
  ConsumerState<StoryList> createState() => _StoryListState();
}

class _StoryListState extends ConsumerState<StoryList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void markStoryAsRead(int index) {
    if (!mounted) return;

    try {
      final stories = ref.read(storiesProvider).valueOrNull;
      if (stories != null && index < stories.length) {
        setState(() {
          stories[index].read = true;
          // print("Story ${index + 1} marked as read");
        });
      }
    } catch (e) {
      print('❌ Ошибка при отметке истории как прочитанной: $e');
    }
  }

  void _handleStoryTap(int index, List<Story> storiesList) {
    if (!mounted) return;

    try {
      setState(() {
        _selectedIndex = index;
      });

      _animationController.forward().then((_) {
        if (!mounted) return;

        markStoryAsRead(index);
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: AppColors.primary.withOpacity(0.5),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return StoryDetailsPage(
              stories: storiesList,
              initialIndex: index,
              onStoryRead: (readIndex) {
                if (!mounted) return;
                markStoryAsRead(readIndex);
              },
            );
          },
        ).then((_) {
          // Reset animation when story view is closed
          if (!mounted) return;

          setState(() {
            _selectedIndex = null;
          });
          _animationController.reverse();
        });
      });
    } catch (e) {
      print('❌ Ошибка при открытии истории: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);

    return stories.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) {
        print('❌ Ошибка при загрузке историй: $error');

        // Проверяем, содержит ли ошибка код 500
        final is500Error = error.toString().contains('500') ||
            error.toString().contains('Internal Server Error');

        return Container(
          color: AppColors.primary,
          height: 120,
          width: double.infinity,
          child: SafeArea(
            child: Container(
              height: 100,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: ErrorRefreshWidget(
                onRefresh: () {
                  print('🔄 Обновление историй...');
                  // Используем Future.microtask для асинхронного обновления
                  Future.microtask(() async {
                    try {
                      ref.refresh(storiesProvider);
                    } catch (e) {
                      print('❌ Ошибка при обновлении историй: $e');
                    }
                  });
                },
                errorMessage: is500Error
                    ? 'stories.error.server'.tr()
                    : 'stories.error.loading'.tr(),
                refreshText: 'common.refresh'.tr(),
                isCompact: true,
                isServerError: true,
                backgroundColor: Colors.transparent,
                textColor: Colors.red.shade900,
                errorColor: Colors.red,
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ),
        );
      },
      data: (storiesList) {
        if (storiesList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Container(
              height: 120,
              padding: const EdgeInsets.symmetric(
                  vertical: AppLength.xs, horizontal: AppLength.xs),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: storiesList.length,
                itemBuilder: (context, index) {
                  final story = storiesList[index];
                  // print(
                  // 'Story $index: ${story.name}, ${story.previewImage}');
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: AppLength.four),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _handleStoryTap(index, storiesList),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final scale = _selectedIndex == index
                                  ? _scaleAnimation.value
                                  : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: story.read
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.network(
                                    story.previewImage ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.name ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(
              vertical: AppLength.xs, horizontal: AppLength.xs),
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: AppLength.four),
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[700]!,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class StoryDetailsPage extends ConsumerStatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(int) onStoryRead;

  const StoryDetailsPage({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryRead,
  });

  @override
  ConsumerState<StoryDetailsPage> createState() => _StoryDetailsPageState();
}

class _StoryDetailsPageState extends ConsumerState<StoryDetailsPage>
    with TickerProviderStateMixin {
  late int currentStoryIndex;
  late int currentInnerStoryIndex = 0;
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _transitionController;
  late Animation<Offset> _slideAnimation;
  bool _isForward = true;
  late List<StoryItem> currentStories = [];

  @override
  void initState() {
    super.initState();
    currentStoryIndex = widget.initialIndex;
    currentStories = widget.stories[currentStoryIndex].stories ?? [];
    _pageController = PageController(initialPage: 0);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          handleNextStory();
        }
      });

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOut,
    ));

    _markCurrentStoryAsRead();
    _progressController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStoryDetails();
    });
  }

  void _fetchStoryDetails() {
    final currentStory = currentStories[currentInnerStoryIndex];
    if (currentStory.id != null) {
      // Invalidate the previous state and fetch new details
      ref.invalidate(storyDetailProvider(currentStory.id!));
    }
  }

  void _markCurrentStoryAsRead() {
    if (!widget.stories[currentStoryIndex].read) {
      widget.onStoryRead(currentStoryIndex);
    }
  }

  Future<void> handleNextStory() async {
    if (currentInnerStoryIndex < currentStories.length - 1) {
      setState(() {
        currentInnerStoryIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _fetchStoryDetails();
      _progressController.reset();
      _progressController.forward();
    } else if (currentStoryIndex < widget.stories.length - 1) {
      _isForward = true;
      final nextStoryIndex = currentStoryIndex + 1;
      final nextStories = widget.stories[nextStoryIndex].stories ?? [];

      setState(() {
        currentStoryIndex = nextStoryIndex;
        currentStories = nextStories;
        currentInnerStoryIndex = 0;
      });

      _pageController.jumpToPage(0);
      _fetchStoryDetails();
      _markCurrentStoryAsRead();
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> handlePreviousStory() async {
    if (currentInnerStoryIndex > 0) {
      setState(() {
        currentInnerStoryIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _fetchStoryDetails();
      _progressController.reset();
      _progressController.forward();
    } else if (currentStoryIndex > 0) {
      _isForward = false;
      final prevStoryIndex = currentStoryIndex - 1;
      final prevStories = widget.stories[prevStoryIndex].stories ?? [];

      setState(() {
        currentStoryIndex = prevStoryIndex;
        currentStories = prevStories;
        currentInnerStoryIndex = prevStories.length - 1;
      });

      _pageController.jumpToPage(prevStories.length - 1);
      _fetchStoryDetails();
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentStory = currentStories[currentInnerStoryIndex];

    final storyDetails = ref.watch(
      storyDetailProvider(currentStory.id ?? -1),
    );

    final button = storyDetails.when(
      data: (data) => data?.button,
      loading: () => null,
      error: (error, stack) => null,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            itemCount: currentStories.length,
            itemBuilder: (context, index) {
              final story = currentStories[index];
              return GestureDetector(
                onTapDown: (details) {
                  _progressController.stop();
                  if (details.globalPosition.dx < screenWidth / 2) {
                    handlePreviousStory();
                  } else {
                    handleNextStory();
                  }
                },
                onTapUp: (details) {
                  _progressController.forward();
                },
                child: Container(
                  color: Colors.black,
                  child: Image.network(
                    story.previewImage ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error, color: Colors.white)),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: paddingTop + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    currentStories.length,
                    (index) => Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: ValueListenableBuilder<double>(
                          valueListenable: _progressController,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: index < currentInnerStoryIndex
                                  ? 1.0
                                  : (index == currentInnerStoryIndex
                                      ? value
                                      : 0.0),
                              backgroundColor: Colors.grey.withOpacity(0.5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            widget.stories[currentStoryIndex].previewImage ??
                                '',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.stories[currentStoryIndex].name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: paddingTop,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (button != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: CustomButton(
                button: button,
                type: ButtonType.bordered,
                isFullWidth: true,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.of(context).pop();
                  ButtonNavigationHandler.handleNavigation(
                      context, ref, button);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _transitionController.dispose();
    super.dispose();
  }
}

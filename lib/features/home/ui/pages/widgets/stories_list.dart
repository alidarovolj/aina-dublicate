import 'package:aina_flutter/shared/types/stories_type.dart'
    show Story, StoryItem;
import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/stories_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/shared/ui/blocks/error_refresh_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class StoryList extends ConsumerStatefulWidget {
  const StoryList({super.key});

  @override
  ConsumerState<StoryList> createState() => _StoryListState();
}

class _StoryListState extends ConsumerState<StoryList> {
  @override
  void initState() {
    super.initState();
  }

  void markStoryAsRead(int index) {
    final stories = ref.read(storiesProvider).valueOrNull;
    if (stories != null) {
      setState(() {
        stories[index].read = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);

    return stories.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) {
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
                  ref.refresh(storiesProvider);
                },
                errorMessage: is500Error
                    ? 'stories.error.server'.tr()
                    : 'stories.error.loading'.tr(),
                refreshText: 'common.refresh'.tr(),
                isCompact: true,
                isServerError: is500Error,
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

        return _buildStoriesList(storiesList);
      },
    );
  }

  Widget _buildStoriesList(List<Story> stories) {
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
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: AppLength.four),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        markStoryAsRead(index);
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: MaterialLocalizations.of(context)
                              .modalBarrierDismissLabel,
                          barrierColor: AppColors.primary.withOpacity(0.5),
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            return StoryDetailsPage(
                              stories: stories.map((story) => story).toList(),
                              initialIndex: index,
                              onStoryRead: (readIndex) {
                                markStoryAsRead(readIndex);
                              },
                            );
                          },
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
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
                        color: AppColors.white,
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

class StoryDetailsPage extends StatefulWidget {
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
  _StoryDetailsPageState createState() => _StoryDetailsPageState();
}

class _StoryDetailsPageState extends State<StoryDetailsPage>
    with SingleTickerProviderStateMixin {
  late int currentStoryIndex;
  late int currentInnerStoryIndex = 0;
  late PageController _pageController;
  late AnimationController _progressController;
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
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          handleNextStory();
        }
      });

    _markCurrentStoryAsRead();
    _progressController.forward();
  }

  void _markCurrentStoryAsRead() {
    if (!widget.stories[currentStoryIndex].read) {
      widget.onStoryRead(currentStoryIndex);
    }
  }

  void handleNextStory() {
    if (currentInnerStoryIndex < currentStories.length - 1) {
      // Move to next inner story
      setState(() {
        currentInnerStoryIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _progressController.forward();
    } else if (currentStoryIndex < widget.stories.length - 1) {
      // Move to next story set
      setState(() {
        currentStoryIndex++;
        currentInnerStoryIndex = 0;
        currentStories = widget.stories[currentStoryIndex].stories ?? [];
      });
      _markCurrentStoryAsRead();
      _progressController.reset();
      _progressController.forward();
    } else {
      // Close modal when all stories are viewed
      Navigator.of(context).pop();
    }
  }

  void handlePreviousStory() {
    if (currentInnerStoryIndex > 0) {
      // Move to previous inner story
      setState(() {
        currentInnerStoryIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _progressController.forward();
    } else if (currentStoryIndex > 0) {
      // Move to previous story set
      setState(() {
        currentStoryIndex--;
        currentStories = widget.stories[currentStoryIndex].stories ?? [];
        currentInnerStoryIndex = currentStories.length - 1;
      });
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: currentStories.length,
            onPageChanged: (index) {
              setState(() {
                currentInnerStoryIndex = index;
              });
              _progressController.reset();
              _progressController.forward();
            },
            itemBuilder: (context, index) {
              final story = currentStories[index];
              return GestureDetector(
                onTapDown: (details) {
                  _progressController.stop();
                  // Determine tap position
                  if (details.globalPosition.dx < screenWidth / 2) {
                    handlePreviousStory();
                  } else {
                    handleNextStory();
                  }
                },
                onTapUp: (details) {
                  _progressController.forward();
                },
                child: Image.network(
                  story.previewImage ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, color: Colors.white)),
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
                        child: LinearProgressIndicator(
                          value: index < currentInnerStoryIndex
                              ? 1.0
                              : (index == currentInnerStoryIndex
                                  ? _progressController.value
                                  : 0.0),
                          backgroundColor: Colors.grey.withOpacity(0.5),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

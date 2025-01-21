import 'package:aina_flutter/core/types/stories_type.dart'
    show Story, StoryItem;
import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/stories_provider.dart';

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
        debugPrint("Story ${index + 1} marked as read");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);

    // Debug prints
    debugPrint('Stories state: $stories');
    debugPrint('Stories value: ${stories.valueOrNull}');
    debugPrint('Stories length: ${stories.valueOrNull?.length}');

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: AppLength.xs),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (storiesList) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: storiesList.length,
          itemBuilder: (context, index) {
            final story = storiesList[index];
            debugPrint('Story $index: ${story.name}, ${story.previewImage}');
            return Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: AppLength.tiny),
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
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return StoryDetailsPage(
                            stories: stories.valueOrNull
                                    ?.map((story) => story)
                                    .toList() ??
                                [],
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
                              ? AppColors.textSecondary
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
      debugPrint("Story ${currentStoryIndex + 1} marked as read");
      widget.onStoryRead(currentStoryIndex);
    }
  }

  void handleNextStory() {
    if (currentInnerStoryIndex < currentStories.length - 1) {
      setState(() {
        currentInnerStoryIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;

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
                },
                onTapUp: (details) {
                  _progressController.forward();
                },
                onTap: handleNextStory,
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
            child: Row(
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

import 'package:aina_flutter/shared/types/stories_type.dart'
    show Story, StoryItem;
import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/stories_provider.dart';
import 'package:aina_flutter/app/providers/requests/stories/detail.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/widgets/custom_button.dart'
    show CustomButton, ButtonType;
import 'package:aina_flutter/shared/utils/button_navigation_handler.dart';
import 'package:aina_flutter/entities/error_refresh_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:ui' show ImageFilter;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' show pi, cos;

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

  void _logStoryClick() {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'story_click',
      eventProperties: {
        'Platform': platform,
      },
    );
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
      _logStoryClick();
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
          barrierColor: AppColors.primary.withAlpha(128),
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
      debugPrint('❌ Ошибка при открытии истории: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);

    return stories.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) {
        final is500Error = error.toString().contains('500') ||
            error.toString().contains('Internal Server Error');

        return ErrorRefreshWidget(
          height: 120,
          onRefresh: () {
            Future.microtask(() async {
              try {
                ref.refresh(storiesProvider);
              } catch (e) {
                debugPrint('❌ Ошибка при обновлении историй: $e');
              }
            });
          },
          errorMessage: is500Error
              ? 'stories.error.server'.tr()
              : 'stories.error.loading'.tr(),
          refreshText: 'common.refresh'.tr(),
          isCompact: true,
          isServerError: true,
          icon: Icons.warning_amber_rounded,
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
                vertical: AppLength.xs,
                horizontal: AppLength.xs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: storiesList.length,
                itemBuilder: (context, index) {
                  final story = storiesList[index];
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
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: story.read
                                      ? [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.8),
                                        ]
                                      : [
                                          AppColors.secondary,
                                          AppColors.secondary.withOpacity(0.8),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (story.read
                                            ? AppColors.primary
                                            : AppColors.secondary)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
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
            vertical: AppLength.xs,
            horizontal: AppLength.xs,
          ),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[700]!.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
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
  late PageController _groupPageController;
  late AnimationController _progressController;
  late AnimationController _uiAnimationController;
  late Animation<double> _uiFadeAnimation;
  late List<StoryItem> currentStories = [];
  final Map<int, Story?> _preloadedStories = {};

  // Добавляем переменные для отслеживания свайпа
  double _dragOffset = 0.0;
  bool _isDragging = false;

  // Добавляем контроллер для анимации куба
  late AnimationController _cubeController;
  late Animation<double> _cubeAnimation;
  bool _isAnimating = false;

  // Добавляем метод для расчета трансформации
  double _calculateScale() {
    // Начинаем уменьшать с 1.0 до 0.8
    return 1.0 + (_dragOffset.abs() / 1000).clamp(0.0, 0.2);
  }

  double _calculateOpacity() {
    // Уменьшаем прозрачность от 1.0 до 0.0
    return (1.0 - (_dragOffset.abs() / 400).clamp(0.0, 1.0));
  }

  @override
  void initState() {
    super.initState();
    currentStoryIndex = widget.initialIndex;
    currentStories = widget.stories[currentStoryIndex].stories ?? [];
    _pageController = PageController(initialPage: 0);
    _groupPageController = PageController(initialPage: currentStoryIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          handleNextStory();
        }
      });

    _uiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _uiFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: Curves.easeInOut,
    ));

    _markCurrentStoryAsRead();
    _progressController.forward();

    // Загружаем текущую историю сразу
    _loadCurrentStory();
    // Остальные истории загружаем в фоне
    _preloadRemainingStories();

    _cubeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _cubeAnimation = CurvedAnimation(
      parent: _cubeController,
      curve: Curves.easeInOut,
    );
  }

  void _markCurrentStoryAsRead() {
    if (!widget.stories[currentStoryIndex].read) {
      widget.onStoryRead(currentStoryIndex);
    }
  }

  Future<void> _loadCurrentStory() async {
    final currentStory = currentStories[currentInnerStoryIndex];
    if (currentStory.id != null) {
      final storyDetails =
          await ref.read(storyDetailProvider(currentStory.id!).future);
      if (mounted) {
        setState(() {
          _preloadedStories[currentStory.id!] = storyDetails;
        });
      }
    }
  }

  Future<void> _preloadRemainingStories() async {
    for (var story in widget.stories) {
      for (var innerStory in story.stories ?? []) {
        if (innerStory.id != null &&
            !_preloadedStories.containsKey(innerStory.id)) {
          final storyDetails =
              await ref.read(storyDetailProvider(innerStory.id!).future);
          if (mounted) {
            setState(() {
              _preloadedStories[innerStory.id!] = storyDetails;
            });
          }
        }
      }
    }
  }

  Widget _buildCubeItem(
      Widget child, bool isNext, Animation<double> animation) {
    final rotationY =
        isNext ? animation.value * -pi / 2 : animation.value * pi / 2;
    final opacity = cos(rotationY).abs();
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.003) // Добавляем перспективу
      ..rotateY(rotationY);

    return Transform(
      transform: transform,
      alignment: isNext ? Alignment.centerLeft : Alignment.centerRight,
      child: Opacity(
        opacity: opacity,
        child: child,
      ),
    );
  }

  Future<void> _animateCubeTransition(bool isNext) async {
    if (_isAnimating) return;
    _isAnimating = true;

    await _cubeController.forward();
    _cubeController.reset();
    _isAnimating = false;
  }

  // Модифицируем PageView.builder для основного контента
  Widget _buildPageView() {
    return AnimatedBuilder(
      animation: _cubeAnimation,
      builder: (context, child) {
        final groupStories = widget.stories[currentStoryIndex].stories ?? [];
        final currentStory = groupStories[currentInnerStoryIndex];

        Widget currentPage = _buildStoryContent(currentStory);
        Widget? nextPage;
        Widget? prevPage;

        if (currentInnerStoryIndex < groupStories.length - 1) {
          nextPage =
              _buildStoryContent(groupStories[currentInnerStoryIndex + 1]);
        }
        if (currentInnerStoryIndex > 0) {
          prevPage =
              _buildStoryContent(groupStories[currentInnerStoryIndex - 1]);
        }

        return Stack(
          children: [
            _buildCubeItem(currentPage, false, _cubeAnimation),
            if (nextPage != null)
              _buildCubeItem(nextPage, true, _cubeAnimation),
            if (prevPage != null)
              _buildCubeItem(prevPage, false, _cubeAnimation),
          ],
        );
      },
    );
  }

  // Модифицируем методы переключения историй
  Future<void> handleNextStory() async {
    if (currentInnerStoryIndex < currentStories.length - 1) {
      await _animateCubeTransition(true);
      setState(() {
        currentInnerStoryIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else if (currentStoryIndex < widget.stories.length - 1) {
      await _uiAnimationController.forward();

      final nextStoryIndex = currentStoryIndex + 1;
      final nextStories = widget.stories[nextStoryIndex].stories ?? [];

      // Check if the controller is attached before animating
      if (_groupPageController.hasClients) {
        await _groupPageController.animateToPage(
          nextStoryIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // If not attached, just update the state
        setState(() {
          currentStoryIndex = nextStoryIndex;
          currentStories = nextStories;
          currentInnerStoryIndex = 0;
        });
      }

      setState(() {
        currentStoryIndex = nextStoryIndex;
        currentStories = nextStories;
        currentInnerStoryIndex = 0;
      });

      // Предзагружаем первую историю в новой группе если она еще не загружена
      final nextStory = currentStories[0];
      if (nextStory.id != null &&
          !_preloadedStories.containsKey(nextStory.id)) {
        _loadCurrentStory();
      }

      _pageController = PageController(initialPage: 0);
      _markCurrentStoryAsRead();
      _progressController.reset();
      _progressController.forward();

      await _uiAnimationController.reverse();
    } else {
      context.pop();
    }
  }

  Future<void> handlePreviousStory() async {
    if (currentInnerStoryIndex > 0) {
      await _animateCubeTransition(false);
      setState(() {
        currentInnerStoryIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else if (currentStoryIndex > 0) {
      await _uiAnimationController.forward();

      final prevStoryIndex = currentStoryIndex - 1;
      final prevStories = widget.stories[prevStoryIndex].stories ?? [];

      await _groupPageController.animateToPage(
        prevStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        currentStoryIndex = prevStoryIndex;
        currentStories = prevStories;
        currentInnerStoryIndex = prevStories.length - 1;
      });

      _pageController = PageController(initialPage: prevStories.length - 1);
      _progressController.reset();
      _progressController.forward();

      await _uiAnimationController.reverse();
    }
  }

  Widget _buildStoryContent(StoryItem story) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Размытый фон для заполнения всего экрана
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                image: NetworkImage(story.previewImage ?? ''),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.15),
              ),
            ),
          ),
          // Основное изображение с отступами
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.03,
              ),
              child: Stack(
                children: [
                  // Основное изображение
                  Image.network(
                    story.previewImage ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error, color: Colors.white)),
                  ),
                  // Размытие по краям
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Тень сверху
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Тень снизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentStory = currentStories[currentInnerStoryIndex];
    final button = _preloadedStories[currentStory.id ?? -1]?.button;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Transform.scale(
        scale: _calculateScale(),
        child: Opacity(
          opacity: _calculateOpacity(),
          child: Stack(
            children: [
              _buildPageView(), // Заменяем старый PageView на новый с эффектом куба
              // GestureDetector для обработки тапов
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    _progressController.stop();
                  },
                  onTapUp: (details) {
                    if (!_isDragging) {
                      if (details.globalPosition.dx < screenWidth / 2) {
                        handlePreviousStory();
                      } else {
                        handleNextStory();
                      }
                      _progressController.forward();
                    }
                  },
                  onTapCancel: () {
                    if (!_isDragging) {
                      _progressController.forward();
                    }
                  },
                  onVerticalDragStart: (_) {
                    _isDragging = true;
                    _progressController.stop();
                  },
                  onVerticalDragUpdate: (details) {
                    // Теперь обрабатываем только свайп вверх (отрицательное значение)
                    if (details.primaryDelta! > 0) return;

                    setState(() {
                      _dragOffset += details.primaryDelta!;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    _isDragging = false;

                    // Проверяем скорость свайпа вверх (отрицательное значение)
                    if (_dragOffset.abs() > 100 ||
                        (details.primaryVelocity ?? 0) < -300) {
                      // Закрываем историю если достаточно оттянули или быстро свайпнули вверх
                      Navigator.of(context).pop();
                    } else {
                      // Возвращаем на место с анимацией
                      setState(() {
                        _dragOffset = 0;
                      });
                      _progressController.forward();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;

                    // Если скорость свайпа меньше определенного порога, игнорируем
                    if (details.primaryVelocity!.abs() < 200) return;

                    if (details.primaryVelocity! > 0) {
                      // Свайп вправо - к предыдущей группе
                      if (currentStoryIndex > 0) {
                        _uiAnimationController.forward();
                        final prevStoryIndex = currentStoryIndex - 1;
                        final prevStories =
                            widget.stories[prevStoryIndex].stories ?? [];

                        _groupPageController
                            .animateToPage(
                          prevStoryIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                            .then((_) {
                          setState(() {
                            currentStoryIndex = prevStoryIndex;
                            currentStories = prevStories;
                            currentInnerStoryIndex = 0;
                          });
                          _pageController = PageController(initialPage: 0);
                          _progressController.reset();
                          _progressController.forward();
                          _uiAnimationController.reverse();
                        });
                      }
                    } else {
                      // Свайп влево - к следующей группе
                      if (currentStoryIndex < widget.stories.length - 1) {
                        _uiAnimationController.forward();
                        final nextStoryIndex = currentStoryIndex + 1;
                        final nextStories =
                            widget.stories[nextStoryIndex].stories ?? [];

                        _groupPageController
                            .animateToPage(
                          nextStoryIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                            .then((_) {
                          setState(() {
                            currentStoryIndex = nextStoryIndex;
                            currentStories = nextStories;
                            currentInnerStoryIndex = 0;
                          });
                          _pageController = PageController(initialPage: 0);
                          _progressController.reset();
                          _progressController.forward();
                          _uiAnimationController.reverse();
                        });
                      }
                    }
                  },
                ),
              ),
              // Верхняя панель с прогрессом и информацией
              FadeTransition(
                opacity: _uiFadeAnimation,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: paddingTop + 8,
                    left: 16,
                    right: 16,
                  ),
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
                                    backgroundColor:
                                        Colors.grey.withOpacity(0.5),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      widget.stories[currentStoryIndex]
                                              .previewImage ??
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
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Кнопка внизу экрана
              if (button != null)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 16,
                  right: 16,
                  child: FadeTransition(
                    opacity: _uiFadeAnimation,
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _groupPageController.dispose();
    _uiAnimationController.dispose();
    _cubeController.dispose();
    super.dispose();
  }
}

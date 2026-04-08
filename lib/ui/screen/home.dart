import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/cache_image.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/util/version_checker.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:holo/util/local_storage.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final CarouselController _carouselController = CarouselController();
  final ValueNotifier<List<SubjectItem>> _hotNotifier = ValueNotifier([]);
  final Logger _logger = Logger();

  int index = 0;
  Timer? _carouselTimer;
  Timer? _autoSlideTimer;
  bool _isLoading = false;
  bool _isRefresh = false;
  String _msg = '';
  int _page = 1;
  List<SubjectItem> _rank = [];

  Future<void> _fetchHot() async {
    final hot = await Api.bangumi.fetchRecommend(
      year: DateTime.now().year,
      sort: "rank",
      page: _page,
      size: 20,
      exception: (e) {
        safeSetState(() {
          _logger.e("home->fetch hot error: $e");
          _msg = context.tr("common.load_failed");
        });
      },
    );
    safeSetState(() {
      _hotNotifier.value = hot;
    });
    LocalStorage.setHomeHotCache(_hotNotifier.value);
  }

  Future<void> _fetchRank({int page = 1, bool loadMore = false}) async {
    if (_isLoading) return;
    safeSetState(() => _isLoading = true);

    final rank = await Api.bangumi.fetchRecommend(
      sort: "rank",
      page: page,
      size: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 30
          : 10,
      exception: (e) {
        safeSetState(() {
          _logger.e("home->fetch rank error: $e");
          _msg = context.tr("common.load_failed");
          _isLoading = false;
        });
      },
    );

    safeSetState(() {
      if (loadMore) {
        _rank.addAll(rank);
      } else {
        _rank = rank;
      }
    });
    LocalStorage.setHomeRankCache(_rank);
    safeSetState(() => _isLoading = false);
  }

  void _onScrollToBottom() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading) {
      _logger.i("load more page: $_page");
      _fetchRank(page: ++_page, loadMore: true);
    }
  }

  void _homeScreenInit() {
    final autoCheckUpdate = LocalStorage.getAutoCheckUpdate();
    if (autoCheckUpdate) {
      VersionChecker.checkVersion(context);
    }
    _hotNotifier.addListener(() {
      if (_hotNotifier.value.isNotEmpty) {
        _carouselTimer?.cancel();
        _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
          index = index.remainder(_hotNotifier.value.length);
          _carouselController.animateToItem(index++);
        });
      }
    });

    _hotNotifier.value = LocalStorage.getHomeHotCache();
    _rank = LocalStorage.getHomeRankCache();

    if (DateTime.now().hour % 3 == 0 || _hotNotifier.value.isEmpty) {
      _fetchHot();
    }
    if (DateTime.now().hour % 3 == 0 || _rank.isEmpty) {
      _fetchRank();
    }

    _scrollController.addListener(_onScrollToBottom);
  }

  void _refreshAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _carouselTimer?.cancel();
      _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        index = index.remainder(_hotNotifier.value.length);
        _carouselController.animateToItem(index++);
      });
    });
  }

  Widget _buildHotSkeleton(bool isLandscape) {
    return SizedBox(
      height: isLandscape ? 400 : 200,
      width: double.infinity,
      child: CarouselView.weighted(
        controller: _carouselController,
        itemSnapping: true,
        flexWeights: isLandscape ? [1, 1, 1] : [5, 1],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: [1, 2, 3, 4].map((e) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white38),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankSkeleton(bool isLandscape) {
    return SliverGrid.builder(
      key: const ValueKey('home_rank_grid'),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 6 : 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverGrid(
    List<SubjectItem> items, {
    required bool isLandscape,
    required String heroKey,
  }) {
    return SliverGrid.builder(
      key: ValueKey('home_rank_grid_$heroKey'),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 6 : 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        var item = items[index];
        return MediaGrid(
          id: '${heroKey}_${item.id}',
          imageUrl: item.images.medium ?? "",
          title: item.title,
          onTap: () => context.push(
            '/detail',
            extra: {
              'id': item.id,
              'keyword': item.title,
              'subject': item,
              'cover': item.images.large ?? '',
              'from': heroKey,
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _homeScreenInit();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _autoSlideTimer?.cancel();
    _hotNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return Scaffold(
          appBar: isLandscape
              ? null
              : AppBar(
                  titleSpacing: 0,
                  animateColor: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.image_search_rounded),
                      onPressed: () => context.push('/image_search'),
                    ),
                  ],
                  title: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.all(0),
                        hintText: context.tr("home.hint_text"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      onTap: () => context.push('/search'),
                    ),
                  ),
                ),
          body: SafeArea(
            child: RepaintBoundary(
              child: _HomeContent(state: this, isLandscape: isLandscape),
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state, required this.isLandscape});

  final _HomeScreenState state;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    if (state._msg.isNotEmpty) {
      return LoadingOrShowMsg(msg: state._msg);
    }

    return RefreshIndicator(
      onRefresh: () async {
        state.safeSetState(() => state._isRefresh = true);
        await state._fetchRank(page: ++state._page, loadMore: false);
        state.safeSetState(() => state._isRefresh = false);
      },
      child: Column(
        children: [
          if (state._isLoading && !state._isRefresh)
            const LinearProgressIndicator(),
          Expanded(
            child: RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: CustomScrollView(
                  controller: state._scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: MouseRegion(
                        onExit: (_) {
                          state._carouselTimer?.cancel();
                          state._carouselTimer = Timer.periodic(
                            const Duration(seconds: 3),
                            (timer) {
                              state.index = state.index.remainder(
                                state._hotNotifier.value.length,
                              );
                              state._carouselController.animateToItem(
                                state.index++,
                              );
                            },
                          );
                        },
                        onHover: (_) => state._carouselTimer?.cancel(),
                        child: Row(
                          children: [
                            Text(
                              tr('home.recommend_hot'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 6),
                            if (isLandscape)
                              IconButton(
                                onPressed: () {
                                  if (state.index == 0) return;
                                  state._carouselController.animateToItem(
                                    --state.index,
                                  );
                                },
                                icon: const Icon(Icons.navigate_before_rounded),
                              ),
                            if (isLandscape)
                              IconButton(
                                onPressed: () {
                                  if (state.index >=
                                      state._hotNotifier.value.length - 1) {
                                    return;
                                  }
                                  state._carouselController.animateToItem(
                                    ++state.index,
                                  );
                                },
                                icon: const Icon(Icons.navigate_next_rounded),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: MouseRegion(
                        onExit: (_) {
                          state._carouselTimer?.cancel();
                          state._carouselTimer = Timer.periodic(
                            const Duration(seconds: 3),
                            (timer) {
                              state.index = state.index.remainder(
                                state._hotNotifier.value.length,
                              );
                              state._carouselController.animateToItem(
                                state.index++,
                              );
                            },
                          );
                        },
                        onHover: (_) => state._carouselTimer?.cancel(),
                        child: ValueListenableBuilder<List<SubjectItem>>(
                          valueListenable: state._hotNotifier,
                          builder: (context, hot, child) {
                            return hot.isEmpty
                                ? state._buildHotSkeleton(isLandscape)
                                : SizedBox(
                                    height: isLandscape ? 400 : 200,
                                    width: double.infinity,
                                    child: GestureDetector(
                                      onPanDown: (_) {
                                        state._carouselTimer?.cancel();
                                      },
                                      onPanCancel: () {
                                        state._refreshAutoSlideTimer();
                                      },
                                      child: CarouselView.weighted(
                                        controller: state._carouselController,
                                        itemSnapping: true,
                                        onTap: (idx) {
                                          context.push(
                                            '/detail',
                                            extra: {
                                              'id': hot[idx].id,
                                              'subject': hot[idx],
                                              'keyword': hot[idx].title,
                                              'cover':
                                                  hot[idx].images.large ?? '',
                                              'from': "home-hot",
                                            },
                                          );
                                        },
                                        flexWeights: isLandscape
                                            ? [1, 1, 1]
                                            : [5, 1],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        children: hot.map((e) {
                                          return Stack(
                                            children: [
                                              Hero(
                                                tag: 'home-hot_${e.id}',
                                                child: CacheImage(
                                                  imageUrl:
                                                      e.images.medium ?? '',
                                                  fit: BoxFit.cover,
                                                  memCacheWidth: 700,
                                                  memCacheHeight: 900,
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment
                                                          .bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Colors.black
                                                            .withOpacity(0.5),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                  child: Text(
                                                    e.title,
                                                    maxLines: 2,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Text(
                        tr('home.recommend_hight_score'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 6)),
                    state._rank.isEmpty
                        ? state._buildRankSkeleton(isLandscape)
                        : state._buildSliverGrid(
                            state._rank,
                            isLandscape: isLandscape,
                            heroKey: "home-rank",
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

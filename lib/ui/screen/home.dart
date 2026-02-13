import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/util/check_version.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final CarouselController _carouselController = CarouselController();
  final ValueNotifier<List<Data>> _hotNotifier = ValueNotifier([]);
  final Logger _logger = Logger();
  int index = 0;
  Timer? _carouselTimer;
  bool _isLoading = false;
  bool _isRefresh = false;
  String _msg = '';
  int _page = 1;
  List<Data> _rank = [];
  Future<void> _fetchHot() async {
    final hot = await Api.bangumi.fetchRecommend(
      year: DateTime.now().year,
      // month: DateTime.now().month,
      sort: "rank",
      page: _page,
      size: 10,
      exception: (e) {
        setState(() {
          _logger.e("home->fetch hot error: $e");
          _msg = context.tr("common.load_failed");
        });
      },
    );
    safeSetState(() {
      _hotNotifier.value = hot?.data ?? [];
    });
    LocalStore.setHomeHotCache(Subject(data: hot?.data));
  }

  Future<void> _fetchRank({int page = 1, bool loadMore = false}) async {
    if (_isLoading) {
      return;
    }
    safeSetState(() {
      _isLoading = true;
    });
    final rank = await Api.bangumi.fetchRecommend(
      sort: "rank",
      page: page,
      size: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 10
          : 30,
      exception: (e) {
        setState(() {
          _logger.e("home->fetch rank error: $e");
          _msg = context.tr("common.load_failed");
          _isLoading = false;
        });
      },
    );
    safeSetState(() {
      if (loadMore) {
        _rank.addAll(rank?.data ?? []);
      } else {
        _rank = rank?.data ?? [];
      }
    });
    LocalStore.setHomeRankCache(Subject(data: _rank));
    safeSetState(() {
      _isLoading = false;
    });
  }

  void _onScrollToBottom() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading) {
      _logger.i("load more page: $_page");
      _fetchRank(page: ++_page, loadMore: true);
    }
  }

  void _checkVersion() async {
    final asset = await CheckVersion.checkVersion();
    if (asset != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr("common.new_version")),
          content: ListTile(
            title: Text(
              "${context.tr("common.current_version")}:v${asset.currentVersion}",
            ),
            subtitle: Text(
              "${context.tr("common.latest_version")}:v${asset.latestVersion}",
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(context.tr("common.dialog.cancel")),
            ),
            FilledButton(
              onPressed: () =>
                  launchUrl(Uri.parse(asset.browserDownloadUrl ?? "")),
              child: Text(context.tr("common.dialog.update")),
            ),
          ],
        ),
      );
    }
  }

  void _homeScreenInit() {
    _checkVersion();
    _hotNotifier.addListener(() {
      if (_hotNotifier.value.isNotEmpty) {
        _carouselTimer?.cancel();
        _carouselTimer = Timer.periodic(Duration(seconds: 3), (timer) {
          index = index.remainder(_hotNotifier.value.length);
          _carouselController.animateToItem(index++);
        });
      }
    });
    _hotNotifier.value = LocalStore.getHomeHotCache()?.data ?? [];
    _rank = LocalStore.getHomeRankCache()?.data ?? [];
    if (DateTime.now().hour % 3 == 0 || _hotNotifier.value.isEmpty) {
      _fetchHot();
    }
    if (DateTime.now().hour % 3 == 0 || _rank.isEmpty) {
      _fetchRank();
    }
    _scrollController.addListener(_onScrollToBottom);
  }

  // 热门推荐骨架屏（支持横竖屏）
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

  // 高分推荐骨架屏（支持横竖屏）
  Widget _buildRankSkeleton(bool isLandscape) {
    return SliverGrid.builder(
      key: ValueKey('home_rank_grid'),
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
          child: Container(color: Colors.white38),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _homeScreenInit();
  }

  Widget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      animateColor: true,
      actions: [
        IconButton(
          icon: Icon(Icons.image_search_rounded),
          onPressed: () {
            context.push('/image_search');
          },
        ),
      ],
      title: Padding(
        padding: EdgeInsets.only(left: 12),
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            contentPadding: EdgeInsets.all(0),
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
          onTap: () {
            context.push('/search');
          },
        ),
      ),
    );
  }

  Widget _buildSliverGrid(
    List<Data> items, {
    required bool isLandscape,
    required String heroKey,
  }) {
    return SliverGrid.builder(
      key: ValueKey('home_rank_grid_$heroKey'),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 6 : 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.6,
      ),

      itemCount: items.length,
      itemBuilder: (context, index) {
        var item = items[index];
        var name = item.nameCn != null && item.nameCn!.isNotEmpty
            ? item.nameCn!
            : item.name ?? "";
        return MediaGrid(
          id: '${heroKey}_${item.id}',
          // airDate: item.date,
          // rating: item.rating?.score,
          showRating: false,
          imageUrl: item.images?.large ?? "",
          title: name,
          onTap: () => context.push(
            '/detail',
            extra: {
              'id': item.id!,
              'keyword': name,
              'subject': item,
              'cover': item.images?.large ?? '',
              'from': heroKey,
            },
          ),
        );
      },
    );
  }

  @override
  dispose() {
    _carouselTimer?.cancel();
    _hotNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: isLandscape ? null : _buildAppBar() as PreferredSizeWidget?,
      body: SafeArea(
        child: _msg.isNotEmpty
            ? LoadingOrShowMsg(msg: _msg)
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _isRefresh = true;
                  });
                  await _fetchRank(page: ++_page, loadMore: false);
                  setState(() {
                    _isRefresh = false;
                  });
                },
                child: Column(
                  children: [
                    if (_isLoading && !_isRefresh) LinearProgressIndicator(),
                    Expanded(
                      child: Padding(
                        padding: .symmetric(horizontal: 12),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Row(
                                spacing: 6,
                                children: [
                                  Text(
                                    '热门推荐',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  if (isLandscape) ...[
                                    IconButton(
                                      onPressed: () {
                                        if (index == 0) {
                                          return;
                                        }
                                        _carouselController.animateToItem(
                                          index--,
                                        );
                                      },
                                      icon: Icon(Icons.navigate_before_rounded),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (index >=
                                            _hotNotifier.value.length - 1) {
                                          return;
                                        }
                                        _carouselController.animateToItem(
                                          index++,
                                        );
                                      },
                                      icon: Icon(Icons.navigate_next_rounded),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            SliverToBoxAdapter(
                              child: ValueListenableBuilder(
                                valueListenable: _hotNotifier,
                                builder: (context, hot, child) {
                                  return hot.isEmpty
                                      ? _buildHotSkeleton(isLandscape)
                                      : SizedBox(
                                          height: isLandscape ? 400 : 200,
                                          width: double.infinity,
                                          child: CarouselView.weighted(
                                            controller: _carouselController,
                                            itemSnapping: true,
                                            onTap: (index) {
                                              var name =
                                                  hot[index].nameCn != null &&
                                                      hot[index]
                                                          .nameCn!
                                                          .isNotEmpty
                                                  ? hot[index].nameCn!
                                                  : hot[index].name ?? "";
                                              context.push(
                                                '/detail',
                                                extra: {
                                                  'id': hot[index].id!,
                                                  'subject': hot[index],
                                                  'keyword': name,
                                                  'cover':
                                                      hot[index]
                                                          .images
                                                          ?.large ??
                                                      '',
                                                  'from': "home-hot",
                                                },
                                              );
                                            },
                                            flexWeights: isLandscape
                                                ? [1, 1, 1]
                                                : [5, 1],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            children: hot.map((e) {
                                              return Stack(
                                                children: [
                                                  Hero(
                                                    tag: 'home-hot_${e.id}',
                                                    child: CachedNetworkImage(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      imageUrl:
                                                          e.images?.large ?? "",
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Icon(
                                                            Icons.error,
                                                          ),
                                                      progressIndicatorBuilder:
                                                          (
                                                            context,
                                                            url,
                                                            progress,
                                                          ) => const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment: .bottomCenter,
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding: .symmetric(
                                                        horizontal: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment
                                                              .bottomCenter,
                                                          end: Alignment
                                                              .topCenter,
                                                          colors: [
                                                            Colors.black
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        e.nameCn ?? "",
                                                        maxLines: 2,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        );
                                },
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Text(
                                '高分推荐',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            SliverToBoxAdapter(child: SizedBox(height: 6)),
                            _rank.isEmpty
                                ? _buildRankSkeleton(isLandscape)
                                : _buildSliverGrid(
                                    _rank,
                                    isLandscape: isLandscape,
                                    heroKey: "home-rank",
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

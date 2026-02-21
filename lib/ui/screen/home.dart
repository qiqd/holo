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

/// 首页屏幕组件
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 首页屏幕状态管理类
class _HomeScreenState extends State<HomeScreen> {
  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 轮播图控制器
  final CarouselController _carouselController = CarouselController();

  /// 热门推荐数据通知器
  final ValueNotifier<List<Data>> _hotNotifier = ValueNotifier([]);

  /// 日志记录器
  final Logger _logger = Logger();

  /// 轮播图当前索引
  int index = 0;

  /// 轮播图定时器
  Timer? _carouselTimer;

  /// 自动滑动定时器
  Timer? _autoSlideTimer;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在刷新
  bool _isRefresh = false;

  /// 错误信息
  String _msg = '';

  /// 当前页码
  int _page = 1;

  /// 排行榜数据
  List<Data> _rank = [];

  /// 获取热门推荐数据
  Future<void> _fetchHot() async {
    final hot = await Api.bangumi.fetchRecommend(
      year: DateTime.now().year,
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
    // 缓存热门推荐数据
    LocalStore.setHomeHotCache(Subject(data: hot?.data));
  }

  /// 获取排行榜数据
  /// [page] 页码
  /// [loadMore] 是否加载更多
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
          ? 30
          : 10,
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
    // 缓存排行榜数据
    LocalStore.setHomeRankCache(Subject(data: _rank));
    safeSetState(() {
      _isLoading = false;
    });
  }

  /// 滚动到底部加载更多
  void _onScrollToBottom() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading) {
      _logger.i("load more page: $_page");
      _fetchRank(page: ++_page, loadMore: true);
    }
  }

  /// 首页初始化
  void _homeScreenInit() {
    // 检查版本更新
    CheckVersion.checkVersion(context);
    // 监听热门推荐数据变化
    _hotNotifier.addListener(() {
      if (_hotNotifier.value.isNotEmpty) {
        _carouselTimer?.cancel();
        _carouselTimer = Timer.periodic(Duration(seconds: 3), (timer) {
          index = index.remainder(_hotNotifier.value.length);
          _carouselController.animateToItem(index++);
        });
      }
    });
    // 从缓存加载数据
    _hotNotifier.value = LocalStore.getHomeHotCache()?.data ?? [];
    _rank = LocalStore.getHomeRankCache()?.data ?? [];
    // 每3小时更新一次数据或数据为空时更新
    if (DateTime.now().hour % 3 == 0 || _hotNotifier.value.isEmpty) {
      _fetchHot();
    }
    if (DateTime.now().hour % 3 == 0 || _rank.isEmpty) {
      _fetchRank();
    }
    // 添加滚动监听器
    _scrollController.addListener(_onScrollToBottom);
  }

  /// 刷新自动滑动定时器
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

  /// 热门推荐骨架屏（支持横竖屏）
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

  /// 高分推荐骨架屏（支持横竖屏）
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

  /// 构建应用栏
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

  /// 构建网格布局
  /// [items] 数据列表
  /// [isLandscape] 是否为横屏
  /// [heroKey] Hero动画标签
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
    // 取消定时器
    _carouselTimer?.cancel();
    _autoSlideTimer?.cancel();
    // 释放资源
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
                              child: MouseRegion(
                                onExit: (_) {
                                  _carouselTimer?.cancel();
                                  _carouselTimer = Timer.periodic(
                                    Duration(seconds: 3),
                                    (timer) {
                                      index = index.remainder(
                                        _hotNotifier.value.length,
                                      );
                                      _carouselController.animateToItem(
                                        index++,
                                      );
                                    },
                                  );
                                },
                                onHover: (_) {
                                  _carouselTimer?.cancel();
                                },
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
                                            --index,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.navigate_before_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          if (index >=
                                              _hotNotifier.value.length - 1) {
                                            return;
                                          }
                                          _carouselController.animateToItem(
                                            ++index,
                                          );
                                        },
                                        icon: Icon(Icons.navigate_next_rounded),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: MouseRegion(
                                onExit: (_) {
                                  _carouselTimer?.cancel();
                                  _carouselTimer = Timer.periodic(
                                    Duration(seconds: 3),
                                    (timer) {
                                      index = index.remainder(
                                        _hotNotifier.value.length,
                                      );
                                      _carouselController.animateToItem(
                                        index++,
                                      );
                                    },
                                  );
                                },
                                onHover: (_) => _carouselTimer?.cancel(),
                                child: ValueListenableBuilder(
                                  valueListenable: _hotNotifier,
                                  builder: (context, hot, child) {
                                    return hot.isEmpty
                                        ? _buildHotSkeleton(isLandscape)
                                        : SizedBox(
                                            height: isLandscape ? 400 : 200,
                                            width: double.infinity,
                                            child: GestureDetector(
                                              onPanDown: (_) {
                                                _carouselTimer?.cancel();
                                              },
                                              onPanCancel: () {
                                                _refreshAutoSlideTimer();
                                              },
                                              child: CarouselView.weighted(
                                                controller: _carouselController,
                                                itemSnapping: true,
                                                onTap: (index) {
                                                  var name =
                                                      hot[index].nameCn !=
                                                              null &&
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
                                                          width:
                                                              double.infinity,
                                                          height:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          imageUrl:
                                                              e.images?.large ??
                                                              "",
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
                                                        alignment:
                                                            .bottomCenter,
                                                        child: Container(
                                                          width:
                                                              double.infinity,
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
                                                                Colors
                                                                    .transparent,
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
                                                                  color: Colors
                                                                      .white,
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

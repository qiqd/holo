import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/web_dav.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/entity/user_subscribe.dart';
import 'package:holo/main.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/hive_util.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:holo/extension/safe_set_state.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final String keyword;
  final String cover;
  final String from;
  final SubjectItem? subject;
  const DetailScreen({
    super.key,
    required this.id,
    required this.keyword,
    required this.cover,
    required this.from,
    this.subject,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late String _keyword = widget.keyword;
  late SubjectItem? _subject = widget.subject;
  List<Person> _person = [];
  List<Person> _character = [];
  List<SubjectRelation> _relation = [];
  final Map<SourceService, List<Media>> _source2Media = {};
  List<SourceService> _sourceService = [];
  bool _isLoading = false;
  bool _isFetched = false;
  bool _isCompleted = false;
  late TabController tabController = TabController(vsync: this, length: 4);
  late TabController subTabController = TabController(
    vsync: this,
    length: Api.getSources().length,
  );
  String _msg = "";
  Media? defaultMedia;
  SourceService? defaultSource;
  bool isSubscribed = false;
  int _viewingStatus = 0;
  final userSetting = MyApp.userSettingNotifier.value;
  UserSubscribe? _userSubscribe;

  Future<void> _fetchSubject() async {
    var subject = HiveUtil.getSubjectItemById(widget.id);

    if (widget.subject == null || subject == null) {
      final res = await Api.bangumi.fetchSubjectById(widget.id, (e) {
        safeSetState(() {
          _msg = e.toString();
        });
      });
      if (res != null) {
        safeSetState(() {
          _subject = res;
        });
        HiveUtil.setSubjectItem(res);
      }
    }
    _loadSubscribeHistory();
  }

  Future<void> _fetchMedia() async {
    safeSetState(() {
      _isLoading = true;
      _isFetched = true;
      _isCompleted = false;
    });
    final sources = Api.getSources();
    final future = sources.map((source) async {
      final res = await source.fetchSearch(_keyword, 1, 10, (e) {});
      double highestScore = 0;
      Media? tempMedia;
      SourceService? tempSource;
      for (var m in res) {
        double s = JaroWinklerSimilarity.apply(widget.keyword, m.title!);
        m.score = s;
        if (s > 0.9 && s > highestScore) {
          highestScore = s;
          tempMedia = m;
          tempSource = source;
        }
      }
      if (tempMedia != null && tempSource != null) {
        defaultMedia = tempMedia;
        defaultSource = tempSource;
        safeSetState(() {
          _isLoading = false;
        });
      }
      _source2Media[source] = res;
    });
    await Future.wait(future);
    for (var value in _source2Media.values) {
      value.sort((a, b) => b.score!.compareTo(a.score!));
    }
    final keys = _source2Media.keys.toList();
    keys.sort((a, b) => b.delay.compareTo(a.delay));
    safeSetState(() {
      _sourceService = keys;
      _isLoading = false;
      _isFetched = false;
      _isCompleted = true;
    });
  }

  Future<void> _fetchPerson() async {
    final res = await Api.bangumi.fetchPerson(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    if (mounted) {
      setState(() {
        _person = res;
      });
    }
  }

  Future<void> _fetchCharacter() async {
    final res = await Api.bangumi.fetchCharacter(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    if (mounted) {
      setState(() {
        _character = res;
      });
    }
  }

  Future<void> _fetchRelation() async {
    final res = await Api.bangumi.fetchSubjectRelation(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    if (mounted) {
      setState(() {
        _relation = res;
      });
    }
  }

  void _loadSubscribeHistory() {
    if (_subject == null) {
      return;
    }

    final subs = HiveUtil.getUserSubscribes(id: _subject!.id.toInt());
    if (subs.isNotEmpty) {
      safeSetState(() {
        isSubscribed = true;
        _viewingStatus = subs.first.viewingStatus;
        _userSubscribe = subs.first;
      });
    }
  }

  Future<void> _updateSubscribeHistory() async {
    if (_subject == null) {
      return;
    }
    if (isSubscribed) {
      UserSubscribe subscribe = _userSubscribe != null
          ? _userSubscribe!.copyWith(
              viewingStatus: _viewingStatus,
              createdAt: DateTime.now(),
            )
          : UserSubscribe(
              id: _subject!.id.toInt(),
              email: userSetting.email,
              title: _subject!.title,
              imgUrl: widget.cover,
              createdAt: DateTime.now(),
              isSync: false,
              viewingStatus: _viewingStatus,
            );
      await HiveUtil.setUserSubscribe(subscribe);
    } else {
      if (_userSubscribe != null) {
        await HiveUtil.clearUserSubscribe(id: _userSubscribe!.id);
      }
    }
    if (MyApp.userSettingNotifier.value.email.isNotEmpty) {
      await WebDAV.syncData(false);
    }
  }

  Future<void> subscribeHandle() async {
    setState(() {
      isSubscribed = !isSubscribed;
    });
    await _updateSubscribeHistory();
  }

  Future<void> _openBangumiUrl() async {
    if (_subject == null) {
      return;
    }
    await launchUrl(Uri.parse("https://bangumi.tv/subject/${_subject!.id}"));
  }

  Widget _buildShimmerSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          MediaCard(
            id: "${widget.from}_${widget.id}",
            imageUrl: widget.cover,
            title: "---------",
            genre: "---------",
            airDate: "---------",
            height: 200,
            rating: 0.0,
            showShimmer: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: .center,
              children: List.generate(4, (index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // 内容区域骨架屏
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCharacterDetail(Person person, BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(12),

          child: Row(
            spacing: 4,
            children: [
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    width: double.infinity,
                    height: double.infinity,
                    person.images?.large ?? '',
                    fit: BoxFit.fitHeight,
                    loadingBuilder: (context, child, loadingProgress) =>
                        loadingProgress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(size: 70, Icons.error)),
                  ),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        person.name ?? "detail.unknown".tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'CV: ${person.actors?.map((e) => e.name).join('·') ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        person.relation ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      Text(
                        person.summary ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _buildSearchResults() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextField(
                      textInputAction: TextInputAction.search,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hint: FittedBox(
                          fit: .scaleDown,
                          child: Text("detail.search_hint".tr()),
                        ),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      onSubmitted: (value) async {
                        setState(() {
                          _keyword = value;
                          _isLoading = true;
                        });
                        await _fetchMedia();
                        setState(() {
                          _isLoading = false;
                        });
                      },
                    ),

                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      controller: subTabController,
                      tabs: _sourceService
                          .map((e) => Tab(text: e.getName()))
                          .toList(),
                    ),
                    Expanded(
                      child: _source2Media.isEmpty
                          ? LoadingOrShowMsg(
                              msg: "detail.no_search_results".tr(),
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: TabBarView(
                                controller: subTabController,
                                children: _sourceService.map((e) {
                                  final item = _source2Media[e] ?? [];
                                  return _isLoading
                                      ? LoadingOrShowMsg(msg: _msg)
                                      : ListView.builder(
                                          itemCount: item.length,
                                          itemBuilder: (context, index) {
                                            final m = item[index];
                                            return Column(
                                              children: [
                                                MediaCard(
                                                  id: " ${Random().nextInt(10000)}_${m.id!}",
                                                  score: m.score ?? 0,
                                                  imageUrl: m.coverUrl!,
                                                  title:
                                                      m.title ??
                                                      "detail.no_title".tr(),
                                                  genre: m.type,
                                                  height: 150,
                                                  onTap: () {
                                                    defaultMedia = m;
                                                    defaultSource = e;
                                                    _goToPlayer();
                                                  },
                                                ),
                                                Divider(height: 5),
                                              ],
                                            );
                                          },
                                        );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _goToPlayer() {
    if (defaultMedia == null || defaultSource == null || _isLoading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("detail.no_source_found".tr())));
      return;
    }
    context.push(
      "/player",
      extra: {
        "mediaId": defaultMedia!.id!,
        "subject": _subject!,
        "source": defaultSource!,
        "nameCn": defaultMedia?.title ?? "detail.no_title".tr(),
        "isLove": isSubscribed,
        'person': _person,
        'character': _character,
        'relation': _relation,
      },
    );
  }

  Widget _buildSummary() {
    return _subject?.summary.isNotEmpty == true
        ? SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                _subject?.summary.isEmpty == true
                    ? "detail.no_summary".tr()
                    : _subject!.summary,
              ),
            ),
          )
        : Center(child: Text("detail.no_summary".tr()));
  }

  Widget _buildListTile({
    required List<Map<String, String?>> data,
    required String placeholder,
    void Function(String id)? onTap,
  }) {
    return data.isNotEmpty
        ? ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final p = data[index];
              return ListTile(
                leading: CircleAvatar(
                  foregroundImage: NetworkImage(p['image'] ?? ''),
                ),
                title: Text(p['title'] ?? "detail.unknown".tr()),
                subtitle: Text(p['subtitle'] ?? ''),
                onTap: () => onTap?.call(p['id'] as String),
              );
            },
          )
        : Center(child: Text(placeholder));
  }

  Widget _buildAppBar() {
    return AppBar(
      actionsPadding: .symmetric(horizontal: 12),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded),
        onPressed: () {
          context.pop(context);
        },
      ),
      //  title: Text("detail.title".tr()),
      actions: [
        IconButton(
          tooltip: "Link to Bangumi",
          onPressed: _openBangumiUrl,
          icon: Icon(Icons.link_rounded),
        ),
        IconButton(
          tooltip: "Subscribe/Unsubscribe",
          onPressed: () {
            if (_subject == null) {
              return;
            }
            subscribeHandle();
          },
          icon: Icon(
            isSubscribed
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
          ),
        ),
        IconButton(
          tooltip: 'All search results',
          onPressed: () {
            if (!_isCompleted) {
              return;
            }
            _buildSearchResults();
          },
          icon: AnimatedSwitcher(
            key: ValueKey("detail_search_icon"),
            duration: Duration(milliseconds: 500),
            child: _isFetched
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,

                      key: ValueKey("detail_search_loading"),
                      padding: .zero,
                    ),
                  )
                : const Icon(
                    Icons.search_rounded,
                    key: ValueKey("detail_search_icon"),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _updateSubscribeHistory();
    subTabController.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchSubject();
    _fetchPerson();
    _fetchCharacter();
    _fetchRelation();
    _fetchMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //浮动播放按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _goToPlayer,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _isLoading
              ? const CircularProgressIndicator(
                  key: ValueKey("detail_floating_loading"),
                )
              : const Icon(
                  Icons.play_arrow_rounded,
                  key: ValueKey("detail_floating_icon"),
                ),
        ),
      ),
      appBar: _buildAppBar() as PreferredSizeWidget,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          return SafeArea(
            child: _subject == null
                ? _buildShimmerSkeleton()
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        MediaCard(
                          id: "${widget.from}_${_subject!.id}",
                          imageUrl: widget.cover,
                          viewingStatus: isSubscribed ? _viewingStatus : null,
                          title: _subject!.title,
                          genre: _subject!.metaTags.join('/'),
                          episode: _subject!.totalEpisodes,
                          rating: _subject!.rating,
                          isFavorite: isSubscribed,
                          ratingCount: _subject!.ratingCount,
                          height: 200,
                          airDate: _subject!.airDate,
                          isLandscape: isLandscape,
                          onViewingStatusChange: (status) {
                            setState(() {
                              _viewingStatus = status;
                            });
                            _updateSubscribeHistory();
                          },
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              TabBar(
                                isScrollable: true,
                                tabAlignment: .center,
                                controller: tabController,
                                tabs: [
                                  Tab(text: "detail.tabs.summary".tr()),
                                  Tab(text: "detail.tabs.characters".tr()),
                                  Tab(text: "detail.tabs.relations".tr()),
                                  Tab(text: "detail.tabs.related_works".tr()),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: tabController,
                                  children: [
                                    _buildSummary(),

                                    //人物板块
                                    _buildListTile(
                                      data: _person
                                          .map(
                                            (e) => {
                                              'id': e.id.toString(),
                                              'title': e.name,
                                              'subtitle': e.relation,
                                              'image': e.images!.grid!,
                                            },
                                          )
                                          .toList(),
                                      placeholder: "detail.no_person_data".tr(),
                                    ),
                                    //角色板块
                                    _buildListTile(
                                      data: _character
                                          .map(
                                            (e) => {
                                              'id': e.id.toString(),
                                              'title': e.name,
                                              'subtitle': e.relation,
                                              'image': e.images!.grid!,
                                            },
                                          )
                                          .toList(),
                                      placeholder: "detail.no_character_data"
                                          .tr(),
                                      onTap: (id) => _showCharacterDetail(
                                        _character.firstWhere(
                                          (e) => e.id == int.parse(id),
                                        ),
                                        context,
                                      ),
                                    ),
                                    //关系板块
                                    _buildListTile(
                                      data: _relation
                                          .map(
                                            (e) => {
                                              'id': e.id.toString(),
                                              'title': e.nameCn,
                                              'subtitle': e.relation,
                                              'image': e.images!.medium!,
                                            },
                                          )
                                          .toList(),
                                      placeholder: "detail.no_relation_data"
                                          .tr(),
                                    ),
                                    // ListView.builder(
                                    //   itemCount: _relation.length,
                                    //   itemBuilder: (context, index) {
                                    //     final r = _relation[index];
                                    //     return ListTile(
                                    //       leading: r.images != null
                                    //           ? Image.network(
                                    //               r.images!.medium!.replaceAll(
                                    //                 "http",
                                    //                 "https",
                                    //               ),
                                    //               fit: BoxFit.cover,
                                    //               errorBuilder:
                                    //                   (
                                    //                     context,
                                    //                     error,
                                    //                     stackTrace,
                                    //                   ) => const Icon(
                                    //                     size: 70,
                                    //                     Icons.error,
                                    //                   ),
                                    //             )
                                    //           : const Icon(Icons.person),
                                    //       title: Text(
                                    //         r.nameCn ?? "detail.unknown".tr(),
                                    //       ),
                                    //       subtitle: Text(r.relation ?? ''),
                                    //     );
                                    //   },
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:holo/util/local_storage.dart';
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
  late String keyword = widget.keyword;
  late SubjectItem? subject = widget.subject;
  List<Person> person = [];
  List<Character> character = [];
  List<SubjectRelation> relation = [];
  Map<SourceService, List<Media>> source2Media = {};
  List<SourceService> sourceService = [];
  bool isLoading = false;
  bool _isFetched = false;
  bool isCompleted = false;
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
  void _fetchSubject() async {
    if (subject == null) {
      final res = await Api.bangumi.fetchSubjectById(widget.id, (e) {
        setState(() {
          _msg = e.toString();
        });
      });
      setState(() {
        subject = res;
      });
    }
    _loadSubscribeHistory();
  }

  Future<void> _fetchMedia() async {
    safeSetState(() {
      isLoading = true;
      _isFetched = true;
      isCompleted = false;
    });
    final sources = Api.getSources();
    final future = sources.map((source) async {
      final res = await source.fetchSearch(keyword, 1, 10, (e) {});
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
          isLoading = false;
        });
      }
      source2Media[source] = res;
    });
    await Future.wait(future);
    for (var value in source2Media.values) {
      value.sort((a, b) => b.score!.compareTo(a.score!));
    }
    final keys = source2Media.keys.toList();
    keys.sort((a, b) => b.delay.compareTo(a.delay));
    safeSetState(() {
      sourceService = keys;
      isLoading = false;
      _isFetched = false;
      isCompleted = true;
    });
  }

  void _fetchPerson() async {
    final res = await Api.bangumi.fetchPerson(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    if (mounted) {
      setState(() {
        person = res;
      });
    }
  }

  void _fetchCharacter() async {
    final res = await Api.bangumi.fetchCharacter(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    if (mounted) {
      setState(() {
        character = res;
      });
    }
  }

  void _fetchRelation() async {
    final res = await Api.bangumi.fetchSubjectRelation(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    if (mounted) {
      setState(() {
        relation = res;
      });
    }
  }

  void _loadSubscribeHistory() {
    if (subject == null) {
      return;
    }
    final history = LocalStorage.getSubscribeHistoryById(subject!.id);
    if (mounted && history != null) {
      setState(() {
        isSubscribed = true;
        _viewingStatus = history.viewingStatus;
      });
    }
  }

  void _storeSubscribeHistory() async {
    if (subject == null) {
      return;
    }
    if (isSubscribed) {
      SubscribeHistory history = SubscribeHistory(
        subId: subject!.id,
        title: subject!.title,
        imgUrl: subject!.images.large ?? "",
        createdAt: DateTime.now(),
        viewingStatus: _viewingStatus,
      );
      _syncSubscribeHistory(history);
      LocalStorage.addSubscribeHistory(history);
    } else {
      _cancelSync(subject!.id);
      LocalStorage.removeSubscribeHistoryBySubId(subject!.id);
    }
  }

  void subscribeHandle() {
    setState(() {
      isSubscribed = !isSubscribed;
    });
    _storeSubscribeHistory();
  }

  void _cancelSync(int subId) {
    SubscribeApi.deleteSubscribeRecordBySubId(subId, () {}, (msg) {});
  }

  void _syncSubscribeHistory(SubscribeHistory history) async {
    SubscribeApi.saveSubscribeHistory(history, () {
      history.isSync = true;
    }, (e) {}).then((newSubscribe) {});
  }

  Future<void> _openBangumiUrl() async {
    if (subject == null) {
      return;
    }
    await launchUrl(Uri.parse("https://bangumi.tv/subject/${subject!.id}"));
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

  Future<void> _showCharacterDetail(Character character, BuildContext context) {
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
                    character.images?.large ?? '',
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
                        character.name ?? "detail.unknown".tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'CV: ${character.actors?.map((e) => e.name).join('·') ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        character.relation ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      Text(
                        character.summary ?? '',
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
                          keyword = value;
                          isLoading = true;
                        });
                        await _fetchMedia();
                        setState(() {
                          isLoading = false;
                        });
                      },
                    ),

                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      controller: subTabController,
                      tabs: sourceService
                          .map((e) => Tab(text: e.getName()))
                          .toList(),
                    ),
                    Expanded(
                      child: source2Media.isEmpty
                          ? LoadingOrShowMsg(
                              msg: "detail.no_search_results".tr(),
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: TabBarView(
                                controller: subTabController,
                                children: sourceService.map((e) {
                                  final item = source2Media[e] ?? [];
                                  return isLoading
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
    if (defaultMedia == null || defaultSource == null || isLoading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("detail.no_source_found".tr())));
      return;
    }
    context.push(
      "/player",
      extra: {
        "mediaId": defaultMedia!.id!,
        "subject": subject!,
        "source": defaultSource!,
        "nameCn": defaultMedia?.title ?? "detail.no_title".tr(),
        "isLove": isSubscribed,
        'person': person,
        'character': character,
        'relation': relation,
      },
    );
  }

  @override
  void dispose() {
    _storeSubscribeHistory();
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
          child: isLoading
              ? const CircularProgressIndicator(
                  key: ValueKey("detail_floating_loading"),
                )
              : const Icon(
                  Icons.play_arrow_rounded,
                  key: ValueKey("detail_floating_icon"),
                ),
        ),
      ),
      appBar: AppBar(
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
              if (subject == null) {
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
              if (!isCompleted) {
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
      ),
      body: SafeArea(
        child: subject == null
            ? _buildShimmerSkeleton()
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    MediaCard(
                      id: "${widget.from}_${subject!.id}",
                      imageUrl: widget.cover,
                      viewingStatus: isSubscribed ? _viewingStatus : null,
                      title: subject!.title,
                      genre: subject!.metaTags.join('/'),
                      episode: subject!.totalEpisodes,
                      rating: subject!.rating,
                      isFavorite: isSubscribed,
                      ratingCount: subject!.ratingCount,
                      height: 200,
                      airDate: subject!.airDate,
                      onViewingStatusChange: (status) {
                        setState(() {
                          _viewingStatus = status;
                        });
                        _storeSubscribeHistory();
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
                                // 简介板块
                                subject?.summary.isNotEmpty == true
                                    ? SizedBox(
                                        width: double.infinity,
                                        child: SingleChildScrollView(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            subject?.summary.isEmpty == true
                                                ? "detail.no_summary".tr()
                                                : subject!.summary,
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text("detail.no_summary".tr()),
                                      ),

                                //人物板块
                                person.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: person.length,
                                        itemBuilder: (context, index) {
                                          final p = person[index];
                                          return ListTile(
                                            leading: p.images != null
                                                ? Image.network(
                                                    p.images!.grid!.startsWith(
                                                          "https://",
                                                        )
                                                        ? p.images!.grid!
                                                        : p.images!.grid!
                                                              .replaceAll(
                                                                "http://",
                                                                "https://",
                                                              ),
                                                    // width: 70,
                                                    // height: 70,
                                                    fit: BoxFit.fill,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          size: 70,
                                                          Icons.error,
                                                        ),
                                                  )
                                                : const Icon(Icons.person),
                                            title: Text(
                                              p.name ?? "detail.unknown".tr(),
                                            ),
                                            subtitle: Text(p.relation ?? ''),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          "detail.no_character_data".tr(),
                                        ),
                                      ),
                                //角色板块
                                character.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: character.length,
                                        itemBuilder: (context, index) {
                                          final c = character[index];
                                          return ListTile(
                                            leading: c.images != null
                                                ? Image.network(
                                                    fit: BoxFit.fill,
                                                    c.images!.grid!.replaceAll(
                                                      "http",
                                                      "https",
                                                    ),
                                                    // color: Colors.limeAccent,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          size: 70,
                                                          Icons.error,
                                                        ),
                                                  )
                                                : const Icon(Icons.person),
                                            title: Text(
                                              c.name ?? "detail.unknown".tr(),
                                            ),
                                            subtitle: Text(c.relation ?? ''),
                                            onTap: () => _showCharacterDetail(
                                              c,
                                              context,
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          "detail.no_relation_data".tr(),
                                        ),
                                      ),
                                ListView.builder(
                                  itemCount: relation.length,
                                  itemBuilder: (context, index) {
                                    final r = relation[index];
                                    return ListTile(
                                      leading: r.images != null
                                          ? Image.network(
                                              r.images!.medium!.replaceAll(
                                                "http",
                                                "https",
                                              ),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    size: 70,
                                                    Icons.error,
                                                  ),
                                            )
                                          : const Icon(Icons.person),
                                      title: Text(
                                        r.nameCn ?? "detail.unknown".tr(),
                                      ),
                                      subtitle: Text(r.relation ?? ''),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

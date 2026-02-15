import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject.dart' show Data;
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/language_util.dart';
import 'package:holo/util/local_store.dart';
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
  final Data? subject;
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
  late Data? data = widget.subject;
  List<Person> person = [];
  List<Character> character = [];
  List<SubjectRelation>? relation;
  Map<SourceService, List<Media>> source2Media = {};
  List<SourceService> sourceService = [];
  bool isLoading = false;
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
  void _fetchSubjec() async {
    if (data == null) {
      final res = await Api.bangumi.fetchSubjectSync(widget.id, (e) {
        setState(() {
          _msg = e.toString();
        });
      });
      setState(() {
        data = res;
      });
    }
    _loadSubscribeHistory();
  }

  Future<void> _fetchMedia() async {
    safeSetState(() {
      isLoading = true;
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
    // Media? target;
    double tempScore = 0;
    for (var entity in source2Media.entries) {
      var value = entity.value;
      for (var m in value) {
        double s = JaroWinklerSimilarity.apply(widget.keyword, m.title!);
        m.score = s;
        if (defaultMedia == null && s > tempScore) {
          tempScore = s;
          //target = m;
          defaultMedia = m;
          defaultSource = entity.key;
        }
      }
    }
    for (var value in source2Media.values) {
      value.sort((a, b) => b.score!.compareTo(a.score!));
    }
    final keys = source2Media.keys.toList();
    keys.sort((a, b) => b.delay.compareTo(a.delay));
    var sourceName = widget.subject?.sourceName;
    if (sourceName != null && sourceName.isNotEmpty) {
      defaultSource = sources.firstWhere(
        (element) => element.getName() == sourceName,
        orElse: () => keys.first,
      );
      defaultMedia = source2Media[defaultSource]!.isEmpty
          ? null
          : source2Media[defaultSource]!.first;
    }

    //defaultSource = keys.first;
    safeSetState(() {
      sourceService = keys;
      isLoading = false;
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
    final history = LocalStore.getSubscribeHistoryById(data!.id!);
    if (mounted && history != null) {
      setState(() {
        isSubscribed = true;
        _viewingStatus = history.viewingStatus;
      });
    }
  }

  void _storeSubscribeHistory() async {
    if (data == null) {
      return;
    }
    if (isSubscribed) {
      var title = getTitle(data!);
      SubscribeHistory history = SubscribeHistory(
        subId: data!.id!,
        title: title,
        imgUrl: data!.images?.large ?? "",
        createdAt: DateTime.now(),
        viewingStatus: _viewingStatus,
      );
      _syncSubscribeHistory(history);
      LocalStore.addSubscribeHistory(history);
    } else {
      _cancelSync(data!.id!);
      LocalStore.removeSubscribeHistoryBySubId(data!.id!);
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
    if (data == null) {
      return;
    }

    await launchUrl(Uri.parse("https://bangumi.tv/subject/${data!.id}"));
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

  void _showCharacterDetail(Character character, BuildContext context) {
    showModalBottomSheet(
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
    _fetchSubjec();
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
        onPressed: () {
          if (defaultMedia == null || defaultSource == null || isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("detail.no_source_found".tr())),
            );
            return;
          }
          context.push(
            "/player",
            extra: {
              "mediaId": defaultMedia!.id!,
              "subject": data!,
              "source": defaultSource!,
              "nameCn": defaultMedia!.title!,
              "isLove": isSubscribed,
            },
          );
        },
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
            onPressed: _openBangumiUrl,
            icon: Icon(Icons.link_rounded),
          ),
          IconButton(
            onPressed: () {
              if (data == null) {
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

              showModalBottomSheet(
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
                                  hintText: "detail.search_hint".tr(),
                                  hintStyle: Theme.of(
                                    context,
                                  ).textTheme.bodySmall,
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
                                                            imageUrl:
                                                                m.coverUrl!,
                                                            title:
                                                                m.title ??
                                                                "detail.no_title"
                                                                    .tr(),
                                                            genre: m.type,
                                                            height: 150,
                                                            onTap: () {
                                                              context.push(
                                                                "/player",
                                                                extra: {
                                                                  "isLove":
                                                                      isSubscribed,
                                                                  "mediaId":
                                                                      m.id!,
                                                                  "subject":
                                                                      data,
                                                                  "source": e,
                                                                  "nameCn":
                                                                      m.title ??
                                                                      "detail.no_title"
                                                                          .tr(),
                                                                },
                                                              );
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
            },
            icon: Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: data == null
            ? _buildShimmerSkeleton()
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    MediaCard(
                      id: "${widget.from}_${data!.id!}",
                      imageUrl: widget.cover,
                      viewingStatus: isSubscribed ? _viewingStatus : null,
                      title: getTitle(data!),
                      genre: data!.metaTags?.join('/'),
                      episode: data!.eps ?? 0,
                      rating: data!.rating?.score,
                      isFavorite: isSubscribed,
                      ratingCount: data!.rating?.total,
                      height: 200,
                      airDate: data?.date,
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
                                data?.summary != null &&
                                        data!.summary!.isNotEmpty
                                    ? SizedBox(
                                        width: double.infinity,
                                        child: SingleChildScrollView(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            data?.summary == null ||
                                                    data!.summary!.isEmpty
                                                ? "detail.no_summary".tr()
                                                : data!.summary!,
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
                                                    p.images!.medium!,
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
                                                    c.images!.medium!,
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
                                relation != null
                                    ? ListView.builder(
                                        itemCount: relation?.length ?? 0,
                                        itemBuilder: (context, index) {
                                          final r = relation![index];
                                          return ListTile(
                                            leading: r.images != null
                                                ? Image.network(
                                                    r.images!.medium!,
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
                                      )
                                    : Center(
                                        child: Text(
                                          "detail.no_related_works_data".tr(),
                                        ),
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

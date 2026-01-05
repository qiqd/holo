import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject.dart' show Data, InfoBox;
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/meida_card.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final String keyword;

  const DetailScreen({super.key, required this.id, required this.keyword});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late String keyword = widget.keyword;
  Data? data;
  List<Person>? person;
  List<Character>? character;
  List<SubjectRelation>? relation;
  Map<SourceService, List<Media>> source2Media = {};
  List<SourceService> sourceService = [];
  bool isLoading = false;
  late TabController tabController = TabController(vsync: this, length: 4);
  late TabController subTabController = TabController(
    vsync: this,
    length: Api.getSources().length,
  );
  String _msg = "";
  Media? defaultMedia;
  SourceService? defaultSource;
  bool isSubscribed = false;
  Timer? _syncTimer;
  Timer? _cancelSyncTimer;

  void _fetchSubjec() async {
    final res = await Api.bangumi.fetchSubjectSync(widget.id, (e) {
      setState(() {
        _msg = e.toString();
      });
    });
    setState(() {
      data = res;
      _loadHistory();
    });
  }

  Future<void> _fetchMedia() async {
    setState(() {
      isLoading = true;
    });
    final sources = Api.getSources();
    final future = sources.map((source) async {
      final res = await source.fetchSearch(keyword, 1, 10, (e) {});
      source2Media[source] = res;
    });
    await Future.wait(future);
    for (var value in source2Media.values) {
      for (var m in value) {
        m.score = JaroWinklerSimilarity.apply(widget.keyword, m.title!);
      }
    }
    for (var value in source2Media.values) {
      value.sort((a, b) => b.score!.compareTo(a.score!));
    }
    if (source2Media.values.isNotEmpty &&
        source2Media.values.first.isNotEmpty) {
      defaultMedia = source2Media.values.first.first;
    }
    final keys = source2Media.keys.toList();
    keys.sort((a, b) => b.delay.compareTo(a.delay));
    defaultSource = keys.first;
    if (mounted) {
      setState(() {
        sourceService = keys;
        isLoading = false;
      });
    }
  }

  void _fetchPerson() async {
    final res = await Api.bangumi.fetchPersonSync(widget.id, (e) {
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
    final res = await Api.bangumi.fetchCharacterSync(widget.id, (e) {
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
    final res = await Api.bangumi.fetchSubjectRelationSync(widget.id, (e) {
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

  void _loadHistory() {
    final history = LocalStore.getSubscribeHistoryById(data!.id!);
    if (mounted && history != null) {
      setState(() {
        isSubscribed = true;
      });
    }
  }

  void _storeLocalHistory() async {
    if (data == null) {
      return;
    }
    if (isSubscribed) {
      SubscribeHistory history = SubscribeHistory(
        subId: data!.id!,
        title: data!.nameCn!,
        imgUrl: data!.images?.large ?? "",
        createdAt: DateTime.now(),
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
    _storeLocalHistory();
  }

  void _cancelSync(int subId) {
    _syncTimer?.cancel();

    _cancelSyncTimer = Timer(Duration(seconds: 2), () {
      if (isSubscribed) {
        return;
      }
      SubscribeApi.deleteSubscribeRecordBySubId(subId, () {}, (msg) {});
    });
  }

  void _syncSubscribeHistory(SubscribeHistory history) async {
    _syncTimer?.cancel();
    _syncTimer = Timer(Duration(seconds: 2), () async {
      if (!isSubscribed) {
        return;
      }
      SubscribeApi.saveSubscribeHistory(history, () {
        history.isSync = true;
      }, (e) {}).then((newSubscribe) {});
    });
  }

  @override
  void dispose() {
    _storeLocalHistory();
    tabController.dispose();
    subTabController.dispose();
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
          if (defaultMedia == null || defaultSource == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('没有匹配到播放源,请点击右上角手动搜索')),
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
        child: const Icon(Icons.play_arrow_rounded),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            context.pop(context);
          },
        ),
        title: const Text('详情'),
        actions: [
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
            onPressed: () {
              if (isLoading) {
                return;
              }
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            TextField(
                              textInputAction: TextInputAction.search,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: '若结果为空，尝试输入其他关键词搜索',
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
                                  ? LoadingOrShowMsg(msg: "暂无搜索结果")
                                  : TabBarView(
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
                                                      MeidaCard(
                                                        id: 0,

                                                        score: m.score ?? 0,
                                                        imageUrl: m.coverUrl!,
                                                        nameCn:
                                                            m.title ?? "暂无标题",
                                                        genre: m.type,
                                                        height: 150,
                                                        onTap: () {
                                                          context.push(
                                                            "/player",
                                                            extra: {
                                                              "isLove":
                                                                  isSubscribed,
                                                              "mediaId": m.id!,
                                                              "subject": data,
                                                              "source": e,
                                                              "nameCn":
                                                                  m.title ??
                                                                  "暂无标题",
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
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: data == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  MeidaCard(
                    id: data!.id!,
                    imageUrl: data!.images?.large!,
                    nameCn: data!.nameCn!,
                    name: data!.name!,
                    genre: data!.metaTags?.join('/'),
                    episode: data!.eps ?? 0,
                    rating: data!.rating?.score,
                    height: 250,
                    airDate: data!.infobox
                        ?.firstWhere(
                          (element) => element.key?.contains("放送开始") ?? false,
                          orElse: () => InfoBox(),
                        )
                        .value,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TabBar(
                          controller: tabController,
                          tabs: const [
                            Tab(text: '简介'),
                            Tab(text: '人物'),
                            Tab(text: '角色'),
                            Tab(text: '关联作品'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: tabController,
                            children: [
                              SingleChildScrollView(
                                child: Text(data?.summary ?? '暂无简介'),
                              ),
                              person != null
                                  ? ListView.builder(
                                      itemCount: person?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final p = person![index];
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
                                          title: Text(p.name ?? '未知'),
                                          subtitle: Text(p.relation ?? ''),
                                        );
                                      },
                                    )
                                  : const Center(child: Text('人物暂无数据')),
                              character != null
                                  ? ListView.builder(
                                      itemCount: character?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final c = character![index];
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
                                          title: Text(c.name ?? '未知'),
                                          subtitle: Text(c.relation ?? ''),
                                        );
                                      },
                                    )
                                  : const Center(child: Text('角色暂无数据')),
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
                                          title: Text(r.nameCn ?? '未知'),
                                          subtitle: Text(r.relation ?? ''),
                                        );
                                      },
                                    )
                                  : const Center(child: Text('关联作品暂无数据')),
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
  }
}

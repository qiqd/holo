import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/ui/component/shimmer.dart';
import 'package:holo/util/local_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  Subject? _recommended;
  bool _loading = false;
  int _page = 1;
  String? _msg;

  void _fetchRecommended({int page = 1, bool isLoadMore = false}) async {
    setState(() {
      _loading = true;
    });
    final recommended = await Api.bangumi.fetchRecommendSync(page, 20, (e) {});
    setState(() {
      isLoadMore
          ? _recommended?.data?.addAll(recommended?.data ?? [])
          : _recommended = recommended;
    });
    if (_recommended != null) {
      LocalStore.setHomeCache(_recommended!);
    }
    setState(() {
      _loading = false;
    });
  }

  void _onScrollToBottom() {
    // log("scroll to bottom");
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_loading) {
      log("home->load more");
      _fetchRecommended(page: ++_page, isLoadMore: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _recommended = LocalStore.getHomeCache();
    _scrollController.addListener(_onScrollToBottom);
    if (_recommended == null) {
      _fetchRecommended();
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: isLandscape
          ? null
          : AppBar(
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
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading) LinearProgressIndicator(),
            Expanded(
              child: Center(
                child: _msg != null
                    ? LoadingOrShowMsg(msg: _msg)
                    : _recommended == null
                    ? buildShimmerSkeleton()
                    : GridView.builder(
                        controller: _scrollController,
                        itemCount: _recommended!.data!.length,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          crossAxisCount: isLandscape ? 6 : 3,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, index) {
                          final item = _recommended!.data![index];
                          var nameCN = item.nameCn ?? '';
                          var name = item.name ?? "";
                          return MediaGrid(
                            id: "home_${item.id!}",
                            imageUrl: item.images?.medium,
                            title: nameCN.isNotEmpty ? nameCN : name,
                            rating: item.rating?.score,
                            airDate: item.infobox
                                ?.firstWhere(
                                  (element) =>
                                      element.key?.contains("放送开始") ?? false,
                                )
                                .value,
                            onTap: () {
                              context.push(
                                '/detail',
                                extra: {
                                  'id': item.id!,
                                  'keyword': item.nameCn ?? item.name ?? "",
                                  'cover': item.images?.large ?? "",
                                  'from': "home",
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/ui/component/shimmer.dart';

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
    _scrollController.addListener(_onScrollToBottom);
    _fetchRecommended();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        animateColor: true,
        title: TextField(
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
      body: Column(
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                          ),
                      itemBuilder: (context, index) {
                        final item = _recommended!.data![index];
                        return MediaGrid(
                          id: "home_${item.id!}",
                          imageUrl: item.images?.medium,
                          title: item.nameCn!.isEmpty
                              ? item.name ?? ""
                              : item.nameCn,
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
    );
  }
}

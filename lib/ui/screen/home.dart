import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/media_grid.dart';

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
    log("scroll to bottom");
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_loading) {
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
        surfaceTintColor: Colors.red,
        title: const Text("推荐"),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () {
              context.push('/search');
            },
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(),
          Expanded(
            child: Center(
              child: _recommended == null
                  ? const Text("暂无推荐")
                  : GridView.builder(
                      controller: _scrollController,
                      itemCount: _recommended!.data!.length,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                          ),
                      itemBuilder: (context, index) {
                        final item = _recommended!.data![index];
                        return MediaGrid(
                          id: item.id!,
                          imageUrl: item.images?.medium,
                          title: item.nameCn!.isEmpty
                              ? item.name ?? ""
                              : item.nameCn,
                          rating: item.rating?.score,
                          onTap: () {
                            context.push(
                              '/detail',
                              extra: {
                                'id': item.id!,
                                'keyword': item.nameCn ?? item.name ?? "",
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

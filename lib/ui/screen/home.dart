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
  String? _msg;
  int _month = 1;
  int _year = DateTime.now().year;
  int _page = 1;
  void _fetchRecommended({
    int page = 1,
    bool isLoadMore = false,
    int year = 2018,
    int month = 1,
  }) async {
    setState(() {
      _msg = null;
      _loading = isLoadMore;
    });
    final recommended = await Api.bangumi.fetchRecommendSync(
      page,
      100,
      year,
      month,
      (e) {
        setState(() {
          log("home->fetch recommend error: $e");
          _msg = e.toString();
          _loading = false;
        });
      },
    );
    setState(() {
      isLoadMore
          ? _recommended?.data?.addAll(recommended?.data ?? [])
          : _recommended = recommended;
    });
    if (_recommended != null) {
      var s = recommended!.data
          ?.where(
            (element) =>
                element.date?.substring(0, 4) == DateTime.now().year.toString(),
          )
          .toList();
      LocalStore.setHomeCache(Subject(data: s));
    }
    setState(() {
      _loading = false;
    });
  }

  void _onScrollToBottom() {
    if ((_recommended?.total ?? 0) <= (_recommended?.data?.length ?? 0) &&
        _page + 1 >= _month + 3) {
      log("load more cancle, page: $_page, month: $_month");
      return;
    }
    log("load more page: $_page");
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_loading) {
      _fetchRecommended(year: _year, month: ++_page, isLoadMore: true);
    }
  }

  void _onYearSelected(int year) {
    if (_loading) {
      return;
    }
    setState(() {
      _year = year;
      _recommended = null;
    });
    _fetchRecommended(year: _year, month: _month, isLoadMore: false);
  }

  void _onMonthSelected(int month) {
    if (_loading) {
      return;
    }
    setState(() {
      _month = month;
      _recommended = null;
    });
    _fetchRecommended(year: _year, month: _month, isLoadMore: false);
  }

  @override
  void initState() {
    super.initState();
    _recommended = LocalStore.getHomeCache();
    _scrollController.addListener(_onScrollToBottom);
    if (_recommended == null || _recommended?.data?.isEmpty == true) {
      _fetchRecommended(year: _year, month: _month);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: isLandscape
          ? AppBar(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: SegmentedButton(
                segments: [
                  ButtonSegment(value: 1, label: Text("冬季")),
                  ButtonSegment(value: 4, label: Text("春季")),
                  ButtonSegment(value: 7, label: Text("夏季")),
                  ButtonSegment(value: 10, label: Text("秋季")),
                ],
                onSelectionChanged: (value) {
                  log("home->month selected: ${value.first}");
                  _onMonthSelected(value.first);
                  _page = value.first;
                },
                selected: {_month},
              ),
              leading: PopupMenuButton(
                icon: Icon(Icons.calendar_month),
                onSelected: (value) {
                  _onYearSelected(value);
                },
                itemBuilder: (context) {
                  var item = <PopupMenuItem<int>>[];
                  var year = DateTime.now().year;
                  for (var i = 2000; i <= year; i++) {
                    item.add(
                      PopupMenuItem(
                        value: i,
                        child: Text(
                          i.toString(),
                          style: TextStyle(
                            color: i == _year
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                      ),
                    );
                  }
                  return item.reversed.toList();
                },
              ),
            )
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
                    : (_recommended == null ||
                          _recommended?.data?.isEmpty == true)
                    ? const ShimmerSkeleton()
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

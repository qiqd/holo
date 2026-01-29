import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/calendar.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/ui/component/shimmer.dart';
import 'package:holo/util/local_store.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController = TabController(vsync: this, length: 7);
  List<Calendar> _calendar = [];
  String? _msg;
  List<String> _weekdays = tr("calendar.week").split(',');
  void _fetchCalendar() async {
    if (_calendar.isNotEmpty && DateTime.now().hour % 3 != 0) {
      return;
    }
    final calendar = await Api.bangumi.fetchCalendarSync(
      (e) => setState(() {
        _msg = e.toString();
      }),
    );
    setState(() {
      _calendar = calendar;
    });
    LocalStore.setCalendarCache(calendar);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    setState(() {
      _weekdays = "calendar.week".tr().split(',');
      _tabController = TabController(vsync: this, length: 7);
    });
  }

  @override
  void initState() {
    _calendar = LocalStore.getCalendarCache();
    _fetchCalendar();
    WidgetsBinding.instance.addObserver(this);
    _tabController.animateTo(DateTime.now().weekday - 1);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        actionsPadding: .symmetric(horizontal: 12),
        title: Text(tr("calendar.title")),
        actions: [
          if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) ...[
            IconButton(
              tooltip: 'Refresh Calendar',
              onPressed: _fetchCalendar,
              icon: Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelPadding: .zero,
            tabs: List.generate(7, (index) => Tab(text: _weekdays[index])),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) {
                return _msg != null
                    ? LoadingOrShowMsg(msg: _msg)
                    : _calendar.isEmpty
                    ? const ShimmerSkeleton()
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _calendar[index].items?.length ?? 0,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isLandscape ? 6 : 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, itemIndex) {
                          final item = _calendar[index].items;
                          var nameCN = item?[itemIndex].nameCn ?? '';
                          var name = item?[itemIndex].name ?? "";
                          return MediaGrid(
                            id: "calendar_${item![itemIndex].id ?? 0}",
                            rating:
                                item[itemIndex].rating?.score?.toDouble() ?? 0,
                            imageUrl: item[itemIndex].images?.large ?? '',
                            title: nameCN.isNotEmpty ? nameCN : name,
                            airDate: item[itemIndex].airDate ?? "1999-9-9",
                            onTap: () => context.push(
                              '/detail',
                              extra: {
                                'id': item[itemIndex].id!,
                                'keyword':
                                    item[itemIndex].nameCn ??
                                    item[itemIndex].name ??
                                    "",
                                'cover': item[itemIndex].images?.large ?? '',
                                'from': "calendar",
                              },
                            ),
                          );
                        },
                      );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

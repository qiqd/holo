import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/calendar.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/ui/component/shimmer.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    vsync: this,
    length: 7,
  );
  List<Calendar> _calendar = [];
  String? _msg;
  final List<String> _weekdays = tr("calendar.week").split(',');
  void _fetchCalendar() async {
    final calendar = await Api.bangumi.fetchCalendarSync(
      (e) => setState(() {
        _msg = e.toString();
      }),
    );
    setState(() {
      _calendar = calendar;
    });
  }

  @override
  void initState() {
    _fetchCalendar();
    _tabController.animateTo(DateTime.now().weekday - 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("calendar.title"))),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: List.generate(7, (index) => Tab(text: _weekdays[index])),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) {
                return _msg != null
                    ? LoadingOrShowMsg(msg: _msg)
                    : _calendar.isEmpty
                    ? buildShimmerSkeleton()
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _calendar[index].items?.length ?? 0,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, itemIndex) {
                          final item = _calendar[index].items;
                          return MediaGrid(
                            id: "calendar_${item![itemIndex].id ?? 0}",
                            rating:
                                item[itemIndex].rating?.score?.toDouble() ?? 0,
                            imageUrl: item[itemIndex].images?.large ?? '',
                            title:
                                item[itemIndex].nameCn ??
                                item[itemIndex].name ??
                                '',

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

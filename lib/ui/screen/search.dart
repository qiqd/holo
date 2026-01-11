import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Subject? _recommended;
  bool _loading = false;

  List<String> _searchHistory = [];
  final TextEditingController _controller = TextEditingController();
  void _fetchSearch(String keyword, BuildContext content) async {
    if (keyword.isEmpty) return;
    if (_searchHistory.contains(keyword)) {
      _searchHistory.remove(keyword);
    }
    _searchHistory.insert(0, keyword);
    LocalStore.saveSearchHistory(_searchHistory);
    setState(() {
      _loading = true;
    });
    final result = await Api.bangumi.fetchSearchSync(keyword, (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("search.error_searching".tr(args: [e.toString()])),
        ),
      );
    });
    setState(() {
      _loading = false;
      _recommended = result;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchHistory = LocalStore.getSearchHistory();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("search.delete_search_history".tr()),
        content: Text("search.confirm_delete_search_history".tr()),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text("search.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              LocalStore.removeAllSearchHistory();
              setState(() {
                _searchHistory.clear();
              });
              context.pop();
            },
            child: Text("search.confirm".tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              _showDeleteDialog();
            },
            icon: Icon(Icons.delete_forever_rounded),
            tooltip: "search.delete_search_history".tr(),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
        title: TextField(
          controller: _controller,
          onSubmitted: (value) {
            _fetchSearch(value, context);
          },
          onChanged: (_) {
            setState(() {});
          },
          maxLines: 1,
          autofocus: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: _controller.value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () => setState(() {
                      _recommended = null;
                      _controller.clear();
                    }),
                  )
                : null,
            hintText: "search.hint_text".tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading) LinearProgressIndicator(),
            Expanded(
              child: SizedBox(
                child: _recommended == null
                    ? SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                "search.search_history".tr(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    children: _searchHistory.map((historyItem) {
                                      return Chip(
                                        label: InkWell(
                                          child: Text(historyItem),
                                          onTap: () => _fetchSearch(
                                            historyItem,
                                            context,
                                          ),
                                        ),
                                        avatar: Icon(Icons.history, size: 18),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.5),
                                        deleteIcon: Icon(Icons.close, size: 18),
                                        onDeleted: () {
                                          setState(() {
                                            _searchHistory.remove(historyItem);
                                            LocalStore.saveSearchHistory(
                                              _searchHistory,
                                            );
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
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
                            id: "search_${item.id!}",
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
                                  'cover': item.images?.large ?? '',
                                  'from': "search",
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

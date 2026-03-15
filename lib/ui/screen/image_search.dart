import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:image_picker/image_picker.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  List<Map<String, dynamic>>? _searchResult;
  List<SubjectItem> _subject = [];
  XFile? _image;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  void _fetchAnimeFromImage() async {
    if (_isLoading) {
      return;
    }
    safeSetState(() {
      _isLoading = true;
      _searchResult = null;
      _subject = [];
    });
    var result = await Api.animeTrace.findAnimeFromImage(
      image: _image!,
      onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('image_search.image_search_error'))),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _searchResult = result;
      });
      var res = await Api.bangumi.fetchSearch(result.first['work'], (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('image_search.subject_search_error'))),
        );
      });
      safeSetState(() {
        _subject = res;
      });
    }
    safeSetState(() {
      _searchResult = result;
      _isLoading = false;
    });
  }

  void _imagePick() async {
    if (_isLoading) {
      return;
    }
    final response = await _picker.pickImage(source: ImageSource.gallery);

    if (response == null) {
      return;
    }
    final file = File(response.path);
    final fileSize = await file.length();
    const maxSize = 2 * 1024 * 1024;

    if ((fileSize > maxSize) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('image_search.image_size_tip'))),
      );
      return;
    }
    setState(() {
      _image = response;
    });
    log('pick image: ${response.path}');
    _fetchAnimeFromImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        animateColor: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(tr('image_search.title')),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          // spacing: 6,
          children: [
            if (_isLoading) LinearProgressIndicator(),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _imagePick();
                  },
                  child: Text(tr('image_search.picker_title')),
                ),
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  child: (_image != null && !_isLoading)
                      ? FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.red,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _image = null;
                              _searchResult = null;
                              _subject = [];
                            });
                          },
                          child: Text(
                            tr('image_search.reset'),
                            style: TextStyle(
                              color: (_image != null && !_isLoading)
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                          ),
                        )
                      : SizedBox(),
                ),
              ],
            ),
            // 显示选中的图片
            AnimatedContainer(
              height: _image != null ? 150 : 0,
              constraints: BoxConstraints(maxHeight: 200),
              duration: Duration(milliseconds: 300),
              child: Card(
                margin: EdgeInsets.all(0),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    spacing: 6,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width / 2,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_image?.path ?? ''),
                            fit: BoxFit.fitHeight,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.error_outline_rounded),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.person_outline_rounded),
                                title: Container(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    child: Text(
                                      _searchResult?.first['character'] ??
                                          tr('image_search.no_character'),
                                      key: ValueKey<String>(
                                        _searchResult?.first['character'] ??
                                            tr('image_search.no_character'),
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Icon(Icons.video_label_rounded),
                                title: Container(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    child: Text(
                                      _searchResult?.first['work'] ??
                                          tr('image_search.no_work'),
                                      maxLines: 5,
                                      key: ValueKey<String>(
                                        _searchResult?.first['work'] ??
                                            tr('image_search.no_work'),
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 显示搜索结果
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _subject.length,
                padding: EdgeInsets.symmetric(vertical: 6),
                itemBuilder: (context, index) {
                  var data = _subject[index];
                  return MediaGrid(
                    id: "image.search_${data.id}",
                    imageUrl: data.images.large ?? '',
                    title: data.title,
                    airDate: data.airDate,
                    onTap: () {
                      context.push(
                        '/detail',
                        extra: {
                          "id": data.id,
                          "keyword": data.title,
                          "cover": data.images.large ?? '',
                          "from": "image.search",
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

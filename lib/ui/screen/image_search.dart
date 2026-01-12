import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:image_picker/image_picker.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  List<Map<String, dynamic>>? _searchResult;
  Subject? _subject;
  XFile? _image;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  void _fetchAnimeFromImage() async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _searchResult = null;
      _subject = null;
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
      var res = await Api.bangumi.fetchSearchSync(result.first['work'], (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('image_search.subject_search_error'))),
        );
      });
      setState(() {
        _subject = res;
      });
    } else {}
    setState(() {
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
          spacing: 6,
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

                AnimatedContainer(
                  width: (_image != null && !_isLoading) ? 100 : 0,
                  duration: Duration(milliseconds: 300),
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                    ),
                    onPressed: () {
                      setState(() {
                        _image = null;
                        _searchResult = null;
                        _subject = null;
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
                  ),
                ),
              ],
            ),
            AnimatedOpacity(
              opacity: _image != null ? 1 : 0,
              duration: Duration(milliseconds: 300),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxHeight: 200),
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
                      ),
                      Flexible(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.person_outline_rounded),
                              title: Text(
                                _searchResult?.first['character'] ??
                                    tr('image_search.no_character'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ListTile(
                              trailing: null,
                              leading: Icon(Icons.video_label_rounded),
                              title: Text(
                                _searchResult?.first['work'] ??
                                    tr('image_search.no_work'),
                                maxLines: 5,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _subject == null
                  ? Center(child: Text(tr('image_search.no_work')))
                  : ListView.separated(
                      itemCount: _subject?.data?.length ?? 0,
                      separatorBuilder: (context, index) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        var data = _subject?.data;
                        return MediaCard(
                          id: "image.search_${data?[index].id!}",
                          imageUrl: data?[index].images?.large ?? '',
                          nameCn: data?[index].nameCn ?? '',
                          airDate: data?[index].date,
                          genre: data?[index].metaTags?.join('/') ?? '',
                          onTap: () {
                            context.push(
                              '/detail',
                              extra: {
                                "id": data?[index].id ?? 0,
                                "keyword": data?[index].nameCn ?? '',
                                "cover": data?[index].images?.large ?? '',
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

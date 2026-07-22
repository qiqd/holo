import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/anime_info.dart';
import 'package:holo/extension/safe_set_state_extension.dart';
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
  List<AnimeInfo> _subject = [];
  XFile? _image;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  Future<void> _fetchAnimeFromImage() async {
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

  Future<void> _imagePick() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(animateColor: true, title: Text(tr('image_search.title'))),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox.expand(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 200,
                        height: 200,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: [
                            if (_image != null)
                              Image.file(File(_image!.path), fit: BoxFit.cover),
                            InkWell(
                              onTap: () {
                                _imagePick();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Align(
                                alignment: Alignment.center,
                                child:
                                    _image == null ||
                                        _image?.path.isEmpty == true
                                    ? Icon(Icons.upload_rounded)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_image == null ||
                                  _image?.path.isEmpty == true) {
                                return;
                              }

                              _fetchAnimeFromImage();
                            },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLoading
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  year2023: false,
                                ),
                              )
                            : Text(tr('image_search.search')),
                      ),
                    ),
                  ),
                ),
                if (_searchResult != null)
                  SliverToBoxAdapter(
                    child: Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.person_rounded),
                            title: Text(
                              _searchResult?.first['character'] ??
                                  tr('image_search.no_character'),
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.local_movies_outlined),
                            title: Text(
                              _searchResult?.first['work'] ??
                                  tr('image_search.no_work'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 显示搜索结果
                if (_subject.isNotEmpty) ...[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.6,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        childCount: _subject.length,
                        (context, index) {
                          var data = _subject[index];
                          return MediaGrid(
                            id: "image.search_${data.id}",
                            imageUrl: data.images.large ?? '',
                            title: data.title,
                            airDate: data.airDateTime != null
                                ? DateFormat.yMd().format(data.airDateTime!)
                                : null,
                            onTap: () {
                              context.push(
                                '/detail',
                                extra: {
                                  "id": data.id,
                                  "keyword": data.title,
                                  "cover": data.images.large ?? '',
                                  "from": "image.search",
                                  "subject": data,
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

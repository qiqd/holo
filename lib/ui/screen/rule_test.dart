import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:video_player/video_player.dart';

class RuleTestScreen extends StatefulWidget {
  final SourceService source;
  final bool showNavBtn;
  const RuleTestScreen({
    super.key,
    required this.source,
    this.showNavBtn = true,
  });

  @override
  State<RuleTestScreen> createState() => _RuleTestScreenState();
}

class _RuleTestScreenState extends State<RuleTestScreen> {
  String _keyword = '';
  List<Media> _mediaList = [];
  Detail? _detail;
  String? _playUrl;
  bool _isloading = false;
  VideoPlayerController? _controller;
  void _fetchTest() async {
    bool hasError = false;
    setState(() {
      _isloading = true;
    });
    try {
      var search = await widget.source.fetchSearch(_keyword, 1, 10, (e) {
        hasError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('fetch search error: ${e.toString()}')),
        );
      });
      setState(() {
        _mediaList = search;
      });
      if (hasError) {
        return;
      }
      var detail = await widget.source.fetchDetail(_mediaList[0].id!, (e) {
        hasError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('fetch detail error: ${e.toString()}')),
        );
      });
      log('detail: ${detail?.toJson()}');
      setState(() {
        _detail = detail;
      });
      if (hasError || detail == null || detail.lines!.isEmpty) {
        return;
      }
      var url = await widget.source.fetchPlaybackUrl(
        detail.lines![0].episodes![0],
        (e) {
          hasError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('fetch view error: ${e.toString()}')),
          );
        },
      );
      if (url == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('video url is null')));
        return;
      }
      _controller =
          VideoPlayerController.networkUrl(
              Uri.parse(Uri.parse(url!).toString()),
            )
            ..initialize()
            ..play().then((_) {
              setState(() {});
            });
      setState(() {
        _playUrl = url;
        _isloading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isloading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('test error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.showNavBtn
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => context.pop(),
              )
            : SizedBox(),
        title: Text('${widget.source.getName()} Test'),
      ),
      body: Container(
        padding: .only(bottom: 20),
        width: double.infinity,
        height: double.infinity,
        child: SizedBox(
          child: SingleChildScrollView(
            padding: .symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                  onSubmitted: (value) {
                    _fetchTest();
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Input keyword',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                if (_isloading) const LinearProgressIndicator(),
                Text(
                  'Search Result:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: GridView.builder(
                    itemCount: _mediaList.length,
                    scrollDirection: .horizontal,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 6,
                      childAspectRatio: 4 / 3,
                    ),
                    itemBuilder: (context, index) {
                      return MediaGrid(
                        id: _mediaList[index].id!,
                        title: _mediaList[index].title,
                        imageUrl: _mediaList[index].coverUrl,
                      );
                    },
                  ),
                ),
                Text(
                  'Detail Result:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _detail?.lines?.length ?? 0,
                    itemBuilder: (context, lineIndex) {
                      var line = _detail?.lines?[lineIndex];
                      return SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: GridView.builder(
                          itemCount: line?.episodes?.length ?? 0,
                          scrollDirection: .horizontal,
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                                childAspectRatio: 1 / 2.5,
                              ),
                          itemBuilder: (context, episodeIndex) {
                            return ChoiceChip(
                              label: Text(
                                'source${lineIndex + 1}-ep${episodeIndex + 1}',
                              ),
                              selected: false,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  'Player Result:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: _controller?.value.isInitialized ?? false
                        ? AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VideoPlayer(_controller!),
                          )
                        : Container(
                            color: Colors.black,
                            child: Text(
                              'url: $_playUrl',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

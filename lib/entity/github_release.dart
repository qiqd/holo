import 'package:json_annotation/json_annotation.dart';
part 'github_release.g.dart';

@JsonSerializable(explicitToJson: true)
class GitHubRelease {
  @JsonKey(name: 'tag_name')
  final String? tagName;
  @JsonKey(name: 'target_commitish')
  final String? targetCommitish;
  final String? name;
  final bool? draft;
  final bool? immutable;
  final bool? prerelease;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
  final List<GitHubAsset>? assets;
  @JsonKey(name: 'tarball_url')
  final String? tarballUrl;
  @JsonKey(name: 'zipball_url')
  final String? zipballUrl;
  final String? body;
  GitHubRelease({
    this.tagName,
    this.targetCommitish,
    this.name,
    this.draft,
    this.immutable,
    this.prerelease,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.assets,
    this.tarballUrl,
    this.zipballUrl,
    this.body,
  });
  factory GitHubRelease.fromJson(Map<String, dynamic> json) =>
      _$GitHubReleaseFromJson(json);
  Map<String, dynamic> toJson() => _$GitHubReleaseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class GitHubAsset {
  final String? url;
  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'node_id')
  final String? nodeId;
  final String? name;
  final String? label;
  @JsonKey(name: 'content_type')
  final String? contentType;
  final String? state;
  final int? size;
  final String? digest;
  @JsonKey(name: 'download_count')
  final int? downloadCount;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'browser_download_url')
  final String? browserDownloadUrl;

  GitHubAsset({
    this.url,
    this.id,
    this.nodeId,
    this.name,
    this.label,
    this.contentType,
    this.state,
    this.size,
    this.digest,
    this.downloadCount,
    this.createdAt,
    this.updatedAt,
    this.browserDownloadUrl,
  });
  factory GitHubAsset.fromJson(Map<String, dynamic> json) =>
      _$GitHubAssetFromJson(json);
  Map<String, dynamic> toJson() => _$GitHubAssetToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SimpleGitHubAsset {
  String? currentVersion;
  String? latestVersion;
  String? releaseLog;
  String? browserDownloadUrl;
  SimpleGitHubAsset({
    this.currentVersion,
    this.latestVersion,
    this.releaseLog,
    this.browserDownloadUrl,
  });
  factory SimpleGitHubAsset.fromJson(Map<String, dynamic> json) =>
      _$SimpleGitHubAssetFromJson(json);
  Map<String, dynamic> toJson() => _$SimpleGitHubAssetToJson(this);
}

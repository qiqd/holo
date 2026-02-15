// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubRelease _$GitHubReleaseFromJson(Map<String, dynamic> json) =>
    GitHubRelease(
      tagName: json['tag_name'] as String?,
      targetCommitish: json['target_commitish'] as String?,
      name: json['name'] as String?,
      draft: json['draft'] as bool?,
      immutable: json['immutable'] as bool?,
      prerelease: json['prerelease'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      assets: (json['assets'] as List<dynamic>?)
          ?.map((e) => GitHubAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
      tarballUrl: json['tarball_url'] as String?,
      zipballUrl: json['zipball_url'] as String?,
      body: json['body'] as String?,
    );

Map<String, dynamic> _$GitHubReleaseToJson(GitHubRelease instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
      'target_commitish': instance.targetCommitish,
      'name': instance.name,
      'draft': instance.draft,
      'immutable': instance.immutable,
      'prerelease': instance.prerelease,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'published_at': instance.publishedAt?.toIso8601String(),
      'assets': instance.assets?.map((e) => e.toJson()).toList(),
      'tarball_url': instance.tarballUrl,
      'zipball_url': instance.zipballUrl,
      'body': instance.body,
    };

GitHubAsset _$GitHubAssetFromJson(Map<String, dynamic> json) => GitHubAsset(
  url: json['url'] as String?,
  id: (json['id'] as num?)?.toInt(),
  nodeId: json['node_id'] as String?,
  name: json['name'] as String?,
  label: json['label'] as String?,
  contentType: json['content_type'] as String?,
  state: json['state'] as String?,
  size: (json['size'] as num?)?.toInt(),
  digest: json['digest'] as String?,
  downloadCount: (json['download_count'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  browserDownloadUrl: json['browser_download_url'] as String?,
);

Map<String, dynamic> _$GitHubAssetToJson(GitHubAsset instance) =>
    <String, dynamic>{
      'url': instance.url,
      'id': instance.id,
      'node_id': instance.nodeId,
      'name': instance.name,
      'label': instance.label,
      'content_type': instance.contentType,
      'state': instance.state,
      'size': instance.size,
      'digest': instance.digest,
      'download_count': instance.downloadCount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'browser_download_url': instance.browserDownloadUrl,
    };

SimpleGitHubAsset _$SimpleGitHubAssetFromJson(Map<String, dynamic> json) =>
    SimpleGitHubAsset(
      currentVersion: json['currentVersion'] as String?,
      latestVersion: json['latestVersion'] as String?,
      releaseLog: json['summary'] as String?,
      browserDownloadUrl: json['browserDownloadUrl'] as String?,
    );

Map<String, dynamic> _$SimpleGitHubAssetToJson(SimpleGitHubAsset instance) =>
    <String, dynamic>{
      'currentVersion': instance.currentVersion,
      'latestVersion': instance.latestVersion,
      'summary': instance.releaseLog,
      'browserDownloadUrl': instance.browserDownloadUrl,
    };

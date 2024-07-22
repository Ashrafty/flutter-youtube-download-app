import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeService {
  final _yt = YoutubeExplode();

  Future<Video> getVideoInfo(String url) async {
    return await _yt.videos.get(url);
  }

  Future<List<DownloadOption>> getDownloadOptions(String url) async {
    var manifest = await _yt.videos.streamsClient.getManifest(url);
    List<DownloadOption> options = [];

    // Video with audio options
    options.addAll(manifest.muxed.map((s) => DownloadOption(
          type: DownloadType.videoWithAudio,
          quality: s.videoQuality.toString(),
          formatNote: 'mp4',
          size: s.size.totalBytes,
          itag: s.tag,
        )));

    // Video-only options
    options.addAll(manifest.videoOnly.map((s) => DownloadOption(
          type: DownloadType.videoOnly,
          quality: s.videoQuality.toString(),
          formatNote: s.container.name,
          size: s.size.totalBytes,
          itag: s.tag,
        )));

    // Audio-only options
    options.addAll(manifest.audioOnly.map((s) => DownloadOption(
          type: DownloadType.audioOnly,
          quality: '${s.bitrate.kiloBitsPerSecond.round()} kbps',
          formatNote: s.container.name,
          size: s.size.totalBytes,
          itag: s.tag,
        )));

    return options;
  }

  Future<String> downloadMedia(String videoId, DownloadOption option, String path, Function(double) onProgress) async {
    print('Starting download for video: $videoId');
    var manifest = await _yt.videos.streamsClient.getManifest(videoId);
    StreamInfo? streamInfo;

    switch (option.type) {
      case DownloadType.videoWithAudio:
        streamInfo = manifest.muxed.firstWhere((s) => s.tag == option.itag);
        break;
      case DownloadType.videoOnly:
        streamInfo = manifest.videoOnly.firstWhere((s) => s.tag == option.itag);
        break;
      case DownloadType.audioOnly:
        streamInfo = manifest.audioOnly.firstWhere((s) => s.tag == option.itag);
        break;
    }

    if (streamInfo == null) {
      throw Exception('Unable to find the specified stream');
    }

    print('Stream info: ${streamInfo.codec}, ${streamInfo.size.totalBytes} bytes');
    var stream = _yt.videos.streamsClient.get(streamInfo);
    var file = File(path);
    var fileStream = file.openWrite();
    var totalBytes = streamInfo.size.totalBytes;
    var bytesReceived = 0;

    try {
      await for (final chunk in stream) {
        fileStream.add(chunk);
        bytesReceived += chunk.length;
        var progress = bytesReceived / totalBytes;
        print('Download progress: ${(progress * 100).toStringAsFixed(2)}%');
        onProgress(progress);
      }
    } catch (e) {
      print('Error during download: $e');
      rethrow;
    } finally {
      await fileStream.flush();
      await fileStream.close();
    }

    print('Download completed. Verifying file size...');
    var fileSize = await file.length();
    if (fileSize != totalBytes) {
      print('File size mismatch. Expected: $totalBytes, Actual: $fileSize');
      throw Exception('Download incomplete: expected $totalBytes bytes, got $fileSize bytes');
    }

    print('File size verified. Download successful.');
    return file.path;
  }

  void dispose() {
    _yt.close();
  }
}

enum DownloadType { videoWithAudio, videoOnly, audioOnly }

class DownloadOption {
  final DownloadType type;
  final String quality;
  final String formatNote;
  final int size;
  final int itag;

  DownloadOption({
    required this.type,
    required this.quality,
    required this.formatNote,
    required this.size,
    required this.itag,
  });

  String get typeString {
    switch (type) {
      case DownloadType.videoWithAudio:
        return 'Video with Audio';
      case DownloadType.videoOnly:
        return 'Video Only';
      case DownloadType.audioOnly:
        return 'Audio Only';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'quality': quality,
      'formatNote': formatNote,
      'size': size,
      'itag': itag,
    };
  }

  factory DownloadOption.fromJson(Map<String, dynamic> json) {
    return DownloadOption(
      type: DownloadType.values[json['type']],
      quality: json['quality'],
      formatNote: json['formatNote'],
      size: json['size'],
      itag: json['itag'],
    );
  }
}
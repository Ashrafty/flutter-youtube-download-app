import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_picker/file_picker.dart';
import '../services/youtube_service.dart';
import '../services/file_service.dart';
import '../services/background_download_service.dart';
import '../widgets/video_info_card.dart';
import '../widgets/download_button.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _youtubeService = YouTubeService();
  final _fileService = FileService();
  final _urlController = TextEditingController();
  Video? _videoInfo;
  List<DownloadOption>? _downloadOptions;
  bool _isLoading = false;
  String? _error;
  String? _currentDownloadPath;
  String _downloadStatus = '';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentDownloadPath();
    BackgroundDownloadService.initializeService();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _youtubeService.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isDownloading) {
      _startBackgroundDownload();
    }
  }

  void _loadCurrentDownloadPath() async {
    final path = await _fileService.getDownloadPath();
    setState(() {
      _currentDownloadPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YouTube Downloader')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildInputPanel(),
        ),
        VerticalDivider(width: 1, thickness: 1),
        Expanded(
          flex: 2,
          child: _buildOutputPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputPanel(),
          Divider(height: 1, thickness: 1),
          _buildOutputPanel(),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'YouTube URL',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _getVideoInfo,
            child: Text('Get Video Info'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _changeDownloadPath,
            child: Text('Change Download Path'),
          ),
          SizedBox(height: 8),
          Text('Current download path:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(_currentDownloadPath ?? 'Not set', style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 16),
          if (_isDownloading)
            Column(
              children: [
                LinearProgressIndicator(value: _downloadProgress),
                SizedBox(height: 8),
                Text('${(_downloadProgress * 100).toStringAsFixed(2)}%'),
              ],
            )
          else
            Text(_downloadStatus),
        ],
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : _videoInfo != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VideoInfoCard(video: _videoInfo!),
                        SizedBox(height: 16),
                        Text('Download Options:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        if (_downloadOptions != null)
                          ..._downloadOptions!.map((option) => Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: DownloadButton(
                                  option: option,
                                  onPressed: _downloadMedia,
                                ),
                              )),
                      ],
                    )
                  : Center(child: Text('Enter a YouTube URL and click "Get Video Info"')),
    );
  }

  void _getVideoInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _videoInfo = null;
      _downloadOptions = null;
      _downloadStatus = '';
    });
    try {
      final videoInfo = await _youtubeService.getVideoInfo(_urlController.text);
      final options = await _youtubeService.getDownloadOptions(_urlController.text);
      setState(() {
        _videoInfo = videoInfo;
        _downloadOptions = options;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadMedia(DownloadOption option) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Starting download...';
    });

    try {
      final extension = option.type == DownloadType.audioOnly ? 'mp3' : 'mp4';
      final fileName = '${_videoInfo!.title}.$extension'.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final path = await _fileService.getLocalFile(fileName);
      await _youtubeService.downloadMedia(_videoInfo!.id.value, option, path.path, _updateProgress);
      setState(() {
        _downloadStatus = 'Download complete: ${path.path}';
      });
    } catch (e) {
      print('Download error: $e');
      setState(() {
        _downloadStatus = 'Download failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _downloadProgress = progress;
      _downloadStatus = 'Downloading: ${(progress * 100).toStringAsFixed(2)}%';
    });
  }

  void _startBackgroundDownload() async {
    if (_videoInfo != null && _downloadOptions != null) {
      final option = _downloadOptions![0]; // You might want to let the user choose which option to use for background download
      final extension = option.type == DownloadType.audioOnly ? 'mp3' : 'mp4';
      final fileName = '${_videoInfo!.title}.$extension'.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final path = await _fileService.getLocalFile(fileName);
      await BackgroundDownloadService.startDownload(_videoInfo!.id.value, option, path.path);
    }
  }

  Future<void> _changeDownloadPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await _fileService.setCustomDownloadPath(selectedDirectory);
      _loadCurrentDownloadPath();
    }
  }
}
import 'package:flutter/material.dart';
import '../services/youtube_service.dart';

class DownloadButton extends StatefulWidget {
  final DownloadOption option;
  final Future<void> Function(DownloadOption option) onPressed;
  
  const DownloadButton({
    Key? key,
    required this.option,
    required this.onPressed,
  }) : super(key: key);

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isDownloading ? null : _startDownload,
      child: Text(_isDownloading
          ? 'Downloading...'
          : '${widget.option.typeString} - ${widget.option.quality} ${widget.option.formatNote} (${_formatFileSize(widget.option.size)})'),
    );
  }

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
    });
    try {
      await widget.onPressed(widget.option);
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
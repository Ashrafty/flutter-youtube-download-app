import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/youtube_service.dart';
import '../services/file_service.dart';

class BackgroundDownloadService {
  static const String _isolateName = 'backgroundDownload';
  static YouTubeService? _youtubeService;
  static FileService? _fileService;
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(android: androidInitialize);
    await _notificationsPlugin!.initialize(initializationSettings);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'youtube_downloader_channel',
        initialNotificationTitle: 'YouTube Downloader',
        initialNotificationContent: 'Preparing download...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    _youtubeService = YouTubeService();
    _fileService = FileService();

    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    if (sendPort != null) {
      service.on('download').listen((event) async {
        if (event != null) {
          final videoId = event['videoId'] as String;
          final option = DownloadOption.fromJson(event['option'] as Map<String, dynamic>);
          final path = event['path'] as String;

          try {
            await _youtubeService!.downloadMedia(videoId, option, path, (progress) {
              sendPort.send({'status': 'progress', 'progress': progress});
              _updateNotification(progress);
            });
            sendPort.send({'status': 'completed', 'path': path});
            _showCompletionNotification();
          } catch (e) {
            sendPort.send({'status': 'error', 'message': e.toString()});
            _showErrorNotification(e.toString());
          }
        }
      });
    }
  }

  static void _updateNotification(double progress) {
    _notificationsPlugin!.show(
      888,
      'Downloading',
      'Progress: ${(progress * 100).toStringAsFixed(2)}%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'youtube_downloader_channel',
          'YouTube Downloader',
          channelDescription: 'Download progress notification',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: (progress * 100).toInt(),
        ),
      ),
    );
  }

  static void _showCompletionNotification() {
    _notificationsPlugin!.show(
      888,
      'Download Completed',
      'Your video has been downloaded successfully',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'youtube_downloader_channel',
          'YouTube Downloader',
          channelDescription: 'Download completion notification',
        ),
      ),
    );
  }

  static void _showErrorNotification(String error) {
    _notificationsPlugin!.show(
      888,
      'Download Error',
      'An error occurred: $error',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'youtube_downloader_channel',
          'YouTube Downloader',
          channelDescription: 'Download error notification',
        ),
      ),
    );
  }

  static Future<void> startDownload(String videoId, DownloadOption option, String path) async {
    final service = FlutterBackgroundService();
    await service.startService();

    final ReceivePort receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName);

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        switch (message['status']) {
          case 'progress':
            print('Download progress: ${message['progress']}');
            break;
          case 'completed':
            print('Download completed: ${message['path']}');
            break;
          case 'error':
            print('Download error: ${message['message']}');
            break;
        }
      }
    });

    service.invoke('download', {
      'videoId': videoId,
      'option': option.toJson(),
      'path': path,
    });
  }
}
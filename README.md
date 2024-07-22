# YouTube Downloader

## Overview

YouTube Downloader is a Flutter application that allows users to download videos and audio from YouTube. The app provides a user-friendly interface for entering YouTube URLs, retrieving video information, and selecting download options based on quality and format.

## Features

- Enter YouTube URL to fetch video information
- Display video details including title, author, duration, and thumbnail
- Offer various download options (video with audio, video only, audio only)
- Download selected media in the background
- Change download path
- Support for both portrait and landscape orientations

## Technologies Used

- Flutter: UI framework for building natively compiled applications
- Dart: Programming language used with Flutter
- youtube_explode_dart: Library for interacting with YouTube
- flutter_background_service: For handling background downloads
- flutter_local_notifications: For showing download progress notifications
- permission_handler: For managing app permissions
- path_provider: For accessing device file system
- shared_preferences: For storing user preferences

## Project Structure

```
lib/
├── main.dart
├── screens/
│   └── home_screen.dart
├── services/
│   ├── youtube_service.dart
│   ├── file_service.dart
│   └── background_download_service.dart
└── widgets/
    ├── video_info_card.dart
    └── download_button.dart
```

## Main Components

1. **HomeScreen**: The main interface of the app, handling user input, video info display, and download options.
2. **YouTubeService**: Manages interactions with YouTube, including fetching video info and handling downloads.
3. **FileService**: Handles file system operations, including setting and getting the download path.
4. **BackgroundDownloadService**: Manages background download tasks and notifications.
5. **VideoInfoCard**: Widget for displaying video information.
6. **DownloadButton**: Widget for initiating downloads with specific options.

## Component Relationships

- `HomeScreen` uses `YouTubeService` to fetch video information and initiate downloads.
- `HomeScreen` uses `FileService` to manage download paths.
- `HomeScreen` uses `BackgroundDownloadService` to handle background downloads.
- `YouTubeService` uses `FileService` to write downloaded content to the file system.
- `BackgroundDownloadService` uses `YouTubeService` to perform downloads in the background.

## Building and Running the App

1. **Prerequisites**:
   - Install [Flutter](https://flutter.dev/docs/get-started/install)
   - Set up an Android or iOS development environment

2. **Clone the repository**:
   ```
   git clone https://github.com/Ashrafty/flutter-youtube-download-app.git
   cd youtube_downloader
   ```

3. **Install dependencies**:
   ```
   flutter pub get
   ```

4. **Run the app**:
   - Connect a device or start an emulator
   ```
   flutter run
   ```

5. **Building for release**:
   - Android:
     ```
     flutter build apk
     ```
   - iOS:
     ```
     flutter build ios
     ```

## Permissions

The app requires the following permissions:
- Internet access
- Read and write external storage
- Foreground service
- Wake lock

These permissions are necessary for downloading videos, saving them to the device, and performing background downloads.

## Contributing

Contributions to the YouTube Downloader project are welcome. Please feel free to submit pull requests or create issues for bugs and feature requests.

## License

[Specify your license here, e.g., MIT, GPL, etc.]

## Disclaimer

This app is for educational purposes only. Please respect YouTube's terms of service and content creators' rights when using this application.
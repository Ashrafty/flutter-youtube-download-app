import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoInfoCard extends StatelessWidget {
  final Video video;

  const VideoInfoCard({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.title,
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Text('Author: ${video.author}'),
            Text('Duration: ${video.duration}'),
            SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                video.thumbnails.highResUrl,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_trimmer/src/utils/trimmer_utils.dart';

class FixedThumbnailViewer extends StatefulWidget {
  /// The video file from which thumbnails are generated.
  final File videoFile;

  /// The total duration of the video in milliseconds.
  final int videoDuration;

  /// The height of each thumbnail.
  final double thumbnailHeight;

  /// How the thumbnails should be inscribed into the allocated space.
  final BoxFit fit;

  /// The number of thumbnails to generate.
  final int numberOfThumbnails;

  /// Callback function that is called when thumbnail loading is complete.
  final ValueChanged<List<Uint8List?>> onThumbnailLoadingComplete;

  /// The quality of the generated thumbnails, ranging from 0 to 100.
  final int quality;

  final List<Uint8List?>? thumbnails;

  /// For showing the thumbnails generated from the video,
  /// like a frame by frame preview
  ///
  /// - [videoFile] is the video file from which thumbnails are generated.
  /// - [videoDuration] is the total duration of the video in milliseconds.
  /// - [thumbnailHeight] is the height of each thumbnail.
  /// - [numberOfThumbnails] is the number of thumbnails to generate.
  /// - [fit] is how the thumbnails should be inscribed into the allocated space.
  /// - [onThumbnailLoadingComplete] is the callback function that is called when thumbnail loading is complete.
  /// - [quality] is the quality of the generated thumbnails, ranging from 0 to 100. Defaults to 75.
  const FixedThumbnailViewer({
    super.key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
    this.thumbnails,
  });

  @override
  State<StatefulWidget> createState() {
    return _FixedThumbnailViewerState();
  }
}

class _FixedThumbnailViewerState extends State<FixedThumbnailViewer> {
  late final ValueNotifier<List<Uint8List?>?> thumbnails;

  @override
  void initState() {
    super.initState();
    thumbnails = ValueNotifier(widget.thumbnails);
    _generateThumbnails();
  }

  _generateThumbnails() {
    try {
      if (thumbnails.value?.isNotEmpty ?? false) return;
      final stream = generateThumbnail(
        videoPath: widget.videoFile.path,
        videoDuration: widget.videoDuration,
        numberOfThumbnails: widget.numberOfThumbnails,
        quality: widget.quality,
        thumbnails: widget.thumbnails,
        onThumbnailLoadingComplete: widget.onThumbnailLoadingComplete,
      ).asBroadcastStream();
      stream.listen((bytes) {
        thumbnails.value = [...bytes];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Uint8List?>?>(
      valueListenable: thumbnails,
      child: Container(
        color: Colors.grey[900],
        height: widget.thumbnailHeight,
        width: double.maxFinite,
      ),
      builder: (context, byteArray, child) {
        final imageBytes = byteArray ?? [];

        if (imageBytes.isEmpty) {
          return child!;
        }
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: List.generate(
            widget.numberOfThumbnails,
            (index) => SizedBox(
              height: widget.thumbnailHeight,
              width: widget.thumbnailHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.2,
                    child: Image.memory(
                      imageBytes[0] ?? kTransparentImage,
                      fit: widget.fit,
                    ),
                  ),
                  index < imageBytes.length
                      ? FadeInImage(
                          placeholder: MemoryImage(kTransparentImage),
                          image: MemoryImage(imageBytes[index]!),
                          fit: widget.fit,
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

library mmeno.spritemap_generator;

import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:image/image.dart';
import 'package:logging/logging.dart';

Map<String, String> images = {
  'v1': '_verse1.png',
  'v2': '_verse2.png',
  'c': '_chorus.png',
  'c2': '_chorus2.png',
  'c3': '_chorus3.png'
};

String highlightsDir = new Directory.fromUri(Platform.script).parent.parent.parent.path;
String jsonDir = path.join(
    new Directory.fromUri(Platform.script).parent.parent.parent.parent.parent.parent.path, '_includes', 'flashlights');

Logger log = new Logger('Generator');

main(List args) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(print);

  if (args.isEmpty) {
    print('Usage: dart create_spritemap <options>');
    print('');
    print('Options:');
    print('  -v1: Verse 1');
    print('  -v2: Verse 2');
    print('  -c: Chorus');
    print('  -c2: Chorus 2');
    print('  -c3: Chorus 3');
    print('  -a: all');
  }

  var selectedImages = [];

  if (args.contains('-a')) selectedImages = images.values;
  else {
    selectedImages = images.keys.where((key) => args.contains('-$key')).map((key) => images[key]);
  }

  if (selectedImages.isEmpty) {
    print('Invalid options $args');
    exit(1);
  }

  for (var img in selectedImages) {
    await createSpritemap(img);
  }
}

createSpritemap(String filename) async {
  final lineHeight = 220;

  log.info('Reading file $filename...');
  final data = await new File(path.join(highlightsDir, filename)).readAsBytes();

  log.info('Decoding image (this might take a while)...');
  Image sourceImage = decodeImage(data);

  var sprites = <Sprite>[], currentX = 0;

  for (var i = 0; i < sourceImage.height / lineHeight; i++) {
    log.info('Processing image nr. $i');

    log.fine('Copying image to a temporary sprite image...');
    var untrimmedSpriteImage = copyCrop(sourceImage, 0, i * lineHeight, sourceImage.width, lineHeight);

    // [x, y, width, height]
    TrimRect trimRect;
    try {
      log.fine('Finding trim...');
      trimRect = new TrimRect.fromList(findTrim(untrimmedSpriteImage, mode: TRIM_TRANSPARENT));
    } on NoSuchMethodError {
      /// [findTrim] throws when there is no content, so we know it was the last image.
      break;
    }

    var spriteImage = copyCrop(untrimmedSpriteImage, trimRect.x, trimRect.y, trimRect.width, trimRect.height);

    int centeredX = ((sourceImage.width - trimRect.width) / 2).floor(),
        centeredY = ((lineHeight - trimRect.height) / 2).floor();

    sprites.add(new Sprite(
        spriteImage, currentX, trimRect.width, trimRect.height, trimRect.x - centeredX, trimRect.y - centeredY));

    currentX += trimRect.width;
  }
  int totalWidth = sprites.fold(0, (prevValue, sprite) => prevValue + sprite.width),
      totalHeight = sprites.fold(0, (prevValue, sprite) => math.max(prevValue, sprite.height));
  var finalImage = new Image(totalWidth, totalHeight);

  sprites.fold(0, (currentX, sprite) {
    copyInto(finalImage, sprite.image, dstX: currentX, blend: false);
    return currentX + sprite.width;
  });

  var targetFilename = filename.substring(1),
      targetPath = path.join(highlightsDir, targetFilename);

  log.info('Writing resulting spritemap to $targetFilename');

  await new File(targetPath).writeAsBytes(encodePng(finalImage));

  log.info('Optimizing png...');
  var processResult = await Process.run('optipng', ['-o3', targetFilename], workingDirectory: highlightsDir);

  print(processResult.stdout);
  print(processResult.stderr);
  if (processResult.exitCode != 0) throw new Exception('Unable to optimize png');


  var json = JSON.encode({
    'totalWidth': (totalWidth / 2).floor(),
    'totalHeight': (totalHeight / 2).floor(),
    'sprites': sprites.map((sprite) => sprite.toJson()).toList()
  });

  var jsonTargetPath = path.join(jsonDir, filename.substring(1).replaceFirst('.png', '.json'));
  log.info('Writing json information to to $jsonTargetPath');
  await new File(jsonTargetPath).writeAsString(json);
}

class TrimRect {
  final int x;
  final int y;
  final int width;
  final int height;
  TrimRect.fromList(List<int> trimRect)
      : this.x = trimRect[0],
        this.y = trimRect[1],
        this.width = trimRect[2],
        this.height = trimRect[3];
}

/// Holds necessary information about a sprite in the sprite map
class Sprite {
  /// The actual image data
  final Image image;

  /// The width of the sprite
  final int width;

  /// The height of the sprite
  final int height;

  /// The x position of the sprite in the spritemap
  final int x;

  /// The y position of the sprite in the spritemap.
  /// We always place the sprite at the top of the image for now.
  final int y = 0;

  /// This defines how many pixel this image is horizontally offset from its center
  final int offsetX;

  /// This defines how many pixel this image is vertically offset from its center
  final int offsetY;

  Sprite(this.image, this.x, this.width, this.height, this.offsetX, this.offsetY);

  String toString() => 'Sprite: x: $x y: $y width: $width height: $height offsetX: $offsetX offsetY: $offsetY';

  Map toJson() => {
        'x': (x / 2).floor(),
        'width': (width / 2).floor(),
        'height': (height / 2).floor(),
        'offsetX': (offsetX / 2).floor(),
        'offsetY': (offsetY / 2).floor()
      };
}

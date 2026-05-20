import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

const shareQrUrl = 'https://www.bilibili.com';

/// Widget → 离屏渲染为 ui.Image
Future<ui.Image> renderToImage(GlobalKey key, {double pixelRatio = 3.0}) async {
  final obj = key.currentContext?.findRenderObject();
  if (obj is! RenderRepaintBoundary) throw Exception('RepaintBoundary not found');
  return obj.toImage(pixelRatio: pixelRatio);
}

/// ui.Image → PNG bytes
Future<Uint8List> imageToPngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw Exception('Failed to convert image to PNG');
  return byteData.buffer.asUint8List();
}

/// 保存 PNG 到缓存并返回文件路径
Future<String> saveToCache(Uint8List pngBytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename.png');
  await file.writeAsBytes(pngBytes);
  return file.path;
}

/// 分享图片文件
Future<void> shareImageFile(String filePath, {String? subject}) async {
  await Share.shareXFiles(
    [XFile(filePath)],
    subject: subject,
  );
}

/// 分享文本
Future<void> shareText(String text, {String? subject}) async {
  await Share.share(text, subject: subject);
}

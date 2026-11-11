import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object> tourImageProvider(String path) {
  final uri = Uri.tryParse(path);
  if (uri?.scheme == 'file') return FileImage(File.fromUri(uri!));
  if (uri?.scheme == 'http' || uri?.scheme == 'https') {
    return NetworkImage(path);
  }
  return AssetImage(path);
}

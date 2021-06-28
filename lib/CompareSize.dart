import 'package:image/image.dart';
import 'dart:io';
import 'package:flutter/material.dart';

Size GetSizeImage(String pathImage){
  var bytes  = File(pathImage).readAsBytesSync();
  final imageDecode =decodeImage(bytes);
  return new Size(imageDecode.width.toDouble() ,imageDecode.height.toDouble());
}
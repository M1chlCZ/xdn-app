import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../globals.dart' as globals;
import '../support/NetInterface.dart';

class AvatarPicker extends StatefulWidget {
  final dynamic userID;
  final double? borderRadius;
  final Color? color;
  final double? size;
  final double? padding;

  const AvatarPicker({Key? key, this.userID, this.borderRadius = 8.0, this.color = Colors.white24, this.size = 125.0, this.padding = 5.0}) : super(key: key);

  @override
  AvatarPickerState createState() => AvatarPickerState();
}

class AvatarPickerState extends State<AvatarPicker> {
  String? _image64;
  File? _imageFile;
  late BuildContext ctx;
  bool localUser = false;
  bool shit = false;

  @override
  void initState() {
    super.initState();
    _checkLocalUser();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    ctx = context;
    return Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: widget.color, borderRadius: const BorderRadius.all(Radius.circular(20.0))),
          child: GestureDetector(
            onTap: () {
              if (localUser) {
                _pickImage();
              }
            },
            child: Center(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                  ),
                  height: widget.size! - widget.padding!,
                  width: widget.size! - widget.padding!,
                  child: _image64 != null ? Image.memory(base64Decode(_image64!)) : _placeholderAvatar(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _checkForFile() async {
    String fileName = "avatar";
    String dir = (await getApplicationDocumentsDirectory()).path;
    String savePath = '$dir/$fileName';

    if (await File(savePath).exists()) {
      setState(() {
        _imageFile = File.fromUri(Uri.parse(savePath));
      });
      return true;
    } else {
      return false;
    }
  }

  _saveToCache(String addr) async {
    String fileName = widget.userID.toString();
    String dir = (await getApplicationDocumentsDirectory()).path;
    String savePath = '$dir/$fileName';
    if (await File(savePath).exists()) {
      setState(() {
        _imageFile = File.fromUri(Uri.parse(savePath));
      });
    }
    int i = await NetInterface.getAvatarVersion(addr);
    if (i == 1) {
      String? base64 = await NetInterface.dowloadPictureByAddr(addr);
      if (base64 != null && base64 != "ok") {
        await File(savePath).writeAsBytes(base64Decode(base64));
        setState(() {
          _imageFile = File.fromUri(Uri.parse(savePath));
        });
      }
    } else {
      if (await File(savePath).exists()) {
        setState(() {
          _imageFile = File.fromUri(Uri.parse(savePath));
        });
      } else {
        String? base64 = await NetInterface.dowloadPictureByAddr(addr);
        if (base64 != null && base64 != "ok") {
          await File(savePath).writeAsBytes(base64Decode(base64));
          setState(() {
            _imageFile = File.fromUri(Uri.parse(savePath));
          });
        }
      }
    }
  }

  void _checkLocalUser() async {
    if (widget.userID is String) {
      await _saveToCache(widget.userID.toString());
    } else {
      String? localUser = await SecureStorage.read(key: globals.ID);
      if (widget.userID == null || int.parse(localUser!) == widget.userID) {
        this.localUser = true;
        bool file = await _checkForFile();
        var addr = await SecureStorage.read(key: globals.ADR);
        int i = await NetInterface.getAvatarVersion(addr);
        if (!file || i == 1) {
          await _downloadPictureLocal(widget.userID);
        }
      } else {
        this.localUser = false;
        await _downloadPicture(widget.userID);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker  picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    // final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    _imageFile = pickedImage != null ? File(pickedImage.path) : _imageFile;
    if (_imageFile != null) {
      _cropImage();
    }
  }

  Future<void> _cropImage() async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: _imageFile!.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
              ]
            : [
                CropAspectRatioPreset.square,
              ],
        uiSettings: [
          AndroidUiSettings(toolbarTitle: '', toolbarColor: Colors.deepPurpleAccent, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: true),
          IOSUiSettings(
            rectHeight: 512.0,
            rectWidth: 512.0,
            rectX: 0,
            rectY: 0,
            resetAspectRatioEnabled: false,
            resetButtonHidden: true,
            aspectRatioLockEnabled: true,
            hidesNavigationBar: true,
            aspectRatioPickerButtonHidden: true,
            aspectRatioLockDimensionSwapEnabled: true,
            title: '',
          ),
        ]);

    if (croppedFile == null) return;

    imageCache.clear();

    ImageProperties properties = await FlutterNativeImage.getImageProperties(croppedFile.path);
    File compressedFile = await FlutterNativeImage.compressImage(croppedFile.path, quality: 80, targetWidth: 512, targetHeight: (properties.height! * 512 / properties.width!.toInt()).round());

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    final File localImage = await compressedFile.copy('$appDocPath/avatar');
    await _saveFileToCloud(localImage);
    setState(() {});
    _imageFile = compressedFile;

    setState(() {});
  }

  Widget _placeholderAvatar() {
    if (_imageFile != null && !shit) {
      return Image.file(_imageFile!);
    } else {
      if (_image64 != null) return Image.memory(base64Decode(_image64!));
      return const Icon(
        FontAwesomeIcons.userAstronaut,
        size: 55.0,
      );
    }
  }

  _saveFileToCloud(File img) async {

    final bytes = File(img.path).readAsBytesSync();
    String img64 = base64Encode(bytes);
    NetInterface.uploadPicture(ctx, img64);
  }

  _downloadPicture(int id) async {
    String? base64 = await NetInterface.dowloadPicture(context, id);
    setState(() {
      if (base64 != "ok") {
        _image64 = base64;
      }
    });
  }

  _downloadPictureLocal(int? id) async {
    String fileName = "avatar";
    String dir = (await getApplicationDocumentsDirectory()).path;
    String savePath = '$dir/$fileName';
    String? base64 = await NetInterface.dowloadPicture(context, id);
    if (base64 != null && base64 != "ok") {
      await File(savePath).writeAsBytes(base64Decode(base64));
      setState(() {
        _imageFile = File.fromUri(Uri.parse(savePath));
      });
    }
  }
}

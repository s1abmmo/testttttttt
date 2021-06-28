import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'main.dart';
import 'dart:io';
import 'CompareSize.dart';

class Popup extends StatefulWidget {
  final String text;
  Popup({Key key, @required this.text}) : super(key: key);
  @override
  _Popup createState() => _Popup();
}

Offset startOffset;
Size startSize1;

class _Popup extends State<Popup> {
  double height;
  double width;
  List<bool> onHoverList = new List<bool>();
  String pathImages = Directory.current.path + "\\images\\";
  String pathThump = Directory.current.path + "\\thump\\";
  String pathSvg = Directory.current.path + "\\svg\\";

  bool firsttime = false;
  // Size startSize;

  // List<Size> listSize=new List<Size>();

  List<Widget> ReviewImages() {
    List<Widget> listposition = new List<Widget>();
    double widthPopup = width * 0.9;
    double heightPopup = height * 0.9;

    listposition.add(ValueListenableBuilder<String>(
        valueListenable: pathBackground,
        builder: (context, value, child) {
          BoxFit boxfit = BoxFit.fitWidth;

          // var bytes  = File(value).readAsBytesSync();
          // Image image = Image.memory(bytes);

          Size sizeImage = value == null
              ? new Size(10, 10)
              : GetSizeImage(value);

          if ((widthPopup ~/ sizeImage.width) /
                  (heightPopup ~/ sizeImage.height) >
              1) boxfit = BoxFit.fitHeight;
          print(sizeImage);
          print(widthPopup.toString() +
              ' ' +
              sizeImage.width.toString() +
              ' ' +
              heightPopup.toString() +
              ' ' +
              sizeImage.height.toString());
          print((sizeImage.width) /
              (sizeImage.height));

          return value != null
              ? Container(
                  width: widthPopup,
                  child: Image.file(
                    File(value),
                    fit: boxfit,
                  ))
              : Container();
        }));

    for (int a = 0; a < listImageReview.value.length; a++) {
      onHoverList.add(false);
      // print("X1 : " + listImageReview.value[a].xPopupReview.toString());
      // print("Y1 : " + listImageReview.value[a].yPopupReview.toString());

      // Offset startOffset;
      // double width=listImageReview.value[a].size.width * 3;
      // double height=listImageReview.value[a].size.height * 3;

      // listSize.add(new Size(width,height));

      void _onPanUpdateHandler(DragUpdateDetails details) {
        final touchPositionFromCenter = details.localPosition;
        setState(
              () {
            listImageReview.value[a].angle =
                touchPositionFromCenter.direction;
          },
        );
      }

      listposition.add(Positioned(
        left: listImageReview.value[a].xPopupReview,
        top: listImageReview.value[a].yPopupReview,
        child: MouseRegion(
          onHover: (value) {
            if (!onHoverList[a])
              setState(() {
                onHoverList[a] = true;
                // print(onHoverList[a]);
              });
          },
          onExit: (event) {
            if (onHoverList[a])
              setState(() {
                onHoverList[a] = false;
                // print(onHoverList[a]);
              });
          },
          child: Stack(
            children: [
              Container(
                margin: EdgeInsets.only(left: 25, bottom: 25),
                child: Stack(
                  children: [
                    Container(
                      child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: onHoverList[a]
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              width: 1,
                            ),
                            color: Colors.transparent,
                          ),
                          width: listImageReview.value[a].size.width * 3,
                          child: Stack(
                            children: [
                              Draggable(
                                child:                               Container(
                          width:
                          listImageReview.value[a].size.width *
                            3,
                            child: Image.file(
                              File(svgRegExp.hasMatch(
                                  listImageReview.value[a].path)
                                  ? pathSvg +
                                  ChangeSvg(listImageReview
                                      .value[a].path)
                                  : pathImages +
                                  listImageReview.value[a].path),
                              fit: BoxFit.fitWidth,
                            ),
                          )
          ,
                                feedback: Container(
                                  width:
                                  listImageReview.value[a].size.width *
                                      3,
                                  child: Image.file(
                                    File(svgRegExp.hasMatch(
                                        listImageReview.value[a].path)
                                        ? pathSvg +
                                        ChangeSvg(listImageReview
                                            .value[a].path)
                                        : pathImages +
                                        listImageReview.value[a].path),
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                                childWhenDragging: Container(),
                                onDragEnd: (dragDetails) {
                                  Offset nOffset = dragDetails.offset;
                                  var x = nOffset.dx - ((width - (widthPopup)) / 2);
                                  var y = nOffset.dy - ((height - (heightPopup)) / 2);
                                  listImageReview.value[a].xPopupReview = x;
                                  listImageReview.value[a].yPopupReview = y;
                                  // print(nOffset);
                                  // print("X : " +
                                  //     listImageReview.value[a].xPopupReview.toString());
                                  // print("Y : " +
                                  //     listImageReview.value[a].yPopupReview.toString());

                                  ImageReview ir = listImageReview.value[a];
                                  listImageReview.value.remove(listImageReview.value[a]);
                                  listImageReview.value.add(ir);

                                  listImageReview.notifyListeners();
                                },
                              ),

                              onHoverList[a]
                                  ? Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    //width: 80,
                                    height: 25,
                                    //color: Colors.black,
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            listImageReview.value.remove(
                                                listImageReview.value[a]);
                                            listImageReview
                                                .notifyListeners();
                                          },
                                          child: Icon(Icons
                                              .restore_from_trash_outlined),
                                        ),

        ],
                                    ),
                                  ))
                                  : Container(),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
              onHoverList[a]
                  ? Positioned(
                      right: 0,
                      bottom: 0,
                      child:
                      ResizeTool(a),
                    )
                  : Container(),
              // onHoverList[a] ? RotateIcon(a) : Container(),
            ],
          ),
        ),
      ));
    }
    return listposition;
  }

  Widget ResizeTool(int index) {
    return GestureDetector(
      onPanStart: (details) {
        Offset updateOffset = details.localPosition;
        startOffset = updateOffset;

        startSize1 = listImageReview.value[index].size;
        print('startSize' + startSize1.toString());
      },
      onPanUpdate: (details) {
        Offset updateOffset = details.localPosition;
        print(updateOffset);
        print('updateOffset ' +
            new Offset(updateOffset.dx - startOffset.dx,
                    updateOffset.dy - startOffset.dy)
                .toString());
        if (startSize1 != null) {
          print('updateOffset1 ' +
              new Offset(updateOffset.dx - startOffset.dx,
                      updateOffset.dy - startOffset.dy)
                  .toString());

          listImageReview.value[index].size = new Size(
              startSize1.width + ((updateOffset.dx - startOffset.dx)/3),
              startSize1.height);
          print(listImageReview.value[index].size);
          listImageReview.notifyListeners();
        }
      },
      child: Icon(Icons.add),
    );
  }

  Widget RotateIcon(int index) {
    void _onPanUpdateHandler(DragUpdateDetails details) {
      final touchPositionFromCenter = details.localPosition;
      setState(
        () {
          listImageReview.value[index].angle =
              touchPositionFromCenter.direction;
        },
      );
    }

    return Positioned(
        right: 0,
        top: 0,
        child: GestureDetector(
          onPanUpdate: _onPanUpdateHandler,
          child: Transform.rotate(
            angle: listImageReview.value[index].angle,
            child: Container(
              color: Colors.red,
              child: SizedBox(
                child: Icon(Icons.undo),
                height: 100,
                width: 100,
              ),
            ),
          ),
          // child: GestureDetector(
          //   child: Icon(Icons.undo),
          // ),
        ));
  }

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    //print(width.toString());
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      content: RepaintBoundary(
        // key: previewContainer,
        child: Container(
          height: height * 0.9,
          width: width * 0.9,
          color: Colors.white,
          child: ValueListenableBuilder<List<ImageReview>>(
              valueListenable: listImageReview,
              builder: (context, value, child) {
                return Stack(
                  overflow: Overflow.clip,
                  children: ReviewImages(),
                );
              }),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'Popup.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
// import 'package:image/image.dart';
// import 'package:flutter_menu/flutter_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:path/path.dart';
import 'CompareSize.dart';

void main() {
  runApp(MyApp());
  doWhenWindowReady(() {
    final win = appWindow;
    // final initialSize = Size(600, 450);
    // win.minSize = initialSize;
    // win.size = initialSize;
    // win.alignment = Alignment.center;
    win.title = "Images Manager Tool V0.3";
    win.show();
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Images manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  //MyHomePage({Key? key, required this.title}) : super(key: key);
  //final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

final ValueNotifier<List<ImageReview>> listImageReview =
    ValueNotifier<List<ImageReview>>(new List<ImageReview>());

final ValueNotifier<List<Widget>> listItemOnPage =
    ValueNotifier<List<Widget>>(new List<Widget>());

final ValueNotifier<List<bool>> onHoverList =
    ValueNotifier<List<bool>>(new List<bool>());

final ValueNotifier<ImageSelected> imageSelected =
    ValueNotifier<ImageSelected>(new ImageSelected());

final ValueNotifier<String> pathBackground = ValueNotifier<String>(null);

RegExp svgRegExp = new RegExp(r'svg$');

String ChangeSvg(String path){
  if (svgRegExp.hasMatch(path)) {
    //path = path.replaceAll(pathImages, pathSvg);
    String replaceSvg = path.replaceAll(svgRegExp, 'png');
    path = replaceSvg;
    //path=pathSvg+path;
  }
  return path;
}

class _MyHomePageState extends State<MyHomePage> {

  List<ImageInfomation> ListII;

  double imageWidth = 150;
  double imageHeight = 150;
  // double distanceWidth = 150;
  // double distanceHeight = 150;
  int itemPerPage = 50;
  int currentPage = 0;

  List<Offset> listpoint = new List<Offset>();
  double ContainerHeight = 0;
  // List<Widget> listItemOnPage = new List<Widget>();
  double widthOfApp = 1000;

  TextEditingController itemWidth = new TextEditingController();
  TextEditingController itemHeight = new TextEditingController();
  // TextEditingController itemDistanceX = new TextEditingController();
  // TextEditingController itemDistanceY = new TextEditingController();
  TextEditingController itemPerPageController = new TextEditingController();
  TextEditingController pageIndexToGoto = new TextEditingController();
  bool loading = false;
  bool addBookmarkOnHover = false;
  List<BookmarkItem> listBookmark;
  List<BookmarkItem> recentBookmark;

  List<int> indexSuggestBookmark;
  TextEditingController bookmarkCreator = new TextEditingController();
  Tabpage tabpage=Tabpage.Review;
  List<ImageInfomation> listIIBookmarksSelected;
  int currentPageBookmarksSelected=0;

  String searchBookmarksString='';
  TextEditingController searchBookmarksController = new TextEditingController();

  String pathImages = Directory.current.path + "\\images\\";
  String pathThump= Directory.current.path + "\\thump\\";
  String pathSvg = Directory.current.path + "\\svg\\";
  TextEditingController indexPageBookmarkToGoto = new TextEditingController();
  LoadImage tabload=LoadImage.All;

  Size sizeBgReview;

  SaveConfig() {
    List<String> configString = [
      itemPerPage.toString(),
      currentPage.toString()
    ];
    File(Directory.current.path + "\\config")
        .writeAsString(configString.join('\r\n'));
  }

  LoadConfig() async {
    List<String> configString =
        await File(Directory.current.path + "\\config").readAsLines();
    setState(() {
      // imageWidth = double.parse(configString[0]);
      // imageHeight = double.parse(configString[1]);
      itemPerPage = int.parse(configString[0]);
      currentPage = int.parse(configString[1]);
      itemWidth.text = imageWidth.toInt().toString();
      itemHeight.text = imageWidth.toInt().toString();
      itemPerPageController.text = imageWidth.toInt().toString();
    });
  }

  LoadBookMarkList() async {
    listBookmark = new List<BookmarkItem>();
    List<FileSystemEntity> filesList =
        await Directory(Directory.current.path + "\\bookmark\\").listSync();
    listBookmark = new List<BookmarkItem>();
    for (int a = 0; a < filesList.length; a++) {
      BookmarkItem bi = new BookmarkItem();
      bi.name = basename(filesList[a].path);
      bi.selected=false;
      bi.onHover=false;

      List<String> bookmarkList = await File(filesList[a].path).readAsLines();

      bi.listImages = new List<String>();
      for (int b = 0; b < bookmarkList.length; b++) {
        if (bookmarkList[b].isNotEmpty) bi.listImages.add(bookmarkList[b]);
      }
      listBookmark.add(bi);
      bookmarkList.clear();
    }
    filesList.clear();
  }

  SaveBookmarkList(String nameBookmark) async {
    List<String> configString = [];
    BookmarkItem bi =
        listBookmark.where((element) => element.name == nameBookmark).first;
    for (int a = 0; a < bi.listImages.length; a++) {
      configString.add(bi.listImages[a]);
    }

    File(Directory.current.path + "\\bookmark\\" + bi.name)
        .writeAsString(configString.join('\r\n'));
  }

  LoadRecentBookmarks() async {
    recentBookmark = new List<BookmarkItem>();
    List<String> recentBookmarkList =
        await File(Directory.current.path + "\\recentbookmark").readAsLines();
    recentBookmark = new List<BookmarkItem>();
    for (int a = 0; a < recentBookmarkList.length; a++) {
      BookmarkItem bi = new BookmarkItem();
      bi.name = recentBookmarkList[a];
      bi.onHover=false;

      recentBookmark.add(bi);
    }
    recentBookmarkList.clear();
  }

  SaveRecentBookmarkList() async {
    List<String> configString = [];
    for (int a = 0; a < recentBookmark.length; a++) {
      configString.add(recentBookmark[a].name);
    }

    File(Directory.current.path + "\\recentbookmark")
        .writeAsString(configString.join('\r\n'));
  }

  List<Widget> ReturnRecentList(String pathImageSelected) {
    List<Widget> recentList = new List<Widget>();
    for (int a = recentBookmark.length - 1; a >= 0; a--) {

      int index=listBookmark.indexWhere((element) => element.name==recentBookmark[a].name);

      recentList.add(new Container(
          width: double.infinity,
          height: 35,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white,
                width: 2.0,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: InkWell(
              onTap: () async {
                AddNewItemBookmark(recentBookmark[a].name, pathImageSelected);
                BookmarkItem bi = new BookmarkItem();
                bi.name = recentBookmark[a].name;
                bi.listImages = new List<String>();
                bi.onHover=false;

                AddRecentBookmark(bi);
                setState(() {
                  recentBookmark;
                });
                SaveRecentBookmarkList();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(recentBookmark[a].name,
                      style: TextStyle(color: Colors.white)),
                  CheckImageAvailableInBookmark(
                          pathImageSelected, recentBookmark[a].name)
                      ?
                  MouseRegion(
                      onHover: (value) {
                        if (!listBookmark[index].onHover) {
                          listBookmark[index].onHover = true;
                          setState(() {
                            listBookmark;
                          });
                          print('hover ' + listBookmark[index].onHover.toString());
                        }
                      },
                      onExit: (value) {
                        if (listBookmark[index].onHover) {
                          listBookmark[index].onHover = false;
                          setState(() {
                            listBookmark;
                          });
                          print('exit ' + listBookmark[index].onHover.toString());
                        }
                      },
                      child:  InkWell(
                        onTap: (){
                          int index1=listBookmark[index].listImages.indexWhere((element) => element==pathImageSelected);
                          listBookmark[index].listImages.removeAt(index1);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child:
                          AspectRatio(
                              aspectRatio: 1,
                              child:
                              Container(
                                decoration: BoxDecoration(
                                  color: listBookmark[index].onHover?Colors.red:Colors.transparent,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(3.0),
                                  ),
                                ),
                                child:
                                Center(
                                    child: listBookmark[index].onHover?Icon(Icons.close,color:Colors.white, size: 13):Icon(Icons.check, color: Colors.white, size: 13)
                                ),
                              )
                          ),
                        ),
                      )
                  )
                      : Container()
                ],
              ))));
    }
    return recentList;
  }

  List<Widget> ReturnSuggestBookmark(
      String pathImageSelected, List<int> indexList) {
    List<Widget> recentList = new List<Widget>();
    for (int a = 0; a < indexList.length; a++) {

      recentList.add(new Container(
          width: double.infinity,
          height: 35,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: a == 0 ? Colors.transparent : Colors.white,
                width: 2.0,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: InkWell(
              onTap: () {
                AddNewItemBookmark(
                    listBookmark[indexList[a]].name, pathImageSelected);
                BookmarkItem bi = new BookmarkItem();
                bi.name = listBookmark[indexList[a]].name;
                AddRecentBookmark(bi);
                setState(() {
                  indexSuggestBookmark;
                });
                SaveRecentBookmarkList();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(listBookmark[indexList[a]].name,
                      style: TextStyle(color: Colors.white)),
                  CheckImageAvailableInBookmark(
                          pathImageSelected, listBookmark[indexList[a]].name)
                      ?
                  MouseRegion(
                      onHover: (value) {
                        if (!listBookmark[indexList[a]].onHover) {
                          listBookmark[indexList[a]].onHover = true;
                          setState(() {
                            listBookmark;
                          });
                          print('hover ' + listBookmark[indexList[a]].onHover.toString());
                        }
                      },
                      onExit: (value) {
                        if (listBookmark[indexList[a]].onHover) {
                          listBookmark[indexList[a]].onHover = false;
                          setState(() {
                            listBookmark;
                          });
                          print('exit ' + listBookmark[indexList[a]].onHover.toString());
                        }
                      },
                      child:  InkWell(
                      onTap: (){
                        int index=listBookmark[indexList[a]].listImages.indexWhere((element) => element==pathImageSelected);
                        listBookmark[indexList[a]].listImages.removeAt(index);
                      },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child:
                          AspectRatio(
                              aspectRatio: 1,
                              child:
                              Container(
                                decoration: BoxDecoration(
                                  color: listBookmark[indexList[a]].onHover?Colors.red:Colors.transparent,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(3.0),
                                  ),
                                ),
                                child:
                                Center(
                                    child: listBookmark[indexList[a]].onHover?Icon(Icons.close,color:Colors.white, size: 13):Icon(Icons.check, color: Colors.white, size: 13)
                                ),
                              )
                          ),
                        ),
                      )
                  )
                      : Container()
                ],
              ))));
    }
    return recentList;
  }

  void bookmarkCreatorChanged() {
    indexSuggestBookmark = new List<int>();
    if (bookmarkCreator.text != null && bookmarkCreator.text != '') {
      indexSuggestBookmark = MakeSuggestBookmark(bookmarkCreator.text);
      print('indexSuggestBookmark: ' + indexSuggestBookmark.toString());
    }
    setState(() {
      indexSuggestBookmark;
    });
  }

  void searchBookmarkChanged() {
    searchBookmarksString=
    searchBookmarksController.text;
    print('searchBookmarksString '+searchBookmarksString);
    setState(() {
      listBookmark;
    });
  }

  bool CheckImageAvailableInBookmark(String path, String bookmarkName) {
    bool exists = false;
    print('bookmark item');
    if (listBookmark.where((element) => element.name == bookmarkName).length >
        0) {
      BookmarkItem bookmark =
          listBookmark.where((element) => element.name == bookmarkName).first;
      exists = bookmark.listImages.contains(path);
    }
    return exists;
  }

  bool CheckBookmarkExists(String bookmarkName) {
    bool exists = false;
    int index =
        listBookmark.indexWhere((element) => element.name == bookmarkName);
    if (index != -1) exists = true;
    return exists;
  }

  CreateBookmark(String bookmarkName) {
    BookmarkItem bi = new BookmarkItem();
    bi.name = bookmarkName;
    bi.listImages = new List<String>();
    bi.onHover=false;
    bi.selected=false;

    listBookmark.add(bi);
  }

  AddRecentBookmark(BookmarkItem bi) {
    int index=recentBookmark.indexWhere((element) => element.name==bi.name);

    if(index==-1){
      if (recentBookmark.length > 0 && recentBookmark.length >= 5)
        recentBookmark.removeAt(0);
    }else{
      recentBookmark.removeAt(index);
    }

    recentBookmark.add(bi);
  }

  AddNewItemBookmark(String bookmarkName, String imagePath) async {
    int index =
        listBookmark.indexWhere((element) => element.name == bookmarkName);
    print('index ' + index.toString() + bookmarkName + imagePath);

    if (index != -1) {
      if (listBookmark[index]
              .listImages
              .indexWhere((element) => element == imagePath) !=
          -1) return;

      print('basename(imagePath) '+basename(imagePath));
      String folderContainer= imagePath.replaceFirst(new RegExp('\\\\'+basename(imagePath)) , '');
      print('folderContainer '+folderContainer);
      List<FileSystemEntity> listFileName= await Directory(Directory.current.path + "\\images\\"+folderContainer).listSync();
      for(int a=0;a<listFileName.length;a++){
        String filePath=listFileName[a].path;
        print('filePath '+filePath);
        listBookmark[index].listImages.add(filePath.replaceFirst(Directory.current.path + "\\images\\", ''));
      }
      SaveBookmarkList(bookmarkName);
      print('AddNewItemBookmark ' +
          listBookmark[index].listImages.length.toString());

    }
  }

  Load() async {
    setState(() {
      loading = true;
    });

    imageWidth = double.parse(itemWidth.text);
    imageHeight = double.parse(itemHeight.text);
    // distanceWidth=double.parse(itemDistanceX.text);
    // distanceHeight=double.parse(itemDistanceY.text);
    itemPerPage = int.parse(itemPerPageController.text);

    ListII = new List<ImageInfomation>();
    listItemOnPage.value = new List<Widget>();

    // currentPage=33;
    // itemPerPage=60;

    int numberPathInJson = 1000;
    int startItemIndex = currentPage * itemPerPage;
    int endItemIndex = startItemIndex + itemPerPage;

    int sIndexJsonFile = -1;
    int eIndexJsonFile = -1;
    int cIndexJsonFile = -1;
    int indexNameJsonFile = -1;
    List<String> listpath = new List<String>();

    String pathJson = Directory.current.path + "\\listpath\\";
    String pathImages = Directory.current.path + "\\images\\";
    String pathThump = Directory.current.path + "\\thump\\";

    for (int a = startItemIndex; a < endItemIndex; a++) {
      if (sIndexJsonFile == -1 || cIndexJsonFile == eIndexJsonFile) {
        indexNameJsonFile = (a ~/ numberPathInJson) + 1;
        sIndexJsonFile = a % numberPathInJson;
        eIndexJsonFile = (sIndexJsonFile + itemPerPage) >= 1000
            ? 1000
            : (sIndexJsonFile + itemPerPage);
        cIndexJsonFile = sIndexJsonFile;
        print(indexNameJsonFile.toString() +
            ' ' +
            sIndexJsonFile.toString() +
            ' ' +
            eIndexJsonFile.toString());
        listpath =
            await File(pathJson + '(' + indexNameJsonFile.toString() + ').txt')
                .readAsLines();
      }

      print(cIndexJsonFile.toString() +
          ' ' +
          listpath[cIndexJsonFile].toString());
      ImageInfomation ii = new ImageInfomation();
      ii.path =  listpath[cIndexJsonFile].toString();
      String fullPathThump = ii.path.replaceFirst(pathImages, pathThump);
      String replaceSvg = fullPathThump.replaceAll(svgRegExp, 'png');
      print('test ' + replaceSvg);
      ii.pathThump = replaceSvg;
      // ii.onHover=false;
      // ii.selected = false;

      if (await File(pathThump+ii.pathThump).exists()) {
        ListII.add(ii);
      }

      cIndexJsonFile++;
    }
    CountPosition();
    SaveConfig();
  }

  LoadBookmarksSelected() async {
    RegExp imagesRegExp = new RegExp(r'^images');

    setState(() {
      loading = true;
    });

    imageWidth = double.parse(itemWidth.text);
    imageHeight = double.parse(itemHeight.text);
    itemPerPage = int.parse(itemPerPageController.text);

    ListII = new List<ImageInfomation>();
    listItemOnPage.value = new List<Widget>();

    //String currentPath = Directory.current.path;

    int startItemIndex=itemPerPage*currentPageBookmarksSelected;
    int endItemIndex=startItemIndex+itemPerPage;

    listIIBookmarksSelected=new List<ImageInfomation>();
    for(int a=0;a<listBookmark.length; a++){
      if(listBookmark[a].selected){
        for(int b=0;b<listBookmark[a].listImages.length;b++){

          ImageInfomation ii = new ImageInfomation();
          ii.path=listBookmark[a].listImages[b];
          //print('ii.path '+ii.path);
          listIIBookmarksSelected.add(ii);
        }
      }
    }

    print(listIIBookmarksSelected.length);
    print(endItemIndex);

    for (int a = startItemIndex; a < endItemIndex && a<listIIBookmarksSelected.length; a++) {
      print(a);

      ImageInfomation ii = new ImageInfomation();
      ii.path = listIIBookmarksSelected[a].path;

      String fullPathThump = ii.path.replaceFirst(imagesRegExp, 'thump');
      String replaceSvg = fullPathThump.replaceAll(svgRegExp, 'png');
      print('test ' + replaceSvg);
      ii.pathThump = replaceSvg;

      if (await File(Directory.current.path + "\\thump\\"+ii.pathThump).exists()) {
        ListII.add(ii);
      }

    }
    CountPosition();
    // SaveConfig();
  }

  List<bool> onHoverListReview= new List<bool>();

  List<Widget> ReviewImages() {
    List<Widget> listposition = new List<Widget>();

    // if (pathBackground != null){
    //
    //   listposition.add(ValueListenableBuilder<String>(
    //       valueListenable: pathBackground,
    //       builder: (context, value, child) {
    //         Size  GetSizeImage(value);
    //         double widthBg=
    //
    //         return value != null
    //             ? Container(
    //             width: widthOfApp * 0.25,
    //             child: Image.file(
    //               File(value),
    //               fit: BoxFit.fitWidth,
    //             ))
    //             : Container();
    //       }));
    //
    // }

    for (int a = 0; a < listImageReview.value.length; a++) {
      onHoverListReview.add(false);
      Size startSize;

      listposition.add(Positioned(
        left: listImageReview.value[a].xMiniReview,
        top: listImageReview.value[a].yMiniReview,
        child:
        MouseRegion(
            onHover: (value) {
              if (!onHoverListReview[a])
                setState(() {
                  onHoverListReview[a] = true;
                  print(onHoverListReview[a]);
                });
            },
            onExit: (event) {
              if (onHoverListReview[a])
                setState(() {
                  onHoverListReview[a] = false;
                  print(onHoverListReview[a]);
                });
            },
            child: Stack(
                children: [
            Container(
            margin: EdgeInsets.only(left: 25, bottom: 25),
              child:
              Draggable(
                child: Container(
                    color: Colors.transparent,
                    width: listImageReview.value[a].size.width,
                    //height: listImageReview.value[a].size.height,
                    child: Image.file(
                      File(svgRegExp.hasMatch(listImageReview.value[a].path)?pathSvg+ChangeSvg(listImageReview.value[a].path) :pathImages+ listImageReview.value[a].path),
                      fit: BoxFit.fitWidth,
                    )),
                feedback: Container(
                    color: Colors.transparent,
                    width: listImageReview.value[a].size.width,
                    //height: listImageReview.value[a].size.height,
                    child: Image.file(
                      File(svgRegExp.hasMatch(listImageReview.value[a].path)?pathSvg+ ChangeSvg(listImageReview.value[a].path):pathImages+ listImageReview.value[a].path),
                      fit: BoxFit.fitWidth,
                    )),
                childWhenDragging: Container(),
                onDragEnd: (dragDetails) {
                  Offset nOffset = dragDetails.offset;

                  var x = nOffset.dx - 36;
                  var y = nOffset.dy - 91;
                  // var xRatio=x/2;
                  // var yRatio=y/2;
                  // if (xRatio < 1) xRatio = 1;
                  // if (xRatio > 85) xRatio = 85;
                  // if (yRatio < 1) yRatio = 1;
                  // if (yRatio > 75) yRatio = 75;
                  listImageReview.value[a].xMiniReview = x;
                  listImageReview.value[a].yMiniReview = y;
                  print(nOffset);
                  print("X  : " + listImageReview.value[a].xMiniReview.toString());
                  print("Y  : " + listImageReview.value[a].yMiniReview.toString());

                  ImageReview ir = listImageReview.value[a];
                  listImageReview.value.remove(listImageReview.value[a]);
                  listImageReview.value.add(ir);

                  listImageReview.notifyListeners();
                },
              ),
            ),
                  onHoverListReview[a]
                      ? Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanStart: (details) {
                        startSize = listImageReview.value[a].size;
                      },
                      onPanEnd: (details) {
                        listImageReview.notifyListeners();
                      },
                      onPanUpdate: (details) {
                        Offset updateOffset = details.localPosition;
                        Size ns1 = new Size(startSize.width + updateOffset.dx,
                            startSize.height);
                        if(ns1.width>startSize.width+50){
                          ns1 = new Size(startSize.width+50,
                              startSize.height);
                        }else if(ns1.width<startSize.width-50){
                          ns1 = new Size(startSize.width-50,
                              startSize.height);
                        }else if(ns1.width<10){
                          ns1 = new Size(10,
                              startSize.height);
                        }else if(ns1.width>100){
                          ns1 = new Size(100,
                              startSize.height);
                        }
                        listImageReview.value[a].size =
                        new Size(ns1.width, ns1.height);
                      },
                      child: Icon(Icons.add),
                    ),
                  )
                      : Container(),
                ]
            )),
      ));
    }

    listposition.add(
      Positioned(
        left: 15,
        bottom: 15,
        child: InkWell(
          onTap: () {
            listImageReview.value = new List<ImageReview>();
            listImageReview.notifyListeners();
          },
          child: Container(
            width: 65,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.all(
                Radius.circular(3.0),
              ),
            ),
            child: Center(
                child: Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            )),
          ),
        ),
      ),
    );

    listposition.add(
      Positioned(
        right: 15,
        bottom: 15,
        child: Row(children: [
          InkWell(
            onTap: () {
              setState(() {
                pathBackground.value = null;
                pathBackground.notifyListeners();
              });
            },
            child: Container(
              width: 80,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.all(
                  Radius.circular(3.0),
                ),
              ),
              child: Center(
                  child: Text(
                'Reset BG',
                style: TextStyle(color: Colors.white),
              )),
            ),
          ),
          Container(
            width: 10,
          ),
          InkWell(
            onTap: () {
              final file = OpenFilePicker()
                ..filterSpecification = {
                  'JPEG file (*.jpg)': '*.jpg',
                  'PNG file (*.png)': '*.png',
                  'All Files': '*.*'
                }
                ..defaultFilterIndex = 0
                ..defaultExtension = 'doc'
                ..title = 'Select a document';

              final result = file.getFile();
              if (result != null) {
                print(result.path);
              }
              setState(() {
                pathBackground.value = result.path;
                pathBackground.notifyListeners();
              });
            },
            child: Container(
              width: 115,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.all(
                  Radius.circular(3.0),
                ),
              ),
              child: Center(
                  child: Text(
                'Set background',
                style: TextStyle(color: Colors.white),
              )),
            ),
          ),
        ]),
      ),
    );

    return listposition;
  }

  CountPosition() async {
    listItemOnPage.value = new List<Widget>();
    listItemOnPage.notifyListeners();
    onHoverList.value = List<bool>();

    //List<Widget> listposition = new List<Widget>();
    // Offset currentOffset = new Offset(10, 10);

    Codec<String, String> stringToBase64 = utf8.fuse(base64);

    List<String> list64encode = [];

    for (int a = 0; a < ListII.length; a++) {
      String ListIIEncodedBase64 = stringToBase64.encode(ListII[a].path);
      list64encode.add(ListIIEncodedBase64);
    }

    String pathImages = Directory.current.path + "\\images\\";
    String pathThump= Directory.current.path + "\\thump\\";
    String pathSvg = Directory.current.path + "\\svg\\";

    //print(list64encode);

    File(Directory.current.path + "\\listbase64encode")
        .writeAsString(list64encode.join('\r\n'));

    // var p = await Process.run(
    //     Directory.current.path +
    //         "\\resize.exe",
    //     [imageWidth.toInt().toString(),imageHeight.toInt().toString()]);
    //
    // var exitCode = await p.exitCode;

    // print('exit code: $exitCode');

    //String pathCacheImages = Directory.current.path + "\\thump\\";

    for (int a = 0; a < ListII.length; a++) {
      print(pathThump+ListII[a].pathThump);

      var bytes = File(pathThump+ListII[a].pathThump).readAsBytesSync();
      Image image = Image.memory(bytes);
      // Image itemImage=new FileImage();

      //new Image.file(File(pathCacheImages+a.toString()+'.png'));

      onHoverList.value.add(false);

      listItemOnPage.value.add(MouseRegion(
        onHover: (value) {
          if (!onHoverList.value[a]) {
            onHoverList.value[a] = true;
            print(onHoverList.value[a]);
            onHoverList.notifyListeners();
          }
          ;
        },
        onExit: (event) {
          if (onHoverList.value[a]) {
            setState(() {
              onHoverList.value[a] = false;
            });
            print(onHoverList.value[a]);
            onHoverList.notifyListeners();
          }
          ;
        },
        child: Stack(
          children: [
            InkWell(
              onTap: () {
                ImageReview ir = new ImageReview();
                String path = ListII[a].path;
                print(path);
                // if (svgRegExp.hasMatch(path)) {
                //   //path = path.replaceAll(pathImages, pathSvg);
                //   String replaceSvg = path.replaceAll(svgRegExp, 'png');
                //   path = replaceSvg;
                //   //path=pathSvg+path;
                // }
                // print(path);
                ir.path = path;
                ir.xMiniReview = 1;
                ir.yMiniReview = 1;
                ir.xPopupReview = 1;
                ir.yMiniReview = 1;
                ir.size = new Size(widthOfApp * 0.25 * 0.7, 100);
                ir.angle=0.0;

                print(ir.size);

                listImageReview.value.add(ir);
                print(a);
                listImageReview.notifyListeners();
              },
              child: Container(
                  color: Colors.transparent,
                  width: imageWidth,
                  height: imageHeight,
                  child: image),
            ),
            ValueListenableBuilder<List<bool>>(
                valueListenable: onHoverList,
                builder: (context, value, child) {
                  //CountPosition();
                  return value[a]
                      ? Positioned(
                          right: 0,
                          top: 0,
                          child: MouseRegion(
                              onHover: (value) {
                                if (!imageSelected.value.show) {
                                  print(value.position);
                                  Offset newO = new Offset(
                                      value.position.dx - (widthOfApp * 0.25),
                                      value.position.dy);
                                  imageSelected.value.point = newO;
                                  imageSelected.value.show = true;
                                  imageSelected.value.path = ListII[a].path;
                                  imageSelected.notifyListeners();
                                }
                              },
                              // onExit: (value){
                              //   if(imageSelected.value.show){
                              //   imageSelected.value.show=false;
                              //   imageSelected.notifyListeners();}
                              // },
                              child: Icon(IconData(63764,
                                  fontFamily: CupertinoIcons.iconFont,
                                  fontPackage:
                                      CupertinoIcons.iconFontPackage))))
                      : Container();
                }),
          ],
        ),
      ));

      setState(() {
        loading = false;
      });
    }

    print('tong so: ' + listItemOnPage.value.length.toString());
    listItemOnPage.notifyListeners();
  }

  List<int> MakeSuggestBookmark(String text) {
    RegExp regExp = new RegExp(text);
    List<int> indexList = new List<int>();
    for (int a = 0; a < listBookmark.length; a++) {
      if (regExp.hasMatch(listBookmark[a].name)) indexList.add(a);
      if (indexList.length > 4) break;
    }
    return indexList;
  }

  Future<int> CountLineBookmark(String path) async {
    int numberImages=
    await File(Directory.current.path + "\\"+path).readAsLinesSync().length;
    return numberImages;
  }

  Widget AllBookmarks(){
    return ListView.builder(
      itemCount: listBookmark.length,
      itemBuilder: (context, i) {
        return new RegExp(searchBookmarksString).hasMatch(listBookmark[i].name) ? InkWell(
          onTap: (){
            listBookmark[i].selected=!listBookmark[i].selected;
            setState(() {
              listBookmark;
            });
          },
          child:
          Container(
            width: double.infinity,
            height: 30,
            padding: EdgeInsets.symmetric(horizontal: 75),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(listBookmark[i].name),

                listBookmark[i].selected?Icon(Icons.check_box_outlined):Icon(Icons.check_box_outline_blank),

              ],
            ),
          )
        ):Container()
          ;
      },
    );
  }

  Widget BookmarksSelected(){
    return ListView.builder(
      itemCount: listBookmark.length,
      itemBuilder: (context, i) {
        return listBookmark[i].selected?InkWell(
            onTap: (){
              listBookmark[i].selected=!listBookmark[i].selected;
              setState(() {
                listBookmark;
              });
            },
            child:
            Container(
              width: double.infinity,
              height: 30,
              padding: EdgeInsets.symmetric(horizontal: 75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(listBookmark[i].name),

                  listBookmark[i].selected?Icon(Icons.check_box_outlined):Icon(Icons.check_box_outline_blank),

                ],
              ),
            )
        ):Container()
        ;
      },
    );
  }

  bool CheckSvg(String path){
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    indexSuggestBookmark = new List<int>();
    LoadRecentBookmarks();
    LoadBookMarkList();
    ListII = new List<ImageInfomation>();
    LoadConfig();
    imageSelected.value.show = false;
    bookmarkCreator.addListener(bookmarkCreatorChanged);
    searchBookmarksController.addListener(searchBookmarkChanged);
  }

  ScrollController _scrollController = new ScrollController();
  double ScrollTop = 0;

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var width = screenSize.width;
    widthOfApp = width;
    var height = screenSize.height;

    return Scaffold(
        body: Row(
      children: [
        Container(
          //color:Colors.black,
          height: double.infinity,
          width: width * 0.25,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.only(left:10),
                child:
                Container(
                  height:40,
                  width: double.infinity,
                  //color: Colors.black,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: (){
                          setState(() {
                            tabpage=Tabpage.Review;
                          });
                        },
                        child:Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: tabpage==Tabpage.Review? Colors.transparent: Colors.deepPurple,
                              width: 1,
                            ),
                            color: tabpage==Tabpage.Review? Colors.deepPurple: Colors.transparent,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0)),
                          ),
                          height:double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child:Center(
                              child: Text('Review',
                                style: TextStyle(color: tabpage==Tabpage.Review? Colors.white: Colors.deepPurple,)
                              )
                          ),
                        ),
                      ),
                      Container(width: 1,),
                      InkWell(
                        onTap: (){
                          setState(() {
                            tabpage=Tabpage.AllBookmarks;
                            tabload=LoadImage.BookmarkSelected;
                          });
                        },
                        child:
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: tabpage==Tabpage.AllBookmarks? Colors.transparent: Colors.deepPurple,
                            width: 1,
                          ),
                          color: tabpage==Tabpage.AllBookmarks? Colors.deepPurple: Colors.transparent,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.0),
                              topRight: Radius.circular(10.0)),
                        ),
                        height:double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child:Center(
                            child: Text('All bookmark',
                                style: TextStyle(color: tabpage==Tabpage.AllBookmarks? Colors.white: Colors.deepPurple,))
                        ),
                      ),),
                      Container(width: 1,),
                      InkWell(
                        onTap: (){
                          setState(() {
                            tabpage=Tabpage.BookmarksSelected;
                            tabload=LoadImage.BookmarkSelected;
                          });
                        },
                        child:
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: tabpage==Tabpage.BookmarksSelected? Colors.transparent: Colors.deepPurple,
                            width: 1,
                          ),
                          color: tabpage==Tabpage.BookmarksSelected? Colors.deepPurple: Colors.transparent,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.0),
                              topRight: Radius.circular(10.0)),
                        ),
                        height:double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child:Center(
                            child: Text('Bookmark selected',
                                style: TextStyle(color: tabpage==Tabpage.BookmarksSelected? Colors.white: Colors.deepPurple,))
                        ),
                      ),)

                    ]
                  )
                ),
              ),
              // Container(height: 10),
              tabpage==Tabpage.Review?
              Container(
                height: 50,
                width: double.infinity,
                margin: EdgeInsets.only(left: 10),
                child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          barrierDismissible: true,
                          opaque: false,
                          pageBuilder: (_, anim1, anim2) => Popup(text: 'tag1'),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        // border: Border.all(
                        //   width: 1,
                        // ),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(3.0),
                            // topLeft: Radius.circular(3.0)
                          ),
                        color: Colors.deepPurple,
                      ),
                      //color: Colors.transparent,
                      width: 200,
                      height: 35,
                      child: Center(
                          child: Text('View',
                              style: TextStyle(color: Colors.white))),
                    )),
              ):Container(),
              tabpage==Tabpage.Review?
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(3.0),
                        bottomRight: Radius.circular(3.0)),
                  ),

                  // height: 250,
                  // width: double.infinity,
                  margin: EdgeInsets.only(left: 10),
                  //color: Colors.black,
                  child: ValueListenableBuilder<List<ImageReview>>(
                      valueListenable: listImageReview,
                      builder: (context, value, child) {
                        return Stack(
                          children: ReviewImages(),
                        );
                      }),
                ),
              ):Container(),
              tabpage==Tabpage.AllBookmarks?
                  Expanded(child:Container(
                      margin: EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: Colors.deepPurple,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(3.0),
                          // topLeft: Radius.circular(3.0)
                        ),
                      ),
                      child:
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.deepPurple,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(3.0),
                              ),
                            ),
                            margin: EdgeInsets.all(10),
                            height: 60,
                            width: double.infinity,
                            child: Center(
                              child: Container(
                                height: 30,
                                width: double.infinity,
                                //color: Colors.black,

                                child: Row(
                                  children: [
                                    Container(width: 10),
                                    Text('Bookmark'),
                                    Container(width: 10),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.deepPurple,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(3.0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                // decoration: BoxDecoration(
                                                //   border: Border.all(
                                                //     color: Colors.deepPurple,
                                                //     width: 1,
                                                //   ),
                                                //   borderRadius: BorderRadius.all(
                                                //     Radius.circular(3.0),
                                                //   ),
                                                // ),
                                                width: 90.0,
                                                height: 25.0,
                                                //padding: EdgeInsets.all(10.0),
                                                child: TextFormField(
                                                  controller: bookmarkCreator,
                                                  cursorColor: Colors.black,
                                                  cursorWidth: 0.5,
                                                  decoration: new InputDecoration(
                                                    border: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    errorBorder: InputBorder.none,
                                                    disabledBorder: InputBorder.none,
                                                    contentPadding:
                                                    EdgeInsets.only(top: -20, left: 10),

                                                    // hintText: "Hint here"
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                                padding: EdgeInsets.symmetric(vertical: 3),
                                                child: InkWell(
                                                  onTap: () {
                                                    if (bookmarkCreator.text != null &&
                                                        bookmarkCreator.text !=
                                                            '' &&
                                                        !CheckBookmarkExists(bookmarkCreator.text)) {
                                                      CreateBookmark(
                                                          bookmarkCreator.text);
                                                      BookmarkItem
                                                      bi =
                                                      new BookmarkItem();
                                                      bi.name =
                                                          bookmarkCreator.text;
                                                      bi.listImages =
                                                      new List<String>();
                                                      AddRecentBookmark(
                                                          bi);
                                                      SaveBookmarkList(
                                                          bi.name);
                                                      bookmarkCreator.text =
                                                      '';
                                                      setState(
                                                              () {
                                                            recentBookmark;
                                                          });
                                                      SaveRecentBookmarkList();
                                                    }
                                                  },
                                                  child: AspectRatio(
                                                    aspectRatio: 1,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          width: 1,
                                                        ),
                                                        color: Colors.deepPurple,
                                                        borderRadius: BorderRadius.all(
                                                          Radius.circular(3.0),
                                                        ),
                                                      ),
                                                      width: 50,
                                                      height: 26.0,
                                                      //padding: EdgeInsets.all(10.0),
                                                      child: Center(
                                                          child: Icon(Icons.add,
                                                              color: Colors.white,
                                                              size: 12)),
                                                    ),
                                                  ),
                                                )),
                                            Container(
                                              width: 3,
                                            ),
                                            // AspectRatio(
                                            //   aspectRatio: 1,
                                            //   child: Container(
                                            //       color: Colors.deepPurple,
                                            //       child: Icon(Icons.arrow_drop_down,
                                            //           color: Colors.white)),
                                            // ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(width: 10),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.deepPurple,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(3.0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            AspectRatio(
                                              aspectRatio: 1,
                                              child: Container(
                                                  color: Colors.deepPurple,
                                                  child: Icon(Icons.search,
                                                      color: Colors.white)),
                                            ),
                                            Container(
                                              width: 100.0,
                                              height: 25.0,
                                              //padding: EdgeInsets.all(10.0),
                                              child: TextFormField(
                                                controller: searchBookmarksController,
                                                cursorColor: Colors.black,
                                                cursorWidth: 0.5,
                                                decoration: new InputDecoration(
                                                  border: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  disabledBorder: InputBorder.none,
                                                  contentPadding:
                                                  EdgeInsets.only(top: -20, left: 10),

                                                  // hintText: "Hint here"
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(width: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child:
                            AllBookmarks(),
                          ),

                        ],
                      )
                  )):Container(),
              tabpage==Tabpage.BookmarksSelected?
              Expanded(child:Container(
                  margin: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: Colors.deepPurple,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(3.0),
                      // topLeft: Radius.circular(3.0)
                    ),
                  ),
                  child:
                  Column(
                    children: [
                      Expanded(
                        child:
                        BookmarksSelected(),
                      ),
                    ],
                  )
              )):Container(),

              Container(height: 10),

              Container(
                padding: EdgeInsets.only(left:10),
                child:
                Container(
                    height:40,
                    width: double.infinity,
                    //color: Colors.black,
                    child: Row(
                        children: [
                          InkWell(
                            onTap: (){
                              setState(() {
                                tabload=LoadImage.All;
                              });
                            },
                            child:Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: tabload==LoadImage.All? Colors.transparent: Colors.deepPurple,
                                  width: 1,
                                ),
                                color: tabload==LoadImage.All? Colors.deepPurple: Colors.transparent,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10.0),
                                    topRight: Radius.circular(10.0)),
                              ),
                              height:double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child:Center(
                                  child: Text('All',
                                      style: TextStyle(color: tabload==LoadImage.All? Colors.white: Colors.deepPurple,)
                                  )
                              ),
                            ),
                          ),
                          Container(width: 1,),
                          InkWell(
                            onTap: (){
                              setState(() {
                                tabload=LoadImage.BookmarkSelected;
                              });
                            },
                            child:
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: tabload==LoadImage.BookmarkSelected? Colors.transparent: Colors.deepPurple,
                                  width: 1,
                                ),
                                color: tabload==LoadImage.BookmarkSelected? Colors.deepPurple: Colors.transparent,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10.0),
                                    topRight: Radius.circular(10.0)),
                              ),
                              height:double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child:Center(
                                  child: Text('Bookmark',
                                      style: TextStyle(color: tabload==LoadImage.BookmarkSelected? Colors.white: Colors.deepPurple,))
                              ),
                            ),),

                        ]
                    )
                ),
              ),

              tabload==LoadImage.BookmarkSelected?
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepPurple,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(3.0),
                  ),
                ),
                margin: EdgeInsets.only(left: 10),
                height: 60,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(width: 10),
                    Text('Items/page:'),
                    Container(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurple,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(3.0),
                        ),
                      ),
                      width: 60.0,
                      height: 25.0,
                      //padding: EdgeInsets.all(10.0),
                      child: TextFormField(
                        controller: itemPerPageController,
                        cursorColor: Colors.black,
                        cursorWidth: 0.5,
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding:
                          EdgeInsets.only(top: -20, left: 10),

                          // hintText: "Hint here"
                        ),
                      ),
                    ),
                    Container(width: 10),
                    InkWell(
                      onTap: () {
                        LoadBookmarksSelected();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(3.0),
                          ),
                        ),
                        width: 50,
                        height: 26.0,
                        //padding: EdgeInsets.all(10.0),
                        child: Center(
                          child: Text('Load',
                              style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ),
                    ),
                    Container(width: 10),
                    InkWell(
                      onTap: () {
                        if (currentPageBookmarksSelected > 0) {
                          currentPageBookmarksSelected--;
                          LoadBookmarksSelected();
                          indexPageBookmarkToGoto.text = (currentPageBookmarksSelected + 1).toString();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(3.0),
                          ),
                        ),
                        width: 25.0,
                        height: 25.0,
                        padding: EdgeInsets.only(left: 10.0),
                        child: Center(
                            child: Icon(Icons.arrow_back_ios,size:13,
                                color: Colors.deepPurple)),
                      ),
                    ),
                    Container(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurple,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(3.0),
                        ),
                      ),
                      width: 75.0,
                      height: 25.0,
                      //padding: EdgeInsets.all(10.0),
                      child: TextFormField(
                        textInputAction: TextInputAction.go,
                        onEditingComplete: () {
                          currentPage =
                              int.parse(pageIndexToGoto.text) - 1;
                          Load();
                        },
                        textAlign: TextAlign.center,
                        controller: indexPageBookmarkToGoto,
                        cursorColor: Colors.black,
                        cursorWidth: 0.5,
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding:
                          EdgeInsets.only(top: -20, left: 0),
                          // hintText: "Hint here"
                        ),
                      ),
                    ),
                    Container(width: 10),
                    InkWell(
                      onTap: () {
                        setState(() {
                          currentPageBookmarksSelected++;
                          LoadBookmarksSelected();
                          indexPageBookmarkToGoto.text = (currentPageBookmarksSelected + 1).toString();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(3.0),
                          ),
                        ),
                        width: 25.0,
                        height: 25.0,
                        //padding: EdgeInsets.all(10.0),
                        child: Center(
                            child: Icon(Icons.arrow_forward_ios,size:13,
                                color: Colors.deepPurple)),
                      ),
                    ),
                  ],
                ),
              ):Container(),

              tabload==LoadImage.All?
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepPurple,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(3.0),
                  ),
                ),
                margin: EdgeInsets.only(left: 10),
                height: 60,
                width: double.infinity,
                child:                       Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(width: 10),
                    Text('Items/page:'),
                    Container(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurple,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(3.0),
                        ),
                      ),
                      width: 60.0,
                      height: 25.0,
                      //padding: EdgeInsets.all(10.0),
                      child: TextFormField(
                        controller: itemPerPageController,
                        cursorColor: Colors.black,
                        cursorWidth: 0.5,
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding:
                          EdgeInsets.only(top: -20, left: 10),

                          // hintText: "Hint here"
                        ),
                      ),
                    ),
                    Container(width: 10),
                    InkWell(
                      onTap: () {
                        Load();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(3.0),
                          ),
                        ),
                        width: 50,
                        height: 26.0,
                        //padding: EdgeInsets.all(10.0),
                        child: Center(
                          child: Text('Load',
                              style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ),
                    ),
                    Container(width: 10),
                    InkWell(
                      onTap: () {
                        if (currentPage > 0) {
                          currentPage--;
                          Load();
                          pageIndexToGoto.text = (currentPage + 1).toString();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(3.0),
                          ),
                        ),
                        width: 25.0,
                        height: 25.0,
                        padding: EdgeInsets.only(left: 10.0),
                        child: Center(
                            child: Icon(Icons.arrow_back_ios,size:13,
                                color: Colors.deepPurple)),
                      ),
                    ),
                    Container(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurple,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(3.0),
                        ),
                      ),
                      width: 75.0,
                      height: 25.0,
                      //padding: EdgeInsets.all(10.0),
                      child: TextFormField(
                        textInputAction: TextInputAction.go,
                        onEditingComplete: () {
                          currentPage =
                              int.parse(pageIndexToGoto.text) - 1;
                          Load();
                        },
                        textAlign: TextAlign.center,
                        controller: pageIndexToGoto,
                        cursorColor: Colors.black,
                        cursorWidth: 0.5,
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding:
                          EdgeInsets.only(top: -20, left: 0),
                          // hintText: "Hint here"
                        ),
                      ),
                    ),
                    Container(width: 10),
                    InkWell(
                      onTap: () {
                        setState(() {
                          currentPage++;
                          Load();
                          pageIndexToGoto.text = (currentPage + 1).toString();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(3.0),
                          ),
                        ),
                        width: 25.0,
                        height: 25.0,
                        //padding: EdgeInsets.all(10.0),
                        child: Center(
                            child: Icon(Icons.arrow_forward_ios,size:13,
                                color: Colors.deepPurple)),
                      ),
                    ),
                  ],
                ),

              ):Container(),
              Container(height: 20),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              !loading
                  ? ValueListenableBuilder<List<Widget>>(
                      valueListenable: listItemOnPage,
                      builder: (context, value, child) {
                        //CountPosition();
                        return GridView.extent(
                            primary: true,
                            maxCrossAxisExtent: imageWidth,
                            children: value);
                      })
                  : Container(),
              loading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container(),
              ValueListenableBuilder<ImageSelected>(
                  valueListenable: imageSelected,
                  builder: (context, value, child) {
                    return value.show || addBookmarkOnHover
                        ? Positioned(
                            left: value.point.dx - 25,
                            top: value.point.dy - 50,
                            child: MouseRegion(
                              // onHover: (value){
                              //   if(!imageSelected.value.show){
                              //     print(value.position);
                              //     Offset newO=new Offset(value.position.dx-(widthOfApp*0.25),value.position.dy);
                              //     imageSelected.value.point=newO;
                              //     imageSelected.value.show=true;
                              //     imageSelected.value.path=ListII[a].path;
                              //     imageSelected.notifyListeners();
                              //   }
                              // },
                              onExit: (value) {
                                if (imageSelected.value.show) {
                                  imageSelected.value.show = false;
                                  imageSelected.notifyListeners();
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 35, horizontal: 30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        // border: Border.all(
                                        //   color: Colors.deepPurple,
                                        //   width: 1,
                                        // ),
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10.0),
                                        ),
                                      ),

                                      // padding: EdgeInsets.symmetric(
                                      //     vertical: 10, horizontal: 20),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: MouseRegion(
                                              onHover: (value) {
                                                if (!addBookmarkOnHover) {
                                                  setState(() {
                                                    addBookmarkOnHover = true;
                                                  });
                                                  print('hover ' +
                                                      addBookmarkOnHover
                                                          .toString());
                                                }
                                              },
                                              onExit: (value) {
                                                if (addBookmarkOnHover) {
                                                  setState(() {
                                                    addBookmarkOnHover = false;
                                                  });
                                                  print('exit ' +
                                                      addBookmarkOnHover
                                                          .toString());
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      //                   <--- left side
                                                      color: Colors.white,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                ),
                                                padding:
                                                    EdgeInsets.only(left: 10),
                                                child: InkWell(
                                                    onTap: () async {
                                                      print('Add bookmark');
                                                    },
                                                    child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                            'Add bookmark',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)))),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    //                   <--- left side
                                                    color: Colors.white,
                                                    width: 2.0,
                                                  ),
                                                ),
                                              ),
                                              padding:
                                                  EdgeInsets.only(left: 10),
                                              child: InkWell(
                                                  onTap: () async {
                                                    print('Open folder');

                                                    Codec<String, String>
                                                        stringToBase64 =
                                                        utf8.fuse(base64);

                                                    String pathBase64Encode =
                                                        stringToBase64.encode(
                                                            pathImages+ imageSelected
                                                                .value.path);

                                                    var p = await Process.run(
                                                        Directory.current.path +
                                                            "\\imageoption.exe",
                                                        [
                                                          '0',
                                                          pathBase64Encode
                                                        ]);

                                                    var exitCode =
                                                        await p.exitCode;

                                                    imageSelected.value.show =
                                                        false;
                                                    imageSelected
                                                        .notifyListeners();

                                                    // print('exit code: $exitCode');
                                                  },
                                                  child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text('Open folder',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)))),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      //                   <--- left side
                                                      color: Colors.white,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                ),
                                                padding:
                                                    EdgeInsets.only(left: 10),
                                                child: InkWell(
                                                    onTap: () async {
                                                      print('Open folder');

                                                      Codec<String, String>
                                                          stringToBase64 =
                                                          utf8.fuse(base64);

                                                      String pathBase64Encode =
                                                          stringToBase64.encode(
                                                              pathImages+imageSelected
                                                                  .value.path);

                                                      var p = await Process.run(
                                                          Directory.current
                                                                  .path +
                                                              "\\imageoption.exe",
                                                          [
                                                            '1',
                                                            pathBase64Encode
                                                          ]);

                                                      var exitCode =
                                                          await p.exitCode;

                                                      imageSelected.value.show =
                                                          false;
                                                      imageSelected
                                                          .notifyListeners();

                                                      // print('exit code: $exitCode');
                                                    },
                                                    child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                            'Copy image',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white))))),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding:
                                                  EdgeInsets.only(left: 10),
                                              child: InkWell(
                                                  onTap: () async {
                                                    print('Open folder');

                                                    Codec<String, String>
                                                        stringToBase64 =
                                                        utf8.fuse(base64);

                                                    String pathBase64Encode =
                                                        stringToBase64.encode(
                                                            pathImages+imageSelected
                                                                .value.path);

                                                    var p = await Process.run(
                                                        Directory.current.path +
                                                            "\\imageoption.exe",
                                                        [
                                                          '2',
                                                          pathBase64Encode
                                                        ]);

                                                    var exitCode =
                                                        await p.exitCode;

                                                    imageSelected.value.show =
                                                        false;
                                                    imageSelected
                                                        .notifyListeners();

                                                    // print('exit code: $exitCode');
                                                  },
                                                  child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text('Open file',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)))),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    MouseRegion(
                                        onHover: (value) {
                                          if (!addBookmarkOnHover) {
                                            setState(() {
                                              addBookmarkOnHover = true;
                                            });
                                            print('hover ' +
                                                addBookmarkOnHover.toString());
                                          }
                                        },
                                        onExit: (value) {
                                          if (addBookmarkOnHover) {
                                            setState(() {
                                              addBookmarkOnHover = false;
                                            });

                                            print('exit ' +
                                                addBookmarkOnHover.toString());
                                          }
                                        },
                                        child: Container(
                                          width: 10,
                                          height: 37.5, //color:Colors.black
                                        )),
                                    addBookmarkOnHover
                                        ? MouseRegion(
                                            onHover: (value) {
                                              if (!addBookmarkOnHover) {
                                                setState(() {
                                                  addBookmarkOnHover = true;
                                                });
                                                print('hover ' +
                                                    addBookmarkOnHover
                                                        .toString());
                                              }
                                            },
                                            onExit: (value) {
                                              if (addBookmarkOnHover) {
                                                setState(() {
                                                  addBookmarkOnHover = false;
                                                });

                                                print('exit ' +
                                                    addBookmarkOnHover
                                                        .toString());
                                              }
                                            },
                                            child: Container(
                                              width: 120,
                                              // height: 150,
                                              decoration: BoxDecoration(
                                                // border: Border.all(
                                                //   color: Colors.deepPurple,
                                                //   width: 1,
                                                // ),
                                                color: Colors.deepPurple,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(10.0),
                                                ),
                                              ),

                                              // padding: EdgeInsets.symmetric(
                                              //     vertical: 10, horizontal: 20),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    height: 40,
                                                    child: MouseRegion(
                                                      onHover: (value) {
                                                        if (!addBookmarkOnHover) {
                                                          addBookmarkOnHover =
                                                              true;
                                                          print('hover ' +
                                                              addBookmarkOnHover
                                                                  .toString());
                                                        }
                                                      },
                                                      onExit: (value) {
                                                        if (addBookmarkOnHover) {
                                                          addBookmarkOnHover =
                                                              false;
                                                          print('exit ' +
                                                              addBookmarkOnHover
                                                                  .toString());
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          // color: Colors.deepPurple,
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          10),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          10)),
                                                          color: Colors.white,
                                                        ),
                                                        margin:
                                                            EdgeInsets.all(3),
                                                        padding:
                                                            EdgeInsets.all(3),
                                                        child: Container(
                                                          // decoration: BoxDecoration(
                                                          //   border: Border(
                                                          //     bottom: BorderSide(
                                                          //       //                   <--- left side
                                                          //
                                                          //       width: 2.0,
                                                          //     ),
                                                          //   ),
                                                          // ),
                                                          //padding: EdgeInsets.only(left: 10),
                                                          child: Container(
                                                            color: Colors.white,
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                    // decoration: BoxDecoration(
                                                                    //   border: Border.all(
                                                                    //     color: Colors.deepPurple,
                                                                    //     width: 1,
                                                                    //   ),
                                                                    //   borderRadius: BorderRadius.all(
                                                                    //     Radius.circular(3.0),
                                                                    //   ),
                                                                    // ),
                                                                    width: 90.0,
                                                                    height:
                                                                        25.0,
                                                                    //padding: EdgeInsets.all(10.0),
                                                                    child:
                                                                        TextFormField(
                                                                      controller:
                                                                          bookmarkCreator,
                                                                      cursorColor:
                                                                          Colors
                                                                              .black,
                                                                      cursorWidth:
                                                                          0.5,
                                                                      decoration:
                                                                          new InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                        focusedBorder:
                                                                            InputBorder.none,
                                                                        enabledBorder:
                                                                            InputBorder.none,
                                                                        errorBorder:
                                                                            InputBorder.none,
                                                                        disabledBorder:
                                                                            InputBorder.none,
                                                                        contentPadding: EdgeInsets.only(
                                                                            top:
                                                                                -20,
                                                                            left:
                                                                                10),

                                                                        // hintText: "Hint here"
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                    padding: EdgeInsets
                                                                        .symmetric(
                                                                            vertical:
                                                                                3),
                                                                    child:
                                                                        InkWell(
                                                                      onTap:
                                                                          () {
                                                                        if (bookmarkCreator.text != null &&
                                                                            bookmarkCreator.text !=
                                                                                '' &&
                                                                            !CheckBookmarkExists(bookmarkCreator.text)) {
                                                                          CreateBookmark(
                                                                              bookmarkCreator.text);
                                                                          BookmarkItem
                                                                              bi =
                                                                              new BookmarkItem();
                                                                          bi.name =
                                                                              bookmarkCreator.text;
                                                                          bi.listImages =
                                                                              new List<String>();
                                                                          AddRecentBookmark(
                                                                              bi);
                                                                          SaveBookmarkList(
                                                                              bi.name);
                                                                          bookmarkCreator.text =
                                                                              '';
                                                                          setState(
                                                                              () {
                                                                            recentBookmark;
                                                                          });
                                                                          SaveRecentBookmarkList();
                                                                        }
                                                                      },
                                                                      child:
                                                                          AspectRatio(
                                                                        aspectRatio:
                                                                            1,
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            border:
                                                                                Border.all(
                                                                              width: 1,
                                                                            ),
                                                                            color:
                                                                                Colors.deepPurple,
                                                                            borderRadius:
                                                                                BorderRadius.all(
                                                                              Radius.circular(3.0),
                                                                            ),
                                                                          ),
                                                                          width:
                                                                              50,
                                                                          height:
                                                                              26.0,
                                                                          //padding: EdgeInsets.all(10.0),
                                                                          child:
                                                                              Center(child: Icon(Icons.add, color: Colors.white, size: 12)),
                                                                        ),
                                                                      ),
                                                                    )),
                                                                Container(
                                                                  width: 3,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(height: 10),
                                                  Container(
                                                    width: 120,
                                                    child: Column(
                                                        children:
                                                            ReturnRecentList(
                                                                imageSelected
                                                                    .value
                                                                    .path)),
                                                  ),
                                                  // Expanded(
                                                  //   flex: 1,
                                                  //   child: Container(
                                                  //     decoration: BoxDecoration(
                                                  //       border: Border(
                                                  //         bottom: BorderSide(
                                                  //           //                   <--- left side
                                                  //           color: Colors.white,
                                                  //           width: 2.0,
                                                  //         ),
                                                  //       ),
                                                  //     ),
                                                  //     padding: EdgeInsets.only(left: 10),
                                                  //     child: InkWell(
                                                  //         onTap: () async {
                                                  //           print('Open folder');
                                                  //
                                                  //           Codec<String, String>
                                                  //           stringToBase64 =
                                                  //           utf8.fuse(base64);
                                                  //
                                                  //           String pathBase64Encode =
                                                  //           stringToBase64.encode(
                                                  //               imageSelected
                                                  //                   .value.path);
                                                  //
                                                  //           var p = await Process.run(
                                                  //               Directory.current.path +
                                                  //                   "\\imageoption.exe",
                                                  //               ['0', pathBase64Encode]);
                                                  //
                                                  //           var exitCode = await p.exitCode;
                                                  //
                                                  //           imageSelected.value.show =
                                                  //           false;
                                                  //           imageSelected.notifyListeners();
                                                  //
                                                  //           // print('exit code: $exitCode');
                                                  //         },
                                                  //         child: Align(
                                                  //             alignment:
                                                  //             Alignment.centerLeft,
                                                  //             child: Text('Open folder',
                                                  //                 style: TextStyle(
                                                  //                     color:
                                                  //                     Colors.white)))),
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ))
                                        : Container(),
                                    MouseRegion(
                                        onHover: (value) {
                                          if (!addBookmarkOnHover) {
                                            setState(() {
                                              addBookmarkOnHover = true;
                                            });
                                            print('hover ' +
                                                addBookmarkOnHover.toString());
                                          }
                                        },
                                        onExit: (value) {
                                          if (addBookmarkOnHover) {
                                            setState(() {
                                              addBookmarkOnHover = false;
                                            });

                                            print('exit ' +
                                                addBookmarkOnHover.toString());
                                          }
                                        },
                                        child: Container(
                                          width: 10,
                                          height: 37.5, //color:Colors.black
                                        )),
                                    addBookmarkOnHover
                                        ? MouseRegion(
                                            onHover: (value) {
                                              if (!addBookmarkOnHover) {
                                                setState(() {
                                                  addBookmarkOnHover = true;
                                                });
                                                print('hover ' +
                                                    addBookmarkOnHover
                                                        .toString());
                                              }
                                            },
                                            onExit: (value) {
                                              if (addBookmarkOnHover) {
                                                setState(() {
                                                  addBookmarkOnHover = false;
                                                });

                                                print('exit ' +
                                                    addBookmarkOnHover
                                                        .toString());
                                              }
                                            },
                                            child: Container(
                                              width: 120,
                                              // height: 150,
                                              decoration: BoxDecoration(
                                                // border: Border.all(
                                                //   color: Colors.deepPurple,
                                                //   width: 1,
                                                // ),
                                                color: Colors.deepPurple,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(10.0),
                                                ),
                                              ),

                                              // padding: EdgeInsets.symmetric(
                                              //     vertical: 10, horizontal: 20),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 120,
                                                    child: Column(
                                                        children:
                                                            ReturnSuggestBookmark(
                                                                imageSelected
                                                                    .value.path,
                                                                indexSuggestBookmark)),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        : Container(),
                                  ],
                                ),
                              ),
                            ))
                        : Container();
                  })
            ],
          ),
          // ListView(controller: _scrollController, children: [
          //   Container(
          //     width: double.infinity,
          //     height: ContainerHeight,
          //     child: Stack(
          //       children: listItemOnPage,
          //     ),
          //   ),
          // ]),
        ),
      ],
    ));
  }
}

class ImageInfomation {
  String path;
  String pathThump;
  //bool onHover;
  // bool selected;
  // double x;
  // double y;
  // Size size;
  String pathResize;
}

class ImageReview {
  String path;
  double xMiniReview;
  double yMiniReview;
  double xPopupReview;
  double yPopupReview;
  Size size;
  int index;
  double angle;
  double xRatio;
  double yRatio;
}

class ImageSelected {
  String path;
  Offset point;
  bool show;
}

int calc_ranks(ranks) {
  double multiplier = .5;
  return (multiplier * ranks).round();
}

class BookmarkItem {
  String name;
  List<String> listImages;
  bool onHover;
  bool selected;
}

enum Tabpage{
  Review,
  AllBookmarks,
  BookmarksSelected
}

enum LoadImage{
  All,
  BookmarkSelected
}

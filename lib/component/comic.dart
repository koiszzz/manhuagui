import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'util/baseUtil.dart';
import 'package:html/dom.dart' as html;

class _ComicDetail {
  String title;
  String publishYear;
  String area;
  String indexLetter;
  String plot;
  String author;
  String alis;
  String state;
  String description;
  List<_Section> sections;

  _ComicDetail() {
    this.sections = [];
  }
}

class _Section {
  String name;
  List<_Chapter> chapters;

  _Section() {
    this.chapters = [];
  }
}

class _Chapter {
  String name;
  String url;

  _Chapter({this.name, this.url});
}

class ComicDetail extends StatefulWidget {
  final Comic comic;

  ComicDetail({Key key, this.comic}) : super(key: key);

  @override
  _ComicDetailState createState() => _ComicDetailState();
}

enum LoadState { LOADING, SUCCESS, FAIL }

class _ComicDetailState extends State<ComicDetail> {
  var _loadState = LoadState.LOADING;
  _ComicDetail _comicDetail;

  @override
  initState() {
    super.initState();
    _loadComicDetail();
  }

  Future<_ComicDetail> _loadComicDetail() async {
    setState(() {
      this._loadState = LoadState.LOADING;
    });
    String url = "https://www.manhuagui.com" + widget.comic.url;
    print('url: $url');
    String docStr = await BaseUtil.httpGet(url);
    if (docStr != null) {
      var dom = BaseUtil.parseHtml(docStr);
      var temp = _ComicDetail();
      temp.title = dom
          .getElementsByClassName('book-title')
          .first
          .children
          .first
          .innerHtml;
      var infoEle =
          dom.getElementsByClassName('detail-list cf').first.children.toList();
      var row = infoEle[0].getElementsByTagName('a').toList();
      temp.publishYear = row[0].innerHtml;
      temp.area = row[1].innerHtml;
      temp.indexLetter = row[2].innerHtml;
      temp.plot = infoEle[1]
          .getElementsByTagName('span')
          .first
          .getElementsByTagName('a')
          .toList()
          .map((html.Element e) => e.innerHtml)
          .join(',');
      temp.author = infoEle[1].getElementsByTagName('a').last.innerHtml;
      temp.alis = infoEle[2]
          .getElementsByTagName('a')
          .toList()
          .map((html.Element e) => e.innerHtml)
          .join(',');
      temp.state = infoEle[3].getElementsByClassName('red').first.innerHtml;
      temp.description = dom.getElementById('intro-cut').innerHtml;
      var sectionTitle = dom
          .getElementsByClassName('chapter cf mt16')
          .first
          .getElementsByTagName('h4')
          .toList();
      var sectionList = dom
          .getElementsByClassName('chapter cf mt16')
          .first
          .getElementsByClassName('chapter-list cf mt10')
          .toList();
      var size = sectionList.length < sectionTitle.length
          ? sectionList.length
          : sectionTitle.length;
      for (int i = 0; i < size; i++) {
        var tempS = new _Section();
        tempS.name =
            sectionTitle[i].getElementsByTagName('span').first.innerHtml;
        var chapters = sectionList[i].getElementsByTagName('a').toList();
        for (var chapter in chapters) {
          tempS.chapters.add(_Chapter(
              name: chapter.attributes['title'],
              url: chapter.attributes['href']));
        }
        temp.sections.add(tempS);
      }
      setState(() {
        _loadState = LoadState.SUCCESS;
        _comicDetail = temp;
      });
      return temp;
    } else {
      _loadState = LoadState.FAIL;
      return null;
    }
  }

  Widget _buildBody() {
    switch (this._loadState) {
      case LoadState.FAIL:
        return Center(
          child: FlatButton(onPressed: _loadComicDetail, child: Text('重新加载')),
        );
      case LoadState.LOADING:
        return _buildLoad();
      case LoadState.SUCCESS:
        return DefaultTabController(
            length: _comicDetail.sections.length,
            child: new Scaffold(
              appBar: new AppBar(
                title: Text(widget.comic.title),
                bottom: new TabBar(
                  isScrollable: true,
                  tabs: _comicDetail.sections.map((_Section section) {
                    return new Tab(
                      text: section.name,
                      icon: new Icon(Icons.book),
                    );
                  }).toList(),
                ),
              ),
              body: TabBarView(
                children: _comicDetail.sections.map((_Section section) {
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: section.chapters
                        .map((_Chapter chapter) => ListTile(
                      title: Text(chapter.name),
                    ))
                        .toList(),
                  );
                }).toList(),
              ),
            ));
    }
  }

  Widget _buildLoad() {
    return Center(
      child: Opacity(opacity: 1.0, child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }
}

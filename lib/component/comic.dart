import 'package:flutter/material.dart';
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

class _ComicDetailState extends State<ComicDetail> {
  _ComicDetail _comicDetail;

  @override
  initState() {
    super.initState();
    _loadComicDetail();
  }

  Future<_ComicDetail> _loadComicDetail() async {
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
        _comicDetail = temp;
      });
      return temp;
    } else {
      return null;
    }
  }

  Widget _buildBody() {
    if (_comicDetail == null) {
      print(_comicDetail == null);
      return Text('数据加载中');
    } else {
      return Container(
        padding: EdgeInsets.all(5.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Image.network(widget.comic.cover),
                Container(
                  child: Column(
                    children: <Widget>[
                      Text('标题: ${_comicDetail.title}'),
                      Text('作者: ${_comicDetail.author}')
                    ],
                  ),
                )
              ],
            ),
            Column(
              children: _buildSection(_comicDetail.sections),
            )
          ],
        ),
      );
    }
  }

  List<Widget> _buildSection(List<_Section> list) {
    return list
        .map((section) => Column(
              children: <Widget>[
                Text(section.name),
                Container(
                  height: 400,
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(4.0),
                    childAspectRatio: 1.3,
                    scrollDirection: Axis.vertical,
                    children: _buildChapter(section.chapters),
                  ),
                )
              ],
            ))
        .toList();
  }

  List<Widget> _buildChapter(List<_Chapter> list) {
    print('load list ${list.length}');
    return list
        .map((chapter) => Card(
              child: Text(chapter.name),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.comic.title),
      ),
      body: _buildBody(),
    );
  }
}

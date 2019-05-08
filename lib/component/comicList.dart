import 'package:flutter/material.dart';
import 'package:my_app/component/comic.dart';
import 'util/baseUtil.dart';

class ComicList extends StatefulWidget {
  ComicList({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ComicList createState() => _ComicList();
}

class _ComicList extends State<ComicList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  bool isLoadMore = false;
  final _pageSize = 42; //每页漫画书
  List<Comic> _comics = <Comic>[];
  var _curIndex = 1; //当前页数
  var _pageNum = 1; //页面总数
  ScrollController _scrollController = new ScrollController();
  final List<DownGroup> indexOrderList = <DownGroup>[
    DownGroup(value: 'index', name: '最新发布'),
    DownGroup(value: 'update', name: '最近更新'),
    DownGroup(value: 'view', name: '人气最旺'),
    DownGroup(value: 'rate', name: '评分最高'),
  ].toList();
  DownGroup dropdown1Value;

  @override
  initState() {
    super.initState();
    dropdown1Value = indexOrderList.first;
    initList();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        print('listener working');
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  initList() {
    this._searchComics().then(((comics) {
      setState(() {
        isLoading = false;
        _comics = comics;
      });
    }));
  }

  _loadMore() async {
    print('当前页面： $_curIndex, 最大页面: $_pageNum');
    if (_curIndex < _pageNum) {
      setState(() {
        _curIndex++;
        isLoadMore = true;
      });
      List<Comic> comics = await this._searchComics();
      setState(() {
        isLoadMore = false;
        _comics.addAll(comics);
      });
    }
  }

  Future<Null> _refreshList() async {
    print('refresh list');
    _curIndex = 1;
    await _searchComics().then((comics) {
      setState(() {
        _comics.clear();
        _comics.addAll(comics);
        return null;
      });
    });
  }

  Widget _buildEndLine() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Opacity(
            opacity: 1.0,
            child: isLoadMore
                ? CircularProgressIndicator()
                : Text('当前已加载到: $_curIndex, 可加载最大页面: $_pageNum'),
          ),
        ));
  }

  Widget _buildBody() {
    if (isLoading) {
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Center(
            child: new Opacity(
              opacity: isLoading ? 1.0 : 0.0,
              child: new CircularProgressIndicator(),
            ),
          ));
    } else {
      return _buildList();
    }
  }

  Widget _buildList() {
    return RefreshIndicator(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _comics.length,
        itemBuilder: (context, i) {
          if (i == _comics.length - 1) {
            return _buildEndLine();
          }
          return _buildRow(_comics[i]);
        },
        controller: _scrollController,
      ),
      onRefresh: _refreshList,
    );
  }

  Widget _buildRow(Comic comic) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ComicDetail(
                      comic: comic,
                    )));
      },
      child: Card(
        child: Row(
          children: <Widget>[
            Container(
              height: 120,
              padding: const EdgeInsets.all(5.0),
              child: Image.network(comic.cover),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(comic.title),
                  Text(
                    comic.lastUpdate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Comic>> _searchComics() async {
    var url = 'https://www.manhuagui.com/list/japan_shaonv_2018/' +
        (dropdown1Value == null ? 'index' : dropdown1Value.value) +
        '_p' +
        _curIndex.toString() +
        '.html';
    print('url: $url');
    try {
      var docStr = await BaseUtil.httpGet(url);
      var document = BaseUtil.parseHtml(docStr);
      var pageInfoEle = document
          .getElementsByClassName('result-count')
          .first
          .getElementsByTagName('strong');
      if (pageInfoEle.length == 3) {
        _pageNum = int.parse(pageInfoEle[1].innerHtml);
      }
      var list = <Comic>[];
      for (var child in document.getElementById('contList').children) {
        var attr = child.firstChild.attributes;
        var url = attr['href'];
        var title = attr['title'];
        var cover = child.getElementsByTagName('img').first.attributes['src'];
        if (cover == null) {
          cover =
          child.getElementsByTagName('img').first.attributes['data-src'];
        }
        var lastUpdate = child.getElementsByClassName('tt').first.innerHtml;
        list.add(new Comic(
            url: url, title: title, cover: cover, lastUpdate: lastUpdate));
      }
      return list;
    } catch (exception) {
      print(exception);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          tooltip: 'Navigation menu',
          onPressed: () {
            _scaffoldKey.currentState.openDrawer();
          },
        ),
        title: Text(dropdown1Value.name),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.search),
            tooltip: 'Search',
            onPressed: null,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

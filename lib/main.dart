import 'package:flutter/material.dart';
import 'comic.dart';
import 'baseUtil.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '首页'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _comics = <Comic>[];
  final _pageSize = 42; //每页漫画书
  var _curIndex = 1; //当前页数
  var _pageNum = 1; //页面总数
  final List<DownGroup> list = <DownGroup>[
    DownGroup(value: 'index', name: '最新发布'),
    DownGroup(value: 'update', name: '最近更新'),
    DownGroup(value: 'view', name: '人气最旺'),
    DownGroup(value: 'rate', name: '评分最高'),
  ].toList();
  DownGroup dropdown1Value;

  @override
  initState() {
    super.initState();
    dropdown1Value = list.first;
    this._searchComics().then(((comics) => {comics.forEach(_addComics)}));
  }

  _addComics(dynamic comic) {
    setState(() {
      this._comics.add(comic);
    });
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _comics.length,
        itemBuilder: (context, i) {
          if (i >= _comics.length - 1) {
            print('当前已加载到:' +
                _curIndex.toString() +
                ',可加载最大页面:' +
                _pageNum.toString());
            if (_curIndex < _pageNum) {
              _curIndex++;
              _searchComics().then(((comics) => {comics.forEach(_addComics)}));
            } else {
              return Text('当前已加载到:' +
                  _curIndex.toString() +
                  ',可加载最大页面:' +
                  _pageNum.toString());
            }
          }
          return _buildRow(_comics[i]);
        });
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
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: const Text('Kois'),
              accountEmail: const Text('kois@example.com'),
            ),
            Expanded(
                child: Container(
                    child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  title: const Text('排列方式:'),
                  trailing: DropdownButton<DownGroup>(
                    value: dropdown1Value,
                    onChanged: (DownGroup newValue) {
                      setState(() {
                        dropdown1Value = newValue;
                        _comics.clear();
                        _searchComics()
                            .then(((comics) => {comics.forEach(_addComics)}));
                      });
                    },
                    items: list
                        .map<DropdownMenuItem<DownGroup>>((DownGroup group) {
                      return DropdownMenuItem<DownGroup>(
                        value: group,
                        child: Text(group.name),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )))
          ],
        ),
      ),
      body: _buildSuggestions(),
    );
  }
}

import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';

class User {
  final int id;
  final String email, first_name, last_name, avatar;

  User({this.id, this.email, this.first_name, this.last_name, this.avatar});

  factory User.fromJson(Map<String, dynamic> jsonVal) {
    return User(
        id: jsonVal['id'],
        email: jsonVal['email'],
        first_name: jsonVal['first_name'],
        last_name: jsonVal['last_name'],
        avatar: jsonVal['avatar']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': first_name,
      'last_name': last_name,
      'avatar': avatar,
    };
  }

}

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Future<sql.Database> database;
  List _contact = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  _checkInternetConnection() async {
    await _getDBPath();
    print("The statement 'this machine is connected to the Internet' is: ");
    print(await DataConnectionChecker().hasConnection);
    print("Current status: ${await DataConnectionChecker().connectionStatus}");
    print("Last results: ${DataConnectionChecker().lastTryResults}");
    var listener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          print('Data connection is available.');
          _loadDataFromApi(context);
          break;
        case DataConnectionStatus.disconnected:
          print('You are disconnected from the internet.');
          break;
      }
    });

    await Future.delayed(Duration(seconds: 1));
    await listener.cancel();
  }

  _getDBPath() async {
    final _pro = Provider.of<DataConnectionStatus>(context, listen: false);
    print('setting up the database');
    database = sql.openDatabase(
      path.join(await sql.getDatabasesPath(), 'mango_leap.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE contact(id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT, avatar TEXT)",
        );
      },
      version: 1,
    );
    // final insert = new User(
    //   id: 1,
    //   first_name: 'First',
    //   last_name: 'Second',
    //   email: 'bashaadil2727@gmail.com',
    //   avatar: 'https://mangoleap.com/images/logo_mangoleap.png',
    // );
    // await insertContact(insert);

    if (await DataConnectionChecker().connectionStatus ==
        DataConnectionStatus.disconnected) {
      print('No Internet Connection');
      await contacts();
    } else {
      print('Internet Connected');
      await _loadDataFromApi(context);
    }
  }

  Future<void> insertMany() async {
    print('insert query running');
    for (var x in _contact) {
      final sql.Database db = await database;
      await db.insert(
        'contact',
        x,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
    }
    print('insert query completed');
  }

  Future<List> contacts() async {
    final sql.Database db =
        await Future.delayed(Duration(seconds: 1), () => database);
    final List<Map<String, dynamic>> maps = await db.query('contact');
    setState(() {
      maps.forEach((element) => _contact.add(element));
    });
  }

  _loadDataFromApi(context) async {
    setState(() {
      _loading = true;
    });
    Response res =
        await Dio().get("https://reqres.in/api/users?page=1&per_page=20");
    setState(() {
      final list = res.data['data'];
      _contact.clear();
      _contact = list;
      _loading = false;
    });
    await insertMany();
  }

  Future<Null> _handleRefresh() async {
    setState(() {
      _contact.clear();
    });
    if (await DataConnectionChecker().connectionStatus ==
        DataConnectionStatus.disconnected) {
      await Future.delayed(Duration(seconds: 3), () async {
        print('refresh');
        final sql.Database db = await database;
        final List<Map<String, dynamic>> maps = await db.query('contact');
        setState(() {
          maps.forEach((element) => _contact.add(element));
        });
      });
    } else {
      await _loadDataFromApi(context);
    }
  }

  void handleClick(String value) async{
    switch (value) {
      case 'Id':
        Comparator sortById = (a, b) => a['id'].compareTo(b['id']);
        setState(() {
          _contact.sort(sortById);
        });
        break;
      case 'Name':
        Comparator sortByName = (a, b) => a['first_name'].compareTo(b['first_name']);
        setState(() {
          _contact.sort(sortByName);
        });
        break;
      case 'Email':
        Comparator sortByEmail = (a, b) => a['email'].compareTo(b['email']);
        setState(() {
          _contact.sort(sortByEmail);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3A3A3A),
        title: Text(
          'Contact',
          style: GoogleFonts.fredokaOne(color: Color(0xFFfdb803)),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return {'Id', 'Name', 'Email'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: _loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _contact == null
                    ? ListView(
                        children: [
                          Container(
                            color: Colors.redAccent,
                            child: Text(
                              'No Data Available, Switch on your internet and refresh this page',
                              style:
                                  GoogleFonts.nunito(color: Color(0xFFfdb803)),
                            ),
                          )
                        ],
                      )
                    : ListView.builder(
                        itemCount: _contact == null ? 0 : _contact.length,
                        itemBuilder: (context, index) {
                          return _listViewContainer(_contact[index], index);
                        },
                      ),
              ),
      ),
      bottomSheet: Provider.of<DataConnectionStatus>(context) ==
              DataConnectionStatus.disconnected
          ? Container(
              height: 45,
              width: double.infinity,
              color: Color(0xFFfdb803),
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Please Check Your Connection',
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                  Spacer(),
                  Icon(Icons.wifi_off)
                ],
              ),
            )
          : Container(
              height: 0,
            ),
    );
  }

  Widget _listViewContainer(dynamic val, int index) {
    return GestureDetector(
      onLongPress: () async {
        print('the id is ${val['id']}');
        return showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text(
                    'Are You sure to delete the user  ${val['first_name']}',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    Row(
                      children: [
                        FlatButton(
                          onPressed: () async {
                            final sql.Database db = await database;
                            db.rawDelete(
                                'DELETE FROM contact WHERE id = ${val['id']}');
                            final List<Map<String, dynamic>> maps =
                                await db.query('contact');
                            setState(() {
                              _contact.removeAt(index);
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: Text("Yes"),
                        ),
                        FlatButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: Text("No"),
                        ),
                      ],
                    )
                  ],
                ));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Color(0xFF3D3E40), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              // backgroundImage: NetworkImage(val['avatar']),
              radius: 25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10000.0),
                child: CachedNetworkImage(
                  imageUrl: val['avatar'],
                  placeholder: (context, url) =>
                      new CircularProgressIndicator(),
                  errorWidget: (context, url, error) => new Icon(Icons.error),
                ),
              ),
            ),
            SizedBox(
              width: 15,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${val['first_name']} & ${val['last_name']}",
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  val['email'],
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Color(0xFFfdb803),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

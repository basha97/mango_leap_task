import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

class Dog {
  final int id;
  final String name;
  final int age;

  Dog({this.id, this.name, this.age});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }
}

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

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  List<int> items = List.generate(12, (i) => i);
  List _contact = [];
  bool _loading = false;

  Future<Database> database;
  int version = 1;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    WidgetsFlutterBinding.ensureInitialized();
    _getDBPath();
    _testingdb();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _loadDataFromApi(context));
    contacts();
  }

  _testingdb() async{
    final Database db = await Future.delayed(Duration(seconds: 1), () => database);
    final List<Map<String, dynamic>> maps = await db.query('contact');
    final val = [];
    maps.forEach((element) => val.add(element));
    print('the size of the val is ${val.length}');
  }

  _checkInternetConnection() async {
    print("The statement 'this machine is connected to the Internet' is: ");
    print(await DataConnectionChecker().hasConnection);
    print("Current status: ${await DataConnectionChecker().connectionStatus}");
    print("Last results: ${DataConnectionChecker().lastTryResults}");
    var listener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          print('Data connection is available.');
          break;
        case DataConnectionStatus.disconnected:
          print('You are disconnected from the internet.');
          break;
      }
    });
    await Future.delayed(Duration(seconds: 30));
    await listener.cancel();
  }

  _getDBPath() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'mango_leap.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          "CREATE TABLE contact(id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT, avatar TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> insertMany() async{
    for(var x in _contact){
      final Database db = await database;
      await db.insert('contact', x,conflictAlgorithm: ConflictAlgorithm.replace,);
    }
  }

  Future<void> insertContact(User usr) async {
    final Database db = await database;
    final value = await db.insert(
      'contact',
      usr.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List> contacts() async {
    //final Database db = await database;
    final Database db = await Future.delayed(Duration(seconds: 1), () => database);
    final List<Map<String, dynamic>> maps = await db.query('contact');
    maps.forEach((element) => _contact.add(element));
    print(_contact.length);
    // return List.generate(maps.length, (i) {
    //   return _contact.add(maps[i]).toList();
    //   return User(
    //     id: maps[i]['id'],
    //     first_name: maps[i]['first_name'],
    //     last_name: maps[i]['last_name'],
    //     email: maps[i]['email'],
    //     avatar: maps[i]['avatar'],
    //   );
    // });
  }

  _loadDataFromApi(context) async {
    //contacts();
    // final dataconnection = Provider.of<DataConnectionStatus>(context);
    // print('the connection is ${dataconnection}');


    setState(() {
      _loading = true;
    });
    Response res =
        await Dio().get("https://reqres.in/api/users?page=1&per_page=20");
    setState(() {
      final list = res.data['data'];
      _contact = list.map((val) => new User.fromJson(val)).toList();
      _loading = false;
    });
    print('the lenght is after api ${_contact.length}');
    if(_contact.length < 1){
      insertMany();
      contacts();
    }
  }

  Future<Null> _handleRefresh() async {
    await Future.delayed(Duration(seconds: 3), () async{
      print('refresh');
      final Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('contact');
      setState(() {
        maps.forEach((element) => _contact.add(element));
        // items.clear();
        // items = List.generate(36, (i) => i);
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    _check(BuildContext context) {
      print('called **********************');
      final d = Provider.of<DataConnectionStatus>(context, listen: false);
      print('the connection is $d');
      contacts();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _check(context));


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3A3A3A),
        title: Text(
          'Contact',
          style: GoogleFonts.fredokaOne(color: Color(0xFFfdb803)),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: Icon(Icons.sort),
          ),
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
                child: _contact == '' ? Center(
                  child: Text('No Data Available, Switch on your internet and refresh this page', style: GoogleFonts.nunito(color: Color(0xFFfdb803)),),
                ) : ListView.builder(
                  itemCount: _contact?.length,
                  itemBuilder: (context, index) {
                    return _listViewContainer(_contact[index]);
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

  Widget _listViewContainer(dynamic val) {
    return Container(
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
            backgroundImage: NetworkImage(val.avatar),
            radius: 30,
          ),
          SizedBox(
            width: 15,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${val.first_name} & ${val.last_name}",
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                val.email,
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
    );
  }
}

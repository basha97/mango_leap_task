import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:path/path.dart';
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
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _loadDataFromApi(context));
    _getDBPath();
  }

  _checkInternetConnection() async{
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

  _getDBPath() async{
     database = openDatabase(
      join(await getDatabasesPath(), 'doggie_database.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          "CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)",
        );
      },
       version: 1,
    );
     final fido = Dog(
       id: 0,
       name: 'Fido',
       age: 35,
     );
     //insertDog(fido);
     dogs();
  }

  Future<void> insertDog(Dog dog) async {
    final Database db = await database;
    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Dog>> dogs() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dogs');
    print('the fetch query is $maps');
    return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });

  }

  _loadDataFromApi(context) async{
    setState(() {
      _loading = true;
    });
    Response res = await Dio().get("https://reqres.in/api/users?page=1&per_page=20");
    setState(() {
      _contact = res.data['data'];
      _loading = false;
    });
  }

  Future<Null> _handleRefresh() async {
    await Future.delayed(Duration(seconds: 5), () {
      print('refresh');
      setState(() {
        items.clear();
        items = List.generate(36, (i) => i);
      });
    });
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
          Container(
            margin: EdgeInsets.only(right: 10),
            child: Icon(Icons.sort),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: _loading ? Center(
          child: CircularProgressIndicator(),
        ) : RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            itemCount: _contact?.length,
            itemBuilder: (context, index) {
              return _listViewContainer(_contact[index]);
            },
          ),
        ),
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
            backgroundImage:
                NetworkImage(val['avatar']),
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
                "${val['first_name']} & ${val['last_name']}",
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                val['email'],
                style: GoogleFonts.nunito(fontSize: 16, color: Color(0xFFfdb803), fontWeight: FontWeight.w700),
              ),
            ],
          )
        ],
      ),
    );
  }
}

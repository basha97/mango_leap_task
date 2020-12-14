import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mango_leap_task/contact.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;


class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {


  Future<sql.Database> database;
  List _contact = [];
  
  @override
  void initState() {
    super.initState();

    _checkInternetConnection();
    //_getDBPath();
    // SchedulerBinding.instance.addPostFrameCallback(
    //     (_) => _loadDataFromApi(context)
    //);
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
    print('setting up the database');
    database = sql.openDatabase(
      path.join(await sql.getDatabasesPath(), 'mango_leap.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          "CREATE TABLE contact(id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT, avatar TEXT)",
        );
      },
      version: 1,
    );
    final insert = new User(
      id: 1,
      first_name: 'First',
      last_name: 'Second',
      avatar: 'https://www.gstatic.com/devrel-devsite/prod/vf7e3a995d426e05d42b78fc7d21a14329a91016dc065dc22c480cc8f443ef33e/android/images/lockup.svg',
    );
    await insertContact(insert);
  }

  Future<void> insertMany() async{
    for(var x in _contact){
      final sql.Database db = await database;
      await db.insert('contact', x,conflictAlgorithm: sql.ConflictAlgorithm.replace,);
    }
  }

  Future<void> insertContact(User usr) async {
    print('insert function');
    final sql.Database db = await database;
    final value = await db.insert(
      'contact',
      usr.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<List> contacts() async {
    print('fetch all function');
    //final Database db = await database;
    final sql.Database db = await Future.delayed(Duration(seconds: 1), () => database);
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
    print('called api function');
    final _pro = Provider.of<DataConnectionStatus>(context, listen: false);
    if(_pro ==
        DataConnectionStatus.disconnected){
      print('disconnect');
    }else{
      contacts();
      print('conneccted');
    }

  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('testing'),
    );
  }
}

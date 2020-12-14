import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';



class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {


  Future<Database> database;
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



  _loadDataFromApi(context) async {
    final _pro = Provider.of<DataConnectionStatus>(context, listen: false);
    if(_pro ==
        DataConnectionStatus.disconnected){
      print('disconnect');
    }else{
      //contacts();
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

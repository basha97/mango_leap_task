import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {

  List<int> items = List.generate(12, (i) => i);
  List _contact = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _loadDataFromApi(context));
  }

  _loadDataFromApi(context) async{
    setState(() {
      _loading = true;
    });
    Response res = await Dio().get("https://reqres.in/api/users?page=1&per_page=20");
    print('the resposne is ${res}');
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

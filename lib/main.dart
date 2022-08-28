import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
void main(){
  runApp(MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();

  List _todoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;


  @override
  void initState() {
    super.initState();
    _readData().then((value){
      setState(() {
        _todoList = json.decode(value!);
      });
    });
  }

  Future<void> _refresh() async{
    await Future.delayed(const Duration(seconds: 1));

    _todoList.sort((a, b){
      if(a["ok"] && !b["ok"]) return 1;
      else if (!a["ok"] && b["ok"]) return -1;
      else return 0;
    });

    setState(() {
      _saveData();
    });
  }

  void _addTodo(){
    Map<String, dynamic> newTodo = Map();
    newTodo["title"] = _todoController.text;
    if (newTodo["title"].toString().isEmpty) {
      return null;
    }
    _todoController.clear();
    newTodo["ok"] = false;
    setState(() {
      _todoList.add(newTodo);
    });
    _saveData();
  }

  Color color = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: color,
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: color),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Text("ADD"),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _todoList.length,
                  itemBuilder: buildItem,
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9,0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      child: CheckboxListTile(
        title: Text(_todoList.elementAt(index)["title"]),
        value: _todoList.elementAt(index)["ok"],
        onChanged: (bool? value) {
          setState(() {
            _todoList.elementAt(index)["ok"] = value;
            _saveData();
          });
        },
        secondary:
        CircleAvatar(
          child:
          Icon(_todoList.elementAt(index)["ok"] ? Icons.check : Icons.error,),
        ),
      ),
      onDismissed: (direction){
        _lastRemoved = Map.from(_todoList.elementAt(index));
        _lastRemovedPos = index;
        setState(() {
          _todoList.removeAt(index);
          _saveData();
          
          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida!!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );

          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async{
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch (e){
      return null;
    }
  }
}

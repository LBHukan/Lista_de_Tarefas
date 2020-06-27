import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();
  List _todoList = [];

  Map<String, dynamic> _todoRemoved = Map();
  int _todoRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _todoAdd() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoController.text;
      _todoController.text = "";
      newTodo["ok"] = false;
      _todoList.add(newTodo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (a["ok"] && b["ok"])
          return 0;
        else
          return -1;
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: Text("Lista de Tarefas"),
          centerTitle: true,
        ),
        body: Column(children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 10.0, 10.0, 15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.text,
                    controller: _todoController,
                    decoration: InputDecoration(
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        labelText: "Nova Tarefa"),
                  ),
                ),
                RaisedButton(
                  padding: EdgeInsets.only(left: 5.0),
                  color: Colors.green,
                  child: Text("ADD"),
                  onPressed: _todoAdd,
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: itemBuilder),
          ))
        ]));
  }

  Widget itemBuilder(context, index) {
    return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        onDismissed: (direction) {
          setState(() {
            _todoRemoved.clear();
            _todoRemoved = Map.from(_todoList[index]);
            _todoList.removeAt(index);
            _todoRemovedPos = index;

            final snack = SnackBar(
              duration: Duration(seconds: 2),
              content: Text("Tarefa ${_todoRemoved["title"]} removido!"),
              action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(_todoRemovedPos, _todoRemoved);
                    _saveData();
                  });
                },
              ),
            );
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snack);
          });
        },
        background: Container(
            color: Colors.red,
            child: Align(
                alignment: Alignment(-0.9, 0.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ))),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(_todoList[index]["title"]),
          value: _todoList[index]["ok"],
          secondary: CircleAvatar(
            child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.cancel),
          ),
          onChanged: (value) {
            setState(() {
              _todoList[index]["ok"] = value;
              _saveData();
            });
          },
        ));
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

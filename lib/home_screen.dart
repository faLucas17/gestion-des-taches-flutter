import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(Duration(days: 1));
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  Future<void> _refreshData() async {
    final data = await SQLHelper.getAllData();
    setState(() {
      _allData = data.map((item) {
        final startDate = DateTime.tryParse(item['startDate'] ?? '') ?? DateTime.now();
        final endDate = DateTime.tryParse(item['endDate'] ?? '') ?? DateTime.now();
        final status = getStatus(startDate, endDate);
        return {
          ...item,
          'startDate': startDate,
          'endDate': endDate,
          'status': status,
        };
      }).toList();
      _isLoading = false;
    });
  }


  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _addData() async {
    if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
      final DateTime startDate = DateTime
          .now(); // Utilisation de la date actuelle
      final DateTime endDate = startDate.add(
          Duration(days: 1)); // Date de fin (demain)
      final String status = getStatus(startDate, endDate); // Calcul du statut

      await SQLHelper.createData(
          _titleController.text, _descController.text, startDate, endDate,
          status);

      await _refreshData(); // Attendre la mise à jour de la liste des données après l'ajout
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Tâche ajoutée avec succès"),
      ));
      _titleController.text =
      ""; // Réinitialiser les champs de saisie après l'ajout
      _descController.text = "";
    } else {
      print("Les champs de titre et de description ne peuvent pas être vides.");
    }
  }

  String getStatus(DateTime startDate, DateTime endDate) {
    final DateTime now = DateTime.now();
    if (now.isBefore(startDate)) {
      return 'Pas Débuté';
    } else if (now.isAfter(endDate)) {
      return 'Terminé';
    } else {
      return 'En cours';
    }
  }




  Future<void> _updateData(int id) async {
    if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
      final existingData = _allData.firstWhere((element) => element['id'] == id);
      final DateTime startDate = existingData['startDate'];
      final DateTime endDate = existingData['endDate'];
      final String status = getStatus(startDate, endDate);

      await SQLHelper.updateData(id, _titleController.text, _descController.text);
      await _refreshData(); // Mettre à jour la liste des données après la mise à jour

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.deepPurpleAccent,
        content: Text("Tâches modifiées avec succès"),
      ));
    } else {
      print("Les champs de titre et de description ne peuvent pas être vides.");
    }
  }



  void _deleteData(int id) async {
    await SQLHelper.deleteData(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Colors.redAccent,
      content: Text("Tâches supprimées avec succès"),
    ));
    _refreshData(); // Mettre à jour la liste des données après la suppression
  }

  void showBottomSheet(int? id) async {
    if (id != null) {
      final existingData = _allData.firstWhere((element) => element['id'] == id);
      _titleController.text = existingData['title'];
      _descController.text = existingData['desc'];
    } else {
      _titleController.text = '';
      _descController.text = '';
    }


    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: EdgeInsets.only(
              top: 30,
              left: 15,
              right: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Titre",
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Description",
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              startDate = selectedDate;
                            });
                          }
                        },
                        child: Text(
                          "Date de début: ${DateFormat('dd/MM/yyyy').format(startDate)}",
                        ),
                      ),

                      TextButton(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              endDate = selectedDate;
                            });
                          }
                        },
                        child: Text(
                          "Date de fin: ${DateFormat('dd/MM/yyyy').format(endDate)}",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
                          final String status = getStatus(startDate, endDate);
                          if (id == null) {
                            await _addData();
                          } else {
                            await _updateData(id); // Modifier la tâche existante
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text("Tâche ajoutée avec succès"),
                          ));
                          _refreshData();
                          _titleController.text = "";
                          _descController.text = "";
                          Navigator.of(context).pop();
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          id == null ? "Ajouter Tâche" : "Modifier Tâche",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }




  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Pas Débuté':
        return Colors.blue;
      case 'En cours':
        return Colors.green;
      case 'Terminé':
        return Colors.red;
      default:
        return Colors.black; // Couleur par défaut si le statut n'est pas reconnu
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEAF4),
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Gestionnaire',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' Des ',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Tâches',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 24.0,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true, // Centrer le titre de l'appBar
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Container( // Utiliser un Container avec une largeur fixe pour éviter le débordement
        width: MediaQuery
            .of(context)
            .size
            .width, // Utiliser la largeur de l'écran
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _allData.length,
                itemBuilder: (context, index) =>
                    Card(
                      margin: EdgeInsets.all(15),
                      child: ListTile(
                        title: Text(
                          _allData[index]['title'],
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue, // Couleur bleue pour le titre
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _allData[index]['desc'],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,// Couleur orange pour la description
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Date de début: ${_allData[index]['startDate'] != null ? DateFormat('dd/MM/yyyy').format(_allData[index]['startDate']) : 'N/A'}',
                              style: TextStyle(
                                color: Colors.blueGrey[900],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              height: 1,
                              color: Colors.blueGrey[900],
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Date de fin: ${_allData[index]['endDate'] != null ? DateFormat('dd/MM/yyyy').format(_allData[index]['endDate']) : 'N/A'}',
                              style: TextStyle(
                                color: Colors.blueGrey[900],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Statut: ${_allData[index]['status']}',
                              style: TextStyle(
                                color: _getColorForStatus(_allData[index]['status']),
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,

                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                showBottomSheet(_allData[index]['id']);
                              },
                              icon: Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _deleteData(_allData[index]['id']);
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),


                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: Icon(Icons.add),
      ),
    );
  }
}
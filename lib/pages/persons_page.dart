import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:simple_app/module/person.dart';
import 'package:simple_app/login_page.dart';


class PersonsPage extends StatefulWidget {
  const PersonsPage({super.key});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  List<Person> persons = [];
  List<Person> filteredPersons = [];
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String sortBy = 'name'; // Default sort by name
  bool isAscending = true;

  // Pagination
  int currentPage = 0;
  final int pageSize = 5;

  @override
  void initState() {
    super.initState();
    fetchPersons();
    searchController.addListener(_filterPersons);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterPersons);
    nameController.dispose();
    ageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPersons() async {
    setState(() => isLoading = true);

    final response = await QueryBuilder(Person()).query();

    if (response.success && response.results != null) {
      persons = response.results!.cast<Person>();
      _filterPersons();
    } else {
      _showMessage("Failed to fetch: ${response.error?.message}");
    }

    setState(() => isLoading = false);
  }

  void _showForm({Person? person}) {
    final isEdit = person != null;

    if (isEdit) {
      nameController.text = person.name;
      ageController.text = person.age.toString();
    } else {
      nameController.clear();
      ageController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Edit Person" : "Add Person"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  } else if (age == null || age <= 0 || age > 100) {
                    return 'Enter a valid age (1–100)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [

          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final name = nameController.text.trim();
                final age = int.parse(ageController.text.trim());

                final newPerson = person ?? Person();
                newPerson.name = name;
                newPerson.age = age;

                final saveResult = await newPerson.save();
                Navigator.pop(context);

                if (saveResult.success) {
                  fetchPersons();
                } else {
                  _showMessage("Save failed: ${saveResult.error?.message}");
                }
              }
            },
            child: const Text("Save"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> deletePerson(Person person) async {
    final response = await person.delete();
    if (response.success) {
      fetchPersons();
    } else {
      _showMessage("Delete failed: ${response.error?.message}");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _filterPersons() {
    final query = searchController.text.trim().toLowerCase();
    filteredPersons = persons
        .where((person) => person.name.toLowerCase().contains(query))
        .toList();
    _sortPersons(sortBy, isAscending: isAscending, updateState: false);
    setState(() {
      currentPage = 0; // Reset to first page on search
    });
  }

  void _sortPersons(String sortBy, {bool? isAscending, bool updateState = true}) {
    if (isAscending == null) {
      if (this.sortBy == sortBy) {
        this.isAscending = !this.isAscending;
      } else {
        this.isAscending = true;
      }
    } else {
      this.isAscending = isAscending;
    }
    this.sortBy = sortBy;

    filteredPersons.sort((a, b) {
      int cmp;
      if (sortBy == 'name') {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        cmp = a.age.compareTo(b.age);
      }
      return this.isAscending ? cmp : -cmp;
    });

    if (updateState) setState(() {});
  }

  String _sortArrow(String column) {
    if (sortBy != column) return '';
    return isAscending ? ' ▲' : ' ▼';
  }

  @override
  Widget build(BuildContext context) {
    // Pagination logic
    final totalPages = (filteredPersons.length / pageSize).ceil();
    final int start = currentPage * pageSize;
    final int end = (start + pageSize) > filteredPersons.length
        ? filteredPersons.length
        : (start + pageSize);
    final List<Person> currentPagePersons =
    filteredPersons.isNotEmpty ? filteredPersons.sublist(start, end) : [];

    return Scaffold(
      appBar: AppBar(title: const Text("All Person Details"), automaticallyImplyLeading: false, centerTitle: true),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => LoginPage.logout(context),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text("Add Person"),
            ),

          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _sortPersons('name'),
                child: Text("Sort by Name${_sortArrow('name')}"),
              ),
              ElevatedButton(
                onPressed: () => _sortPersons('age'),
                child: Text("Sort by Age${_sortArrow('age')}"),
              ),
            ],
          ),
          Expanded(
            child: currentPagePersons.isEmpty
                ? const Center(child: Text("No persons found."))
                : ListView.builder(
              itemCount: currentPagePersons.length,
              itemBuilder: (_, index) {
                final person = currentPagePersons[index];
                return ListTile(
                  title: Text(person.name),
                  subtitle: Text("Age: ${person.age}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(person: person),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deletePerson(person),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Pagination controls at the bottom center
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 0
                      ? () {
                    setState(() {
                      currentPage--;
                    });
                  }
                      : null,
                ),
                Text(
                  'Page ${totalPages == 0 ? 0 : currentPage + 1} of $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: (currentPage + 1) < totalPages
                      ? () {
                    setState(() {
                      currentPage++;
                    });
                  }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

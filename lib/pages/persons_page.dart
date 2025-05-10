import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:simple_app/module/person.dart';
import 'package:simple_app/services/login_page.dart';

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
  final TextEditingController emailController = TextEditingController();


  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String sortBy = 'name';
  bool isAscending = true;

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
    emailController.dispose();
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
      emailController.text = person.email;
    } else {
      nameController.clear();
      ageController.clear();
      emailController.clear();
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
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
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
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email';
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
                final email = emailController.text.trim();

                final newPerson = person ?? Person();
                newPerson.name = name;
                newPerson.age = age;
                newPerson.email = email;

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
      currentPage = 0;
    });
  }

  void _sortPersons(String sortBy,
      {bool? isAscending, bool updateState = true}) {
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
    final totalPages = (filteredPersons.length / pageSize).ceil();
    final int start = currentPage * pageSize;
    final int end = (start + pageSize) > filteredPersons.length
        ? filteredPersons.length
        : (start + pageSize);
    final List<Person> currentPagePersons =
    filteredPersons.isNotEmpty ? filteredPersons.sublist(start, end) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Person Details"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => LoginPage.logout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Person"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showForm(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: Icon(
                    sortBy == 'name'
                        ? (isAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                        : Icons.sort_by_alpha,
                  ),
                  label: Text("Sort by Name${_sortArrow('name')}"),
                  onPressed: () => _sortPersons('name'),
                ),
                ElevatedButton.icon(
                  icon: Icon(
                    sortBy == 'age'
                        ? (isAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                        : Icons.sort,
                  ),
                  label: Text("Sort by Age${_sortArrow('age')}"),
                  onPressed: () => _sortPersons('age'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: currentPagePersons.isEmpty
                  ? const Center(child: Text("No persons found."))
                  : ListView.builder(
                itemCount: currentPagePersons.length,
                itemBuilder: (_, index) {
                  final person = currentPagePersons[index];
                  return Card(
                    elevation: 3,
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      title: Text(person.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text("Age: ${person.age}\nEmail: ${person.email}"),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () =>
                                _showForm(person: person),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () =>
                                deletePerson(person),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 0
                        ? () => setState(() => currentPage--)
                        : null,
                  ),
                  Text(
                    'Page ${totalPages == 0 ? 0 : currentPage + 1} of $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (currentPage + 1) < totalPages
                        ? () => setState(() => currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

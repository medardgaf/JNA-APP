import 'package:flutter/material.dart';
import 'package:kliv_app/services/CategoryService.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = []; // Typé plus précisément
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // CORRECTION 1: Utiliser la méthode 'getAll()' définie dans votre service
      final categories = await CategoryService.getAll();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['nom'] ?? '');
    String selectedType = category?['type'] ?? 'recette';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(isEditing ? 'Modifier la catégorie' : 'Ajouter une catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'recette', child: Text('Recette')),
                DropdownMenuItem(value: 'depense', child: Text('Dépense')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedType = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _showSnackBar('Veuillez entrer un nom de catégorie',
                    isError: true);
                return;
              }

              Navigator.of(context).pop();

              try {
                Map<String, dynamic> result;
                if (isEditing) {
                  // CORRECTION 2: Utiliser les paramètres nommés pour 'update'
                  result = await CategoryService.update(
                    id: category['id'],
                    nom: name,
                    type: selectedType,
                  );
                } else {
                  // CORRECTION 3: Utiliser les paramètres nommés pour 'add'
                  result = await CategoryService.add(
                    nom: name,
                    type: selectedType,
                  );
                }

                // Vérifier la réponse du service
                if (result['success'] == true) {
                  _showSnackBar(result['message'] ?? 'Opération réussie');
                  _loadCategories();
                } else {
                  _showSnackBar(result['message'] ?? 'Une erreur est survenue',
                      isError: true);
                }
              } catch (e) {
                _showSnackBar('Erreur: ${e.toString()}', isError: true);
              }
            },
            child: Text(isEditing ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer la catégorie "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // La méthode 'delete' attend un argument positionnel 'id'
        final result = await CategoryService.delete(id);

        if (result['success'] == true) {
          _showSnackBar(result['message'] ?? 'Suppression réussie');
          _loadCategories();
        } else {
          _showSnackBar(result['message'] ?? 'Une erreur est survenue',
              isError: true);
        }
      } catch (e) {
        _showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des catégories...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune catégorie trouvée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCategoryDialog(),
              child: const Text('Ajouter une catégorie'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isIncome = category['type'] == 'recette';
          final cardColor =
              isIncome ? Colors.green.shade50 : Colors.red.shade50;
          final textColor =
              isIncome ? Colors.green.shade700 : Colors.red.shade700;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: textColor.withValues(alpha: 0.2)),
            ),
            color: cardColor,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                category['nom'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isIncome ? 'Recette' : 'Dépense',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue.shade700),
                    onPressed: () => _showCategoryDialog(category: category),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () =>
                        _deleteCategory(category['id'], category['nom']),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

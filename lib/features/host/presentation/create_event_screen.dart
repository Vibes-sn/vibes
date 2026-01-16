import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/state/user_provider.dart';
import 'package:vibes/core/theme/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();
  final _picker = ImagePicker();
  XFile? _image;
  DateTime? _eventDateTime;
  bool _publishing = true;
  bool _saving = false;
  String _selectedCategory = 'clubbing';

  static const List<_CategoryOption> _categories = [
    _CategoryOption(value: 'clubbing', label: '🕺 Clubbing'),
    _CategoryOption(value: 'concerts', label: '🎤 Concerts'),
    _CategoryOption(value: 'lounge', label: '🍸 Lounge'),
    _CategoryOption(value: 'expos', label: '🎨 Expos'),
  ];

  final List<_TicketTypeItem> _ticketTypes = [
    _TicketTypeItem(label: 'Standard', price: '10000'),
    _TicketTypeItem(label: 'VIP', price: '25000'),
    _TicketTypeItem(label: 'Table', price: '150000'),
  ];

  final List<String> _locationSuggestions = const [
    'Phare des Mamelles',
    'Almadies',
    'Sea Plaza',
    'Place du Souvenir',
    'Monument de la Renaissance',
  ];
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = _locationSuggestions;
    _locationController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationFocus.dispose();
    for (final item in _ticketTypes) {
      item.dispose();
    }
    super.dispose();
  }

  void _filterLocations() {
    final q = _locationController.text.trim().toLowerCase();
    setState(() {
      _filteredSuggestions = _locationSuggestions
          .where((e) => e.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _image = picked);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gradientStart,
            surface: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gradientStart,
            surface: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(
      () => _eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  num _minTicketPrice() {
    num minPrice = double.infinity;
    for (final item in _ticketTypes) {
      final price = num.tryParse(item.priceController.text.trim()) ?? 0;
      if (price > 0 && price < minPrice) {
        minPrice = price;
      }
    }
    return minPrice == double.infinity ? 0 : minPrice;
  }

  Future<String?> _uploadImage(String userId) async {
    if (_image == null) return null;
    final bytes = await _image!.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_image!.name}';
    final path = '$userId/$fileName';
    final bucket = Supabase.instance.client.storage.from('event_images');
    _log('upload start bucket=event_images path=$path');

    if (kIsWeb) {
      await bucket.uploadBinary(path, bytes);
    } else {
      final file = File(_image!.path);
      await bucket.upload(path, file);
    }
    _log('upload done path=$path');
    return bucket.getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (_saving) return;
    HapticFeedback.lightImpact();
    final userProvider = UserScope.of(context);
    if (!userProvider.isHost) {
      _showFeedback('Accès réservé aux organisateurs.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_eventDateTime == null) {
      _showFeedback('Choisis une date et une heure.', isError: true);
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showFeedback('Ajoute un lieu.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        _showFeedback('Connecte-toi pour créer un événement.', isError: true);
        return;
      }

      _log('create event start user=${user.id}');
      final imageUrl = await _uploadImage(user.id);
      final price = _minTicketPrice();

      await client.from('events').insert({
        'host_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_date': _eventDateTime!.toIso8601String(),
        'location_name': _locationController.text.trim(),
        'price': price,
        'category': _selectedCategory,
        'image_url': imageUrl,
        'is_published': _publishing,
      });

      _log('create event success');
      if (!mounted) return;
      _showFeedback('Événement créé avec succès.');
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      _log('create event postgrest error: ${e.message}');
      if (!mounted) return;
      _showFeedback('Erreur Supabase: ${e.message}', isError: true);
    } catch (e) {
      _log('create event error: $e');
      if (!mounted) return;
      _showFeedback('Impossible de créer l’événement.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [Colors.red.shade900, Colors.red.shade700]
                  : const [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _log(String message) {
    debugPrint('[CreateEvent] $message');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = UserScope.of(context);
    if (!userProvider.isHost) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Accès réservé aux organisateurs.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final dateText = _eventDateTime == null
        ? 'Choisir date & heure'
        : DateFormat("EEE d MMM • HH:mm", 'fr_FR').format(_eventDateTime!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Créer un événement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catégorie',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppColors.background,
                      iconEnabledColor: Colors.white70,
                      style: const TextStyle(color: Colors.white),
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.value,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedCategory = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle('Affiche'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: _image == null
                        ? const Center(
                            child: Text(
                              'Uploader une affiche',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _image!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.gradientStart,
                                          ),
                                        );
                                      }
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_image!.path),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle('Informations'),
                const SizedBox(height: 8),
                _TextField(
                  controller: _titleController,
                  label: 'Titre',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Titre requis'
                      : null,
                ),
                const SizedBox(height: 12),
                _TextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _TextField(
                  controller: _locationController,
                  label: 'Lieu (Google Maps)',
                  focusNode: _locationFocus,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lieu requis'
                      : null,
                ),
                if (_locationFocus.hasFocus && _filteredSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: _filteredSuggestions
                          .map(
                            (suggestion) => ListTile(
                              title: Text(
                                suggestion,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () {
                                _locationController.text = suggestion;
                                _locationFocus.unfocus();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                _DatePickerField(label: dateText, onTap: _pickDateTime),
                const SizedBox(height: 16),
                _SectionTitle('Types de tickets'),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (int i = 0; i < _ticketTypes.length; i++)
                      _TicketTypeRow(
                        item: _ticketTypes[i],
                        onRemove: _ticketTypes.length > 1
                            ? () => setState(() => _ticketTypes.removeAt(i))
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () {
                    setState(() {
                      _ticketTypes.add(
                        _TicketTypeItem(label: 'Nouveau', price: '0'),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un type'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _publishing,
                  onChanged: (value) => setState(() => _publishing = value),
                  title: const Text(
                    'Publier immédiatement',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tu peux publier plus tard depuis ton dashboard',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  activeColor: AppColors.gradientStart,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gradientStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Créer l’événement',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _TicketTypeItem {
  _TicketTypeItem({required String label, required String price})
    : labelController = TextEditingController(text: label),
      priceController = TextEditingController(text: price);

  final TextEditingController labelController;
  final TextEditingController priceController;

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}

class _CategoryOption {
  const _CategoryOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _TicketTypeRow extends StatelessWidget {
  const _TicketTypeRow({required this.item, this.onRemove});

  final _TicketTypeItem item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: item.labelController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: item.priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Prix'),
            ),
          ),
          const SizedBox(width: 8),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

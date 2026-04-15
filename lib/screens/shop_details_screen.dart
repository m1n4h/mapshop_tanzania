import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/services/location_service.dart';
import 'package:mapshop_tanzania/services/shop_service.dart';

class ShopDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopDetailsScreen({
    super.key,
    required this.shop,
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late double _latitude;
  late double _longitude;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.shop['description'] ?? '');
    _addressController = TextEditingController(text: widget.shop['address'] ?? '');
    _phoneController = TextEditingController(text: widget.shop['phoneNumber'] ?? '');
    _emailController = TextEditingController(text: widget.shop['email'] ?? '');
    _latitude = (widget.shop['latitude'] as num?)?.toDouble() ?? 0.0;
    _longitude = (widget.shop['longitude'] as num?)?.toDouble() ?? 0.0;
    _isOpen = widget.shop['isOpen'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Shop',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shop Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., My Shop',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe your shop',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Shop address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+255000000000',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'shop@example.com',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingLocation ? null : _fillLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(_isLoadingLocation ? 'Finding location...' : 'Update Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Location: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Shop Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: SwitchListTile(
                      value: _isOpen,
                      onChanged: (value) {
                        setState(() => _isOpen = value);
                      },
                      title: Text(_isOpen ? 'Open' : 'Closed'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fillLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await LocationService().getCurrentLocation();
    setState(() => _isLoadingLocation = false);

    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final shopId = widget.shop['id'];
    final parsedShopId = shopId is int ? shopId : int.parse(shopId.toString());
    final result = await ShopService.updateShop(
      shopId: parsedShopId,
      name: _nameController.text,
      description: _descriptionController.text,
      latitude: _latitude,
      longitude: _longitude,
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      isOpen: _isOpen,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (result['success']) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Shop updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update shop'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Shop'),
          content: const Text('Are you sure you want to delete this shop? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteShop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShop() async {
    setState(() => _isSubmitting = true);
    final shopId = widget.shop['id'];
    final parsedShopId = shopId is int ? shopId : int.parse(shopId.toString());
    final result = await ShopService.deleteShop(parsedShopId);
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (result['success']) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Shop deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete shop'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

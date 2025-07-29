import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../services/product_service.dart';

class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  bool isSaving = false;
  File? imageFile;
  final ImagePicker _imagePicker = ImagePicker();
  String? imageSrc;

  // Controllers cho form
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController paczkaController;
  late TextEditingController kartonController;
  late TextEditingController khoHangController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    priceController = TextEditingController();
    paczkaController = TextEditingController();
    kartonController = TextEditingController();
    khoHangController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    paczkaController.dispose();
    kartonController.dispose();
    khoHangController.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    // Validate required fields
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
      );
      return;
    }

    if (priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá sản phẩm')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final productData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'regular_price': priceController.text.trim(),
        'type': 'simple',
        'status': 'publish',
        'meta_data': [
          {'key': 'paczka', 'value': paczkaController.text.trim()},
          {'key': 'karton', 'value': kartonController.text.trim()},
          {'key': 'kho_hang', 'value': khoHangController.text.trim()},
          {'key': 'custom_price', 'value': priceController.text.trim()},
        ],
      };

      final success = await ProductService.createProduct(
        productData,
        imageFile,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo sản phẩm thành công!')),
          );
          context.go('/products');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Lỗi khi tạo sản phẩm')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        imageFile = File(pickedImage.path);
        imageSrc = pickedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
        title: const Text('Thêm sản phẩm mới'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Product Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Không thể tải ảnh',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload),
                            label: const Text('Tải ảnh lên'),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // Product Description
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả sản phẩm',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // Price
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá bán *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // PACZKA
              TextFormField(
                controller: paczkaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PACZKA',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // Karton
              TextFormField(
                controller: kartonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Karton',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // Kho hàng
              TextFormField(
                controller: khoHangController,
                decoration: const InputDecoration(
                  labelText: 'Kho hàng',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: isSaving ? null : _createProduct,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }
}

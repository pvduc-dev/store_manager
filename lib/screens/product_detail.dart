import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductDetail extends StatefulWidget {
  final String id;
  const ProductDetail({super.key, required this.id});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  Product? product;
  bool isLoading = true;
  bool isSaving = false;
  File? imageFile;
  final ImagePicker _imagePicker = ImagePicker();

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

    _loadProduct();
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

  Future<void> _loadProduct() async {
    try {
      final productId = int.tryParse(widget.id);
      if (productId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final loadedProduct = await ProductService.getProductDetail(productId);
      setState(() {
        product = loadedProduct;
        isLoading = false;
      });

      if (loadedProduct != null) {
        // Populate form fields
        nameController.text = loadedProduct.name;
        descriptionController.text = loadedProduct.description;
        priceController.text = loadedProduct.metaData.firstWhere((element) => element.key == 'custom_price').value;
        paczkaController.text = loadedProduct.paczka;
        kartonController.text = loadedProduct.karton;
        khoHangController.text = loadedProduct.khoHang;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _saveProduct() async {
    if (product == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      final updateData = {
        'name': nameController.text,
        'description': descriptionController.text,
        'meta_data': [
          {'key': 'paczka', 'value': paczkaController.text},
          {'key': 'karton', 'value': kartonController.text},
          {'key': 'kho_hang', 'value': khoHangController.text},
          {'key': 'custom_price', 'value': priceController.text},
        ],
      };

      final success = await ProductService.updateProduct(
        product!.id,
        updateData,
        imageFile,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Lưu thành công!')));
          // Reload product data
          await _loadProduct();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu dữ liệu')));
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
        title: const Text('Chỉnh sửa sản phẩm'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
          ? const Center(child: Text('Không tìm thấy sản phẩm'))
          : SingleChildScrollView(
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
                      child: product!.images.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                product!.images.first.src,
                                fit: BoxFit.cover,
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
                        labelText: 'Tên sản phẩm',
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
                        labelText: 'Giá bán',
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
              onPressed: isSaving ? null : _saveProduct,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}

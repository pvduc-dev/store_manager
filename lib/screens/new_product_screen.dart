import 'dart:io';

import 'package:flashy_flushbar/flashy_flushbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/product_provider.dart';
import '../models/category.dart';
import '../widgets/molecule/category_tree.dart';

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

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController paczkaController;
  late TextEditingController kartonController;
  late TextEditingController khoHangController;

  Category? selectedCategory;

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
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę podać nazwę produktu')),
      );
      return;
    }

    if (priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę podać cenę produktu')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    // Lấy reference tới ProductProvider trước khi navigate
    final productProvider = context.read<ProductProvider>();

    // Chạy tạo sản phẩm ở background trước
    _createProductInBackground(productProvider);

    // Set lại isSaving và chuyển về màn hình product list ngay lập tức
    setState(() {
      isSaving = false;
    });

    if (mounted) {
      context.go('/products');
    }
  }

  Future<void> _createProductInBackground(
    ProductProvider productProvider,
  ) async {
    print('🚀 Bắt đầu tạo sản phẩm background...');

    try {
      // Tạo temporary product với loading state
      final tempProductData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'regular_price': priceController.text.trim(),
        'price': priceController.text.trim(),
        'type': 'simple',
        'status': 'publish',
        'categories': selectedCategory != null
            ? [
                {'id': selectedCategory!.id},
              ]
            : [],
        'meta_data': [
          {'key': 'paczka', 'value': paczkaController.text.trim()},
          {'key': 'karton', 'value': kartonController.text.trim()},
          {'key': 'kho_hang', 'value': khoHangController.text.trim()},
          {'key': 'custom_price', 'value': priceController.text.trim()},
        ],
        'images': [],
      };

      print('📦 Tạo loading product...');
      // Thêm loading product vào danh sách sử dụng provider reference
      productProvider.addLoadingProduct(tempProductData);

      int? uploadedImageId;

             // Upload ảnh nếu có
       if (imageFile != null) {
         print('📸 Bắt đầu upload ảnh...');
         uploadedImageId = await ProductService.uploadImage(imageFile!);
         if (uploadedImageId == null) {
           // Upload ảnh thất bại -> show error và dừng
           print('❌ Upload ảnh thất bại, dừng tạo sản phẩm');
           productProvider.removeLoadingProduct();
           FlashyFlushbar(
             message: 'Nie udało się przesłać zdjęcia',
             duration: const Duration(seconds: 3),
             backgroundColor: Colors.red,
           ).show();
           return; // Dừng việc tạo sản phẩm
         }
         print('✅ Upload ảnh thành công, ID: $uploadedImageId');
       } else {
         print('📷 Không có ảnh để upload');
       }

       // Cập nhật productData với image ID (nếu có)
       final finalProductData = {
         ...tempProductData,
         'images': uploadedImageId != null
             ? [
                 {'id': uploadedImageId},
               ]
             : [],
       };

       print('🛍️ Bắt đầu tạo sản phẩm thực sự...');
       // Tạo sản phẩm thực sự sử dụng provider reference
       await productProvider.createProductFromLoading(finalProductData);
       print('✅ Tạo sản phẩm thành công!');
    } catch (e, stackTrace) {
      print('❌ Lỗi tạo sản phẩm: $e');
      print('📍 Stack trace: $stackTrace');

      // Xóa loading product sử dụng provider reference
      productProvider.removeLoadingProduct();

      FlashyFlushbar(
        message: 'Nie udało się utworzyć produktu',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ).show();

      print('⚠️ Lỗi đã được xử lý, loading product đã bị xóa');
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
        title: const Text('Dodaj nowy produkt'),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Đóng bàn phím khi chạm ra ngoài
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
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
                              fit: BoxFit.fill,
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
                                      'Nie można załadować zdjęcia',
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
                                label: const Text('Prześlij zdjęcie'),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa produktu *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Category Selector
                Text(
                  'Kategoria produktu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                CategorySelector(
                  selectedCategory: selectedCategory,
                  hintText: 'Wybierz kategorię produktu',
                  onCategorySelected: (category) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // TextFormField(
                //   controller: descriptionController,
                //   maxLines: 3,
                //   textInputAction: TextInputAction.newline,
                //   decoration: const InputDecoration(
                //     labelText: 'Mô tả sản phẩm',
                //     border: OutlineInputBorder(),
                //     isDense: true,
                //   ),
                // ),
                // const SizedBox(height: 24),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Cena sprzedaży *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: paczkaController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'PACZKA',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: kartonController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Karton',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: khoHangController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Magazyn',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
                  : const Text('Utwórz produkt'),
            ),
          ],
        ),
      ),
    );
  }
}

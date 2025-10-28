import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
    try {
      // Tạo temporary product với loading state
      final tempProductData = {
        'name': nameController.text.trim(),
        'price': priceController.text.trim(),
        'step': paczkaController.text.trim(),
        'warehouse': khoHangController.text.trim(),
        'carton': kartonController.text.trim(),
        'image': null,  // Sẽ được cập nhật sau khi tạo thành công
        'category': selectedCategory != null
            ? {
                'id': selectedCategory!.id,
                'name': selectedCategory!.name,
              }
            : null,
      };

      // Thêm loading product vào danh sách
      productProvider.addLoadingProduct(tempProductData);

      // Tạo sản phẩm thực sự sử dụng API v9
      await productProvider.createProductWithNewAPI(
        name: nameController.text.trim(),
        price: priceController.text.trim(),
        step: paczkaController.text.trim().isNotEmpty 
            ? paczkaController.text.trim() 
            : null,
        warehouse: khoHangController.text.trim().isNotEmpty 
            ? khoHangController.text.trim() 
            : null,
        carton: kartonController.text.trim().isNotEmpty 
            ? kartonController.text.trim() 
            : null,
        categoryId: selectedCategory?.id.toString(),
        imageFile: imageFile,
      );
    } catch (e) {
      // Xóa loading product sử dụng provider reference
      productProvider.removeLoadingProduct();
    }
  }

  // Tính toán quality dựa trên kích thước file
  int _calculateQuality(int fileSizeInBytes) {
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    
    if (fileSizeInMB < 1) {
      return 70; // File nhỏ, nén nhẹ
    } else if (fileSizeInMB < 2) {
      return 60;
    } else if (fileSizeInMB < 4) {
      return 50;
    } else if (fileSizeInMB < 6) {
      return 40;
    } else {
      return 30; // File lớn, nén mạnh nhất
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      // Lấy kích thước file gốc
      final fileSize = await file.length();
      final quality = _calculateQuality(fileSize);
      
      print('📊 Kích thước file gốc: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB');
      print('🎨 Chất lượng nén: $quality%');
      
      // Lấy thư mục temporary để lưu ảnh đã nén
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Nén ảnh với quality thích ứng
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final compressedSize = await File(compressedFile.path).length();
        final compressionRatio = ((fileSize - compressedSize) / fileSize * 100);
        print('📊 Kích thước sau nén: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)}MB');
        print('🎆 Tiết kiệm: ${compressionRatio.toStringAsFixed(1)}%');
      }

      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      print('Lỗi khi nén ảnh: $e');
      return file; // Trả về ảnh gốc nếu có lỗi
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      final originalFile = File(pickedImage.path);
      
      // Hiển thị loading indicator trong khi nén ảnh
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Nén ảnh
        final compressedFile = await _compressImage(originalFile);
        
        if (mounted) {
          Navigator.of(context).pop(); // Đóng loading dialog
          
          setState(() {
            imageFile = compressedFile;
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Đóng loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xử lý ảnh: $e')),
          );
        }
      }
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

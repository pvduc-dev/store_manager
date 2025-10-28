import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product.dart';
import '../models/category.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/molecule/category_tree.dart';

class ProductDetail extends StatefulWidget {
  final String id;
  const ProductDetail({super.key, required this.id});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool isSaving = false;
  Product? product;
  bool isLoading = false;
  File? imageFile;
  final ImagePicker _imagePicker = ImagePicker();
  String? imageSrc;

  // Controllers cho form
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController customPriceController;
  late TextEditingController paczkaController;
  late TextEditingController kartonController;
  late TextEditingController warehouseController;
  
  Category? selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    customPriceController = TextEditingController();
    paczkaController = TextEditingController();
    kartonController = TextEditingController();
    warehouseController = TextEditingController();
    
    // Ensure categories are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
    
    _loadProduct();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    customPriceController.dispose();
    paczkaController.dispose();
    kartonController.dispose();
    warehouseController.dispose();
    super.dispose();
  }

  void _loadProduct() {
    final productId = int.tryParse(widget.id);
    if (productId == null) return;

    final productProvider = context.read<ProductProvider>();
    final loadedProduct = productProvider.getProductById(productId);

    if (loadedProduct != null) {
      setState(() {
        product = loadedProduct;
      });

      // Populate form fields
      nameController.text = loadedProduct.name;
      descriptionController.text = '';  // Description không còn có trong model mới
      customPriceController.text = loadedProduct.price;
      paczkaController.text = loadedProduct.step;
      kartonController.text = loadedProduct.carton;
      warehouseController.text = loadedProduct.warehouse;
      
      // Load current category
      _loadCurrentCategory(loadedProduct);
    }
  }

  void _loadCurrentCategory(Product product) {
    // Sử dụng single category từ model mới
    if (product.category != null) {
      selectedCategory = Category(
        id: product.category!.id,
        name: product.category!.name,
        slug: '',
        parent: 0,
        description: '',
      );
    } else {
      selectedCategory = null;
    }
  }

  Future<void> _saveProduct() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę podać nazwę produktu')),
      );
      return;
    }

    if (customPriceController.text.trim().isEmpty) {
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

    // Chạy update sản phẩm ở background trước
    _updateProductInBackground(productProvider);

    // Set lại isSaving và chuyển về màn hình product list ngay lập tức
    setState(() {
      isSaving = false;
    });

    if (mounted) {
      context.go('/products');
    }
  }

  Future<void> _updateProductInBackground(
    ProductProvider productProvider,
  ) async {
    try {
      // Cập nhật sản phẩm thực sự sử dụng API v9
      await productProvider.updateProductWithNewAPI(
        productId: product!.id,
        name: nameController.text.trim(),
        price: customPriceController.text.trim(),
        step: paczkaController.text.trim().isNotEmpty 
            ? paczkaController.text.trim() 
            : null,
        warehouse: warehouseController.text.trim().isNotEmpty 
            ? warehouseController.text.trim() 
            : null,
        carton: kartonController.text.trim().isNotEmpty 
            ? kartonController.text.trim() 
            : null,
        categoryId: selectedCategory?.id.toString(),
        imageFile: imageFile,
      );
    } catch (e) {
      // Error handling if needed
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
            imageSrc = compressedFile?.path;
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
        title: const Text('Edytuj produkt'),
        centerTitle: true,
      ),
      body: product == null
          ? const Center(child: Text('Nie znaleziono produktu'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    // Đóng bàn phím khi chạm ra ngoài
                    FocusScope.of(context).unfocus();
                  },
                  child: Column(
                    children: [
                      // Product Image
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
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Nie można załadować zdjęcia',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                )
                              : (product!.image?.src != null
                                    ? CachedNetworkImage(
                                        imageUrl: product!.image!.src!,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                        errorWidget: (context, url, error) {
                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_outlined,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Nie można załadować zdjęcia',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: _pickImage,
                                            child: const Text('Prześlij zdjęcie'),
                                          ),
                                        ],
                                      )),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Product Name
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nazwa produktu',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Custom Price
                      TextFormField(
                        controller: customPriceController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Cena sprzedaży',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PACZKA
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

                      // Magazyn
                      TextFormField(
                        controller: warehouseController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Magazyn',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Karton
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
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSaving ? null : _saveProduct,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Zapisz zmiany',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

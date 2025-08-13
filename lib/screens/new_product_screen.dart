import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as product_category;

class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  bool isSaving = false;
  bool isUploading = false; // Thêm biến theo dõi trạng thái upload
  File? imageFile;
  final ImagePicker _imagePicker = ImagePicker();
  String? imageSrc;
  int? uploadedImageId;

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController paczkaController;
  late TextEditingController kartonController;
  late TextEditingController khoHangController;
  
  product_category.Category? selectedCategory; // Danh mục được chọn
  List<product_category.Category> selectedCategories = []; // Danh sách danh mục được chọn

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    priceController = TextEditingController();
    paczkaController = TextEditingController();
    kartonController = TextEditingController();
    khoHangController = TextEditingController();
    
    // Lấy danh sách danh mục khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categoryProvider = context.read<CategoryProvider>();
      
      // Chỉ load từ cache, không gọi API
      await categoryProvider.loadCategoriesFromCache();
      
    } catch (e) {
      // Lỗi khi load categories
    }
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

    // Kiểm tra xem có chọn ít nhất một danh mục không
    if (selectedCategory == null && selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một danh mục cho sản phẩm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      // Tạo danh sách categories từ cả selectedCategory (để tương thích ngược) và selectedCategories
      List<Map<String, dynamic>> categories = [];
      
      // Thêm selectedCategory nếu có (để tương thích ngược)
      if (selectedCategory != null) {
        categories.add({'id': selectedCategory!.id});
      }
      
      // Thêm tất cả selectedCategories
      for (var category in selectedCategories) {
        if (!categories.any((c) => c['id'] == category.id)) {
          categories.add({'id': category.id});
        }
      }

      final productData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'regular_price': priceController.text.trim(),
        'price': priceController.text.trim(),
        'type': 'simple',
        'status': 'publish',
        'categories': categories,
        'meta_data': [
          {'key': 'paczka', 'value': paczkaController.text.trim()},
          {'key': 'karton', 'value': kartonController.text.trim()},
          {'key': 'kho_hang', 'value': khoHangController.text.trim()},
          {'key': 'custom_price', 'value': priceController.text.trim()},
        ],
        'images': uploadedImageId != null
            ? [
                {'id': uploadedImageId},
              ]
            : [],
      };

      print('Creating product with categories: $categories');
      await context.read<ProductProvider>().addProduct(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo sản phẩm thành công!')),
        );
        context.go('/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi tạo sản phẩm')));
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
        isUploading = true; // Bắt đầu trạng thái upload
      });

      try {
        final imageId = await ProductService.uploadImage(imageFile!);
        if (imageId != null) {
          setState(() {
            uploadedImageId = imageId;
          });
        }
      } catch (e) {
        print('Lỗi upload ảnh: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Lỗi khi upload ảnh')));
        }
      } finally {
        setState(() {
          isUploading = false; // Kết thúc trạng thái upload
        });
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
        title: const Text('Thêm sản phẩm mới'),
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
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  imageFile!,
                                  fit: BoxFit.fill,
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
                                          'Không thể tải ảnh',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              // Hiển thị loading khi đang upload
                              if (isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Đang upload...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (uploadedImageId != null && !isUploading)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Đã upload',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
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
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Dropdown chọn danh mục sản phẩm (để tương thích ngược)
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    if (categoryProvider.categories.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Không có danh mục nào',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<product_category.Category>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Chọn danh mục chính',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.category),
                          ),
                          hint: const Text('Chọn danh mục chính'),
                          items: categoryProvider.categories.map((product_category.Category category) {
                            return DropdownMenuItem<product_category.Category>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (product_category.Category? newValue) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vui lòng chọn danh mục chính';
                            }
                            return null;
                          },
                        ),
                      ],
                    );
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
                    labelText: 'Giá bán *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
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
      ),
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: (isSaving || isUploading) ? null : _createProduct,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : isUploading
                  ? const Text('Đang upload...')
                  : const Text('Tạo sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }
}

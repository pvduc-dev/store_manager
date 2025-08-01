import 'dart:io';

import 'package:flutter/material.dart' hide MetaData;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/product_service.dart';

class ProductDetail extends StatefulWidget {
  final String id;
  const ProductDetail({super.key, required this.id});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool isSaving = false;
  bool isUploading = false; // Thêm biến theo dõi trạng thái upload
  Product? product;
  bool isLoading = false;
  File? imageFile;
  final ImagePicker _imagePicker = ImagePicker();
  String? imageSrc;
  int? uploadedImageId;

  // Controllers cho form
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController customPriceController;
  late TextEditingController paczkaController;
  late TextEditingController kartonController;
  late TextEditingController warehouseController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    customPriceController = TextEditingController();
    paczkaController = TextEditingController();
    kartonController = TextEditingController();
    warehouseController = TextEditingController();
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
      descriptionController.text = loadedProduct.description;
      customPriceController.text = loadedProduct.metaData
          .firstWhere(
            (meta) => meta.key == 'custom_price',
            orElse: () => MetaData(key: 'custom_price', value: ''),
          )
          .value;
      paczkaController.text = loadedProduct.metaData
          .firstWhere(
            (meta) => meta.key == 'paczka',
            orElse: () => MetaData(key: 'paczka', value: ''),
          )
          .value;
      kartonController.text = loadedProduct.metaData
          .firstWhere(
            (meta) => meta.key == 'karton',
            orElse: () => MetaData(key: 'karton', value: ''),
          )
          .value;
      warehouseController.text = loadedProduct.metaData
          .firstWhere(
            (meta) => meta.key == 'kho_hang',
            orElse: () => MetaData(key: 'kho_hang', value: ''),
          )
          .value;
    }
  }

  Future<void> _saveProduct() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
      );
      return;
    }

    if (customPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá sản phẩm')),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final productData = {
        'id': product!.id,
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'regular_price': customPriceController.text.trim(),
        'type': 'simple',
        'status': 'publish',
        'meta_data': [
          {'key': 'paczka', 'value': paczkaController.text.trim()},
          {'key': 'karton', 'value': kartonController.text.trim()},
          {'key': 'kho_hang', 'value': warehouseController.text.trim()},
          {'key': 'custom_price', 'value': customPriceController.text.trim()},
        ],
        'images': uploadedImageId != null
            ? [
                {'id': uploadedImageId},
              ]
            : product!.images.map((e) => {'id': e.id}).toList(),
      };

      await context.read<ProductProvider>().updateProduct(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sản phẩm thành công!')),
        );
        context.go('/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi cập nhật sản phẩm')),
        );
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
        title: const Text('Chỉnh sửa sản phẩm'),
        centerTitle: true,
      ),
      body: product == null
          ? const Center(child: Text('Không tìm thấy sản phẩm'))
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
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        imageFile!,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                              : (product!.images.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: product!.images.first.src!,
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
                                                'Không thể tải ảnh',
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
                                            child: const Text('Tải ảnh lên'),
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
                          labelText: 'Tên sản phẩm',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Product Description
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

                      // Custom Price
                      TextFormField(
                        controller: customPriceController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.done,
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
                        textInputAction: TextInputAction.done,
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
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Karton',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kho hang
                      TextFormField(
                        controller: warehouseController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Kho hang',
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
              onPressed: (isSaving || isUploading) ? null : _saveProduct,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : isUploading
                  ? const Text('Đang upload...')
                  : const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}

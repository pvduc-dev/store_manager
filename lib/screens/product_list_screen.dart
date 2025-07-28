import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Dữ liệu mẫu cho sản phẩm
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'maskotka',
      'id': '250723094732',
      'price': '1 zł',
      'stock': '0(0pcs)',
      'quantity': 1,
      'image': 'https://via.placeholder.com/150/8B5CF6/FFFFFF?text=Gengar',
      'hasBanner': false,
      'hasFABs': false,
    },
    {
      'name': 'so 03',
      'id': '123',
      'price': '121 zł',
      'stock': '0(0pcs)',
      'quantity': 1,
      'image': 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=Group',
      'hasBanner': false,
      'hasFABs': false,
    },
    {
      'name': 'labubu',
      'id': '250722191336',
      'price': '12 zł',
      'stock': '0(0pcs)',
      'quantity': 1,
      'image': 'https://via.placeholder.com/150/8B5CF6/FFFFFF?text=Labubu',
      'hasBanner': false,
      'hasFABs': false,
    },
    {
      'name': 'labubu',
      'id': '250719114552',
      'price': '12 zł',
      'stock': '0(0pcs)',
      'quantity': 1,
      'image': 'https://via.placeholder.com/150/10B981/FFFFFF?text=Box',
      'hasBanner': true,
      'hasFABs': false,
    },
    {
      'name': 'breloczki',
      'id': '250719114003',
      'price': '12 zł',
      'stock': '-4(-4pcs)',
      'quantity': 1,
      'image': 'https://via.placeholder.com/150/F59E0B/FFFFFF?text=Keychains',
      'hasBanner': false,
      'hasFABs': true,
    },
    {
      'name': 'breloczki',
      'id': '250719102012',
      'price': '12 zł',
      'stock': '0(0pcs)',
      'quantity': 1,
      'image': 'https://via.placeholder.com/150/F59E0B/FFFFFF?text=More',
      'hasBanner': false,
      'hasFABs': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header với thanh tìm kiếm
            _buildHeader(),

            // Thanh lọc và sắp xếp
            // _buildFilterBar(),

            // Danh sách sản phẩm
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm các sản phẩm',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              FilledButton(
                onPressed: () {},
                child: Text('Tìm kiếm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Sắp xếp
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text('Sắp xếp mặc định', style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),

          Spacer(),

          // Bộ lọc
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16),
                SizedBox(width: 4),
                Text('Bộ lọc', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),

          SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_products[index]);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        context.push('/products/${product['id']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner (nếu có)
            if (product['hasBanner'])
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Chuyên sỉ và lẻ sẵn hàng tại chợ sapa... Xem thêm',
                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Hình ảnh sản phẩm
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(product['hasBanner'] ? 0 : 12),
                      topRight: Radius.circular(product['hasBanner'] ? 0 : 12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(product['hasBanner'] ? 0 : 12),
                      topRight: Radius.circular(product['hasBanner'] ? 0 : 12),
                    ),
                    child: Image.network(
                      product['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Thông tin sản phẩm
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    product['id'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product['price'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        product['stock'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '[x${product['quantity']}]',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

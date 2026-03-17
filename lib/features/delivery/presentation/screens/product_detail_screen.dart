import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CategoriesRepository _repository = CategoriesRepository(
    categoriesDataProvider: CategoriesDataProvider(apiService: ApiService.instance),
  );

  CategoriesProductsModel? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await _repository.getProductById(widget.productId);
      setState(() {
        _product = product;
        _loading = false;
        if (product == null) _error = 'Product not found';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _product?.name ?? 'Product',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadProduct,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _product == null
                  ? const Center(child: Text('Product not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_product!.image_path != null && _product!.image_path!.isNotEmpty)
                            ClipRRect(
                              child: Image.network(
                                _product!.image_path!,
                                height: 280,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 280,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 280,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.shopping_bag,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product!.name ?? 'Product',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'ETB ${_product!.formatted_price ?? _product!.price ?? '0'}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    if (_product!.is_on_discount == true &&
                                        _product!.formatted_original_price != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        _product!.formatted_original_price!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_product!.description != null && _product!.description!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _product!.description!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      // TODO: Add to cart
                                    },
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Add to cart'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
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
}

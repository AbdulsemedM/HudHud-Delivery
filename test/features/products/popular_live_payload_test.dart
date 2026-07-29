import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/products/model/popular_product_model.dart';

void main() {
  test('parses live auth popular products payload shape', () {
    final body = jsonDecode(_authSample) as Map<String, dynamic>;
    final products =
        PopularProductsResult.fromResponseData(body).products;
    expect(products, isNotEmpty);
    expect(products.first.product.name, 'New me Pizza');
    expect(products.first.shopName, 'New me shop');
  });

  test('parses live public popular products with vendor fallback', () {
    final body = jsonDecode(_publicSample) as Map<String, dynamic>;
    final products =
        PopularProductsResult.fromResponseData(body).products;
    expect(products, isNotEmpty);
    expect(products.first.product.name, 'New me Pizza');
    expect(products.first.shopName, 'New Me Billy');
    expect(products.first.shopId, 57);
  });

  test('parses when response.data is already the list (dio unwrap)', () {
    final body = jsonDecode(_authSample) as Map<String, dynamic>;
    final list = body['data'];
    final products =
        PopularProductsResult.fromResponseData(list).products;
    expect(products, isNotEmpty);
  });
}

const _authSample = r'''
{"success":true,"data":[{"id":2,"vendor_id":57,"category_id":1,"name":"New me Pizza","description":"description","price":"1050.00","discount_price":null,"cost_price":null,"quantity":20,"sku":"9898","barcode":"89392909","image_path":"https://api.hudhuddelivery.com/storage/66/conversions/pizza-medium.jpg","gallery_images":[],"ingredients":[],"allergens":null,"nutrition_facts":null,"preparation_time":30,"is_featured":true,"is_available":true,"status":"active","options":[null],"addons":null,"min_selection":0,"max_selection":2,"created_at":"2026-07-22T10:19:55.000000Z","updated_at":"2026-07-22T10:19:55.000000Z","total_orders":5,"total_quantity_sold":"5","total_revenue":"5250.00","popularity_score":100,"formatted_total_revenue":"5,250.00","vendor_shop":{"id":4,"user_id":57,"shop_name":"New me shop","delivery_fee":"5.00","average_rating":0,"logo_path":"https://api.hudhuddelivery.com/storage/63/conversions/1-medium.jpg","logo_urls":{"medium":"https://api.hudhuddelivery.com/storage/63/conversions/1-medium.jpg"}},"current_price":"1050.00","is_on_discount":false,"discount_percentage":null,"formatted_price":"1,050.00","formatted_original_price":null}],"meta":{"period":"month"}}
''';

const _publicSample = r'''
{"success":true,"data":[{"id":2,"vendor_id":57,"category_id":1,"name":"New me Pizza","description":"description","price":"1050.00","discount_price":null,"cost_price":null,"quantity":20,"sku":"9898","barcode":"89392909","image_path":"https://api.hudhuddelivery.com/storage/66/conversions/pizza-medium.jpg","gallery_images":[],"ingredients":[],"allergens":null,"nutrition_facts":null,"preparation_time":30,"is_featured":true,"is_available":true,"status":"active","options":[null],"addons":null,"min_selection":0,"max_selection":2,"created_at":"2026-07-22T10:19:55.000000Z","updated_at":"2026-07-22T10:19:55.000000Z","total_orders":5,"current_price":"1050.00","is_on_discount":false,"discount_percentage":null,"formatted_price":"1,050.00","formatted_original_price":null,"vendor":{"id":57,"name":"New Me Billy","average_rating":0}}],"period":"month"}
''';

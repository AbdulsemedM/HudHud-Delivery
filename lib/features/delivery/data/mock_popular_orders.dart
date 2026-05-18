/// Mock item for Popular Orders section (restaurant/vendor card).
class MockPopularOrder {
  final String name;
  final double rating;
  final int deliveryFee;
  final String deliveryTime;
  final String? promoText;
  final String imageUrl;
  final int? vendorId;

  const MockPopularOrder({
    required this.name,
    required this.rating,
    required this.deliveryFee,
    required this.deliveryTime,
    this.promoText,
    required this.imageUrl,
    this.vendorId,
  });
}

/// Mock data for Popular Orders - used on Delivery feed and All Categories screens.
/// vendorId is the vendor shop `id` from /api/vendors (e.g. 1, 2, 3).
final List<MockPopularOrder> mockPopularOrders = [
  const MockPopularOrder(
    name: 'Adenine Kitchen',
    rating: 4.4,
    deliveryFee: 120,
    deliveryTime: '10-25 min',
    promoText: '5 orders until ETB 800 reward',
    imageUrl: 'assets/images/categories.jpg',
    vendorId: 1,
  ),
  const MockPopularOrder(
    name: 'Cardinal Chips',
    rating: 4.3,
    deliveryFee: 120,
    deliveryTime: '10-25 min',
    imageUrl: 'assets/images/categories.jpg',
    vendorId: 2,
  ),
  const MockPopularOrder(
    name: 'Urban Bites',
    rating: 4.6,
    deliveryFee: 80,
    deliveryTime: '15-30 min',
    promoText: 'Free delivery on orders over ETB 500',
    imageUrl: 'assets/images/categories.jpg',
    vendorId: 3,
  ),
  const MockPopularOrder(
    name: 'Green Bowl',
    rating: 4.5,
    deliveryFee: 100,
    deliveryTime: '20-35 min',
    imageUrl: 'assets/images/categories.jpg',
    vendorId: 1,
  ),
  const MockPopularOrder(
    name: 'Sunset Grill',
    rating: 4.2,
    deliveryFee: 150,
    deliveryTime: '25-40 min',
    promoText: '20% off first order',
    imageUrl: 'assets/images/categories.jpg',
    vendorId: 2,
  ),
];

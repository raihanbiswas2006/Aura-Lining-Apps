import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/review.dart';

abstract class IProductRepository {
  Future<List<Category>> getCategories();
  Future<Category?> getCategoryById(String id);
  Future<List<Product>> getProducts({
    String? categoryId,
    String? tag,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    List<String>? colors,
    bool? inStockOnly,
    String? sortBy, // "featured", "price_asc", "price_desc", "newest", "rating"
  });
  Future<Product?> getProductById(String id);
  Future<List<String>> getSuggestedSearchTerms(String query);
  Future<List<Review>> getProductReviews(String productId);
  Future<void> addReview(Review review);
}

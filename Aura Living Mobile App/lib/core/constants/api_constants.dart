/// Central Backend API Constants
/// Shared across Website, Mobile App, and Admin App
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://aura-minimalist-e-commerce.vercel.app',
  );

  static String get productsEndpoint => '$baseUrl/api/products';
  static String get categoriesEndpoint => '$baseUrl/api/categories';
  static String get ordersEndpoint => '$baseUrl/api/orders';
  static String get healthEndpoint => '$baseUrl/api/health';
}

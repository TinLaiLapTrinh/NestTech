class ApiConfig {
  static const String baseUrl = "http://192.168.73.13:8000";

  // Auth
  static const String tokenEndpoint = "/o/token/";

  // Product
  static const String productList = "/products/";
  static const String categoryList = "/category/";
  static const String myProductList = "/products/my-product/";
  static String productDetail(int id) => "/products/$id/";
  static String productDelete(int id) => "/products/$id/";
  static String categorySelect(int id) => "/category/$id/";
  static String productOptionSetup(int id) => "/products/$id/option-setup/";
  static String productVariants(int id) => "/product/$id/variant/";
  static String productVariantUpdate(int id, int variantId) => "/product/$id/variant/$variantId/";
  static String addProductVariant(int id)=>"/products/$id/generate-variant/";
  static String productVariantDetai(int id, int variantId) => "/product/$id/variant/$variantId/";
  static String options(int id)=>"/products/$id/get-options/";
  static const String saveFcmToken="/save-fcm-token/";
  static String getRate(int id)=>"/products/$id/rates/";
  static const String productsDeleted ="/products/deleted/";
  
  // Location
  static String getProvinces = "/locations/province/";
  static String getDistrict(String id) => "/locations/$id/district/";
  static String getWards(String id) => "/locations/district/$id/ward";
  static String getLocation = "/user-location";
  static String addUserLocation="/user-location/";
  static String getShippingRoute = "/shipping-route/find-by-regions/";

  // User
  static const String profileUser = "/users/current-user/";
  static String customerRegister = "/users/customer-register/";
  static String supplierRegister = "/users/supplier-register/";
  static String followers = "/follow/followers/";
  static String followings = "/follow/followings/";
  static String unFollow(int id) => "/follow/$id/unfollow/";
  static String isFollowing(int id) => "/follow/$id/is-following/";

  // order
  static String addOrder = "/order/";
  static String getOrder = "/order/";
  static String detailOrder(int id) => "/order/$id/";
  static String deleteOrderDetailItem(int id, int idItem) => "/order/$id/delete-order-detail/$idItem/";
  static String orderDetail = "/order-detail/";
  static String orderDetailUpdate(int id) =>"/order-detail/$id/";
  static String confirmOrderDetail(int id)=>"/order-detail/$id/delivered/";
  static String ratingProduct(int id)=>"/order-detail/$id/rate-product/";

  // cart
  static String shoppingCart = "/shoppingcart/";
  static String shoppingCartAddItems = "/shoppingcart/add-item/";
  static String shoppingCartDeteteItem(int idItem)=>"/shoppingcart/delete-item/$idItem/";
  static String shoppingCartItems = "/shoppingcart/items/";
  static String shoppingCartUpdateItem(int idItem) => "/shoppingcart/update-item/$idItem/"; 



}

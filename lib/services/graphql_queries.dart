class GraphQLQueries {
  // Product Queries
  static const String getProducts = '''
    query GetProducts(\$search: String, \$category: String, \$minPrice: Float, \$maxPrice: Float) {
      products(search: \$search, category: \$category, minPrice: \$minPrice, maxPrice: \$maxPrice) {
        id
        name
        description
        price
        discountPrice
        finalPrice
        stock
        unit
        images {
          id
          image
          isMain
        }
        shop {
          id
          name
          latitude
          longitude
          address
          rating
          isOpen
          deliveryFee
        }
        category {
          id
          name
        }
        rating
        ordersCount
      }
    }
  ''';

  // Shop Queries
  static const String getNearbyShops = '''
    query GetNearbyShops(\$lat: Float!, \$lng: Float!, \$radius: Float) {
      nearbyShops(lat: \$lat, lng: \$lng, radius: \$radius) {
        id
        name
        description
        address
        latitude
        longitude
        rating
        isOpen
        deliveryFee
        distance
        logo
      }
    }
  ''';

  // Order Queries
  static const String getMyOrders = '''
    query GetMyOrders {
      myOrders {
        id
        orderId
        status
        total
        subtotal
        deliveryFee
        createdAt
        shop {
          id
          name
        }
        items {
          id
          quantity
          price
          total
          product {
            id
            name
          }
        }
      }
    }
  ''';

  static const String getSellerOrders = '''
    query GetSellerOrders {
      orders {
        id
        orderId
        status
        total
        createdAt
        buyer {
          id
          email
          username
          phoneNumber
        }
        items {
          id
          quantity
          price
          total
          product {
            id
            name
          }
        }
      }
    }
  ''';

  // Dashboard Stats
  static const String getDashboardStats = '''
    query GetDashboardStats {
      dashboardStats
    }
  ''';

  // Seller Products
  static const String getSellerProducts = '''
    query GetSellerProducts {
      products {
        id
        name
        price
        stock
        unit
        ordersCount
        viewsCount
        rating
      }
    }
  ''';

  // Delivery Queries
  static const String getMyDeliveries = '''
    query GetMyDeliveries {
      myDeliveries {
        id
        deliveryId
        status
        distanceKm
        deliveryFee
        pickupAddress
        deliveryAddress
        order {
          orderId
          total
        }
      }
    }
  ''';
}

class GraphQLMutations {
  // Product Mutations
  static const String createProduct = '''
    mutation CreateProduct(\$shopId: Int!, \$categoryId: Int!, \$name: String!, \$description: String!, \$price: Float!, \$stock: Int!, \$unit: String!) {
      createProduct(shopId: \$shopId, categoryId: \$categoryId, name: \$name, description: \$description, price: \$price, stock: \$stock, unit: \$unit) {
        success
        message
        product {
          id
          name
          price
          stock
        }
      }
    }
  ''';

  static const String updateProduct = '''
    mutation UpdateProduct(\$productId: Int!, \$name: String, \$price: Float, \$stock: Int, \$description: String) {
      updateProduct(productId: \$productId, name: \$name, price: \$price, stock: \$stock, description: \$description) {
        success
        message
        product {
          id
          name
          price
          stock
        }
      }
    }
  ''';

  static const String deleteProduct = '''
    mutation DeleteProduct(\$productId: Int!) {
      deleteProduct(productId: \$productId) {
        success
        message
      }
    }
  ''';

  // Order Mutations
  static const String createOrder = '''
    mutation CreateOrder(\$shopId: Int!, \$items: JSONString!, \$deliveryAddress: String!, \$latitude: Float!, \$longitude: Float!, \$paymentMethod: String!) {
      createOrder(shopId: \$shopId, items: \$items, deliveryAddress: \$deliveryAddress, latitude: \$latitude, longitude: \$longitude, paymentMethod: \$paymentMethod) {
        success
        message
        order {
          id
          orderId
          status
          total
        }
      }
    }
  ''';

  static const String updateOrderStatus = '''
    mutation UpdateOrderStatus(\$orderId: String!, \$status: String!) {
      updateOrderStatus(orderId: \$orderId, status: \$status) {
        success
        message
        order {
          id
          orderId
          status
        }
      }
    }
  ''';

  static const String assignRider = '''
    mutation AssignRider(\$orderId: String!, \$riderId: Int!) {
      assignRider(orderId: \$orderId, riderId: \$riderId) {
        success
        message
        order {
          id
          orderId
          status
          rider {
            id
            email
            username
          }
        }
      }
    }
  ''';

  // Shop Mutations
  static const String updateShopLocation = '''
    mutation UpdateShopLocation(\$shopId: Int!, \$latitude: Float!, \$longitude: Float!, \$address: String!) {
      updateShopLocation(shopId: \$shopId, latitude: \$latitude, longitude: \$longitude, address: \$address) {
        success
        message
        shop {
          id
          name
          latitude
          longitude
          address
        }
      }
    }
  ''';

  // Delivery Mutations
  static const String updateDeliveryStatus = '''
    mutation UpdateDeliveryStatus(\$deliveryId: String!, \$status: String!, \$location: JSONString) {
      updateDeliveryStatus(deliveryId: \$deliveryId, status: \$status, location: \$location) {
        success
        message
        delivery {
          id
          deliveryId
          status
        }
      }
    }
  ''';
}
import graphene
from graphene_django import DjangoObjectType
from django.contrib.auth import get_user_model
from apps.accounts.models import User, UserSession
from apps.shops.models import Shop, ShopHours
from apps.products.models import Category, Product, ProductImage
from apps.orders.models import Order, OrderItem, OrderTracking
from apps.deliveries.models import Delivery, DeliveryTracking
from apps.notifications.models import Notification, UserDevice

UserModel = get_user_model()

# ==================== Accounts Types ====================
class UserType(DjangoObjectType):
    class Meta:
        model = UserModel
        fields = ('id', 'email', 'username', 'phone_number', 'user_type', 
                 'profile_picture', 'latitude', 'longitude', 'address', 
                 'is_verified', 'date_joined', 'last_login')

class UserSessionType(DjangoObjectType):
    class Meta:
        model = UserSession
        fields = '__all__'

# ==================== Shop Types ====================
class ShopHoursType(DjangoObjectType):
    day_name = graphene.String()
    
    class Meta:
        model = ShopHours
        fields = '__all__'
    
    def resolve_day_name(self, info):
        days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        return days[self.day] if 0 <= self.day < 7 else 'Unknown'

class ShopType(DjangoObjectType):
    distance = graphene.Float()
    hours = graphene.List(ShopHoursType)
    
    class Meta:
        model = Shop
        fields = '__all__'
    
    def resolve_hours(self, info):
        return self.hours.all()

# ==================== Product Types ====================
class CategoryType(DjangoObjectType):
    class Meta:
        model = Category
        fields = '__all__'

class ProductImageType(DjangoObjectType):
    class Meta:
        model = ProductImage
        fields = '__all__'

class ProductType(DjangoObjectType):
    final_price = graphene.Float()
    category_name = graphene.String()
    shop_name = graphene.String()
    
    class Meta:
        model = Product
        fields = '__all__'
    
    def resolve_final_price(self, info):
        return float(self.discount_price) if self.discount_price else float(self.price)
    
    def resolve_category_name(self, info):
        return self.category.name
    
    def resolve_shop_name(self, info):
        return self.shop.name

# ==================== Order Types ====================
class OrderItemType(DjangoObjectType):
    product_name = graphene.String()
    product_price = graphene.Float()
    
    class Meta:
        model = OrderItem
        fields = '__all__'
    
    def resolve_product_name(self, info):
        return self.product.name
    
    def resolve_product_price(self, info):
        return float(self.product.price)

class OrderTrackingType(DjangoObjectType):
    class Meta:
        model = OrderTracking
        fields = '__all__'

class OrderType(DjangoObjectType):
    buyer_name = graphene.String()
    shop_name = graphene.String()
    rider_name = graphene.String()
    items = graphene.List(OrderItemType)
    tracking_history = graphene.List(OrderTrackingType)
    
    class Meta:
        model = Order
        fields = '__all__'
    
    def resolve_buyer_name(self, info):
        return self.buyer.email
    
    def resolve_shop_name(self, info):
        return self.shop.name
    
    def resolve_rider_name(self, info):
        return self.rider.email if self.rider else None
    
    def resolve_items(self, info):
        return self.items.all()
    
    def resolve_tracking_history(self, info):
        return self.tracking.all()

# ==================== Delivery Types ====================
class DeliveryTrackingType(DjangoObjectType):
    class Meta:
        model = DeliveryTracking
        fields = '__all__'

class DeliveryType(DjangoObjectType):
    order_id = graphene.String()
    rider_name = graphene.String()
    tracking_history = graphene.List(DeliveryTrackingType)
    
    class Meta:
        model = Delivery
        fields = '__all__'
    
    def resolve_order_id(self, info):
        return self.order.order_id
    
    def resolve_rider_name(self, info):
        return self.rider.email if self.rider else None
    
    def resolve_tracking_history(self, info):
        return self.tracking.all()

# ==================== Notification Types ====================
class NotificationType(DjangoObjectType):
    class Meta:
        model = Notification
        fields = '__all__'

class UserDeviceType(DjangoObjectType):
    class Meta:
        model = UserDevice
        fields = '__all__'

import graphene
from graphene_django import DjangoObjectType
from django.contrib.auth import get_user_model
from django.db.models import Q
from graphql_jwt.decorators import login_required, permission_required
from .types import *
from apps.shops.models import Shop
from apps.products.models import Product
from apps.orders.models import Order
from apps.notifications.models import Notification

UserModel = get_user_model()

class Query(graphene.ObjectType):
    # ==================== User Queries ====================
    me = graphene.Field(UserType)
    users = graphene.List(UserType, search=graphene.String())
    user = graphene.Field(UserType, id=graphene.Int(required=True))
    
    # ==================== Shop Queries ====================
    shops = graphene.List(ShopType, 
                         lat=graphene.Float(), 
                         lng=graphene.Float(), 
                         radius=graphene.Float(),
                         search=graphene.String())
    shop = graphene.Field(ShopType, id=graphene.Int(required=True))
    nearby_shops = graphene.List(ShopType, 
                                lat=graphene.Float(required=True), 
                                lng=graphene.Float(required=True), 
                                radius=graphene.Float(default_value=5))
    
    # ==================== Product Queries ====================
    products = graphene.List(ProductType,
                            category=graphene.String(),
                            shop_id=graphene.Int(),
                            search=graphene.String(),
                            min_price=graphene.Float(),
                            max_price=graphene.Float())
    product = graphene.Field(ProductType, id=graphene.Int(required=True))
    categories = graphene.List(CategoryType)
    
    # ==================== Order Queries ====================
    orders = graphene.List(OrderType, status=graphene.String())
    order = graphene.Field(OrderType, order_id=graphene.String(required=True))
    my_orders = graphene.List(OrderType)
    
    # ==================== Delivery Queries ====================
    deliveries = graphene.List(DeliveryType, status=graphene.String())
    delivery = graphene.Field(DeliveryType, delivery_id=graphene.String(required=True))
    my_deliveries = graphene.List(DeliveryType)
    
    # ==================== Notification Queries ====================
    notifications = graphene.List(NotificationType, unread_only=graphene.Boolean())
    unread_notifications_count = graphene.Int()
    
    # ==================== Dashboard Stats ====================
    dashboard_stats = graphene.JSONString()
    
    # ==================== Resolvers ====================
    def resolve_me(self, info):
        user = info.context.user
        if user.is_anonymous:
            return None
        return user
    
    @login_required
    def resolve_users(self, info, search=None):
        queryset = UserModel.objects.all()
        if search:
            queryset = queryset.filter(
                Q(email__icontains=search) | 
                Q(username__icontains=search) |
                Q(phone_number__icontains=search)
            )
        return queryset
    
    def resolve_user(self, info, id):
        try:
            return UserModel.objects.get(id=id)
        except UserModel.DoesNotExist:
            return None
    
    def resolve_shops(self, info, lat=None, lng=None, radius=None, search=None):
        queryset = Shop.objects.filter(status='ACTIVE')
        
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | 
                Q(address__icontains=search)
            )
        
        # Calculate distance if coordinates provided
        if lat and lng:
            import math
            for shop in queryset:
                distance = self.calculate_distance(lat, lng, shop.latitude, shop.longitude)
                shop.distance = distance
            
            if radius:
                queryset = [shop for shop in queryset if shop.distance <= radius]
                queryset = sorted(queryset, key=lambda x: x.distance)
        
        return queryset
    
    def resolve_shop(self, info, id):
        try:
            return Shop.objects.get(id=id)
        except Shop.DoesNotExist:
            return None
    
    def resolve_nearby_shops(self, info, lat, lng, radius=5):
        shops = Shop.objects.filter(status='ACTIVE')
        import math
        nearby = []
        for shop in shops:
            distance = self.calculate_distance(lat, lng, shop.latitude, shop.longitude)
            if distance <= radius:
                shop.distance = distance
                nearby.append(shop)
        return sorted(nearby, key=lambda x: x.distance)
    
    def resolve_products(self, info, category=None, shop_id=None, search=None, min_price=None, max_price=None):
        queryset = Product.objects.filter(is_active=True)
        
        if category:
            queryset = queryset.filter(category__slug=category)
        if shop_id:
            queryset = queryset.filter(shop_id=shop_id)
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | 
                Q(description__icontains=search)
            )
        if min_price:
            queryset = queryset.filter(price__gte=min_price)
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
        
        return queryset
    
    def resolve_product(self, info, id):
        try:
            return Product.objects.get(id=id)
        except Product.DoesNotExist:
            return None
    
    def resolve_categories(self, info):
        return Category.objects.all()
    
    @login_required
    def resolve_orders(self, info, status=None):
        user = info.context.user
        if user.user_type == 'ADMIN':
            queryset = Order.objects.all()
        elif user.user_type == 'BUYER':
            queryset = Order.objects.filter(buyer=user)
        elif user.user_type == 'SELLER':
            queryset = Order.objects.filter(shop__seller=user)
        elif user.user_type == 'RIDER':
            queryset = Order.objects.filter(rider=user)
        else:
            queryset = Order.objects.none()
        
        if status:
            queryset = queryset.filter(status=status)
        
        return queryset
    
    def resolve_order(self, info, order_id):
        try:
            return Order.objects.get(order_id=order_id)
        except Order.DoesNotExist:
            return None
    
    @login_required
    def resolve_my_orders(self, info):
        return Order.objects.filter(buyer=info.context.user)
    
    @login_required
    def resolve_deliveries(self, info, status=None):
        user = info.context.user
        if user.user_type == 'ADMIN':
            queryset = Delivery.objects.all()
        elif user.user_type == 'RIDER':
            queryset = Delivery.objects.filter(rider=user)
        else:
            queryset = Delivery.objects.filter(order__buyer=user)
        
        if status:
            queryset = queryset.filter(status=status)
        
        return queryset
    
    def resolve_delivery(self, info, delivery_id):
        try:
            return Delivery.objects.get(delivery_id=delivery_id)
        except Delivery.DoesNotExist:
            return None
    
    @login_required
    def resolve_my_deliveries(self, info):
        return Delivery.objects.filter(rider=info.context.user)
    
    @login_required
    def resolve_notifications(self, info, unread_only=None):
        queryset = Notification.objects.filter(user=info.context.user)
        if unread_only:
            queryset = queryset.filter(is_read=False)
        return queryset
    
    @login_required
    def resolve_unread_notifications_count(self, info):
        return Notification.objects.filter(user=info.context.user, is_read=False).count()
    
    @login_required
    def resolve_dashboard_stats(self, info):
        user = info.context.user
        stats = {}
        
        if user.user_type == 'ADMIN':
            stats = {
                'total_users': UserModel.objects.count(),
                'total_shops': Shop.objects.count(),
                'total_products': Product.objects.count(),
                'total_orders': Order.objects.count(),
                'pending_orders': Order.objects.filter(status='PENDING').count(),
                'total_revenue': float(Order.objects.filter(status='DELIVERED').aggregate(total=models.Sum('total'))['total'] or 0),
            }
        elif user.user_type == 'SELLER':
            stats = {
                'total_products': Product.objects.filter(shop__seller=user).count(),
                'total_orders': Order.objects.filter(shop__seller=user).count(),
                'pending_orders': Order.objects.filter(shop__seller=user, status='PENDING').count(),
                'total_revenue': float(Order.objects.filter(shop__seller=user, status='DELIVERED').aggregate(total=models.Sum('total'))['total'] or 0),
                'shop_rating': user.shops.first().rating if user.shops.exists() else 0,
            }
        elif user.user_type == 'RIDER':
            stats = {
                'total_deliveries': Delivery.objects.filter(rider=user).count(),
                'completed_deliveries': Delivery.objects.filter(rider=user, status='DELIVERED').count(),
                'pending_deliveries': Delivery.objects.filter(rider=user, status='PENDING').count(),
                'total_earnings': float(Delivery.objects.filter(rider=user, status='DELIVERED').aggregate(total=models.Sum('delivery_fee'))['total'] or 0),
            }
        else:
            stats = {
                'total_orders': Order.objects.filter(buyer=user).count(),
                'completed_orders': Order.objects.filter(buyer=user, status='DELIVERED').count(),
                'total_spent': float(Order.objects.filter(buyer=user, status='DELIVERED').aggregate(total=models.Sum('total'))['total'] or 0),
            }
        
        return stats
    
    def calculate_distance(self, lat1, lon1, lat2, lon2):
        import math
        R = 6371
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        return R * c

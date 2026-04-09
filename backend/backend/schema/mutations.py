import graphene
import random
import string
from django.contrib.auth import get_user_model
from django.contrib.gis.geos import Point
from django.utils import timezone
from graphql_jwt.shortcuts import get_token, create_refresh_token
from graphql_jwt.decorators import login_required
from .types import *

UserModel = get_user_model()

# ==================== Auth Mutations ====================
class TokenAuthMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String(required=True)
        username = graphene.String(required=True)
        provider = graphene.String(required=True)
        social_id = graphene.String(required=True)
        phone_number = graphene.String()

    success = graphene.Boolean()
    message = graphene.String()
    token = graphene.String()
    refresh_token = graphene.String()
    user = graphene.Field(UserType)

    def mutate(self, info, email, username, provider, social_id, phone_number=None):
        user = UserModel.objects.filter(email=email).first()
        if not user:
            if not phone_number:
                phone_number = '+000' + ''.join(random.choices(string.digits, k=10))

            username = username or email.split('@')[0]
            user = UserModel.objects.create_user(
                email=email,
                username=username,
                phone_number=phone_number,
                password=UserModel.objects.make_random_password(),
                user_type='BUYER'
            )
            user.is_verified = True
            user.save()

        token = get_token(user)
        refresh_token = create_refresh_token(user)
        return TokenAuthMutation(
            success=True,
            message="Login successful",
            token=token,
            refresh_token=refresh_token,
            user=user
        )

class RegisterMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String(required=True)
        username = graphene.String(required=True)
        phone_number = graphene.String(required=True)
        password = graphene.String(required=True)
        user_type = graphene.String(default_value='BUYER')
    
    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)
    token = graphene.String()
    
    def mutate(self, info, email, username, phone_number, password, user_type='BUYER'):
        if UserModel.objects.filter(email=email).exists():
            return RegisterMutation(success=False, message="Email already exists")
        
        user = UserModel.objects.create_user(
            email=email,
            username=username,
            phone_number=phone_number,
            password=password,
            user_type=user_type
        )
        
        token = get_token(user)
        
        return RegisterMutation(success=True, message="User created successfully", user=user, token=token)

class LoginMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String(required=True)
        password = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)
    token = graphene.String()
    refresh_token = graphene.String()
    
    def mutate(self, info, email, password):
        from django.contrib.auth import authenticate
        user = authenticate(email=email, password=password)
        
        if not user:
            return LoginMutation(success=False, message="Invalid credentials")
        
        token = get_token(user)
        refresh_token = create_refresh_token(user)
        
        return LoginMutation(success=True, message="Login successful", user=user, token=token, refresh_token=refresh_token)

class SendOTPMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String()
        phone_number = graphene.String()

    success = graphene.Boolean()
    message = graphene.String()
    otp = graphene.String()
    user = graphene.Field(UserType)

    def mutate(self, info, email=None, phone_number=None):
        if not email and not phone_number:
            return SendOTPMutation(success=False, message="Provide email or phone number to receive OTP.")

        user = None
        if email:
            user = UserModel.objects.filter(email=email).first()
        if not user and phone_number:
            user = UserModel.objects.filter(phone_number=phone_number).first()

        if not user:
            if not email:
                email = f'guest_{phone_number}@mapshoptanzania.local'
            if not phone_number:
                phone_number = '+000' + ''.join(random.choices(string.digits, k=10))
            username = email.split('@')[0]
            user = UserModel.objects.create_user(
                email=email,
                username=username,
                phone_number=phone_number,
                password=UserModel.objects.make_random_password(),
                user_type='BUYER'
            )

        otp = ''.join(random.choices(string.digits, k=4))
        user.otp_code = otp
        user.otp_created_at = timezone.now()
        user.save()

        return SendOTPMutation(success=True, message="OTP sent successfully", otp=otp, user=user)

class VerifyOTPMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String()
        phone_number = graphene.String()
        otp_code = graphene.String(required=True)

    success = graphene.Boolean()
    message = graphene.String()
    token = graphene.String()
    refresh_token = graphene.String()
    user = graphene.Field(UserType)

    def mutate(self, info, otp_code, email=None, phone_number=None):
        if not email and not phone_number:
            return VerifyOTPMutation(success=False, message="Provide email or phone number to verify OTP.")

        user = None
        if email:
            user = UserModel.objects.filter(email=email).first()
        if not user and phone_number:
            user = UserModel.objects.filter(phone_number=phone_number).first()

        if not user or not user.otp_code:
            return VerifyOTPMutation(success=False, message="Invalid OTP or user not found.")

        if user.otp_code != otp_code:
            return VerifyOTPMutation(success=False, message="Invalid OTP.")

        if user.otp_created_at and (timezone.now() - user.otp_created_at).seconds > 300:
            return VerifyOTPMutation(success=False, message="OTP has expired.")

        user.is_verified = True
        user.otp_code = None
        user.otp_created_at = None
        user.save()

        token = get_token(user)
        refresh_token = create_refresh_token(user)
        return VerifyOTPMutation(
            success=True,
            message="OTP verified successfully",
            token=token,
            refresh_token=refresh_token,
            user=user
        )

# ==================== Shop Mutations ====================
class CreateShopMutation(graphene.Mutation):
    class Arguments:
        name = graphene.String(required=True)
        description = graphene.String(required=True)
        latitude = graphene.Float(required=True)
        longitude = graphene.Float(required=True)
        address = graphene.String(required=True)
        phone_number = graphene.String(required=True)
        email = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    shop = graphene.Field(ShopType)
    
    @login_required
    def mutate(self, info, **kwargs):
        user = info.context.user
        if user.user_type != 'SELLER':
            return CreateShopMutation(success=False, message="Only sellers can create shops")
        
        latitude = kwargs.pop('latitude')
        longitude = kwargs.pop('longitude')
        location = Point(longitude, latitude)
        shop = Shop.objects.create(seller=user, location=location, **kwargs)
        return CreateShopMutation(success=True, message="Shop created successfully", shop=shop)

class UpdateShopMutation(graphene.Mutation):
    class Arguments:
        shop_id = graphene.Int(required=True)
        name = graphene.String()
        description = graphene.String()
        latitude = graphene.Float()
        longitude = graphene.Float()
        address = graphene.String()
        phone_number = graphene.String()
        email = graphene.String()
        is_open = graphene.Boolean()
    
    success = graphene.Boolean()
    message = graphene.String()
    shop = graphene.Field(ShopType)
    
    @login_required
    def mutate(self, info, shop_id, **kwargs):
        try:
            shop = Shop.objects.get(id=shop_id)
            if shop.seller != info.context.user and info.context.user.user_type != 'ADMIN':
                return UpdateShopMutation(success=False, message="Permission denied")
            
            latitude = kwargs.pop('latitude', None)
            longitude = kwargs.pop('longitude', None)
            if latitude is not None or longitude is not None:
                current_location = shop.location
                lon = longitude if longitude is not None else current_location.x
                lat = latitude if latitude is not None else current_location.y
                shop.location = Point(lon, lat)

            for key, value in kwargs.items():
                if value is not None:
                    setattr(shop, key, value)
            shop.save()
            
            return UpdateShopMutation(success=True, message="Shop updated successfully", shop=shop)
        except Shop.DoesNotExist:
            return UpdateShopMutation(success=False, message="Shop not found")

# ==================== Product Mutations ====================
class CreateProductMutation(graphene.Mutation):
    class Arguments:
        shop_id = graphene.Int(required=True)
        category_id = graphene.Int(required=True)
        name = graphene.String(required=True)
        description = graphene.String(required=True)
        price = graphene.Float(required=True)
        stock = graphene.Int(required=True)
        unit = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    product = graphene.Field(ProductType)
    
    @login_required
    def mutate(self, info, shop_id, category_id, **kwargs):
        user = info.context.user
        try:
            shop = Shop.objects.get(id=shop_id)
            if shop.seller != user and user.user_type != 'ADMIN':
                return CreateProductMutation(success=False, message="Permission denied")
            
            category = Category.objects.get(id=category_id)
            product = Product.objects.create(shop=shop, category=category, **kwargs)
            return CreateProductMutation(success=True, message="Product created successfully", product=product)
        except Exception as e:
            return CreateProductMutation(success=False, message=str(e))

# ==================== Order Mutations ====================
class CreateOrderMutation(graphene.Mutation):
    class Arguments:
        shop_id = graphene.Int(required=True)
        items = graphene.JSONString(required=True)
        delivery_address = graphene.String(required=True)
        latitude = graphene.Float(required=True)
        longitude = graphene.Float(required=True)
        payment_method = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    order = graphene.Field(OrderType)
    
    @login_required
    def mutate(self, info, shop_id, items, delivery_address, latitude, longitude, payment_method):
        import json
        user = info.context.user
        
        try:
            shop = Shop.objects.get(id=shop_id)
            items_data = json.loads(items)
            
            subtotal = 0
            order_items = []
            
            for item in items_data:
                product = Product.objects.get(id=item['product_id'])
                total = product.price * item['quantity']
                subtotal += total
                order_items.append({
                    'product': product,
                    'quantity': item['quantity'],
                    'price': product.price,
                    'total': total
                })
            
            delivery_fee = 1500  # Base delivery fee
            total = subtotal + delivery_fee
            
            order = Order.objects.create(
                buyer=user,
                shop=shop,
                payment_method=payment_method,
                subtotal=subtotal,
                delivery_fee=delivery_fee,
                total=total,
                latitude=latitude,
                longitude=longitude,
                delivery_address=delivery_address,
                status='PENDING'
            )
            
            for item in order_items:
                OrderItem.objects.create(order=order, **item)
            
            return CreateOrderMutation(success=True, message="Order created successfully", order=order)
        except Exception as e:
            return CreateOrderMutation(success=False, message=str(e))

class UpdateOrderStatusMutation(graphene.Mutation):
    class Arguments:
        order_id = graphene.String(required=True)
        status = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    order = graphene.Field(OrderType)
    
    @login_required
    def mutate(self, info, order_id, status):
        try:
            order = Order.objects.get(order_id=order_id)
            user = info.context.user
            
            if user.user_type not in ['ADMIN', 'SELLER'] and order.shop.seller != user:
                return UpdateOrderStatusMutation(success=False, message="Permission denied")
            
            order.status = status
            order.save()
            
            OrderTracking.objects.create(order=order, status=status, description=f"Order status updated to {status}")
            
            return UpdateOrderStatusMutation(success=True, message="Order status updated", order=order)
        except Order.DoesNotExist:
            return UpdateOrderStatusMutation(success=False, message="Order not found")

# ==================== Mutation Root ====================
class Mutation(graphene.ObjectType):
    # Auth
    register = RegisterMutation.Field()
    login = LoginMutation.Field()
    tokenAuth = TokenAuthMutation.Field()
    sendOTP = SendOTPMutation.Field()
    verifyOTP = VerifyOTPMutation.Field()
    
    # Shop
    create_shop = CreateShopMutation.Field()
    update_shop = UpdateShopMutation.Field()
    
    # Product
    create_product = CreateProductMutation.Field()
    
    # Order
    create_order = CreateOrderMutation.Field()
    update_order_status = UpdateOrderStatusMutation.Field()

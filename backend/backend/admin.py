"""
Unified Admin Configuration for MapShop Tanzania
Registers all models from all apps in one place
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html

# Import all models from all apps
from apps.accounts.models import User, UserSession
from apps.shops.models import Shop, ShopHours
from apps.products.models import Category, Product, ProductImage
from apps.orders.models import Order, OrderItem, OrderTracking
from apps.deliveries.models import Delivery, DeliveryTracking
from apps.notifications.models import Notification, UserDevice


# ==================== ACCOUNTS APP ====================

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('id', 'email', 'username', 'phone_number', 'user_type', 'is_verified', 'is_active', 'date_joined')
    list_filter = ('user_type', 'is_verified', 'is_active', 'is_staff', 'date_joined')
    search_fields = ('email', 'username', 'phone_number', 'first_name', 'last_name')
    ordering = ('-date_joined',)
    
    fieldsets = UserAdmin.fieldsets + (
        ('Contact Information', {
            'fields': ('phone_number', 'address')
        }),
        ('Location', {
            'fields': ('latitude', 'longitude')
        }),
        ('Account Type', {
            'fields': ('user_type', 'is_verified')
        }),
        ('Profile', {
            'fields': ('profile_picture', 'fcm_token')
        }),
        ('OTP Verification', {
            'fields': ('otp_code', 'otp_created_at'),
            'classes': ('collapse',)
        }),
    )
    
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Contact Information', {
            'fields': ('phone_number', 'email')
        }),
        ('Account Type', {
            'fields': ('user_type',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related()

@admin.register(UserSession)
class UserSessionAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'is_active', 'created_at', 'expires_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('user__email', 'user__username', 'ip_address')
    readonly_fields = ('created_at',)
    raw_id_fields = ('user',)


# ==================== SHOPS APP ====================

@admin.register(Shop)
class ShopAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'seller', 'phone_number', 'is_open', 'rating', 'status', 'created_at')
    list_filter = ('is_open', 'status', 'created_at')
    search_fields = ('name', 'seller__email', 'seller__username', 'phone_number', 'address')
    readonly_fields = ('created_at', 'updated_at', 'rating', 'total_ratings', 'total_orders')
    raw_id_fields = ('seller',)
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('seller', 'name', 'description', 'status')
        }),
        ('Contact Information', {
            'fields': ('phone_number', 'email', 'address')
        }),
        ('Location', {
            'fields': ('latitude', 'longitude')
        }),
        ('Business Hours', {
            'fields': ('opening_time', 'closing_time', 'is_open')
        }),
        ('Media', {
            'fields': ('logo', 'cover_image')
        }),
        ('Statistics', {
            'fields': ('rating', 'total_ratings', 'total_orders'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('seller')

@admin.register(ShopHours)
class ShopHoursAdmin(admin.ModelAdmin):
    list_display = ('id', 'shop', 'get_day_display', 'open_time', 'close_time', 'is_closed')
    list_filter = ('day', 'is_closed')
    search_fields = ('shop__name',)
    raw_id_fields = ('shop',)
    
    def get_day_display(self, obj):
        days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        return days[obj.day] if 0 <= obj.day < 7 else 'Unknown'
    get_day_display.short_description = 'Day'


# ==================== PRODUCTS APP ====================

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'slug', 'parent', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('name', 'slug', 'description')
    prepopulated_fields = {'slug': ('name',)}
    raw_id_fields = ('parent',)

@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'image_preview', 'is_main', 'created_at')
    list_filter = ('is_main', 'created_at')
    readonly_fields = ('image_preview',)
    
    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" width="50" height="50" style="border-radius: 5px;"/>', obj.image.url)
        return "No Image"
    image_preview.short_description = 'Preview'

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'shop', 'category', 'price', 'discount_price', 'stock', 'is_active', 'rating', 'created_at')
    list_filter = ('is_active', 'is_featured', 'category', 'shop', 'created_at')
    search_fields = ('name', 'slug', 'description', 'shop__name', 'category__name')
    readonly_fields = ('created_at', 'updated_at', 'views_count', 'orders_count', 'rating', 'total_ratings')
    prepopulated_fields = {'slug': ('name',)}
    raw_id_fields = ('shop', 'category')
    filter_horizontal = ('images',)
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('shop', 'category', 'name', 'slug', 'description')
        }),
        ('Pricing', {
            'fields': ('price', 'discount_price', 'unit')
        }),
        ('Inventory', {
            'fields': ('stock', 'is_active', 'is_featured')
        }),
        ('Media', {
            'fields': ('images',)
        }),
        ('Statistics', {
            'fields': ('views_count', 'orders_count', 'rating', 'total_ratings'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('shop', 'category')


# ==================== ORDERS APP ====================

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'order_id', 'buyer', 'shop', 'status', 'payment_method', 'total', 'created_at')
    list_filter = ('status', 'payment_method', 'payment_status', 'created_at')
    search_fields = ('order_id', 'buyer__email', 'buyer__username', 'shop__name', 'delivery_address')
    readonly_fields = ('order_id', 'created_at', 'updated_at', 'delivered_at')
    raw_id_fields = ('buyer', 'shop', 'rider')
    
    fieldsets = (
        ('Order Information', {
            'fields': ('order_id', 'buyer', 'shop', 'status')
        }),
        ('Payment', {
            'fields': ('payment_method', 'payment_status')
        }),
        ('Amounts', {
            'fields': ('subtotal', 'delivery_fee', 'total')
        }),
        ('Location', {
            'fields': ('latitude', 'longitude', 'delivery_address')
        }),
        ('Delivery', {
            'fields': ('rider', 'delivered_at')
        }),
        ('Additional', {
            'fields': ('notes',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('buyer', 'shop', 'rider')
    
    actions = ['mark_as_validated', 'mark_as_packed', 'mark_as_shipped', 'mark_as_delivered']
    
    def mark_as_validated(self, request, queryset):
        queryset.update(status='VALIDATED')
        self.message_user(request, f"{queryset.count()} orders marked as validated.")
    mark_as_validated.short_description = "Mark selected orders as Validated"
    
    def mark_as_packed(self, request, queryset):
        queryset.update(status='PACKED')
        self.message_user(request, f"{queryset.count()} orders marked as packed.")
    mark_as_packed.short_description = "Mark selected orders as Packed"
    
    def mark_as_shipped(self, request, queryset):
        queryset.update(status='SHIPPED')
        self.message_user(request, f"{queryset.count()} orders marked as shipped.")
    mark_as_shipped.short_description = "Mark selected orders as Shipped"
    
    def mark_as_delivered(self, request, queryset):
        from django.utils import timezone
        queryset.update(status='DELIVERED', delivered_at=timezone.now())
        self.message_user(request, f"{queryset.count()} orders marked as delivered.")
    mark_as_delivered.short_description = "Mark selected orders as Delivered"

@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('id', 'order', 'product', 'quantity', 'price', 'total')
    list_filter = ('order__status',)
    search_fields = ('order__order_id', 'product__name')
    readonly_fields = ('total',)
    raw_id_fields = ('order', 'product')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('order', 'product')

@admin.register(OrderTracking)
class OrderTrackingAdmin(admin.ModelAdmin):
    list_display = ('id', 'order', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('order__order_id', 'description')
    readonly_fields = ('created_at',)
    raw_id_fields = ('order',)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('order')


# ==================== DELIVERIES APP ====================

@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ('id', 'delivery_id', 'order', 'rider', 'status', 'delivery_fee', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('delivery_id', 'order__order_id', 'rider__email', 'pickup_address', 'delivery_address')
    readonly_fields = ('delivery_id', 'created_at', 'updated_at')
    raw_id_fields = ('order', 'rider')
    
    fieldsets = (
        ('Delivery Information', {
            'fields': ('delivery_id', 'order', 'rider', 'status')
        }),
        ('Addresses', {
            'fields': ('pickup_address', 'delivery_address')
        }),
        ('Location', {
            'fields': ('pickup_latitude', 'pickup_longitude', 'delivery_latitude', 'delivery_longitude')
        }),
        ('Timing', {
            'fields': ('pickup_time', 'delivery_time', 'estimated_delivery_time', 'actual_delivery_time')
        }),
        ('Cost & Distance', {
            'fields': ('distance_km', 'delivery_fee')
        }),
        ('Rating', {
            'fields': ('rider_rating', 'rider_comment')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('order', 'rider')

@admin.register(DeliveryTracking)
class DeliveryTrackingAdmin(admin.ModelAdmin):
    list_display = ('id', 'delivery', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('delivery__delivery_id', 'description')
    readonly_fields = ('created_at',)
    raw_id_fields = ('delivery',)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('delivery')


# ==================== NOTIFICATIONS APP ====================

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'user', 'notification_type', 'is_read', 'created_at')
    list_filter = ('notification_type', 'is_read', 'created_at')
    search_fields = ('title', 'message', 'user__email', 'user__username')
    readonly_fields = ('created_at',)
    raw_id_fields = ('user',)
    
    fieldsets = (
        ('Notification', {
            'fields': ('user', 'title', 'message', 'notification_type')
        }),
        ('Status', {
            'fields': ('is_read',)
        }),
        ('Data', {
            'fields': ('data',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')
    
    actions = ['mark_as_read']
    
    def mark_as_read(self, request, queryset):
        queryset.update(is_read=True)
        self.message_user(request, f"{queryset.count()} notifications marked as read.")
    mark_as_read.short_description = "Mark selected notifications as read"

@admin.register(UserDevice)
class UserDeviceAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'device_type', 'device_id', 'is_active', 'created_at')
    list_filter = ('device_type', 'is_active', 'created_at')
    search_fields = ('user__email', 'user__username', 'device_id', 'fcm_token')
    readonly_fields = ('created_at', 'updated_at')
    raw_id_fields = ('user',)


# ==================== CUSTOM ADMIN SITE ====================

class MapShopAdminSite(admin.AdminSite):
    site_header = "MapShop Tanzania Administration"
    site_title = "MapShop Tanzania Admin"
    index_title = "Welcome to MapShop Tanzania Dashboard"
    
    def get_app_list(self, request):
        """
        Customize the admin dashboard display
        """
        app_list = super().get_app_list(request)
        
        # Custom ordering of apps
        custom_order = ['accounts', 'shops', 'products', 'orders', 'deliveries', 'notifications']
        
        for app in app_list:
            if app['app_label'] in custom_order:
                app['order'] = custom_order.index(app['app_label'])
            else:
                app['order'] = 999
        
        app_list.sort(key=lambda x: x.get('order', 999))
        
        return app_list

# Uncomment to use custom admin site
# admin_site = MapShopAdminSite(name='mapshop_admin')
# admin_site.register(User, CustomUserAdmin)
# ... register all models with admin_site instead

# For now, use default admin site
admin.site.site_header = "MapShop Tanzania Administration"
admin.site.site_title = "MapShop Tanzania Admin"
admin.site.index_title = "Welcome to MapShop Tanzania Dashboard"

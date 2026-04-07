from rest_framework import serializers
from .models import Order, OrderItem, OrderTracking

class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    product_price = serializers.ReadOnlyField(source='product.price')
    
    class Meta:
        model = OrderItem
        fields = '__all__'

class OrderTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderTracking
        fields = '__all__'
        read_only_fields = ('created_at',)

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    buyer_name = serializers.ReadOnlyField(source='buyer.email')
    shop_name = serializers.ReadOnlyField(source='shop.name')
    rider_name = serializers.ReadOnlyField(source='rider.email', default=None)
    
    class Meta:
        model = Order
        fields = '__all__'
        read_only_fields = ('order_id', 'created_at', 'updated_at', 'delivered_at')


from rest_framework import serializers
from .models import Shop, ShopHours

class ShopHoursSerializer(serializers.ModelSerializer):
    day_name = serializers.SerializerMethodField()
    
    class Meta:
        model = ShopHours
        fields = '__all__'
    
    def get_day_name(self, obj):
        days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        return days[obj.day] if 0 <= obj.day < 7 else 'Unknown'

class ShopSerializer(serializers.ModelSerializer):
    hours = ShopHoursSerializer(many=True, read_only=True)
    seller_name = serializers.ReadOnlyField(source='seller.email')
    distance = serializers.FloatField(read_only=True, required=False)
    
    class Meta:
        model = Shop
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'rating', 'total_ratings', 'total_orders')

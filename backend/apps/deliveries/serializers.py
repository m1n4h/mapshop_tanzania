from rest_framework import serializers
from .models import Delivery, DeliveryTracking

class DeliverySerializer(serializers.ModelSerializer):
    class Meta:
        model = Delivery
        fields = '__all__'
        read_only_fields = ('delivery_id', 'created_at', 'updated_at')

class DeliveryTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryTracking
        fields = '__all__'
        read_only_fields = ('created_at',)
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from .models import Delivery, DeliveryTracking
from .serializers import DeliverySerializer, DeliveryTrackingSerializer

class DeliveryListView(generics.ListCreateAPIView):
    serializer_class = DeliverySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'ADMIN':
            return Delivery.objects.all()
        elif user.user_type == 'RIDER':
            return Delivery.objects.filter(rider=user)
        elif user.user_type == 'BUYER':
            return Delivery.objects.filter(order__buyer=user)
        return Delivery.objects.none()
    
    def perform_create(self, serializer):
        serializer.save()

class DeliveryDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = DeliverySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'ADMIN':
            return Delivery.objects.all()
        elif user.user_type == 'RIDER':
            return Delivery.objects.filter(rider=user)
        elif user.user_type == 'BUYER':
            return Delivery.objects.filter(order__buyer=user)
        return Delivery.objects.none()

class UpdateDeliveryStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, delivery_id):
        delivery = get_object_or_404(Delivery, delivery_id=delivery_id)
        new_status = request.data.get('status')
        location = request.data.get('location')
        
        if new_status:
            delivery.status = new_status
            delivery.save()
            
            # Create tracking record
            DeliveryTracking.objects.create(
                delivery=delivery,
                status=new_status,
                location=location,
                description=f"Delivery status updated to {new_status}"
            )
            
            # Send notification (implement later)
            # send_delivery_update_notification(delivery)
        
        serializer = DeliverySerializer(delivery)
        return Response(serializer.data)

class DeliveryTrackingView(generics.ListAPIView):
    serializer_class = DeliveryTrackingSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        delivery_id = self.kwargs.get('delivery_id')
        delivery = get_object_or_404(Delivery, delivery_id=delivery_id)
        return DeliveryTracking.objects.filter(delivery=delivery)
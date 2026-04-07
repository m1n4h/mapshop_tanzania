from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from .models import Order, OrderTracking
from .serializers import OrderSerializer, OrderTrackingSerializer

class OrderListView(generics.ListCreateAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'ADMIN':
            return Order.objects.all()
        elif user.user_type == 'BUYER':
            return Order.objects.filter(buyer=user)
        elif user.user_type == 'SELLER':
            return Order.objects.filter(shop__seller=user)
        elif user.user_type == 'RIDER':
            return Order.objects.filter(rider=user)
        return Order.objects.none()
    
    def perform_create(self, serializer):
        serializer.save(buyer=self.request.user)

class OrderDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'ADMIN':
            return Order.objects.all()
        elif user.user_type == 'BUYER':
            return Order.objects.filter(buyer=user)
        elif user.user_type == 'SELLER':
            return Order.objects.filter(shop__seller=user)
        return Order.objects.none()

class TrackOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, order_id):
        order = get_object_or_404(Order, order_id=order_id)
        tracking = OrderTracking.objects.filter(order=order)
        serializer = OrderTrackingSerializer(tracking, many=True)
        return Response({
            'order_id': order.order_id,
            'status': order.status,
            'tracking_history': serializer.data
        })

class UpdateOrderStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, order_id):
        order = get_object_or_404(Order, order_id=order_id)
        new_status = request.data.get('status')
        location = request.data.get('location')
        description = request.data.get('description', f"Order status updated to {new_status}")
        
        if new_status:
            order.status = new_status
            if new_status == 'DELIVERED':
                order.delivered_at = timezone.now()
            order.save()
            
            # Create tracking record
            OrderTracking.objects.create(
                order=order,
                status=new_status,
                location=location,
                description=description
            )
        
        serializer = OrderSerializer(order)
        return Response(serializer.data)

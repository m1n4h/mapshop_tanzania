from rest_framework import generics, permissions, filters
from rest_framework.response import Response
from django.db.models import Q
from .models import Shop
from .serializers import ShopSerializer
import math

class ShopListView(generics.ListCreateAPIView):
    queryset = Shop.objects.filter(status='ACTIVE')
    serializer_class = ShopSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'address', 'description']
    ordering_fields = ['rating', 'created_at', 'name']
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by nearby location
        lat = self.request.query_params.get('lat')
        lng = self.request.query_params.get('lng')
        radius = float(self.request.query_params.get('radius', 5))  # km
        
        if lat and lng:
            lat = float(lat)
            lng = float(lng)
            
            # Calculate distance for each shop
            for shop in queryset:
                distance = self.calculate_distance(lat, lng, shop.latitude, shop.longitude)
                shop.distance = distance
            
            # Filter by radius
            queryset = [shop for shop in queryset if shop.distance <= radius]
            queryset = sorted(queryset, key=lambda x: x.distance)
        
        return queryset
    
    def calculate_distance(self, lat1, lon1, lat2, lon2):
        R = 6371  # Earth's radius in km
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        return R * c
    
    def perform_create(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save(seller=request.user)
            return Response(serializer.data)
        return Response(serializer.errors)

class ShopDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Shop.objects.all()
    serializer_class = ShopSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def perform_update(self, serializer):
        if self.request.user.user_type == 'SELLER' and serializer.instance.seller != self.request.user:
            return Response({'error': 'You can only update your own shop'}, status=403)
        serializer.save()
    
    def perform_destroy(self, instance):
        if self.request.user.user_type == 'SELLER' and instance.seller != self.request.user:
            return Response({'error': 'You can only delete your own shop'}, status=403)
        instance.delete()
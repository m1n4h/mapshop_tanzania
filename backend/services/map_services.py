import googlemaps
from django.conf import settings
from math import radians, cos, sin, asin, sqrt

class MapService:
    def __init__(self):
        self.gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)
    
    def geocode_address(self, address):
        """Convert address to coordinates"""
        try:
            result = self.gmaps.geocode(address)
            if result:
                location = result[0]['geometry']['location']
                return {
                    'lat': location['lat'],
                    'lng': location['lng'],
                    'formatted_address': result[0]['formatted_address']
                }
        except Exception as e:
            print(f"Geocoding error: {e}")
        return None
    
    def calculate_distance(self, origin, destination):
        """Calculate distance between two points in kilometers"""
        try:
            result = self.gmaps.distance_matrix(origin, destination)
            if result['rows'][0]['elements'][0]['status'] == 'OK':
                distance = result['rows'][0]['elements'][0]['distance']['text']
                duration = result['rows'][0]['elements'][0]['duration']['text']
                return {
                    'distance': distance,
                    'duration': duration,
                    'distance_value': result['rows'][0]['elements'][0]['distance']['value'],
                    'duration_value': result['rows'][0]['elements'][0]['duration']['value']
                }
        except Exception as e:
            print(f"Distance calculation error: {e}")
        return None
    
    def get_nearby_shops(self, location, radius_km=5):
        """Get shops within radius"""
        # This would use PostGIS for spatial queries
        from apps.shops.models import Shop
        from django.contrib.gis.db.models.functions import Distance
        from django.contrib.gis.geos import Point
        
        point = Point(location['lng'], location['lat'], srid=4326)
        radius_meters = radius_km * 1000
        
        shops = Shop.objects.filter(
            location__distance_lte=(point, radius_meters),
            status='ACTIVE'
        ).annotate(
            distance=Distance('location', point)
        ).order_by('distance')
        
        return shops
    
    def calculate_delivery_fee(self, distance_km):
        """Calculate delivery fee based on distance"""
        base_fee = 1500  # TZS
        per_km_fee = 500  # TZS per km
        return base_fee + (distance_km * per_km_fee)
    
    def get_eta(self, origin, destination):
        """Get estimated time of arrival"""
        result = self.calculate_distance(origin, destination)
        if result:
            return result['duration']
        return None

    def haversine_distance(self, lat1, lon1, lat2, lon2):
        """Calculate distance between two points using Haversine formula"""
        R = 6371  # Earth's radius in kilometers
        
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        
        return R * c
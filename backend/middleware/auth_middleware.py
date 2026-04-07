from django.utils.deprecation import MiddlewareMixin
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from django.http import JsonResponse

class AuthMiddleware(MiddlewareMixin):
    """Custom authentication middleware for JWT token validation"""
    
    def process_request(self, request):
        # Skip authentication for public endpoints
        public_paths = ['/api/auth/login/', '/api/auth/register/', '/api/auth/verify-otp/', 
                       '/api/auth/resend-otp/', '/api/auth/forgot-password/', '/api/auth/reset-password/',
                       '/health/', '/admin/']
        
        if any(request.path.startswith(path) for path in public_paths):
            return None
        
        # Check for token in Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            try:
                auth = JWTAuthentication()
                validated_token = auth.get_validated_token(token)
                user = auth.get_user(validated_token)
                request.user = user
            except (InvalidToken, TokenError) as e:
                pass
        
        return None

    def process_response(self, request, response):
        # Add CORS headers
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        return response

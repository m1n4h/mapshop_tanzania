from graphene_django.views import GraphQLView
from django.views.decorators.csrf import csrf_exempt
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
#from drf_yasg.views import get_schema_view
#from drf_yasg import openapi
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/shops/', include('apps.shops.urls')),
    path('api/products/', include('apps.products.urls')),
    path('api/orders/', include('apps.orders.urls')),
    path('api/deliveries/', include('apps.deliveries.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
    
    # ✅ GraphQL endpoint
    path('graphql/', csrf_exempt(GraphQLView.as_view(graphiql=True))),
    # API Documentation
path('schema/', SpectacularAPIView.as_view(), name='schema'),
path('docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += [path('__debug__/', include('debug_toolbar.urls'))]
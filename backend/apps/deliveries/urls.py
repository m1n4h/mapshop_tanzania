from django.urls import path
from .views import *

urlpatterns = [
    path('', DeliveryListView.as_view(), name='delivery-list'),
    path('<str:delivery_id>/', DeliveryDetailView.as_view(), name='delivery-detail'),
    path('<str:delivery_id>/update-status/', UpdateDeliveryStatusView.as_view(), name='update-status'),
    path('<str:delivery_id>/tracking/', DeliveryTrackingView.as_view(), name='delivery-tracking'),
]
from django.urls import path
from . import views

urlpatterns = [
    path('', views.OrderListView.as_view(), name='order-list'),
    path('<int:pk>/', views.OrderDetailView.as_view(), name='order-detail'),
    path('track/<str:order_id>/', views.TrackOrderView.as_view(), name='track-order'),
    path('<str:order_id>/update-status/', views.UpdateOrderStatusView.as_view(), name='update-status'),
]

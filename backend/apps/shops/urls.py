from django.urls import path
from . import views

urlpatterns = [
    # Add your shop URLs here
    path('', views.ShopListView.as_view(), name='shop-list'),
    path('<int:pk>/', views.ShopDetailView.as_view(), name='shop-detail'),
]
from django.urls import path
from .views import *

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('<int:notification_id>/read/', MarkNotificationReadView.as_view(), name='mark-read'),
    path('mark-all-read/', MarkAllNotificationsReadView.as_view(), name='mark-all-read'),
    path('<int:notification_id>/delete/', DeleteNotificationView.as_view(), name='delete-notification'),
    path('register-device/', RegisterDeviceView.as_view(), name='register-device'),
    path('unregister-device/', UnregisterDeviceView.as_view(), name='unregister-device'),
]
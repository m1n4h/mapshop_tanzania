from django.db import models
from apps.accounts.models import User

class Notification(models.Model):
    NOTIFICATION_TYPES = (
        ('ORDER', 'Order'),
        ('DELIVERY', 'Delivery'),
        ('PAYMENT', 'Payment'),
        ('SYSTEM', 'System'),
        ('PROMOTION', 'Promotion'),
        ('ALERT', 'Alert'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES, default='SYSTEM')
    is_read = models.BooleanField(default=False)
    data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.user.email}"

class UserDevice(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='devices')
    device_id = models.CharField(max_length=255)
    fcm_token = models.CharField(max_length=255)
    device_type = models.CharField(max_length=50)  # android, ios, web
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_devices'
        unique_together = ['user', 'device_id']
    
    def __str__(self):
        return f"{self.user.email} - {self.device_type}"
from django.contrib.gis.db import models
from apps.accounts.models import User
from apps.orders.models import Order

class Delivery(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ASSIGNED', 'Assigned'),
        ('PICKED_UP', 'Picked Up'),
        ('IN_TRANSIT', 'In Transit'),
        ('ARRIVING_SOON', 'Arriving Soon'),
        ('DELIVERED', 'Delivered'),
        ('FAILED', 'Failed'),
        ('CANCELLED', 'Cancelled'),
    )
    
    delivery_id = models.CharField(max_length=50, unique=True)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='delivery')
    rider = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries_assigned', limit_choices_to={'user_type': 'RIDER'})
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    pickup_location = models.PointField(geography=True)
    delivery_location = models.PointField(geography=True)
    pickup_address = models.TextField()
    delivery_address = models.TextField()
    pickup_time = models.DateTimeField(null=True, blank=True)
    delivery_time = models.DateTimeField(null=True, blank=True)
    estimated_delivery_time = models.DateTimeField(null=True, blank=True)
    actual_delivery_time = models.DateTimeField(null=True, blank=True)
    distance_km = models.FloatField(default=0)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    rider_rating = models.FloatField(default=0)
    rider_comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'deliveries'
        verbose_name_plural = 'Deliveries'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Delivery {self.delivery_id} - Order {self.order.order_id}"
    
    def save(self, *args, **kwargs):
        if not self.delivery_id:
            import random
            import string
            self.delivery_id = 'DEL-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        super().save(*args, **kwargs)

class DeliveryTracking(models.Model):
    delivery = models.ForeignKey(Delivery, on_delete=models.CASCADE, related_name='tracking')
    status = models.CharField(max_length=20)
    location = models.PointField(geography=True, null=True, blank=True)
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'delivery_tracking'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.delivery.delivery_id} - {self.status}"
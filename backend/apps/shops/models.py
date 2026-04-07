from django.contrib.gis.db import models
from apps.accounts.models import User

class Shop(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ACTIVE', 'Active'),
        ('SUSPENDED', 'Suspended'),
        ('CLOSED', 'Closed'),
    )
    
    seller = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shops', limit_choices_to={'user_type': 'SELLER'})
    name = models.CharField(max_length=200)
    description = models.TextField()
    location = models.PointField(geography=True)
    address = models.TextField()
    phone_number = models.CharField(max_length=17)
    email = models.EmailField()
    logo = models.ImageField(upload_to='shop_logos/', null=True, blank=True)
    cover_image = models.ImageField(upload_to='shop_covers/', null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    opening_time = models.TimeField()
    closing_time = models.TimeField()
    is_open = models.BooleanField(default=True)
    rating = models.FloatField(default=0.0)
    total_ratings = models.IntegerField(default=0)
    total_orders = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'shops'
        ordering = ['-rating', '-total_orders']
    
    def __str__(self):
        return self.name

class ShopHours(models.Model):
    DAY_CHOICES = (
        (0, 'Monday'),
        (1, 'Tuesday'),
        (2, 'Wednesday'),
        (3, 'Thursday'),
        (4, 'Friday'),
        (5, 'Saturday'),
        (6, 'Sunday'),
    )
    
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name='hours')
    day = models.IntegerField(choices=DAY_CHOICES)
    open_time = models.TimeField()
    close_time = models.TimeField()
    is_closed = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'shop_hours'
        unique_together = ['shop', 'day']
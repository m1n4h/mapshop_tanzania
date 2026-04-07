from rest_framework import serializers
from django.contrib.auth import authenticate
from django.utils import timezone
from .models import User, UserSession
import random
import string

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'email', 'username', 'phone_number', 'user_type', 
                  'profile_picture', 'location', 'address', 'is_verified', 
                  'date_joined', 'last_login')
        read_only_fields = ('id', 'is_verified', 'date_joined', 'last_login')

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True, min_length=6)
    
    class Meta:
        model = User
        fields = ('email', 'username', 'phone_number', 'password', 'confirm_password', 'user_type')
    
    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"password": "Passwords must match."})
        
        if User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError({"email": "Email already exists."})
        
        if User.objects.filter(phone_number=data['phone_number']).exists():
            raise serializers.ValidationError({"phone_number": "Phone number already exists."})
        
        return data
    
    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = User.objects.create_user(**validated_data)
        
        # Generate OTP
        otp = ''.join(random.choices(string.digits, k=6))
        user.otp_code = otp
        user.otp_created_at = timezone.now()
        user.save()
        
        # Send OTP via SMS (implement in service)
        # send_otp_sms(user.phone_number, otp)
        
        return user

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, data):
        user = authenticate(email=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError("Invalid credentials.")
        if not user.is_active:
            raise serializers.ValidationError("User account is disabled.")
        
        data['user'] = user
        return data

class OTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp_code = serializers.CharField(max_length=6)
    
    def validate(self, data):
        try:
            user = User.objects.get(email=data['email'], otp_code=data['otp_code'])
            if user.otp_created_at and (timezone.now() - user.otp_created_at).seconds > 300:
                raise serializers.ValidationError("OTP has expired.")
            data['user'] = user
            return data
        except User.DoesNotExist:
            raise serializers.ValidationError("Invalid OTP code.")

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True, min_length=6)
    
    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords must match."})
        return data

class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()
    
    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("No user found with this email.")
        return value

class ResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp_code = serializers.CharField(max_length=6)
    new_password = serializers.CharField(min_length=6)
    confirm_password = serializers.CharField(min_length=6)
    
    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords must match."})
        
        try:
            user = User.objects.get(email=data['email'], otp_code=data['otp_code'])
            data['user'] = user
            return data
        except User.DoesNotExist:
            raise serializers.ValidationError("Invalid OTP code.")
from twilio.rest import Client
from django.conf import settings

def send_sms(phone_number, message):
    """Send SMS using Twilio"""
    try:
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            body=message,
            from_=settings.TWILIO_PHONE_NUMBER,
            to=phone_number
        )
        return message.sid
    except Exception as e:
        print(f"SMS sending error: {e}")
        return None

def send_otp_sms(phone_number, otp):
    """Send OTP verification code via SMS"""
    message = f"Your MapShop Tanzania verification code is: {otp}. Valid for 5 minutes."
    return send_sms(phone_number, message)

def send_order_confirmation_sms(phone_number, order_id):
    """Send order confirmation via SMS"""
    message = f"Your order {order_id} has been confirmed. Track your delivery in the MapShop app."
    return send_sms(phone_number, message)

def send_delivery_update_sms(phone_number, order_id, status):
    """Send delivery status update via SMS"""
    message = f"Order {order_id} status update: {status}. Track in real-time on MapShop app."
    return send_sms(phone_number, message)
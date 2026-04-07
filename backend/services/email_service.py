from django.core.mail import send_mail
from django.conf import settings
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def send_email(subject, to_email, html_content, text_content=None):
    """Send email using SendGrid"""
    try:
        message = Mail(
            from_email=settings.EMAIL_HOST_USER,
            to_emails=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=text_content
        )
        sg = SendGridAPIClient(settings.SENDGRID_API_KEY)
        response = sg.send(message)
        return response.status_code
    except Exception as e:
        print(f"Email sending error: {e}")
        return None

def send_otp_email(email, otp):
    """Send OTP verification code via email"""
    subject = "MapShop Tanzania - Verification Code"
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
            .code {{ font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background-color: #f4f4f4; }}
            .footer {{ text-align: center; padding: 20px; color: #666; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>MapShop Tanzania</h1>
            </div>
            <p>Your verification code is:</p>
            <div class="code">{otp}</div>
            <p>This code will expire in 5 minutes.</p>
            <div class="footer">
                <p>© 2024 MapShop Tanzania. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
    return send_email(subject, email, html_content)

def send_welcome_email(email, name):
    """Send welcome email to new user"""
    subject = "Welcome to MapShop Tanzania!"
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; }}
            .button {{ background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Welcome to MapShop Tanzania!</h1>
            </div>
            <div class="content">
                <p>Dear {name},</p>
                <p>Thank you for joining MapShop Tanzania! We're excited to have you on board.</p>
                <p>With MapShop Tanzania, you can:</p>
                <ul>
                    <li>Discover local shops around you</li>
                    <li>Order products with precise GPS delivery</li>
                    <li>Track your orders in real-time</li>
                    <li>Connect with local sellers and riders</li>
                </ul>
                <p>Get started by exploring shops near you!</p>
                <a href="https://mapshoptanzania.com/explore" class="button">Start Exploring</a>
            </div>
            <div class="footer">
                <p>© 2024 MapShop Tanzania. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
    return send_email(subject, email, html_content)
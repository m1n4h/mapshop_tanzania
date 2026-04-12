# MapShop Tanzania Backend API

## Overview
RESTful API backend for MapShop Tanzania - a map-based e-commerce platform for smart local shopping and delivery.

## Features
- User authentication (JWT)
- Shop and product management
- Order processing with real-time tracking
- GPS-based location services
- Delivery rider management
- Push notifications
- SMS and email notifications
- Payment integration

## Technology Stack
- Django 5.0
- Django REST Framework
- PostgreSQL with PostGIS
- Redis (caching & WebSocket)
- Celery (async tasks)
- Google Maps API
- Twilio (SMS)
- SendGrid (Email)
- JWT Authentication

## Installation

### Prerequisites
- Python 3.10+
- PostgreSQL 14+ with PostGIS
- Redis 6+
- Google Maps API Key

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/m1n4h/mapshop-tanzania.git
cd mapshop-tanzania/backend

# create the virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate


# install the dependencies
pip install -r requirements.txt

## SETUP DATABASE
# Create PostgreSQL database with PostGIS
sudo -u postgres createdb mapshop_db
sudo -u postgres psql -c "CREATE EXTENSION postgis;" mapshop_db

# Run migrations
python3 manage.py makemigrations
python3 manage.py migrate


##CREATE THE SUPERUSER

python manage.py createsuperuser

## RUNSERVER
python manage.py runserver
cd n



### INSTALLATION SETUP 
postgresql 16..
postGIS 3..
Redis server 7...
GEOS and GDAL (geos-3.12.1
GDAL 3.8.4, released 2024/02/08
)
-django redis


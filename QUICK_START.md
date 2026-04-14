# Quick Start - MapShop Tanzania Product Management

## 🚀 Start Here

### Backend (Django)

```bash
cd backend

# Activate virtualenv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Ensure categories exist
python manage.py shell
>>> from apps.products.models import Category
>>> Category.objects.get_or_create(name='Food', slug='food', description='Food items')[0]
>>> Category.objects.get_or_create(name='Electronics', slug='electronics', description='Electronics')[0]
>>> Category.objects.get_or_create(name='Clothing', slug='clothing', description='Clothing')[0]
>>> exit()

# Start server
python manage.py runserver 0.0.0.0:8000
```

### Frontend (Flutter)

```bash
cd ../

# Update GraphQL endpoint if needed
# Edit: lib/services/graphql_config.dart
# Line 8: 'http://YOUR_IP:8000/graphql/'

# Run flutter
flutter pub get
flutter run
```

## 🧪 Test Scenario

### Step 1: Create Seller Account
- Email: seller@test.com
- Password: seller123
- User Type: SELLER

### Step 2: Create Shop
- Name: "My Shop"
- Description: "Local shop"
- Address: Your location
- Phone: +255123456789
- Email: shop@test.com
- Location: Current GPS coordinates

### Step 3: Add Product
1. Go to "Add Product"
2. See categories loading from database
3. Fill form:
   ```
   Name: juice
   Category: Food
   Price: 10000
   Stock: 1
   Unit: kg
   Description: juice mango
   ```
4. Click "Add Product"
5. See success message
6. Product appears in "My Products"

### Step 4: View as Buyer
- Login as different user (BUYER)
- See products from all sellers
- Filter by category
- Search by name

## 📋 Status Check

✅ **Backend:**
- CreateProductMutation improved
- Error handling clear
- Shop validation working
- Categories accessible via GraphQL

✅ **Frontend:**
- Dynamic categories loading
- Add product form updated
- ProductProvider manages state
- Sellers can create products
- Buyers can see all products

## 🐛 If Something Goes Wrong

### Categories not loading?
```bash
# Backend check
python manage.py shell
>>> from apps.products.models import Category
>>> Category.objects.all()
# If empty, create categories manually
```

### Permission denied error?
- Seller must create shop first
- User type must be SELLER or ADMIN
- Token must be valid (logout/login)

### Products not appearing?
- Clear app cache: `flutter clean`
- Restart backend: `python manage.py runserver`
- Check is_active=True on product
- Verify seller has a shop

## 📞 Common Commands

```bash
# View categories in backend
python manage.py shell
>>> from apps.products.models import Category
>>> list(Category.objects.values('id', 'name'))

# View products
>>> from apps.products.models import Product
>>> list(Product.objects.values('id', 'name', 'shop__name', 'is_active'))

# View shops
>>> from apps.shops.models import Shop
>>> list(Shop.objects.values('id', 'name', 'seller__email'))

# Test GraphQL query
# Go to http://localhost:8000/graphql/
# Query: { categories { id name } }
```

## 🎯 What's Working Now

| Feature | Status | Path |
|---------|--------|------|
| Dynamic Categories | ✅ | lib/provider/product_provider.dart |
| Create Product | ✅ | lib/screens/add_product_screen.dart |
| Read Products | ✅ | backend/backend/schema/queries.py |
| Update Product | ✅ | backend/backend/schema/mutations.py |
| Delete Product | ✅ | backend/backend/schema/mutations.py |
| Shop Creation | ✅ | lib/services/shop_service.dart |
| Product Search | ✅ | backend/backend/schema/queries.py |
| Category Filter | ✅ | backend/backend/schema/queries.py |
| Authentication | ✅ | lib/services/graphql_config.dart |

## 🔄 Complete Product Flow Diagram

```
┌─────────────┐
│  SELLER     │
│  Registers  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Creates    │
│  Shop       │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│ Add Product Screen              │
│ - Categories load from backend  │
│ - Form data validated           │
│ - Product created with shop_id  │
└──────┬──────────────────────────┘
       │
       ▼ GraphQL Mutation
    ┌──────────────────────────┐
    │ Backend: CreateProduct   │
    │ - Validates seller       │
    │ - Validates shop         │
    │ - Validates category     │
    │ - Creates product        │
    │ - Sets is_active=True    │
    └──────┬───────────────────┘
           │
           ▼
    ┌──────────────────────┐
    │ Database: Product    │
    │ - Linked to Shop     │
    │ - Linked to Category │
    │ - Visible to buyers  │
    └──────┬───────────────┘
           │
           ▼ GraphQL Query
    ┌──────────────────────┐
    │ BUYER sees product   │
    │ - In product browse  │
    │ - In search results  │
    │ - In category filter │
    └──────────────────────┘
```

---

**Ready to test?** Follow the steps above and you should have full product CRUD functionality working!

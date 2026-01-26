# Docker Setup - Issues Fixed

## Issues Resolved

### 1. ✅ OpenAI Client Initialization Error
**Error**: `TypeError: Client.__init__() got an unexpected keyword argument 'proxies'`

**Fix**: Changed to lazy initialization of OpenAI client to avoid import-time errors.

**File**: `backend/workouts/services/natural_language_parser.py`
- Changed from module-level initialization to `get_openai_client()` function
- Client is now created only when needed

### 2. ✅ User Model Email Uniqueness
**Error**: `'User.email' must be unique because it is named as the 'USERNAME_FIELD'`

**Fix**: Explicitly set email field as unique in User model.

**File**: `backend/users/models.py`
- Added `email = models.EmailField(unique=True, ...)`

### 3. ✅ Admin Ordering Error
**Error**: `The value of 'ordering[0]' refers to 'username', which is not a field`

**Fix**: Updated UserAdmin to order by email instead of username.

**File**: `backend/users/admin.py`
- Added `ordering = ['email']`

### 4. ✅ Pillow Missing
**Error**: `Cannot use ImageField because Pillow is not installed`

**Fix**: Added Pillow to requirements.txt.

**File**: `backend/requirements.txt`
- Added `Pillow==10.2.0`

### 5. ✅ OpenAI Version
**Fix**: Updated OpenAI version constraint for better compatibility.

**File**: `backend/requirements.txt`
- Changed from `openai==1.12.0` to `openai>=1.0.0,<2.0.0`

## Current Status

✅ **Backend is running successfully!**
- Server: `http://localhost:8000`
- Database: Connected and migrated
- All errors resolved

## Next Steps

1. **Create a superuser** (optional):
   ```bash
   docker compose exec backend python manage.py createsuperuser
   ```

2. **Test the API**:
   - Register: `POST http://localhost:8000/api/auth/users/`
   - Login: `POST http://localhost:8000/api/auth/jwt/create/`

3. **Use the mobile app**:
   - Update API URL in `mobile/lib/core/constants/api_constants.dart` if needed
   - Register/login with email only (no username!)

## Docker Commands

```bash
# View logs
docker compose logs -f backend

# Run migrations
docker compose exec backend python manage.py migrate

# Create superuser
docker compose exec backend python manage.py createsuperuser

# Stop services
docker compose down
```

# Email-Only Authentication Migration

## Changes Made

### Backend (Django)
1. ✅ Updated `User` model to use email as `USERNAME_FIELD`
2. ✅ Removed username field from User model
3. ✅ Created custom Djoser serializers with role support
4. ✅ Updated all serializers to use email instead of username
5. ✅ Updated admin interface

### Mobile (Flutter)
1. ✅ Updated login screen to use email field
2. ✅ Updated register screen to remove username field
3. ✅ Updated auth repository to use email
4. ✅ Updated auth provider to use email
5. ✅ Updated UserModel to remove username
6. ✅ Updated dashboard to display email

## Important: Database Migration Required

Since we changed the User model structure, you need to create and run migrations:

```bash
cd backend
source venv/bin/activate  # or env/bin/activate
python manage.py makemigrations
python manage.py migrate
```

**⚠️ Warning**: If you have existing users in the database, this migration will:
- Remove the username field
- Use email as the login identifier

If you have existing data, you may need to create a data migration to copy usernames to emails or handle the transition.

## Testing

After running migrations, you can:

1. **Register a new user** via the mobile app:
   - Email: `test@example.com`
   - Password: `test123456`
   - Role: Trainee

2. **Login** with:
   - Email: `test@example.com`
   - Password: `test123456`

## API Changes

- Login endpoint now accepts `email` instead of `username`:
  ```json
  POST /api/auth/jwt/create/
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```

- Registration endpoint no longer requires `username`:
  ```json
  POST /api/auth/users/
  {
    "email": "user@example.com",
    "password": "password123",
    "role": "TRAINEE"
  }
  ```

## Next Steps

1. Run migrations: `cd backend && python manage.py makemigrations && python manage.py migrate`
2. Test registration in the mobile app
3. Test login with email

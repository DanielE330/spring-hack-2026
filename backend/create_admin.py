#!/usr/bin/env python
import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'entry_point.settings')

def main():
    try:
        import django
        django.setup()
    except Exception as e:
        print('Error importing Django:', e)
        sys.exit(1)

    from user.models import User

    ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL', 'admin@example.com')
    ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'adminpass')
    ADMIN_NAME = os.environ.get('ADMIN_NAME', 'Admin')
    ADMIN_SURNAME = os.environ.get('ADMIN_SURNAME', 'User')

    user_qs = User.objects.filter(email=ADMIN_EMAIL)
    if user_qs.exists():
        user = user_qs.first()
        user.is_admin = True
        user.is_superuser = True
        user.set_password(ADMIN_PASSWORD)
        user.name = ADMIN_NAME
        user.surname = ADMIN_SURNAME
        user.save()
        print(f'Updated existing admin: {ADMIN_EMAIL}')
    else:
        try:
            user = User.objects.create_user(email=ADMIN_EMAIL, name=ADMIN_NAME, surname=ADMIN_SURNAME, password=ADMIN_PASSWORD)
        except TypeError:
            # fallback if create_user signature differs
            user = User(email=ADMIN_EMAIL, name=ADMIN_NAME, surname=ADMIN_SURNAME)
            user.set_password(ADMIN_PASSWORD)
            user.save()
        user.is_admin = True
        user.is_superuser = True
        user.save()
        print(f'Created admin user: {ADMIN_EMAIL}')

    print('Credentials:')
    print('  email:', ADMIN_EMAIL)
    print('  password:', ADMIN_PASSWORD)

if __name__ == '__main__':
    main()

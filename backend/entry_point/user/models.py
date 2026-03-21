import logging

from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
import secrets

logger = logging.getLogger('user')


class UserManager(BaseUserManager):
    def create_user(self, email, name, surname, password=None, **extra_fields):
        logger.debug(
            "[UserManager.create_user] email=%s name=%s surname=%s extra=%s",
            email, name, surname, list(extra_fields.keys())
        )
        if not email:
            logger.error("[UserManager.create_user] Email не передан")
            raise ValueError('Email обязателен')

        email = self.normalize_email(email)

        if not name:
            logger.error("[UserManager.create_user] Имя не передано")
            raise ValueError('Имя обязательно')
        if not surname:
            logger.error("[UserManager.create_user] Фамилия не передана")
            raise ValueError('Фамилия обязательна')

        user = self.model(
            email=email,
            name=name,
            surname=surname,
            **extra_fields
        )
        user.set_password(password)
        user.save(using=self._db)
        logger.info("[UserManager.create_user] Пользователь сохранён в БД: id=%s email=%s", user.id, user.email)
        return user

class User(AbstractBaseUser, PermissionsMixin):
    name = models.CharField(max_length=50)
    surname = models.CharField(max_length=50)
    patronymic = models.CharField(max_length=50, blank=True, null=True)
    email = models.EmailField(unique=True)
    is_admin = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = 'email'

    # Django Admin работает через is_staff
    @property
    def is_staff(self):
        return self.is_admin

    def __str__(self):
        return self.email

class UserDevice(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='devices')
    key = models.CharField(max_length=64, unique=True, editable=False)
    device_name = models.CharField(max_length=100, blank=True, null=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        if not self.key:
            self.key = secrets.token_hex(32)
            logger.debug("[UserDevice.save] Сгенерирован новый ключ для user_id=%s device_name=%s", self.user_id, self.device_name)
        super().save(*args, **kwargs)
        if is_new:
            logger.info("[UserDevice.save] Новое устройство создано: id=%s user_id=%s device_name=%s", self.id, self.user_id, self.device_name)
        else:
            logger.debug("[UserDevice.save] Устройство обновлено: id=%s user_id=%s", self.id, self.user_id)

    def __str__(self):
        return f"{self.device_name or 'Device'} - {self.user.email}"
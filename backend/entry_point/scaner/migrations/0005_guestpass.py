import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('scaner', '0004_add_dates_and_finalization'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='GuestPass',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('guest_name', models.CharField(help_text='ФИО гостя', max_length=150)),
                ('guest_company', models.CharField(blank=True, default='', help_text='Компания/организация гостя', max_length=200)),
                ('purpose', models.CharField(choices=[('meeting', 'Встреча'), ('contractor', 'Подрядчик'), ('delivery', 'Доставка/Курьер'), ('temp_employee', 'Временный сотрудник'), ('other', 'Другое')], default='meeting', max_length=20)),
                ('note', models.TextField(blank=True, default='', help_text='Комментарий к пропуску')),
                ('token', models.CharField(editable=False, max_length=64, unique=True)),
                ('status', models.CharField(choices=[('active', 'Активен'), ('used', 'Использован'), ('expired', 'Истёк'), ('revoked', 'Отменён')], default='active', max_length=10)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('valid_from', models.DateTimeField(help_text='Начало действия')),
                ('valid_until', models.DateTimeField(help_text='Конец действия')),
                ('used_at', models.DateTimeField(blank=True, help_text='Когда был предъявлен', null=True)),
                ('revoked_at', models.DateTimeField(blank=True, help_text='Когда был отменён', null=True)),
                ('created_by', models.ForeignKey(help_text='Администратор, создавший пропуск', on_delete=django.db.models.deletion.CASCADE, related_name='created_guest_passes', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]

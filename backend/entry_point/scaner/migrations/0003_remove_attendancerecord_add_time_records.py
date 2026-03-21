import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('scaner', '0002_attendancerecord'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.DeleteModel(
            name='AttendanceRecord',
        ),
        migrations.CreateModel(
            name='WeeklyRecord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('week_start', models.DateField(help_text='Понедельник начала недели')),
                ('days_worked', models.PositiveIntegerField(default=0)),
                ('total_seconds', models.PositiveBigIntegerField(default=0, help_text='Общее время работы за неделю (секунды)')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='weekly_records', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-week_start'],
                'unique_together': {('user', 'week_start')},
            },
        ),
        migrations.CreateModel(
            name='MonthlyRecord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('year', models.PositiveIntegerField()),
                ('month', models.PositiveSmallIntegerField()),
                ('days_worked', models.PositiveIntegerField(default=0)),
                ('total_seconds', models.PositiveBigIntegerField(default=0, help_text='Общее время работы за месяц (секунды)')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='monthly_records', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-year', '-month'],
                'unique_together': {('user', 'year', 'month')},
            },
        ),
        migrations.CreateModel(
            name='YearlyRecord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('year', models.PositiveIntegerField()),
                ('days_worked', models.PositiveIntegerField(default=0)),
                ('total_seconds', models.PositiveBigIntegerField(default=0, help_text='Общее время работы за год (секунды)')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='yearly_records', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-year'],
                'unique_together': {('user', 'year')},
            },
        ),
    ]

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('scaner', '0003_remove_attendancerecord_add_time_records'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # WeeklyRecord: add week_end, is_finalized
        migrations.AddField(
            model_name='weeklyrecord',
            name='week_end',
            field=models.DateField(blank=True, help_text='Воскресенье конца недели', null=True),
        ),
        migrations.AddField(
            model_name='weeklyrecord',
            name='is_finalized',
            field=models.BooleanField(default=False, help_text='Данные перенесены в месяц'),
        ),
        # MonthlyRecord: add start_date, end_date, is_finalized
        migrations.AddField(
            model_name='monthlyrecord',
            name='start_date',
            field=models.DateField(blank=True, help_text='Первое число месяца', null=True),
        ),
        migrations.AddField(
            model_name='monthlyrecord',
            name='end_date',
            field=models.DateField(blank=True, help_text='Последнее число месяца', null=True),
        ),
        migrations.AddField(
            model_name='monthlyrecord',
            name='is_finalized',
            field=models.BooleanField(default=False, help_text='Данные перенесены в год'),
        ),
        # YearlyRecord: add start_date, end_date
        migrations.AddField(
            model_name='yearlyrecord',
            name='start_date',
            field=models.DateField(blank=True, help_text='1 января', null=True),
        ),
        migrations.AddField(
            model_name='yearlyrecord',
            name='end_date',
            field=models.DateField(blank=True, help_text='31 декабря', null=True),
        ),
    ]

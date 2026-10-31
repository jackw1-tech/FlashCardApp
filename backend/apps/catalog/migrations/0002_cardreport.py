import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='CardReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('reason', models.CharField(choices=[('wrong_answer', 'Risposta sbagliata'), ('bad_format', 'Formattata male'), ('other', 'Altro')], max_length=16)),
                ('comment', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('resolved_at', models.DateTimeField(blank=True, null=True)),
                ('card', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reports', to='catalog.card')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='card_reports', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'segnalazione',
                'verbose_name_plural': 'segnalazioni',
                'ordering': ['-created_at'],
            },
        ),
    ]

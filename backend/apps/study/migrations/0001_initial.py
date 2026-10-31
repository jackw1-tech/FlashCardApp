import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('catalog', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Review',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('outcome', models.CharField(choices=[('knew', 'Sapevo'), ('didnt_know', 'Non sapevo')], max_length=16)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('card', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='reviews', to='catalog.card')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='reviews', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'review',
                'verbose_name_plural': 'review',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='CardState',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('last_seen_at', models.DateTimeField()),
                ('times_seen', models.PositiveIntegerField()),
                ('card', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='states', to='catalog.card')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='card_states', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'stato card',
                'verbose_name_plural': 'stati card',
                'constraints': [models.UniqueConstraint(fields=('user', 'card'), name='unique_card_state_per_user')],
            },
        ),
    ]

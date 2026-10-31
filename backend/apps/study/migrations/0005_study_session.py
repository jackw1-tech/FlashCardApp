import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0004_card_embedding'),
        ('study', '0004_temporarydeckdraft'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='StudySession',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('client_id', models.UUIDField()),
                ('note_title', models.CharField(blank=True, max_length=255)),
                ('started_at', models.DateTimeField()),
                ('ended_at', models.DateTimeField(db_index=True)),
                ('knew', models.PositiveIntegerField()),
                ('didnt_know', models.PositiveIntegerField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('deck', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='catalog.deck')),
                ('reviews', models.ManyToManyField(related_name='sessions', to='study.review')),
                ('temporary_deck', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='sessions', to='study.temporarydeck')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='study_sessions', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'sessione',
                'verbose_name_plural': 'sessioni',
                'ordering': ['-ended_at'],
                'constraints': [models.UniqueConstraint(fields=('user', 'client_id'), name='unique_session_client_id')],
            },
        ),
    ]

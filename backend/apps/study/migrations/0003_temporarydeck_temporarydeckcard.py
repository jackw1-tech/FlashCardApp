import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0003_card_note_modified_at'),
        ('study', '0002_reviewundo'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='TemporaryDeck',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=200)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('expires_at', models.DateTimeField()),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='temporary_decks', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'mazzo provvisorio',
                'verbose_name_plural': 'mazzi provvisori',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='TemporaryDeckCard',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('position', models.PositiveIntegerField()),
                ('card', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='temporary_deck_entries', to='catalog.card')),
                ('temporary_deck', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='entries', to='study.temporarydeck')),
            ],
            options={
                'ordering': ['position'],
                'constraints': [models.UniqueConstraint(fields=('temporary_deck', 'card'), name='unique_card_per_temporary_deck'), models.UniqueConstraint(fields=('temporary_deck', 'position'), name='unique_position_per_temporary_deck')],
            },
        ),
    ]

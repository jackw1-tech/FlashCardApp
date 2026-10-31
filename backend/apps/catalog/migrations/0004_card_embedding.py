import django.db.models.deletion
import pgvector.django.vector
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0003_card_note_modified_at'),
    ]

    operations = [
        pgvector.django.VectorExtension(),
        migrations.CreateModel(
            name='CardEmbedding',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('model', models.CharField(max_length=64)),
                ('text_hash', models.CharField(max_length=64)),
                ('vector', pgvector.django.vector.VectorField(dimensions=1024)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('card', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='embedding', to='catalog.card')),
            ],
            options={
                'verbose_name': 'embedding della card',
                'verbose_name_plural': 'embedding delle card',
            },
        ),
    ]

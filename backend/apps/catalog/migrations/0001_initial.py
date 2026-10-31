import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Deck',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('slug', models.CharField(max_length=100, unique=True)),
                ('name', models.CharField(max_length=200)),
            ],
            options={
                'verbose_name': 'mazzo',
                'verbose_name_plural': 'mazzi',
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='Card',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('key', models.CharField(max_length=64, unique=True)),
                ('note_title', models.CharField(max_length=255)),
                ('kind', models.CharField(choices=[('basic', 'Basic'), ('multiline', 'Multiline'), ('cloze', 'Cloze')], max_length=16)),
                ('front', models.TextField()),
                ('back', models.TextField()),
                ('line_number', models.PositiveIntegerField()),
                ('archived_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('deck', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='cards', to='catalog.deck')),
            ],
            options={
                'verbose_name': 'card',
                'verbose_name_plural': 'card',
            },
        ),
    ]

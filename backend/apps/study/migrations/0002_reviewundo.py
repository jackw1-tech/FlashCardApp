import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('study', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ReviewUndo',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('review', models.OneToOneField(on_delete=django.db.models.deletion.PROTECT, related_name='undo', to='study.review')),
            ],
            options={
                'verbose_name': 'annullamento',
                'verbose_name_plural': 'annullamenti',
            },
        ),
    ]

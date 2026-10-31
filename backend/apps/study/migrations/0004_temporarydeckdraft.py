import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('study', '0003_temporarydeck_temporarydeckcard'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='TemporaryDeckDraft',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=200)),
                ('card_ids', models.JSONField()),
                ('by_note', models.JSONField()),
                ('adjustments', models.JSONField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('expires_at', models.DateTimeField()),
                ('temporary_deck', models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='draft', to='study.temporarydeck')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='temporary_deck_drafts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'anteprima di mazzo provvisorio',
                'verbose_name_plural': 'anteprime di mazzi provvisori',
            },
        ),
    ]

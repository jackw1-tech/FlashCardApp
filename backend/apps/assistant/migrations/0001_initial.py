import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Conversation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(blank=True, max_length=200)),
                ('status', models.CharField(choices=[('idle', 'In attesa di un messaggio'), ('running', 'Sta rispondendo'), ('waiting_confirmation', 'In attesa di conferma')], default='idle', max_length=24)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='conversations', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'conversazione',
                'verbose_name_plural': 'conversazioni',
                'ordering': ['-updated_at'],
            },
        ),
        migrations.CreateModel(
            name='Message',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('seq', models.PositiveIntegerField()),
                ('role', models.CharField(max_length=16)),
                ('content', models.JSONField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('conversation', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='assistant.conversation')),
            ],
            options={
                'verbose_name': 'messaggio',
                'verbose_name_plural': 'messaggi',
                'ordering': ['seq'],
                'constraints': [models.UniqueConstraint(fields=('conversation', 'seq'), name='unique_message_seq')],
            },
        ),
    ]

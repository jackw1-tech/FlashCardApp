from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0002_cardreport'),
    ]

    operations = [
        migrations.AddField(
            model_name='card',
            name='note_modified_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]

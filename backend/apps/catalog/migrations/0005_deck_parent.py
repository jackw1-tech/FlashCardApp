from django.db import migrations, models
import django.db.models.deletion


def connect_existing_subdecks(apps, schema_editor):
    Deck = apps.get_model("catalog", "Deck")
    for deck in Deck.objects.filter(slug__contains="/").order_by("slug"):
        parent_slug = deck.slug.rpartition("/")[0]
        parent, _ = Deck.objects.get_or_create(slug=parent_slug, defaults={"name": parent_slug.rsplit("/", 1)[-1]})
        deck.parent = parent
        deck.save(update_fields=["parent"])


class Migration(migrations.Migration):
    dependencies = [("catalog", "0004_card_embedding")]

    operations = [
        migrations.AddField(
            model_name="deck",
            name="parent",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="subdecks",
                to="catalog.deck",
            ),
        ),
        migrations.RunPython(connect_existing_subdecks, migrations.RunPython.noop),
    ]

from rest_framework import serializers

from apps.catalog.models import Card, CardReport, Deck, ReportReason


class DeckRenameSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=Deck._meta.get_field("name").max_length)


class DeckSerializer(serializers.ModelSerializer):
    class Meta:
        model = Deck
        fields = ["slug", "name"]


class CardSerializer(serializers.ModelSerializer):
    deck = DeckSerializer()

    class Meta:
        model = Card
        fields = ["id", "deck", "note_title", "kind", "front", "back"]


class SearchQuerySerializer(serializers.Serializer):
    q = serializers.CharField(allow_blank=True, trim_whitespace=False)
    deck = serializers.CharField(required=False)


class ReportInputSerializer(serializers.Serializer):
    reason = serializers.ChoiceField(choices=ReportReason.choices)
    comment = serializers.CharField(required=False, allow_blank=True, default="", max_length=2000)


class ReportSerializer(serializers.ModelSerializer):
    card = CardSerializer()

    class Meta:
        model = CardReport
        fields = ["id", "reason", "comment", "created_at", "resolved_at", "card"]

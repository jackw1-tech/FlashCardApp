from rest_framework import serializers

from apps.catalog.api.serializers import CardSerializer
from apps.study.models import Outcome, Review


class StudyCardSerializer(CardSerializer):

    recent_outcomes = serializers.ListField(child=serializers.CharField(), read_only=True)

    class Meta(CardSerializer.Meta):
        fields = [*CardSerializer.Meta.fields, "recent_outcomes"]


class DeckSummarySerializer(serializers.Serializer):
    slug = serializers.CharField()
    name = serializers.CharField()
    total_cards = serializers.IntegerField()
    unseen_cards = serializers.IntegerField()
    subdecks = serializers.SerializerMethodField()

    def get_subdecks(self, instance) -> list[dict]:
        return DeckSummarySerializer(instance.subdecks, many=True).data


class NoteSummarySerializer(serializers.Serializer):
    title = serializers.CharField()
    total_cards = serializers.IntegerField()
    unseen_cards = serializers.IntegerField()


class NextCardQuerySerializer(serializers.Serializer):
    deck = serializers.CharField(required=False)
    note = serializers.CharField(required=False)
    temporary_deck = serializers.IntegerField(required=False)
    exclude = serializers.CharField(required=False, allow_blank=True)

    def validate_exclude(self, value: str) -> list[int]:
        try:
            return [int(part) for part in value.split(",") if part]
        except ValueError:
            raise serializers.ValidationError("deve essere una lista di ID separati da virgola")


class ReviewInputSerializer(serializers.Serializer):
    card_id = serializers.IntegerField()
    outcome = serializers.ChoiceField(choices=Outcome.choices)


class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = ["id", "card_id", "outcome", "created_at"]


class DeckStatsSerializer(serializers.Serializer):
    slug = serializers.CharField()
    name = serializers.CharField()
    reviews = serializers.IntegerField()
    knew_ratio = serializers.FloatField(allow_null=True)
    last_studied_at = serializers.DateTimeField(allow_null=True)


class StatsSerializer(serializers.Serializer):
    today = serializers.DateField()
    today_reviews = serializers.IntegerField()
    streak_days = serializers.IntegerField()
    decks = DeckStatsSerializer(many=True)


class TemporaryDeckSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    created_at = serializers.DateTimeField()
    expires_at = serializers.DateTimeField()
    total = serializers.IntegerField()
    done = serializers.IntegerField()
    missed = serializers.IntegerField()


class SessionInputSerializer(serializers.Serializer):
    client_id = serializers.UUIDField()
    review_ids = serializers.ListField(child=serializers.IntegerField(), min_length=1, max_length=1000)
    deck = serializers.CharField(required=False, allow_null=True)
    note = serializers.CharField(required=False, allow_null=True)
    temporary_deck = serializers.IntegerField(required=False, allow_null=True)


class SessionSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    deck = serializers.SerializerMethodField()
    note_title = serializers.CharField()
    temporary_deck = serializers.SerializerMethodField()
    started_at = serializers.DateTimeField()
    ended_at = serializers.DateTimeField()
    knew = serializers.IntegerField()
    didnt_know = serializers.IntegerField()

    def get_deck(self, session) -> dict | None:
        return None if session.deck is None else {"slug": session.deck.slug, "name": session.deck.name}

    def get_temporary_deck(self, session) -> dict | None:
        deck = session.temporary_deck
        return None if deck is None else {"id": deck.pk, "name": deck.name}

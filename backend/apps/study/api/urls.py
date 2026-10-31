from django.urls import path

from apps.study.api import views

urlpatterns = [
    path("decks/", views.deck_list, name="deck-list"),
    path("decks/<path:slug>/notes/", views.note_list, name="deck-notes"),
    path("next-card/", views.next_card, name="next-card"),
    path("reviews/", views.create_review, name="review-create"),
    path("reviews/<int:review_id>/undo/", views.undo_review, name="review-undo"),
    path("stats/", views.stats, name="stats"),
    path("sessions/", views.session_list, name="session-list"),
    path("temporary-decks/", views.temporary_deck_list, name="temporary-deck-list"),
    path("temporary-decks/<int:deck_id>/", views.temporary_deck_detail, name="temporary-deck-detail"),
]

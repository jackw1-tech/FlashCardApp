from django.urls import path

from apps.catalog.api import views

urlpatterns = [
    path("vault/sync/", views.sync_vault, name="vault-sync"),
    path("decks/<path:slug>/", views.rename_deck, name="deck-rename"),
    path("cards/search/", views.search_cards, name="card-search"),
    path("cards/<int:card_id>/reports/", views.report_card, name="card-report"),
    path("reports/", views.open_reports, name="report-list"),
    path("reports/<int:report_id>/resolve/", views.resolve_report, name="report-resolve"),
]

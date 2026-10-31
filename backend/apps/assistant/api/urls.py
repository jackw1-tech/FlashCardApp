from django.urls import path

from apps.assistant.api import views

urlpatterns = [
    path("conversations/", views.conversation_list, name="conversation-list"),
    path("conversations/<int:conversation_id>/", views.conversation_detail, name="conversation-detail"),
    path("conversations/<int:conversation_id>/messages/", views.send_message, name="conversation-messages"),
    path("conversations/<int:conversation_id>/confirmation/", views.confirmation, name="conversation-confirmation"),
]

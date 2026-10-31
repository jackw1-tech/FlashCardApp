from django.contrib import admin

from apps.study.models import Review, StudySession, TemporaryDeck, TemporaryDeckCard


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):

    list_display = ["created_at", "user", "card", "outcome"]
    list_filter = ["outcome", "created_at"]
    list_select_related = ["user", "card"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


class TemporaryDeckCardInline(admin.TabularInline):
    model = TemporaryDeckCard
    fields = ["position", "card"]
    readonly_fields = fields
    extra = 0
    can_delete = False


@admin.register(TemporaryDeck)
class TemporaryDeckAdmin(admin.ModelAdmin):

    list_display = ["name", "user", "created_at", "expires_at"]
    list_select_related = ["user"]
    inlines = [TemporaryDeckCardInline]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(StudySession)
class StudySessionAdmin(admin.ModelAdmin):

    list_display = ["ended_at", "user", "deck", "note_title", "temporary_deck", "knew", "didnt_know"]
    list_select_related = ["user", "deck", "temporary_deck"]
    readonly_fields = ["reviews"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

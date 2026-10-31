from django.contrib import admin

from apps.accounts.models import RefreshToken


@admin.register(RefreshToken)
class RefreshTokenAdmin(admin.ModelAdmin):

    list_display = ["user", "family", "created_at", "expires_at", "used_at", "revoked_at"]
    list_filter = [("revoked_at", admin.EmptyFieldListFilter), ("used_at", admin.EmptyFieldListFilter)]
    readonly_fields = ["user", "family", "token_hash", "created_at", "expires_at", "used_at", "revoked_at"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

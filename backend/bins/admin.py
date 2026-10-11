from django.contrib import admin

from .models import Bin


@admin.register(Bin)
class BinAdmin(admin.ModelAdmin):
    list_display = ("id", "type", "access_level", "latitude", "longitude", "upvotes", "added_by", "created_at")
    list_filter = ("type", "access_level", "created_at")
    search_fields = ("description", "added_by__email")
    readonly_fields = ("created_at",)

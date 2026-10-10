from django.contrib import admin
from .models import Bin


@admin.register(Bin)
class BinAdmin(admin.ModelAdmin):
    list_display = ("id", "type", "latitude", "longitude", "upvotes", "added_by", "created_at")
    list_filter = ("type", "created_at")
    search_fields = ("description", "added_by__email")
    readonly_fields = ("created_at",)

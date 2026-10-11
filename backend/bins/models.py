from django.conf import settings
from django.db import models


class Bin(models.Model):
    BIO = "bio"
    PLASTIC = "plastic"
    BOTH = "both"
    TYPE_CHOICES = [(BIO, "Bio"), (PLASTIC, "Plastic"), (BOTH, "Both")]

    PUBLIC = "public"
    LIMITED = "limited"
    PRIVATE = "private"
    ACCESS_CHOICES = [
        (PUBLIC, "Public"),
        (LIMITED, "Limited entry (campus / office compound)"),
        (PRIVATE, "Private"),
    ]

    latitude = models.FloatField()
    longitude = models.FloatField()
    description = models.TextField(blank=True, default="")
    type = models.CharField(max_length=16, choices=TYPE_CHOICES, default=BIO)
    access_level = models.CharField(
        max_length=12, choices=ACCESS_CHOICES, default=PUBLIC, db_index=True
    )
    added_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        related_name="submitted_bins", blank=True, null=True,
    )
    upvotes = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["latitude", "longitude"], name="bins_lat_lon_idx"),
            models.Index(fields=["access_level", "created_at"], name="bins_access_created_idx"),
        ]

    def __str__(self):
        return f"{self.get_access_level_display()} bin at ({self.latitude}, {self.longitude})"

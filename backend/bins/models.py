from django.conf import settings
from django.db import models


class Bin(models.Model):
    BIO = "bio"
    PLASTIC = "plastic"
    BOTH = "both"
    TYPE_CHOICES = [(BIO, "Bio"), (PLASTIC, "Plastic"), (BOTH, "Both")]

    latitude = models.FloatField()
    longitude = models.FloatField()
    description = models.TextField(blank=True, default="")
    type = models.CharField(max_length=16, choices=TYPE_CHOICES, default=BIO)
    added_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="submitted_bins",
        blank=True,
        null=True,
    )
    upvotes = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["latitude", "longitude"],
                name="bins_lat_lon_idx",
            ),
        ]

    def __str__(self):
        return f"Bin at ({self.latitude}, {self.longitude})"

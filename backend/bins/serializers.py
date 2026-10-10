from rest_framework import serializers
from .models import Bin


class BinSerializer(serializers.ModelSerializer):
    added_by_email = serializers.EmailField(source="added_by.email", read_only=True)

    class Meta:
        model = Bin
        fields = [
            "id", "latitude", "longitude", "description", "type",
            "added_by", "added_by_email", "upvotes", "created_at",
        ]
        read_only_fields = ["id", "added_by", "added_by_email", "upvotes", "created_at"]

    def validate_latitude(self, value):
        if not -90 <= value <= 90:
            raise serializers.ValidationError("Latitude must be between -90 and 90.")
        return value

    def validate_longitude(self, value):
        if not -180 <= value <= 180:
            raise serializers.ValidationError("Longitude must be between -180 and 180.")
        return value

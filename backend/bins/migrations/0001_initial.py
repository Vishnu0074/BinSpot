# Initial BinSpot backend schema.
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True
    dependencies = [migrations.swappable_dependency(settings.AUTH_USER_MODEL)]
    operations = [
        migrations.CreateModel(
            name="Bin",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("latitude", models.FloatField()),
                ("longitude", models.FloatField()),
                ("description", models.TextField(blank=True, default="")),
                ("type", models.CharField(choices=[("bio", "Bio"), ("plastic", "Plastic"), ("both", "Both")], default="bio", max_length=16)),
                ("upvotes", models.PositiveIntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("added_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="submitted_bins", to=settings.AUTH_USER_MODEL)),
            ],
            options={"ordering": ["-created_at"]},
        ),
        migrations.AddIndex(
            model_name="bin",
            index=models.Index(fields=["latitude", "longitude"], name="bins_bin_latitude_long_8a5d2f_idx"),
        ),
    ]

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("bins", "0001_initial")]

    operations = [
        migrations.AddField(
            model_name="bin",
            name="access_level",
            field=models.CharField(
                choices=[
                    ("public", "Public"),
                    ("limited", "Limited entry (campus / office compound)"),
                    ("private", "Private"),
                ],
                db_index=True,
                default="public",
                max_length=12,
            ),
        ),
        migrations.AddIndex(
            model_name="bin",
            index=models.Index(fields=["access_level", "created_at"], name="bins_access_created_idx"),
        ),
    ]

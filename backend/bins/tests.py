from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from .models import Bin

User = get_user_model()


class ApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_health(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], "ok")

    def test_register_and_login_by_email(self):
        response = self.client.post("/api/auth/register/", {
            "email": "tester@example.com",
            "password": "Strong-password-987!",
        }, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertIn("token", response.data)
        login = self.client.post("/api/auth/login/", {
            "email": "tester@example.com",
            "password": "Strong-password-987!",
        }, format="json")
        self.assertEqual(login.status_code, 200)
        self.assertEqual(login.data["email"], "tester@example.com")

    def test_bin_list_and_create_requires_auth(self):
        payload = {
            "latitude": 9.2648,
            "longitude": 76.7758,
            "type": "plastic",
            "description": "Community recycling bin",
        }
        anonymous = self.client.post("/api/bins/", payload, format="json")
        self.assertEqual(anonymous.status_code, 401)

        user = User.objects.create_user(
            username="tester@example.com",
            email="tester@example.com",
            password="Strong-password-987!",
        )
        self.client.force_authenticate(user=user)
        response = self.client.post("/api/bins/", payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["type"], "plastic")
        listed = self.client.get("/api/bins/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data["count"], 1)
        self.assertEqual(listed.data["results"][0]["added_by_email"], "tester@example.com")

    def test_upvote_increments_counter(self):
        obj = Bin.objects.create(latitude=9.2, longitude=76.8, type="bio")
        response = self.client.post(f"/api/bins/{obj.pk}/upvote/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["upvotes"], 1)

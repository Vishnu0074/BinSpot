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

    def test_register_with_username_and_login_by_username(self):
        response = self.client.post("/api/auth/register/", {
            "username": "green_guru",
            "email": "tester@example.com",
            "password": "Strong-password-987!",
        }, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertIn("token", response.data)
        self.assertEqual(response.data["username"], "green_guru")
        login = self.client.post("/api/auth/login/", {
            "username": "green_guru",
            "password": "Strong-password-987!",
        }, format="json")
        self.assertEqual(login.status_code, 200)
        self.assertEqual(login.data["email"], "tester@example.com")
        self.assertEqual(login.data["username"], "green_guru")

    def test_registration_rejects_duplicate_username_case_insensitively(self):
        self.client.post("/api/auth/register/", {
            "username": "Green_Guru",
            "email": "one@example.com",
            "password": "Strong-password-987!",
        }, format="json")
        response = self.client.post("/api/auth/register/", {
            "username": "green_guru",
            "email": "two@example.com",
            "password": "Strong-password-987!",
        }, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("username", response.data)

    def test_bin_creation_defaults_to_public_and_requires_auth(self):
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
        self.assertEqual(response.data["access_level"], "public")

        listed = self.client.get("/api/bins/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data["count"], 1)
        self.assertEqual(listed.data["results"][0]["added_by_email"], "tester@example.com")

    def test_nearby_bins_respects_radius_and_limit(self):
        for i in range(25):
            Bin.objects.create(latitude=9.2648 + i * 0.0001, longitude=76.7758, type="bio")
        Bin.objects.create(latitude=12.0, longitude=76.0, type="bio")
        response = self.client.get("/api/bins/?lat=9.2648&lng=76.7758&radius_km=5&limit=20")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 20)
        self.assertEqual(len(response.data["results"]), 20)

    def test_top_contributors_returns_ranked_nature_titles(self):
        user = User.objects.create_user(username="green@example.com", email="green@example.com", password="Strong-password-987!")
        for i in range(3):
            Bin.objects.create(latitude=9.2 + i * 0.001, longitude=76.8, added_by=user)
        response = self.client.get("/api/contributors/top/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["bins_count"], 3)
        self.assertEqual(response.data["results"][0]["title"], "Seed Planter")

    def test_upvote_increments_counter(self):
        obj = Bin.objects.create(latitude=9.2, longitude=76.8, type="bio")
        response = self.client.post(f"/api/bins/{obj.pk}/upvote/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["upvotes"], 1)

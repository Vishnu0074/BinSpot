import math

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Count, F
from rest_framework import generics, permissions, status
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Bin
from .serializers import BinSerializer

User = get_user_model()


class HealthView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({"status": "ok", "service": "BinSpot API"})


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request):
        username = str(request.data.get("username", "")).strip()
        email = str(request.data.get("email", "")).strip().lower()
        password = str(request.data.get("password", ""))

        if not username or len(username) < 3 or len(username) > 30:
            raise ValidationError({"username": "Username must be between 3 and 30 characters."})
        if not username.replace("_", "").replace("-", "").isalnum():
            raise ValidationError({"username": "Use only letters, numbers, underscores, and hyphens."})
        if User.objects.filter(username__iexact=username).exists():
            raise ValidationError({"username": "This username is already taken."})
        if not email or "@" not in email:
            raise ValidationError({"email": "Enter a valid email address."})
        if User.objects.filter(email__iexact=email).exists():
            raise ValidationError({"email": "An account with this email already exists."})
        if len(password) < 8:
            raise ValidationError({"password": "Password must contain at least 8 characters."})
        try:
            validate_password(password)
        except DjangoValidationError as exc:
            raise ValidationError({"password": list(exc.messages)})

        user = User.objects.create_user(username=username, email=email, password=password)
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "id": user.pk,
            "username": user.username,
            "email": user.email,
        }, status=status.HTTP_201_CREATED)


class LoginView(ObtainAuthToken):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, *args, **kwargs):
        data = request.data.copy()
        data["username"] = str(data.get("username", "")).strip()
        serializer = self.serializer_class(data=data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "id": user.pk,
            "username": user.username,
            "email": user.email,
        })


class CurrentUserView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({
            "id": request.user.pk,
            "username": request.user.username,
            "email": request.user.email,
        })


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class BinListCreateView(generics.ListCreateAPIView):
    serializer_class = BinSerializer

    def get_queryset(self):
        queryset = Bin.objects.select_related("added_by").all()
        try:
            lat = float(self.request.query_params["lat"])
            lng = float(self.request.query_params["lng"])
        except (KeyError, TypeError, ValueError):
            return queryset[:20]

        if not -90 <= lat <= 90 or not -180 <= lng <= 180:
            raise ValidationError({"location": "lat/lng are outside valid ranges."})
        try:
            radius_km = min(max(float(self.request.query_params.get("radius_km", "5")), 0.25), 50)
            limit = min(max(int(self.request.query_params.get("limit", "20")), 1), 100)
        except ValueError:
            raise ValidationError({"query": "radius_km and limit must be valid numbers."})

        lat_delta = radius_km / 110.574
        lon_scale = max(abs(math.cos(math.radians(lat))), 0.01)
        lon_delta = min(radius_km / (111.320 * lon_scale), 180)
        candidates = queryset.filter(
            latitude__gte=max(-90, lat - lat_delta),
            latitude__lte=min(90, lat + lat_delta),
            longitude__gte=max(-180, lng - lon_delta),
            longitude__lte=min(180, lng + lon_delta),
        )
        matches = []
        for bin_obj in candidates:
            phi1, phi2 = math.radians(lat), math.radians(bin_obj.latitude)
            d_phi = math.radians(bin_obj.latitude - lat)
            d_lam = math.radians(bin_obj.longitude - lng)
            a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lam / 2) ** 2
            distance = 6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(max(0, 1 - a)))
            if distance <= radius_km:
                matches.append((distance, bin_obj))
        matches.sort(key=lambda item: item[0])
        self._matched_bins = [item[1] for item in matches[:limit]]
        return self._matched_bins

    def list(self, request, *args, **kwargs):
        bins = self.get_queryset()
        serializer = self.get_serializer(bins, many=True)
        return Response({
            "count": len(bins),
            "results": serializer.data,
            "radius_km": min(max(float(request.query_params.get("radius_km", "5")), 0.25), 50)
            if request.query_params.get("lat") is not None else None,
            "limit": min(max(int(request.query_params.get("limit", "20")), 1), 100),
        })

    def get_permissions(self):
        return [permissions.AllowAny()] if self.request.method == "GET" else [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(added_by=self.request.user)


class BinDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Bin.objects.select_related("added_by").all()
    serializer_class = BinSerializer

    def get_permissions(self):
        return [permissions.AllowAny()] if self.request.method == "GET" else [permissions.IsAuthenticated()]

    def perform_update(self, serializer):
        if self.request.user.is_staff or serializer.instance.added_by_id == self.request.user.id:
            serializer.save()
            return
        raise PermissionDenied("You can only update bins you submitted.")

    def perform_destroy(self, instance):
        if self.request.user.is_staff or instance.added_by_id == self.request.user.id:
            instance.delete()
            return
        raise PermissionDenied("You can only delete bins you submitted.")


class BinUpvoteView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        updated = Bin.objects.filter(pk=pk).update(upvotes=F("upvotes") + 1)
        if not updated:
            return Response({"detail": "Bin not found."}, status=status.HTTP_404_NOT_FOUND)
        bin_obj = Bin.objects.get(pk=pk)
        return Response({"id": bin_obj.pk, "upvotes": bin_obj.upvotes})


class TopContributorsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        users = User.objects.filter(submitted_bins__isnull=False).annotate(
            bins_count=Count("submitted_bins", distinct=True)
        ).order_by("-bins_count", "email")[:10]
        contributors = []
        for rank, user in enumerate(users, start=1):
            count = user.bins_count
            if count >= 100:
                title = "Guardian of the Grove"
            elif count >= 50:
                title = "Forest Steward"
            elif count >= 25:
                title = "Canopy Champion"
            elif count >= 10:
                title = "Green Guardian"
            elif count >= 5:
                title = "Nature Nurturer"
            else:
                title = "Seed Planter"
            contributors.append({
                "rank": rank,
                "user_id": user.pk,
                "display_name": user.username[:40],
                "bins_count": count,
                "title": title,
            })
        return Response({"count": len(contributors), "results": contributors})

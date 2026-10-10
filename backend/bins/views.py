from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import F
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
        email = str(request.data.get("email", "")).strip().lower()
        password = str(request.data.get("password", ""))
        if not email or "@" not in email:
            raise ValidationError({"email": "Enter a valid email address."})
        if len(password) < 8:
            raise ValidationError({"password": "Password must contain at least 8 characters."})
        if User.objects.filter(username__iexact=email).exists() or User.objects.filter(email__iexact=email).exists():
            raise ValidationError({"email": "An account with this email already exists."})
        try:
            validate_password(password)
        except DjangoValidationError as exc:
            raise ValidationError({"password": list(exc.messages)})

        user = User.objects.create_user(username=email, email=email, password=password)
        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {"token": token.key, "id": user.pk, "email": user.email},
            status=status.HTTP_201_CREATED,
        )


class LoginView(ObtainAuthToken):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, *args, **kwargs):
        data = request.data.copy()
        email = str(data.get("email", data.get("username", ""))).strip().lower()
        data["username"] = email
        serializer = self.serializer_class(data=data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "id": user.pk, "email": user.email})


class CurrentUserView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({"id": request.user.pk, "email": request.user.email})


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class BinListCreateView(generics.ListCreateAPIView):
    queryset = Bin.objects.select_related("added_by").all()
    serializer_class = BinSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        serializer.save(added_by=self.request.user if self.request.user.is_authenticated else None)


class BinDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Bin.objects.select_related("added_by").all()
    serializer_class = BinSerializer

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

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

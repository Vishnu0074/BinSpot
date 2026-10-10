from django.contrib import admin
from django.urls import include, path
from rest_framework.authtoken.views import obtain_auth_token
from bins.views import RegisterView, CurrentUserView, LogoutView, HealthView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthView.as_view(), name="health"),
    path("api/auth/register/", RegisterView.as_view(), name="register"),
    path("api/auth/login/", obtain_auth_token, name="login"),
    path("api/auth/logout/", LogoutView.as_view(), name="logout"),
    path("api/auth/me/", CurrentUserView.as_view(), name="current-user"),
    path("api/", include("bins.urls")),
]

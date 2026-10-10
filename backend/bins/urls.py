from django.urls import path
from .views import BinDetailView, BinListCreateView, BinUpvoteView

urlpatterns = [
    path("bins/", BinListCreateView.as_view(), name="bin-list-create"),
    path("bins/<int:pk>/", BinDetailView.as_view(), name="bin-detail"),
    path("bins/<int:pk>/upvote/", BinUpvoteView.as_view(), name="bin-upvote"),
]

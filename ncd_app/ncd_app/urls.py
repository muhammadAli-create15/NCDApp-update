from django.contrib import admin
from django.urls import path, include
try:
    from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
    _HAS_SPECTACULAR = True
except Exception:
    _HAS_SPECTACULAR = False

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
]

if _HAS_SPECTACULAR:
    urlpatterns += [
        path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
        path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    ]

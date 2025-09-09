from core.models import PatientProfile
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth.models import User
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from rest_framework_simplejwt.tokens import RefreshToken
from core.serializers import RegisterSerializer


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        data = request.data
        username = data.get("username")
        password = data.get("password")
        email = data.get("email")
        role = data.get("role", "patient")  # default to 'patient'

        # Required PatientProfile fields
        age = data.get("age")
        gender = data.get("gender")
        height_cm = data.get("height_cm")
        weight_kg = data.get("weight_kg")
        waist_cm = data.get("waist_cm")

        # Optional fields
        phone = data.get("phone", "")
        address = data.get("address", "")
        lifestyle = data.get("lifestyle", "")

        # Validate required fields
        missing_fields = [field for field in ["username", "password", "age", "gender", "height_cm", "weight_kg", "waist_cm"] if not data.get(field)]
        if missing_fields:
            return Response({"error": f"Missing required fields: {', '.join(missing_fields)}"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            validate_password(password)
        except ValidationError as e:
            return Response({"error": e.messages}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists():
            return Response({"error": "Username already exists"}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(username=username, password=password, email=email)

        PatientProfile.objects.create(
            user=user,
            role=role,
            age=age,
            gender=gender,
            height_cm=height_cm,
            weight_kg=weight_kg,
            waist_cm=waist_cm,
            phone=phone,
            address=address,
            lifestyle=lifestyle
        )

        # ✅ Role-based redirect logic
        if role == "patient":
            redirect_url = "/dashboard/patient/"
        elif role == "provider":
            redirect_url = "/dashboard/provider/"
        elif role == "worker":
            redirect_url = "/dashboard/worker/"
        else:
            redirect_url = "/dashboard/"

        return Response({
            "message": "User and profile created successfully",
            "role": role,
            "redirect": redirect_url
        }, status=status.HTTP_201_CREATED)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Logged out successfully"}, status=status.HTTP_205_RESET_CONTENT)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

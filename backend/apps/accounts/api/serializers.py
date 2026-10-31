from rest_framework import serializers


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=256, trim_whitespace=False)


class UserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()


class SessionSerializer(serializers.Serializer):

    user = UserSerializer()
    access_expires_at = serializers.DateTimeField(source="access.expires_at")
    refresh_expires_at = serializers.DateTimeField(allow_null=True)

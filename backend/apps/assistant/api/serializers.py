from rest_framework import serializers


class MessageInputSerializer(serializers.Serializer):
    text = serializers.CharField(max_length=2000, trim_whitespace=True)


class ConfirmationInputSerializer(serializers.Serializer):
    approve = serializers.BooleanField()

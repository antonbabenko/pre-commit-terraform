output "api_address" {
  value       = aws_api_gateway_stage.default_audit_stream.invoke_url
  description = "Invoke URL for the API"
}

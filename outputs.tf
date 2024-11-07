output "public_IP" {
  description = "Public IP Address of Web-Server"
  value       = aws_instance.web.public_ip
}
output "tags" {
  description = "Tags"
  value       = aws_instance.web.tags_all
}
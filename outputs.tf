output "ec2_public_ip" {
  description = "Endereço IP público da instancia EC2"
  value       = aws_instance.debian_ec2.public_ip
}
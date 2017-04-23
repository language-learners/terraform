# Our public IP address.
output "ip" {
  description = "The static public IP address for our server."
  value = "${aws_eip.server.public_ip}"
}

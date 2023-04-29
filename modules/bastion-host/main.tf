resource "aws_security_group" "bastion-sg" {

}

resource "aws_instance" "bastion-host" {
  ami             = "ami-005e54dee72cc1d00" # us-west-2
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.bastion-sg]
  #   network_interface {
  #     network_interface_id = aws_network_interface.foo.id
  #     device_index         = 0
  #   }

  #   credit_specification {
  #     cpu_credits = "unlimited"
  #   }
}

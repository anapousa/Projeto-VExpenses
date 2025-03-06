# Projeto-VExpenses
## Descrição técnica sobre o código modelo

### Provedor AWS
Define a região onde os recursos serão criados na AWS.

```hcl
provider "aws" {
  region = "us-east-1"
}
```
---

### Geração de Chave Privada
Gera uma chave privada segura e a codifica nos formatos PEM e OpenSSH. Este recurso é destinado principalmente para bootstrapping fácil de ambientes de desenvolvimento descartáveis.

```hcl
resource "tls_private_key" "ec2_key" {
 algorithm = "RSA"
 rsa_bits  = 2048
}
```
#### Parâmetros:

- `algorithm`: Nome do algoritmo a ser usado ao gerar a chave privada.  
  - Valores suportados: `RSA`, `ECDSA`, `ED25519`.

- `rsa_bits`: Quando `algorithm` é `RSA`, define o tamanho da chave RSA gerada, em bits.  
  - Padrão: `2048`.

---

### VPC (Virtual Private Cloud)
Cria uma VPC para organizar os recursos da infraestrutura.

```hcl
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}
```
#### Parâmetros:
- `cidr_block`: Define um bloco de endereçamento IPv4 para a VPC.
- `enable_dns_support`: Um sinalizador booleano para habilitar/desabilitar o suporte a DNS na VPC. O padrão é `true`.
- `enable_dns_hostnames`: Um sinalizador booleano para habilitar/desabilitar nomes de host DNS na VPC. O padrão é `false`.

---

### Sub-Rede
Cria uma sub-rede dentro da VPC.

```hcl
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}
```

---

### Gateway de Internet
Cria um Internet Gateway para permitir comunicação da VPC com a Internet.

```hcl
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}
```

---

### Tabela de Roteamento
Cria uma tabela de roteamento associada à VPC.

```hcl
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}
```

---

### Associação da Tabela de Rotas
Associa a tabela de rotas à sub-rede para permitir o tráfego adequado.

```hcl
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}
```

---

### Grupo de Segurança
Cria um grupo de segurança para controlar tráfego de entrada e saída.
Na configuração atual, permite conexão de qualquer IP.

```hcl
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}
```

---

### Seleção de AMI (Imagem de Máquina)
Busca a AMI mais recente do Debian 12.

```hcl
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}
```

---

### Instância EC2
Cria uma instância EC2 Debian 12.

```hcl
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}
```

---

### Saídas
Captura os valores da chave privada e do endereço de IP público da instância EC2.
```hcl
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
```

## Relatório de Correções e Mudanças Implementadas no Arquivo main.tf

### Pré-requisitos para Execução

Os pré-requisitos para execução do código no Terraform são:

- Ter uma conta na AWS.
- Ter configurado o AWS CLI.
- Ter acesso ao AMI Debian 12 via AWS Marketplace para conseguir vincular a imagem à instância. 

**Obs:** Caso não tenha, a criação da instância irá retornar um erro durante a execução do comando `Terraform Apply`.

### Reestruturação do Código

#### Reorganização dos Arquivos

O primeiro passo foi reorganizar a divisão do código para que ele esteja estruturado de maneira mais clara e concisa. As mudanças foram:

- Criação do arquivo `variables.tf`, que armazena todas as variáveis do código.
- Criação do arquivo `providers.tf`, para guardar informações referente ao provedor.
- Criação do arquivo `network.tf`, onde foi adicionado o código de criação de recursos de rede (VPC, Subnet, IGW, Route Table, SG).
- Criação do arquivo `keyfiles.tf`, na qual foram armazenadas as configurações referentes à chave.
- Criação do arquivo `ec2.tf`, contendo as configurações referentes à instância EC2.
- Criação do arquivo `outputs.tf`, para armazenar os códigos de saída.

#### Mudanças

A primeira mudança foi em relação ao armazenamento das chaves. Para habilitar acesso seguro aos recursos da AWS, foi gerado um par de chaves SSH. Este par de chaves será usado para acessar a instância EC2 com segurança.

```hcl
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${var.projeto}-${var.candidato}-key.pem"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "terraform_rsa.pub"
}
```

Em seguida, foi gerado um par de chaves AWS usando a chave SSH pública. Este recurso carrega a chave pública para a AWS, permitindo acessar com segurança a instância do EC2 usando a chave privada correspondente.

Como medida de segurança, o acesso ao ssh, porta 22, foi configurado para ser liberado apenas para o IP do computador usado para realizar este desafio, ao invés de ter acesso público. No contexto da empresa, uma medida de segurança eficaz é manter o acesso à instância liberado somente para usuários (IP’s) específicos. 

Outra medida tomada foi a mudança no trecho de código `security_groups = [aws_security_group.main_sg.name]` para `vpc_security_group_ids = [aws_security_group.main_sg.id]`, pois vpc_security_group_ids permite utilizar o ID do grupo de segurança, que é único dentro da conta AWS e também uma prática melhor recomendada pela AWS. 

Além disso, foi adicionado o seguinte trecho de código:

```hcl
  depends_on = [
        aws_security_group.main_sg,
        aws_internet_gateway.main_igw
  ]

```

O atributo `depends_on` garante que a criação da instância aguarde até que o grupo de segurança e o gateway de internet estejam configurados corretamente, garantindo que a instância possa se comunicar corretamente com a internet.

Por fim, o `output “private_key”` foi removido para evitar a visualização forçada do conteúdo da chave.

#### Instalação do Servidor NGINX 
Os comandos abaixo foram utilizados para instalação do servidor NGINX.
```hcl
#!/bin/bash
apt-get update -y
apt-get upgrade -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
EOF
```

Como o script user_data é executado como root, `sudo` não é necessário.

## Execução
Segue abaixo os comandos que devem ser executados para criar a instância EC2 e instalar o servidor Nginx com os devidos recursos.
```hcl
terraform init
terraform plan
terraform apply
```
Após a execução desses três comandos, o comando `chmod 400 nome_da_chave_privada` deve ser executado para garantir que a chave não fique visível publicamente. Por fim, deve ser executado o comando exibido no console pela AWS para conectar à instância por meio do SSH. 

Para encerrar todos os recursos, deve ser utilizado o comando `terraform destroy`.

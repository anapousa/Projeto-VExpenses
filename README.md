# Projeto-VExpenses
## Descrição técnica sobre o código modelo

### Provedor AWS
Define a região onde os recursos serão criados na AWS.

```hcl
provider "aws" {
  region = "us-east-1"
}
```
### Geração de Chave Privada
Gera uma chave privada segura e a codifica nos formatos PEM e OpenSSH. Este recurso é destinado principalmente para bootstrapping fácil de ambientes de desenvolvimento descartáveis.

```hcl
resource "tls_private_key" "ec2_key" {
 algorithm = "RSA"
 rsa_bits  = 2048
}
```
#### Parâmetros:

- **`algorithm` (String)**: Nome do algoritmo a ser usado ao gerar a chave privada.  
  - Valores suportados: `RSA`, `ECDSA`, `ED25519`.

- **`rsa_bits` (Número)**: Quando `algorithm` é `RSA`, define o tamanho da chave RSA gerada, em bits.  
  - Padrão: `2048`.

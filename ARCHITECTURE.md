# lambda-sqs-stack — Documentação de Arquitetura

## Visão Geral

Esta stack provisiona uma **AWS Lambda function** em Python 3.12 acionada por uma fila **SQS** via event source mapping. A função recebe mensagens em lotes, processa cada registro e interage com um bucket **S3** para leitura, escrita e exclusão de objetos. A stack não cria a fila SQS nem o bucket S3 — ela os consome como entradas vindas dos outputs das stacks `sqs-stack` e `s3-bucket-stack` respectivamente.

---

## Diagrama ASCII do fluxo

```
  ┌─────────────────────┐
  │   sqs-stack         │
  │  (fila SQS)         │
  └──────────┬──────────┘
             │  SQS trigger
             │  (event source mapping)
             ▼
  ┌─────────────────────┐        ┌─────────────────────┐
  │  Lambda Processor   │───────▶│   s3-bucket-stack   │
  │  (python3.12)       │  S3    │  (bucket S3)        │
  │  ReportBatchItem    │  API   │  GetObject          │
  │  Failures           │        │  PutObject          │
  └─────────────────────┘        │  DeleteObject       │
             │                   └─────────────────────┘
             │  CloudWatch Logs
             ▼
  ┌─────────────────────┐
  │  CloudWatch Logs    │
  │  /aws/lambda/       │
  │  {project}-{env}-   │
  │  processor          │
  └─────────────────────┘
```

---

## Recursos criados

| Recurso Terraform | Tipo AWS | Descrição |
|---|---|---|
| `aws_lambda_function.this` | `AWS::Lambda::Function` | Função Lambda Python 3.12 que processa mensagens SQS |
| `aws_lambda_event_source_mapping.this` | `AWS::Lambda::EventSourceMapping` | Mapeamento SQS → Lambda com suporte a partial batch failure |
| `aws_iam_role.this` | `AWS::IAM::Role` | Role de execução da Lambda com trust policy para `lambda.amazonaws.com` |
| `aws_iam_role_policy_attachment.basic_execution` | `AWS::IAM::ManagedPolicy` | Anexa `AWSLambdaBasicExecutionRole` para permissão de escrita em CloudWatch Logs |
| `aws_iam_role_policy.sqs_consumer` | `AWS::IAM::RolePolicy` | Policy inline: `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` |
| `aws_iam_role_policy.s3_readwrite` | `AWS::IAM::RolePolicy` | Policy inline: `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` no bucket alvo |
| `aws_cloudwatch_log_group.this` | `AWS::Logs::LogGroup` | Log group `/aws/lambda/{project}-{env}-processor` com retenção configurável |

---

## Variáveis de entrada

| Variável | Tipo | Default | Descrição |
|---|---|---|---|
| `project_name` | `string` | — | Nome do projeto, usado como prefixo nos recursos |
| `environment` | `string` | — | Ambiente (`dev`, `staging`, `prod`) |
| `aws_region` | `string` | — | Região AWS para deploy dos recursos |
| `sqs_queue_arn` | `string` | — | ARN da fila SQS (output `this_sqs_queue_arn` da sqs-stack) |
| `s3_bucket_arn` | `string` | — | ARN do bucket S3 (output `this_s3_bucket_arn` da s3-bucket-stack) |
| `lambda_handler` | `string` | `handler.lambda_handler` | Handler da Lambda no formato `arquivo.funcao` |
| `lambda_timeout` | `number` | `60` | Timeout máximo em segundos (1–900) |
| `lambda_memory_size` | `number` | `128` | Memória alocada em MB (128–10240) |
| `log_retention_days` | `number` | `14` | Retenção dos logs em dias no CloudWatch |
| `app_log_level` | `string` | `INFO` | Nível de log injetado via env var `LOG_LEVEL` (`DEBUG`, `INFO`, `WARN`, `ERROR`) |
| `batch_size` | `number` | `10` | Número máximo de mensagens SQS por invocação (1–10000) |
| `maximum_batching_window_in_seconds` | `number` | `5` | Janela de agrupamento de mensagens em segundos (0–300) |
| `lambda_role_permissions_boundary` | `string` | `null` | ARN de permissions boundary IAM (opcional) |
| `tags` | `map(string)` | `{}` | Tags adicionais a mesclar em todos os recursos |

---

## Outputs

| Output | Descrição |
|---|---|
| `this_lambda_function_arn` | ARN da função Lambda criada |
| `this_lambda_function_name` | Nome da função Lambda criada |
| `this_iam_role_arn` | ARN da role de execução IAM da Lambda |
| `this_log_group_name` | Nome do CloudWatch Log Group |
| `this_event_source_mapping_uuid` | UUID do event source mapping SQS → Lambda |

---

## Como usar

### Pré-requisitos

1. Bucket S3 de state Terraform configurado (`my-terraform-state`).
2. Tabela DynamoDB de lock configurada (`terraform-state-lock`).
3. Credenciais AWS válidas exportadas (`AWS_PROFILE` ou `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`).
4. Outputs `this_sqs_queue_arn` e `this_s3_bucket_arn` coletados das stacks dependentes.

### Inicialização

```bash
cd lambda-sqs-stack/

terraform init
```

### Planejamento por ambiente

```bash
# dev
terraform plan -var-file="environments/dev.tfvars"

# staging
terraform plan -var-file="environments/staging.tfvars"

# prod
terraform plan -var-file="environments/prod.tfvars"
```

### Apply por ambiente

```bash
# dev
terraform apply -var-file="environments/dev.tfvars"

# staging
terraform apply -var-file="environments/staging.tfvars"

# prod
terraform apply -var-file="environments/prod.tfvars"
```

### Destroy

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

---

## Dependências com outras stacks

| Stack | Output consumido | Variável nesta stack |
|---|---|---|
| `sqs-stack` | `this_sqs_queue_arn` | `sqs_queue_arn` |
| `s3-bucket-stack` | `this_s3_bucket_arn` | `s3_bucket_arn` |

Ambas as stacks devem ser aplicadas antes desta. A fila SQS e o bucket S3 devem existir na mesma conta e região AWS.

---

## Boas práticas implementadas

### Partial Batch Failure (ReportBatchItemFailures)

O event source mapping está configurado com `function_response_types = ["ReportBatchItemFailures"]`. Isso permite que a Lambda retorne somente os `messageId` que falharam no processamento, em vez de falhar o lote inteiro. Mensagens bem-sucedidas são removidas da fila automaticamente; apenas as falhas são recolocadas para reprocessamento.

### Princípio do menor privilégio (IAM)

As permissões IAM são separadas em policies inline distintas por responsabilidade:
- `sqs_consumer`: acesso exclusivo à fila SQS informada via ARN.
- `s3_readwrite`: acesso exclusivo ao bucket S3 informado via ARN, restrito ao path `/*`.
- `AWSLambdaBasicExecutionRole`: gerenciada pela AWS, permite apenas escrita em CloudWatch Logs.

Nenhuma permissão wildcard (`*`) é utilizada em `resources`.

### Tags obrigatórias via `default_tags`

O provider AWS está configurado com `default_tags`, garantindo que todos os recursos recebam automaticamente as tags `Project`, `Environment`, `ManagedBy` e `Stack`, além das tags adicionais informadas via variável `tags`.

### Empacotamento determinístico do código

O `archive_file` data source empacota o `src/handler.py` localmente e expõe o `output_base64sha256`, garantindo que a Lambda só seja republicada quando o código-fonte mudar.

### CloudWatch Log Group provisionado via Terraform

O log group é criado pelo Terraform com retenção configurável antes da criação da Lambda, evitando que a AWS crie um log group sem retenção definida no primeiro deploy.

---

## Checklist de validação

```bash
# Formatação
terraform fmt -recursive -check

# Validação de sintaxe
terraform validate

# Linting
tflint --init && tflint

# Análise de segurança (escolher um)
tfsec .
# ou
checkov -d . --framework terraform
```

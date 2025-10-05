# Script de Deploy com Versionamento - BIA

## Uso do Script

```bash
./deploy-com-ia.sh <cluster-name> <service-name>
```

## Exemplos

### Deploy para cluster sem ALB
```bash
./deploy-com-ia.sh cluster-bia service-bia
```

### Deploy para cluster com ALB
```bash
./deploy-com-ia.sh cluster-bia-alb service-bia-alb
```

## O que o Script Faz

1. **Obtém commit hash** (7 dígitos) do Git atual
2. **Faz login no ECR** usando AWS CLI
3. **Constrói imagem Docker** com tag do commit
4. **Envia imagem para ECR** com versionamento
5. **Atualiza task definition** com nova imagem
6. **Atualiza service ECS** com nova task definition
7. **Aguarda deployment** ser concluído

## Versionamento

- **Tag da imagem:** Commit hash de 7 dígitos (ex: `a1b2c3d`)
- **Rastreabilidade:** Cada deploy é vinculado a um commit específico
- **Rollback:** Possível usando commit hash anterior

## Pré-requisitos

- Git repository inicializado
- AWS CLI configurado
- Docker instalado
- Permissões IAM para ECR e ECS
- `jq` instalado (para manipular JSON)

## Troubleshooting

### Erro de permissão ECR
```bash
aws ecr get-login-password --region us-east-1
```

### Verificar service ECS
```bash
aws ecs describe-services --cluster <cluster-name> --services <service-name>
```

### Verificar task definition
```bash
aws ecs describe-task-definition --task-definition <task-def-arn>
```

#!/bin/bash

# Script de Deploy com Versionamento - Projeto BIA
# Uso: ./deploy-com-ia.sh <cluster-name> <service-name>

set -e

# Validação de parâmetros
if [ $# -ne 2 ]; then
    echo "Uso: $0 <cluster-name> <service-name>"
    echo "Exemplo: $0 cluster-bia service-bia"
    exit 1
fi

CLUSTER_NAME=$1
SERVICE_NAME=$2
REGION="us-east-1"
ECR_REPOSITORY="908027418851.dkr.ecr.us-east-1.amazonaws.com/bia"

# Obter commit hash (7 dígitos)
COMMIT_HASH=$(git rev-parse --short=7 HEAD)
IMAGE_TAG=$COMMIT_HASH

echo "=== Deploy BIA com Versionamento ==="
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Commit Hash: $COMMIT_HASH"
echo "Image Tag: $IMAGE_TAG"
echo "=================================="

# Login no ECR
echo "Fazendo login no ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY

# Build da imagem
echo "Construindo imagem Docker..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Push para ECR
echo "Enviando imagem para ECR..."
docker push $ECR_REPOSITORY:$IMAGE_TAG

# Obter task definition atual
echo "Obtendo task definition atual..."
TASK_DEF_ARN=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].taskDefinition' --output text)
TASK_DEF_FAMILY=$(aws ecs describe-task-definition --task-definition $TASK_DEF_ARN --query 'taskDefinition.family' --output text)

# Criar nova task definition
echo "Criando nova task definition..."
aws ecs describe-task-definition --task-definition $TASK_DEF_ARN --query 'taskDefinition' > task-def.json

# Atualizar imagem na task definition
jq --arg image "$ECR_REPOSITORY:$IMAGE_TAG" '.containerDefinitions[0].image = $image | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)' task-def.json > new-task-def.json

# Registrar nova task definition
NEW_TASK_DEF=$(aws ecs register-task-definition --cli-input-json file://new-task-def.json --query 'taskDefinition.taskDefinitionArn' --output text)

# Atualizar service
echo "Atualizando service ECS..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $NEW_TASK_DEF

# Aguardar deployment
echo "Aguardando deployment..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME

# Limpeza
rm -f task-def.json new-task-def.json

echo "=== Deploy Concluído ==="
echo "Nova versão: $IMAGE_TAG"
echo "Task Definition: $NEW_TASK_DEF"
echo "======================="

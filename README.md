# Docker Mobile Admin

Projeto MVP para a disciplina de Desenvolvimento Mobile.

O objetivo e criar um aplicativo Flutter simples que consome uma API Dart para listar e controlar containers do Docker Desktop rodando localmente no Windows 11.

## Escopo do MVP

- Login simples no aplicativo mobile.
- Consumo de API com token JWT.
- Listagem de containers Docker com nome, imagem e status.
- Acoes basicas: Start, Stop e Restart.
- Backend local em Dart usando Docker Desktop via `localhost:2375`.

## Fora do escopo inicial

- Dashboard de CPU/memoria.
- Logs em tempo real.
- Build iOS nativa.
- Publicacao em loja.
- Docker remoto com TLS.

Esses itens podem virar extras apenas depois do MVP principal estar validado.

## Estrutura do projeto

```text
Docker Mobile/
  backend/   API Dart
  mobile/    Aplicativo Flutter
  docs/      Documentacao auxiliar
```

## Regra de desenvolvimento

O projeto sera construido por etapas. Cada etapa deve ser testada, validada e registrada no Obsidian antes de avancar para a proxima.

## Backend Dart

O backend fica em `backend/` e usa Dart com `shelf`.

Comandos usados nesta maquina:

```powershell
cd "C:\Users\Miguel\Desktop\PROGRAMACAO\Docker Mobile\backend"
dart pub get
dart analyze
dart run bin/server.dart
```

Endpoint validado:

```text
GET http://localhost:3000/health
```

Resposta esperada:

```json
{"status":"ok","service":"docker-mobile-backend","runtime":"dart"}
```

Endpoint implementado para o Passo 2:

```text
GET http://localhost:3000/containers
```

Enquanto o Docker Desktop nao estiver respondendo em `localhost:2375`, a resposta esperada e:

```json
{"error":"docker_unavailable","message":"..."}
```

## Status atual

- Passo 0: Preparacao do projeto validada.
- Passo 1: Backend Dart basico validado.
- Passo 2: Conexao com Docker Desktop validada com `GET /containers` retornando containers reais.
- Proximo passo: iniciar Passo 3, autenticacao JWT.


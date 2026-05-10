# Docker Mobile Admin

Projeto MVP para a disciplina de Desenvolvimento Mobile.

O objetivo e criar um aplicativo Flutter simples que consome uma API NestJS para listar e controlar containers do Docker Desktop rodando localmente no Windows 11.

## Escopo do MVP

- Login simples no aplicativo mobile.
- Consumo de API com token JWT.
- Listagem de containers Docker com nome, imagem e status.
- Acoes basicas: Start, Stop e Restart.
- Backend local em NestJS usando Docker Desktop via `localhost:2375`.

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
  backend/   API NestJS
  mobile/    Aplicativo Flutter
  docs/      Documentacao auxiliar
```

## Regra de desenvolvimento

O projeto sera construido por etapas. Cada etapa deve ser testada, validada e registrada no Obsidian antes de avancar para a proxima.

## Backend

O backend fica em `backend/` e usa NestJS.

Comandos usados nesta maquina:

```powershell
cd "C:\Users\Miguel\Desktop\PROGRAMACAO\Docker Mobile\backend"
& "..\.tools\node-v22.22.0-win-x64\npm.cmd" install
& "..\.tools\node-v22.22.0-win-x64\npm.cmd" run build
& "..\.tools\node-v22.22.0-win-x64\npm.cmd" run start
```

Endpoint validado:

```text
GET http://localhost:3000/health
```

Resposta esperada:

```json
{"status":"ok","service":"docker-mobile-backend"}
```

## Status atual

- Passo 0: Preparacao do projeto validada.
- Passo 1: Backend NestJS basico validado.
- Passo 2: Bloqueado aguardando Docker Desktop responder na porta `2375`.
- Proximo passo: configurar Docker Desktop seguindo `docs/docker-desktop-setup.md`.

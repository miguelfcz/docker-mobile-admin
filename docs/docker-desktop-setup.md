# Configuracao do Docker Desktop para o MVP

Este projeto precisa que o backend Dart consiga conversar com o Docker Desktop local.

## Validacao atual

Comandos usados:

```powershell
docker --version
docker ps
Test-NetConnection -ComputerName 127.0.0.1 -Port 2375
```

Resultado encontrado em 2026-05-08:

- Docker CLI instalado: `Docker version 28.4.0`.
- Docker daemon nao respondeu ao `docker ps`.
- Porta `2375` fechada.

## Como liberar a porta 2375

1. Abrir o Docker Desktop.
2. Ir em Settings.
3. Ir em General.
4. Ativar a opcao:

```text
Expose daemon on tcp://localhost:2375 without TLS
```

5. Aplicar e reiniciar o Docker Desktop, se ele pedir.
6. Testar novamente:

```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 2375
docker ps
```

## Resultado esperado

```text
TcpTestSucceeded : True
```

E o comando `docker ps` deve listar containers ou mostrar uma lista vazia sem erro de conexao.

## Observacao de seguranca

A porta `2375` sem TLS e uma decisao apenas para desenvolvimento local e apresentacao academica. Nao usar como configuracao de producao.

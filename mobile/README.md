# Docker Mobile App

Aplicativo Flutter do Docker Mobile Admin.

## Status

Base inicial criada, login validado e listagem de containers implementada ate o Passo 7.

## Comandos validados

```powershell
flutter analyze
flutter test
flutter build web
```

Para testar o login visualmente, deixe o backend rodando em `http://localhost:3000` e execute:

```powershell
flutter run -d chrome
```

Credenciais padrao de desenvolvimento:

```text
usuario: admin
senha: admin
```

Depois do login, o app busca `GET /containers` usando o token JWT e mostra nome, imagem, estado e status dos containers.

A validacao final do Passo 7 depende do Docker Desktop aberto e da porta `2375` habilitada.

# Docker Mobile App

Aplicativo Flutter do Docker Mobile Admin.

## Status

Base inicial criada e login validado ate o Passo 6.

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

O proximo passo do projeto e listar os containers no app usando o token JWT.

# Mapa de Coleta Sustentável

Aplicativo Flutter desenvolvido para o TCC **Mapa de Coleta Sustentável**, com foco em Teresina/PI.

### Plataformas disponíveis

A versão web permite acessar o aplicativo pelo navegador em computadores, tablets e smartphones, incluindo dispositivos iOS sem necessidade de instalação.
- **Versão Web:** [Acessar o Mapa de Coleta Sustentável](https://viroshi.github.io/mapa-de-coleta-sustentavel/)

Atualmente, a versão instalável está disponível exclusivamente para **Android**, por meio de um arquivo APK publicado na seção Releases do repositório.
- **Versão Android:** [Baixar o aplicativo pela seção Releases](https://github.com/Viroshi/mapa-de-coleta-sustentavel/releases)

Para instalar o aplicativo no Android, baixe o arquivo `.apk` da versão mais recente. Durante a instalação, o Google Play Protect poderá solicitar uma verificação de segurança, basta clicar em "verificar App" e após a validação do Google Play Protect poderá dar continuidade a instalação.

## Funcionalidades previstas no TCC

O projeto implementa o fluxo definido no trabalho:

- mapa interativo com pontos de coleta em Teresina;
- localização do usuário e ordenação dos pontos por proximidade;
- filtros para eletrônicos, pilhas, baterias e óleo de cozinha;
- busca textual de pontos de coleta;
- detalhes do ponto com endereço, horário, contato e resíduos aceitos;
- cálculo de rota até o ponto e abertura de navegação externa;
- sugestão de novos pontos pelo usuário comum;
- login de administrador/empresa autorizada;
- validação ou rejeição de sugestões;
- cadastro, edição e exclusão de pontos pelo painel administrativo;
- armazenamento dos dados administráveis no Cloud Firestore.

## Fontes dos pontos exibidos no mapa

O mapa combina três fontes, sem desativar uma delas quando o Firebase está configurado:

1. **Cloud Firestore**: pontos cadastrados/validados no próprio aplicativo;
2. **base local revisada**: pontos de referência já incluídos no projeto;
3. **OpenStreetMap/Overpass**: pontos públicos compatíveis com os resíduos previstos no TCC.

Quando duas fontes trazem o mesmo ponto com o mesmo nome e coordenadas próximas, o aplicativo evita a duplicação. Pontos do Firebase têm prioridade por serem os registros administrados pelo sistema.

## Preparação do projeto

Na raiz do projeto:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

## Firebase

O projeto está preparado para a configuração oficial do FlutterFire. A configuração gerada fica em:

```text
lib/firebase_options.dart
```

Caso seja necessário gerar novamente:

```bash
firebase login
flutterfire configure
```

No Firebase Console, habilite:

1. **Cloud Firestore**;
2. **Authentication > Email/Password**.

### Estrutura do Firestore

#### `pontos_coleta`

Campos usados pelo aplicativo:

- `nome`
- `descricao`
- `endereco`
- `latitude`
- `longitude`
- `horarioFuncionamento`
- `telefone`
- `materiaisAceitos` (lista)
- `tipo`
- `status` (`validado`)
- `dataCadastro`
- `atualizadoEm`
- `fonte`

#### `sugestoes`

Usa os mesmos dados básicos do ponto, com `status` inicialmente igual a `pendente`. Ao ser validada, a sugestão gera um documento em `pontos_coleta`.

#### `usuarios`

O ID do documento deve ser exatamente o UID do usuário criado no Firebase Authentication.

Para administrador:

```text
tipoUsuario: administrador
```

Para empresa autorizada:

```text
tipoUsuario: empresa
```

A coleção deve se chamar **`usuarios`**, no plural.

## Regras do Firestore

O arquivo `firestore.rules` contém as regras usadas pelo fluxo do aplicativo. Depois de alterar esse arquivo, publique as regras no Firebase Console ou, com o Firebase CLI configurado, execute:

```bash
firebase deploy --only firestore:rules
```

## Atualização do mapa

Ao voltar para a aba **Mapa**, os pontos são consultados novamente. Dessa forma, um ponto recém-validado pelo painel administrativo aparece sem ser necessário reiniciar o aplicativo.

## Testes

Os testes existentes verificam os modelos principais. Execute:

```bash
flutter test
```

O ambiente onde este pacote foi preparado não possui Flutter/Dart instalado; portanto, a validação final de compilação deve ser executada na máquina de desenvolvimento com os comandos acima.

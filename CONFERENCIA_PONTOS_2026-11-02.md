# Conferência documental dos pontos de coleta — 02/11/2026

Esta conferência acompanha a atualização do formulário do aplicativo. **Não representa
vistoria presencial, telefonema ou confirmação de funcionamento em tempo real.**
Nenhuma informação foi inventada, e os nove pontos da base local foram preservados.

## Resultado por fonte

- **Pão de Açúcar — Jóquei Clube; TIM — Av. Frei Serafim; Vivo — Av. Frei
  Serafim; Vivo — Riverside; Santander — Av. João XXIII:** constam na lista
  pública do TRE-PI / TRECiclar, com os tipos de material registrados no projeto.
  Entre esses cinco estabelecimentos, o TRE-PI só informa telefone para a TIM;
  não informa horários de recebimento. Como a lista não apresenta uma data de
  verificação operacional atual, ela **não confirma o atendimento em 2026**.
- **Águas de Teresina — ETA Sul, Loja Parque Piauí, ETE Leste e Sede:** constam
  no informativo institucional referente a outubro, novembro e dezembro de 2022,
  para óleo de cozinha, pilhas e baterias. A divulgação também mencionava uma
  unidade no Dirceu, **não adicionada** porque sua operação como ponto de coleta
  ainda precisa de confirmação atual. Não há horários ou telefones específicos
  para os coletores no informativo.
- **Loja Parque Piauí:** a página atual de contato da Águas de Teresina
  divulga o horário de atendimento da **loja** (segunda a sexta, 8h–17h) e o
  telefone geral da concessionária (0800 223 2000). Isso não é prova de que o
  **coletor de resíduos** esteja acessível durante todo esse período. Por esse
  motivo, os campos de horário e telefone do ponto de coleta foram mantidos
  sem preenchimento automático.

## Fontes públicas consultadas

1. TRE-PI — Relação de locais para coleta e reciclagem de lixo:
   https://www.tre-pi.jus.br/institucional/projetos-sociais/treciclar/relacao-de-locais-para-coleta-e-reciclagem-de-lixo
2. Águas de Teresina — Informativo trimestral out./nov./dez. 2022:
   https://www.aguasdeteresina.com.br/wp-content/uploads/2023/01/Informativo-Ou-Nov-Dez.pdf
3. Águas de Teresina — Contato, horários de lojas e atendimento geral:
   https://www.aguasdeteresina.com.br/contato/

## O que foi alterado no aplicativo

- Os campos **Horário de funcionamento** e **Contato** não bloqueiam mais
  uma sugestão ou cadastro quando não se conhece a informação.
- Os campos exibem a indicação **(opcional)** e a orientação de deixar em
  branco caso a informação seja desconhecida.
- O painel administrativo passa a mostrar **Não informado** em sugestões com
  esses campos vazios, evitando linhas em branco.
- Foi adicionado um teste automatizado para o envio sem esses campos, mais um
  teste que preserva a obrigatoriedade dos dados essenciais.
- Não foram alterados nomes, coordenadas, endereços ou materiais aceitos dos
  pontos da base local. Não houve alteração em autenticação, Firestore ou rotas.

## Verificação recomendada ao responsável pela base

Antes de considerar os pontos confirmados para 2026, contatar os
estabelecimentos e perguntar **se recebem atualmente os resíduos indicados**,
**qual é o horário de acesso ao coletor** e **se existe telefone específico**.
Registrar a data da resposta; o horário geral de funcionamento de uma loja não
precisa coincidir com a disponibilidade de um coletor.

## Testes do projeto

Executar, em uma máquina com Flutter/Dart instalados:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Não foi possível executar esses comandos neste ambiente, porque o SDK Flutter/Dart
não está instalado. O teste automatizado foi incluído para execução posterior.

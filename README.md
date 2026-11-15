# Pet Shop Fila Zero — App do Tutor (Flutter)

Trabalho Integrador da Uninove, feito em grupo, que junta três disciplinas:

- **Computação Móvel**: app Mobile em Flutter/Dart (este projeto)
- **Programação para Banco de Dados**: banco MySQL
- **Aplicações Orientadas a Objetos**: sistema Web em Java (JSP e Servlets)

Este é o app do **tutor** (dono do pet), do módulo de **Filas**. Pelo app, o tutor cria a conta, cadastra os pets, agenda serviços, paga e acompanha a senha na fila. A parte administrativa (chamar o próximo, colocar quem chegou sem agendar na fila, finalizar o atendimento) fica no sistema Java Web.

```
App Flutter  ⇄  API do sistema Java  ⇄  Banco MySQL
```

O app **não acessa o banco direto**. Ele conversa com a API do Java, e o Java acessa o MySQL.

---

## Como rodar no VS Code

1. Abra o VS Code em **File > Open Folder…** e escolha a pasta do projeto.
2. Abra o terminal: **Terminal > New Terminal**.
3. Na primeira vez, rode um comando por vez:

   ```
   flutter create .
   flutter pub get
   ```

4. Para rodar:

   ```
   flutter run -d chrome
   ```

- `r` no terminal recarrega o app, e `q` encerra.
- Para conferir se há erros no código: `flutter analyze`
- Para rodar o teste: `flutter test`

### Modo demonstração x API Java

O modo fica no arquivo `lib/config.dart`:

```dart
static const bool usarApi = false;                              // false = demonstração
static const String urlApi = 'http://localhost:8080/petshop/api'; // endereço da API Java
```

- **`usarApi = false`**: usa os dados do banco do grupo, mas guardados na memória. Não precisa de servidor, e tudo volta ao início quando o app recarrega. Login de teste: **MJ / 12345** (Maria Jane).
- **`usarApi = true`**: usa a API do sistema Java. Ajuste o `urlApi` para o endereço do Tomcat.

---

## Como o app funciona

1. **Login / Cadastro.** O tutor entra com **usuário ou e-mail** e senha. O cadastro pede CPF, nome, telefone, endereço, e-mail, usuário e senha (tabela `tutor`).
2. Depois do login, o app tem 5 abas:

| Aba | O que faz | Tabelas |
|---|---|---|
| **Início** | Mostra os serviços para agendar, a lista de agendamentos (com opção de cancelar) e o aviso sobre o atendimento presencial. | `servico`, `agenda` |
| **Pets** | Cadastrar, editar e excluir pets. | `pet`, `tutela` |
| **Pagamentos** | Pagar os agendamentos com PIX, cartão ou boleto. Mostra também os pagos e os cancelados (**Estornado** se já tinha sido pago, **Cancelado** se foi cancelado antes de pagar). | `agenda`, `fila_atendimento` |
| **Senha** | Mostra a senha, a posição na fila e a espera estimada. Depois que o atendimento é finalizado, o tutor pode avaliar. | `fila_atendimento`, `avaliacao` |
| **Painel** | A mesma tela da TV da recepção: senha atual, próximas senhas e horários marcados de hoje. Atualiza sozinho a cada 15 segundos. | `fila_atendimento` |

No ícone de perfil (canto superior direito), o tutor edita o próprio cadastro.

### Regras da fila

O funcionamento é igual ao de um cabeleireiro:

- **Agendado (senha A001, A002…):** depois de pagar, o pet ganha um lugar na fila para o horário marcado. Quando chega o horário, ele entra **na frente** da fila.
- **Presencial (senha P001, P002…):** quem não agendou vai ao pet shop e pega a senha na recepção, pelo sistema Web. O atendimento é por **ordem de chegada**.
- A senha é formada pela letra + o `id_atendimento` da tabela `fila_atendimento`.
- A espera estimada considera 20 minutos por atendimento.

### Outras regras

- Agendamento de segunda a sábado, das 9h às 17h (sem 12h), nos próximos 7 dias.
- Não dá para marcar um horário que já passou, um horário em que o mesmo serviço já está marcado, nem o mesmo pet duas vezes no mesmo horário.
- Cada agendamento é de **um serviço** (uma linha na tabela `agenda`).
- O agendamento nasce como "Aguardando pagamento" e só vira "Agendado" depois de pago.
- Boleto só para agendamentos com 2 dias ou mais de antecedência.
- Os pagamentos são simulados. Os dados do cartão não são enviados nem salvos.
- Não dá para excluir um pet que tem agendamento ativo.
- Cancelar um agendamento já pago mostra o pagamento como **Estornado**. O app sabe que foi pago porque existe a senha dele na `fila_atendimento` (mesmo pet, serviço, data e hora).

---

## Valores usados nas colunas de texto

Para o app e o sistema Web funcionarem juntos, os dois precisam gravar os mesmos textos:

| Tabela.coluna | Valores |
|---|---|
| `agenda.status` | `Aguardando pagamento`, `Agendado`, `Em andamento`, `Concluído`, `Cancelado` |
| `fila_atendimento.status` | `Aguardando`, `Em atendimento`, `Finalizado`, `Cancelado` |
| `fila_atendimento.criticidade` | `Agendado` ou `Presencial` (define a letra da senha e a prioridade) |
| `fila_atendimento.metodo_cancelamento` | `App` quando o tutor cancela pelo app |
| `tutor.status_conta` | `ativo` (o login só funciona com conta ativa) |
| `tutor.cpf` | `000000000-00` (11 números com hífen, cabe no `varchar(12)`) |

---

## API que o sistema Java precisa ter

Todos os dados vão e voltam em **JSON**, com os **mesmos nomes das colunas do banco** (`cpf`, `codigo_pet`, `id_agenda`, `id_servicoFK`…).

| Método | Endereço | Envia | Devolve / faz |
|---|---|---|---|
| POST | `/login` | `{"login", "senha"}` (login = usuário ou e-mail) | O tutor. Erro se a senha estiver errada ou a conta inativa. |
| POST | `/tutores` | tutor | Cadastra o tutor. |
| PUT | `/tutores/{cpf}` | tutor | Atualiza o cadastro. |
| GET | `/tutores/{cpf}/pets` | — | Lista de pets do tutor (`pet` + `tutela`). |
| POST | `/tutores/{cpf}/pets` | pet | Insere em `pet` e em `tutela`. |
| PUT | `/pets/{codigo_pet}` | pet | Atualiza o pet. |
| DELETE | `/pets/{codigo_pet}` | — | Exclui o pet. |
| GET | `/servicos` | — | Lista de serviços. |
| GET | `/tutores/{cpf}/agendas` | — | Agendamentos do tutor. |
| GET | `/agendas?data=AAAA-MM-DD` | — | Agendamentos do dia (para saber os horários ocupados). |
| POST | `/agendas` | agenda | Cria o agendamento com status `Aguardando pagamento`. |
| PUT | `/agendas/{id_agenda}/cancelar` | `{"metodo_cancelamento": "App"}` | Status `Cancelado`. Se já existir senha na fila, muda o status dela para `Cancelado` (não apagar a linha: é ela que mostra que o agendamento tinha sido pago e foi estornado). |
| POST | `/agendas/{id_agenda}/pagamento` | `{"forma_pagamento": "PIX" \| "Cartão" \| "Boleto"}` | Muda a agenda para `Agendado`, cria a linha em `fila_atendimento` (criticidade `Agendado`, status `Aguardando`, `data_hora_entrada` = data e hora do agendamento) e **devolve esse atendimento**. |
| GET | `/fila?data=AAAA-MM-DD` | — | Todos os atendimentos do dia. |
| GET | `/tutores/{cpf}/atendimentos` | — | Atendimentos dos pets do tutor. |
| GET | `/tutores/{cpf}/avaliacoes` | — | Avaliações feitas pelo tutor. |
| POST | `/avaliacoes` | `{"nota", "comentario", "id_atendimentoFK"}` | Grava a avaliação. |

**Cuidados no Java:**

- Datas como texto: `data_agendamento` = `"2026-11-17"`, `hora_agendamento` = `"17:00:00"`, `data_hora_entrada` = `"2026-11-17 17:00:00"`. O Gson, por padrão, manda datas em outro formato, então é preciso configurar.
- Em caso de erro, responder com status 400 (ou outro de erro) e `{"erro": "mensagem"}`. O app mostra essa mensagem para o usuário.
- Liberar **CORS** (`Access-Control-Allow-Origin`), porque o app roda no Chrome em outra porta.
- O usuário e a senha do banco ficam **só no Java**, nunca no app.

---

## Estrutura do projeto

```
lib/
├── main.dart               ← início do app (login ou abas)
├── config.dart             ← modo demonstração / endereço da API
├── modelos.dart            ← classes das tabelas (Tutor, Pet, Servico, Agenda, Atendimento, Avaliacao)
├── util.dart               ← formatação de data, hora, dinheiro e mensagens
├── repositorio.dart        ← lista de tudo que o app busca ou grava
├── repositorio_api.dart    ← versão que chama a API Java
├── repositorio_demo.dart   ← versão com dados de exemplo
└── telas/
    ├── login_tela.dart
    ├── cadastro_tela.dart  ← criar conta e editar cadastro
    ├── home_tela.dart      ← barra de abas
    ├── inicio_aba.dart
    ├── agendar_tela.dart
    ├── pets_aba.dart
    ├── pet_form_tela.dart
    ├── pagamentos_aba.dart
    ├── pagamento_tela.dart
    ├── senha_aba.dart      ← senha + avaliação
    └── painel_aba.dart
test/
└── widget_test.dart
```

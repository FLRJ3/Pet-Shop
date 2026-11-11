# Pet Shop Fila Zero — App do Tutor (módulo de Filas)

App Mobile em **Flutter/Dart** do Trabalho Integrador da Uninove.
Parte do **Fabio** no módulo de **Filas**. A parte administrativa (chamar o próximo, colocar presenciais na fila) fica no sistema **Java Web**.

> Este projeto é separado do estudo `pet_shop` e do backup `PetShopFilaZero`.

---

## Como rodar no VS Code

1. Abra o VS Code em **File > Open Folder…** e escolha `C:\Developer\pet_shop_filas`.
2. Abra o terminal: **Terminal > New Terminal** (ou `Ctrl + '`).
3. **Só na primeira vez**, rode um comando por vez:

   ```
   flutter create .
   flutter pub get
   ```

   O `flutter create .` cria as pastas de plataforma (`web`, `android`, `windows`…) sem mexer no `lib/main.dart`.

4. Para rodar:

   ```
   flutter run -d chrome
   ```

   Ou escolha **Chrome** no canto inferior direito do VS Code (seletor de dispositivo) e aperte **F5**.

- Salvar (`Ctrl + S`) aplica as mudanças na hora (hot reload). Se não aplicar, aperte `r` no terminal.
- Para parar: `q` no terminal.

**Conta de teste:** `ana@email.com` / `123456` (tem o botão **Preencher** na tela de login).

---

## Estrutura

```
pet_shop_filas/
├── lib/
│   └── main.dart        ← todo o código do app
├── pubspec.yaml         ← nome do projeto e dependências
└── README.md
```

---

## Fluxo do app

1. **Login / Cadastro.** O cadastro valida nome e sobrenome, e-mail, telefone com DDD e senha de no mínimo 6 caracteres (com confirmação).
2. Depois do login, o app tem 4 abas:

| Aba | O que faz |
|---|---|
| **Início** | Agendar consulta e/ou banho e tosa (pet, serviço, dia e horário livre), ver e cancelar agendamentos, cadastrar pets e ver o aviso sobre atendimento presencial. |
| **Pagamentos** | Pagar com PIX (copia e cola), cartão (validação de número, validade e CVV, até 3x) ou boleto (só com 2 dias ou mais de antecedência). Mostra também o histórico. |
| **Senha** | Mostra a senha do agendamento (A001…). No dia, mostra a posição na fila e a espera estimada. |
| **Painel** | A mesma tela da TV da recepção: senha atual, próximas senhas e horários marcados de hoje. |

---

## Regras de negócio

- **A senha só é gerada depois do pagamento.**
- **Agendados (A001, A002…):** entram na frente da fila quando chega o horário marcado.
- **Presenciais (P001, P002…):** sem agendamento, o tutor vai ao pet shop e pega a senha na recepção. O atendimento é por **ordem de chegada (FIFO)**, como num cabeleireiro.
- Não dá para agendar um horário que já passou, um horário já ocupado para o mesmo serviço, nem o mesmo pet duas vezes no mesmo horário.
- Os serviços são agendados de segunda a sábado, das 9h às 17h (sem 12h).
- A espera estimada considera 20 minutos por atendimento.
- Só dá para cancelar agendamentos que ainda não passaram.

---

## Organização do código (`lib/main.dart`)

| Parte | Conteúdo |
|---|---|
| Formatação | Funções para data, hora e dinheiro (`formatarData`, `formatarHora`, `formatarDinheiro`). |
| Modelos | `Usuario`, `Pet`, `Servico`, `FormaPagamento`, `StatusAgendamento`, `Agendamento`, `ItemFila`, `AppException`. |
| Estrutura de dados | `Fila<T>` (FIFO), usada para os presenciais. |
| `AppService` | Regras de negócio: login/cadastro, pets, agendamentos, pagamentos e fila do dia. Avisa as telas com `notifyListeners()`. |
| Telas | `LoginPage`, `CadastroPage`, `HomePage` (abas), `InicioTab`, `AgendarPage`, `NovoPetDialog`, `PagamentosTab`, `PagamentoPage`, `SenhaTab`, `PainelTab`. |

---

## Limitações atuais

- Os dados ficam **só na memória**: quando o app recarrega, tudo volta aos dados de exemplo.
- Os pagamentos são **simulados** (não há cobrança real).
- A fila não anda pelo app. Quem chama o próximo é o sistema Java Web.
- Ainda não está conectado à API Java nem ao banco MySQL. Na versão final, os métodos do `AppService` vão chamar a API.

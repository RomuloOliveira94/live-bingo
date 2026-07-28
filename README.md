<div align="center">
  <img src="public/icon.png" width="120" alt="Logo do Live Bingo! — uma bola de bingo marcada com o número 33">

  # Live Bingo!

  **Um sorteador de bingo gratuito e em tempo real. Sem aplicativo, sem cadastro, sem cartelas — só uma sala e um código compartilhado.**

  [![CI](https://github.com/RomuloOliveira94/live-bingo/actions/workflows/ci.yml/badge.svg)](https://github.com/RomuloOliveira94/live-bingo/actions/workflows/ci.yml)

  ![Ruby](https://img.shields.io/badge/Ruby-4.0.2-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
  ![Rails](https://img.shields.io/badge/Rails-8.1.3-D30001?style=for-the-badge&logo=rubyonrails&logoColor=white)
  ![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-FFE801?style=for-the-badge&logo=hotwire&logoColor=black)
  ![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)
  ![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
  ![Action Cable](https://img.shields.io/badge/Action_Cable-WebSockets-430098?style=for-the-badge)
  ![PWA](https://img.shields.io/badge/PWA-Installable-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white)

  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
</div>

## O que é isso?

Live Bingo! é um **sorteador** de bingo — ele sorteia e chama os números, mas não é o jogo de bingo completo. Um anfitrião abre o app, cria uma sala e recebe um código de 6 caracteres. Os convidados digitam esse código em qualquer celular, tablet ou notebook — sem download, sem conta — e acompanham o mesmo sorteio ao vivo, em sincronia, conforme o anfitrião chama os números.

Não há cartelas pessoais nem detecção de vitória — isso é proposital. Este app resolve o único problema que realmente precisa ser resolvido em uma noite de bingo de verdade: garantir que todo jogador, em qualquer dispositivo, veja exatamente o mesmo número, exatamente ao mesmo tempo. As cartelas e a gritaria ficam por sua conta.

## Funcionalidades

- **Sorteios em tempo real** — cada número chamado é enviado a todos os convidados conectados via Turbo Streams / Action Cable; ninguém precisa atualizar a página.
- **Painel compartilhado de 1 a 75** — um painel único, atualizado ao vivo, com todos os números, marcando as bolas já sorteadas, idêntico para o anfitrião e todos os convidados.
- **Bola animada + som de sorteio** — cada sorteio gira uma bola animada e toca um efeito sonoro.
- **PWA instalável** — adicione à tela inicial e abra como um app nativo.
- **Compartilhamento nativo e código com um toque** — compartilhe a sala pelo menu de compartilhamento do sistema no celular, ou copie o código com um toque.
- **pt-BR / Inglês** — detecção automática de idioma (Accept-Language e depois país), sem precisar trocar manualmente.
- **Analytics com privacidade em mente** — contagem de visitas para entender o uso do produto, com IPs anonimizados antes de serem armazenados.
- **Mobile-first** — construído e ajustado primeiro para a tela do celular, escalando bem até o desktop.

## Capturas de tela

<table>
  <tr>
    <td align="center" width="33%"><img src="docs/screenshots/home-mobile.png" alt="Tela inicial no celular — criar ou entrar em uma sala" width="260"><br><sub>Início — criar ou entrar</sub></td>
    <td align="center" width="33%"><img src="docs/screenshots/waiting-room-mobile.png" alt="Sala de espera no celular, mostrando o código compartilhável da sala" width="260"><br><sub>Sala de espera — compartilhe o código</sub></td>
    <td align="center" width="33%"><img src="docs/screenshots/active-game-desktop.png" alt="Sorteio ao vivo em andamento no desktop, com a bola animada e o painel de 1 a 75" width="320"><br><sub>Sorteio ao vivo — desktop</sub></td>
  </tr>
</table>

## Stack tecnológica

| Camada | Escolha |
|---|---|
| Linguagem | Ruby 4.0.2 |
| Framework | Rails 8.1.3 |
| Front-end | Hotwire — Turbo Rails 2.0.23 + Stimulus Rails 1.3.4, via Importmap (**sem build de Node/JS**) |
| Estilização | Tailwind CSS v4 (`@theme` CSS-first, via a gem `tailwindcss-rails`) |
| Assets | Propshaft |
| Banco de dados | SQLite (todos os ambientes, incluindo produção) |
| Tempo real / jobs / cache | Solid Cable, Solid Queue, Solid Cache — todos baseados em SQLite, sem Redis |
| Testes | Minitest + Capybara/Selenium para testes de sistema, `shoulda-matchers` para specs de model |
| Deploy | Kamal + Docker (Thruster na frente do Puma) |

## Como começar

```bash
git clone https://github.com/RomuloOliveira94/live-bingo.git
cd live-bingo
bin/setup      # bundle install, db:prepare, clears logs/tmp
bin/dev        # Puma + the Tailwind watcher (see Procfile.dev)
```

Depois, acesse `http://localhost:3000`.

O `bin/dev` executa o `Procfile.dev` via `foreman`, que inicia o servidor Rails (`web`) e o watcher do Tailwind CSS (`css`) lado a lado — sem precisar instalar um toolchain de frontend separado.

## Executando os testes

```bash
bin/rails db:test:prepare test    # 176 runs, 893 assertions
bin/rails test:system             # 34 runs
bin/rubocop                       # style, Rails Omakase config
bin/brakeman -q                  # static security analysis
```

Os quatro comandos estão passando (green) no momento deste README (0 failures, 0 offenses, 0 warnings) e rodam no CI a cada push e pull request (veja `.github/workflows/ci.yml`).

## Como funciona

- **Sem contas de usuário.** A identidade do anfitrião é um cookie assinado e `httponly` (veja `SessionData`), gerado no momento em que a sala é criada — nada para cadastrar, nada para lembrar. O mesmo cookie carrega um token de visitante anônimo por navegador, usado para analytics.
- **Um único fluxo de código para todo mundo.** Quando o anfitrião sorteia uma bola, a resposta renderiza esse sorteio inline para o anfitrião **e** transmite um Turbo Stream para todos os outros convidados conectados via Action Cable — assim o anfitrião não é um caso especial com lógica de renderização própria, é só a primeira pessoa a ver a atualização.
- **Atualização de página inteira com morph.** As transições de estado (waiting → active → finished) transmitem um `broadcast_refresh_to`, que o Turbo renderiza como uma atualização de página inteira via morph, em vez de um stream direcionado — assim todo convidado converge para exatamente o mesmo markup, independentemente da tela em que estava.
- **Resolução de idioma (locale)** verifica primeiro o `Accept-Language` da requisição (assim, uma preferência explícita por português sempre prevalece), depois recorre ao país do visitante via header `CF-IPCountry` da Cloudflare, e por fim ao idioma padrão do app (`pt-BR`) caso nenhum dos dois sinais esteja presente.

## Internacionalização

O app é totalmente localizado em pt-BR (padrão) e inglês, incluindo mensagens flash, metadados de SEO e o manifest do PWA. Há um teste dedicado (`test/i18n_hardcoded_strings_test.rb`) que varre todas as views em busca de texto literal não traduzido e falha o build caso algum passe despercebido — além de testes separados que garantem a paridade de chaves entre `pt-BR.yml`/`en.yml` e o comportamento de fallback do locale em português.

## Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE) — livre para usar, modificar e distribuir, com atribuição.

---

<div align="center">
  <sub>Desenvolvido com ❤️ por <a href="https://github.com/RomuloOliveira94">Rômulo Oliveira</a></sub>
</div>

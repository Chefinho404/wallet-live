# wallet-live: carteira de investimentos fullstack em Rust

Aplicação web para cadastrar e acompanhar ativos de investimento (ações, FIIs, ETFs, renda fixa, cripto).
API, banco de dados, autenticação e páginas HTML vivem no mesmo programa Rust.

## O que o projeto faz

- Cadastro e login de pessoas usuárias (senha com hash Argon2).
- Sessão por **JWT guardado em cookie assinado e HttpOnly**.
- **Dashboard** com o valor total da carteira e a lista de ativos, com valor e peso de cada um.
- Criar, listar, **editar** e excluir ativos (páginas HTML).
- API JSON em `/api` para listar, criar, atualizar e consultar o total da carteira.
- Cada pessoa só enxerga e altera os próprios ativos.

## Tecnologias

| Para quê | Biblioteca |
| --- | --- |
| Servidor web e rotas | Axum 0.8 |
| Banco de dados | PostgreSQL 17 + SQLx (consultas em SQL puro e migrations) |
| Páginas HTML | Askama (templates checados na compilação) |
| Login | `password-auth` (Argon2), `jwt-simple` (JWT), `axum-extra` (cookie assinado) |
| Banco local | Docker Compose |
| Erros e logs | `thiserror`, `color-eyre`, `tracing` |

## Como executar

Pré-requisitos: Rust (versão estável recente, o projeto usa a edição 2024) e Docker.

```bash
# 1. configuração (troque os segredos do .env)
cp .env.example .env

# 2. banco de dados
docker compose up -d

# 3. aplicação (as migrations rodam sozinhas ao iniciar)
cargo run
```

Abra <http://127.0.0.1:3000>, crie uma conta e cadastre seus primeiros ativos.

Variáveis do `.env`: `DATABASE_URL`, `JWT_SECRET` (mínimo de 32 caracteres), `COOKIE_SECRET` (mínimo de 64 caracteres) e `BIND_ADDR`.
Para gerar segredos: `openssl rand -base64 64`.

## Melhoria implementada

O foco foi o **valor total da carteira** e o que gira em torno dele:

- Total calculado no banco (`SUM(quantidade * preco_medio)`) e exibido em destaque no dashboard.
- **Peso** de cada ativo na carteira (por exemplo, 33,3%).
- Novo dado em cada investimento: o **tipo** (Ação, FII, ETF, Renda fixa, Cripto, Outro).
- **Edição** de ativos por formulário e exclusão com confirmação.
- **Validações com mensagens claras**: código do ativo, quantidade inteira, preço em reais (`35,50` ou `35.50`), limites máximos e aviso de ativo repetido.
- Dinheiro guardado em **centavos (inteiro)**, sem erros de arredondamento de ponto flutuante.
- Testes unitários das regras de negócio.

## Como testar

### Testes automáticos

```bash
cargo test
```

Cobrem formatação e leitura de dinheiro, cálculo de peso, validação de ativos e de cadastro, e o ciclo do JWT.

### Teste manual pelo navegador

1. Crie uma conta em `/registro`.
2. Cadastre `PETR4`, tipo Ação, quantidade `10`, preço `35,50`. O total deve ser **R$ 355,00**.
3. Cadastre `MXRF11`, tipo FII, quantidade `25`, preço `9,87`. O total passa a **R$ 601,75**.
4. Tente cadastrar `PETR4` de novo (deve avisar que já existe) e digite `abc` na quantidade (deve explicar o erro).
5. Edite um ativo, exclua outro e confira que o total acompanha.

### Teste da API com curl

```bash
# cria a conta e guarda o cookie de sessão em cookies.txt
curl -i -c cookies.txt -d 'email=ana@exemplo.com&senha=senha-forte-123' http://127.0.0.1:3000/registro

# sem cookie: 401
curl -i http://127.0.0.1:3000/api/ativos

# cria um ativo (preço em centavos: 3550 = R$ 35,50)
curl -b cookies.txt -H 'Content-Type: application/json' \
  -d '{"ticker":"PETR4","nome":"Petrobras","tipo":"Ação","quantidade":10,"preco_medio_centavos":3550}' \
  http://127.0.0.1:3000/api/ativos

# lista, atualiza e consulta o total
curl -b cookies.txt http://127.0.0.1:3000/api/ativos
curl -b cookies.txt -X PUT -H 'Content-Type: application/json' \
  -d '{"ticker":"PETR4","nome":"Petrobras PN","tipo":"Ação","quantidade":20,"preco_medio_centavos":3600}' \
  http://127.0.0.1:3000/api/ativos/1
curl -b cookies.txt http://127.0.0.1:3000/api/carteira
```

## Como o código está organizado

```text
src/
  main.rs    configuração, conexão com o banco, migrations e servidor
  state.rs   o que os handlers compartilham (pool do banco e chaves)
  error.rs   tipo de erro da aplicação e como cada um vira resposta HTTP
  auth.rs    hash de senha, JWT, cookie e o extrator AuthUser
  models.rs  tipos (Ativo, formulários) e regras de validação
  money.rs   centavos <-> texto em reais, cálculo de peso
  repo.rs    todo o SQL
  pages.rs   rotas das páginas HTML e dos formulários
  api.rs     rotas JSON em /api
templates/   páginas Askama (base.html é o layout comum)
static/      style.css
migrations/  SQL que cria as tabelas, aplicado pelo sqlx
```

Caminho de uma requisição protegida: o handler declara `user: AuthUser`; o extrator lê o cookie, confere a assinatura e valida o JWT; se falhar, a página redireciona para `/login` e a API responde 401. Depois o handler valida a entrada, chama o `repo` e monta a resposta.

## Limitações e próximos passos

- A quantidade é inteira, então não serve para frações de cripto. Dá para trocar por `NUMERIC` e a crate `rust_decimal`.
- O preço é o **preço médio informado**, não a cotação atual do mercado. Uma evolução natural é buscar cotações por uma API.
- Em produção com HTTPS, marque o cookie como `secure` (há um comentário em `auth.rs`).
- Faltam testes de integração com banco real.

## O que aprendi

> Escreva aqui, com as suas palavras. Algumas perguntas para ajudar:
>
> - Como o JWT e o cookie assinado trabalham juntos no login?
> - Por que guardar dinheiro em centavos?
> - O que o extrator `AuthUser` evita repetir em cada handler?
> - O que foi mais difícil em Rust (propriedade, `Result`, async)? Como você resolveu?

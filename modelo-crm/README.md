# Modelo de CRM da iMarcas

CRM padrão entregue para todo cliente novo da iMarcas. Base: CRM Filho da OrkAI, adaptado para não depender de nada da OrkAI.

- **1 cliente = 1 projeto Supabase + 1 repositório no GitHub + 1 cadastro no painel da iMarcas.**
- Pipeline com Realtime, vendedores com login próprio, distribuição automática de leads, captação por link (webhook), relatórios e PDF.
- Bloqueio automático pelo painel da iMarcas (vencimento + carência).
- Segurança: só o admin e vendedores ativos enxergam os dados.

## Arquivos

| Arquivo | O que é |
| --- | --- |
| `index.html` | O CRM. Trocar só os marcadores em MAIÚSCULO. |
| `schema.sql` | Estrutura do banco. Rodar uma vez no Supabase do cliente. |
| `webhook-lead.ts` | Função que recebe leads de anúncio/formulário. Publicar quando for ligar tráfego. |

## Marcadores para trocar no `index.html`

| Marcador | Onde pegar |
| --- | --- |
| `NOME_DO_CLIENTE` | Nome que aparece no topo e no login (aparece várias vezes, trocar todas) |
| `SLUG_DO_CLIENTE` | Igual ao slug cadastrado na aba Clientes do painel iMarcas |
| `COLE_AQUI_A_URL_DO_SUPABASE_DO_CLIENTE` | Supabase do cliente → Project Settings → API → Project URL |
| `COLE_AQUI_A_CHAVE_ANON_DO_CLIENTE` | Mesma tela → chave `anon` `public` (nunca a `service_role`) |
| `EMAIL_DO_ADMIN` | E-mail de quem administra o CRM (também no `schema.sql`) |

## Passo a passo — cliente novo

1. **Supabase:** criar projeto novo (região São Paulo). Guardar a senha do banco.
2. **Login sem confirmação de e-mail:** Authentication → Sign In / Providers → Email → desligar **Confirm email** → Save.
3. **Criar o admin:** Authentication → Users → Add user → Create new user → e-mail do admin + senha → marcar **Auto Confirm User**.
4. **Banco:** SQL Editor → colar o `schema.sql` com o `EMAIL_DO_ADMIN` trocado → Run. Deve listar 4 tabelas.
5. **Arquivo:** copiar o `index.html` e trocar os marcadores.
6. **GitHub:** criar o repositório `mkticasas/crm-<slug>`, subir o `index.html`, ativar Pages (Settings → Pages → main / root).
7. **Painel iMarcas:** aba Clientes → editar o cliente → colar o link do CRM e a URL do Supabase.
8. **Primeiro acesso:** entrar com o admin, configurar o app autenticador, cadastrar os vendedores (o CRM mostra a senha provisória de cada um).
9. **Captação (quando ligar anúncio):** Edge Functions → Deploy a new function → nome `webhook-lead` → colar `webhook-lead.ts` → Deploy → em Details desligar **Verify JWT**. Depois, no CRM, criar o webhook e usar o link gerado no formulário.

## Diferenças em relação ao CRM da OrkAI

- Bloqueio consulta o painel iMarcas (`imarcas_status_cliente`), não a OrkAI.
- Vendedor novo é criado direto pelo CRM com senha provisória (sem o Worker da OrkAI).
- Chat de suporte e botão de pagamento desligados (cobrança é manual pela iMarcas).
- Lista de vendedores só carrega depois do login.

# iMarcas · Tarefas

Quadro de tarefas da iMarcas: Kanban, aba Semana, checklists, anexos, comentários e exportação em PDF.
Mesmo sistema do quadro da OrkAI, com identidade da iMarcas e dados separados.

- **Hospedagem:** GitHub Pages (`mkticasas/imarcas-tarefas`)
- **Dados:** Supabase da Vitrine iCasas, só em tabelas com prefixo `imarcas_`
- **Login:** mesmo login da Vitrine + verificação em duas etapas (app autenticador). Só entra quem estiver na tabela `imarcas_membros`.
- **Claude:** grava tarefas novas no `tasks.json`; o painel aplica sozinho ao abrir e a cada 60 segundos.

## Como colocar no ar

1. No Supabase da Vitrine, abra o **SQL Editor**, cole o `supabase.sql`, troque o e-mail na seção 8 e rode.
2. Em `index.html`, troque `COLE_AQUI_A_URL_DO_SUPABASE` e `COLE_AQUI_A_CHAVE_ANON` (Project Settings → API → URL e chave `anon`).
3. Suba os arquivos no repositório e ative o GitHub Pages (Settings → Pages → branch `main`, pasta raiz).
4. Abra o link, entre com o login da Vitrine e configure o app autenticador no primeiro acesso.

## Trocar de Supabase no futuro

Rode o `supabase.sql` no projeto novo e mude só `SUPA_URL` e `SUPA_KEY` no `index.html`.

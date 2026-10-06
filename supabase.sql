-- =====================================================================
-- iMarcas · Tarefas — tabelas no Supabase da Vitrine iCasas
-- Rodar inteiro no SQL Editor do Supabase, uma única vez.
-- Não mexe em nenhuma tabela da Vitrine: tudo aqui tem prefixo imarcas_.
-- =====================================================================

-- 1) Quem pode entrar no painel ------------------------------------------
create table if not exists public.imarcas_membros (
  id           uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  name         text not null,
  email        text,
  criado       timestamptz not null default now()
);

create or replace function public.imarcas_eh_membro()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.imarcas_membros where auth_user_id = auth.uid());
$$;

-- 2) Tarefas --------------------------------------------------------------
create table if not exists public.imarcas_tasks (
  id          text primary key,
  codigo      integer,
  titulo      text not null,
  descricao   text,
  area        text,
  prioridade  text default 'media',
  coluna      text default 'todo',
  ordem       numeric,
  pai         text,
  prazo       date,
  dia         text,
  checklist   jsonb not null default '[]'::jsonb,
  anexos      jsonb not null default '[]'::jsonb,
  comentarios jsonb not null default '[]'::jsonb,
  criado      timestamptz not null default now()
);

-- 3) Configuração do quadro (colunas, áreas, modelos de checklist) --------
create table if not exists public.imarcas_task_config (
  id        integer primary key,
  colunas   jsonb,
  areas     jsonb,
  templates jsonb default '[]'::jsonb
);

insert into public.imarcas_task_config (id, colunas, areas, templates) values (
  1,
  '[{"id":"ideas","n":"Ideias","c":"#8a90a0"},
    {"id":"todo","n":"A Fazer","c":"#f59e0b"},
    {"id":"doing","n":"Em Andamento","c":"#3d7eff"},
    {"id":"waiting","n":"Aguardando cliente","c":"#a855f7"},
    {"id":"done","n":"Concluído","c":"#22c55e"}]'::jsonb,
  '[{"id":"imarcas","n":"iMarcas","c":"#C52F43"},
    {"id":"pele-esquadrias","n":"Pelé Esquadrias","c":"#3d7eff"}]'::jsonb,
  '[]'::jsonb
) on conflict (id) do nothing;

-- 4) Controle das atualizações que o Claude manda pelo tasks.json ---------
create table if not exists public.imarcas_task_ops (
  op_id    text primary key,
  aplicado timestamptz not null default now()
);

-- 5) Segurança: só membros leem e escrevem ---------------------------------
alter table public.imarcas_membros     enable row level security;
alter table public.imarcas_tasks       enable row level security;
alter table public.imarcas_task_config enable row level security;
alter table public.imarcas_task_ops    enable row level security;

drop policy if exists "imarcas membro le o proprio cadastro" on public.imarcas_membros;
create policy "imarcas membro le o proprio cadastro" on public.imarcas_membros
  for select to authenticated using (auth_user_id = auth.uid());

drop policy if exists "imarcas membro edita o proprio nome" on public.imarcas_membros;
create policy "imarcas membro edita o proprio nome" on public.imarcas_membros
  for update to authenticated using (auth_user_id = auth.uid()) with check (auth_user_id = auth.uid());

drop policy if exists "imarcas membros tarefas" on public.imarcas_tasks;
create policy "imarcas membros tarefas" on public.imarcas_tasks
  for all to authenticated using (public.imarcas_eh_membro()) with check (public.imarcas_eh_membro());

drop policy if exists "imarcas membros config" on public.imarcas_task_config;
create policy "imarcas membros config" on public.imarcas_task_config
  for all to authenticated using (public.imarcas_eh_membro()) with check (public.imarcas_eh_membro());

drop policy if exists "imarcas membros ops" on public.imarcas_task_ops;
create policy "imarcas membros ops" on public.imarcas_task_ops
  for all to authenticated using (public.imarcas_eh_membro()) with check (public.imarcas_eh_membro());

-- 6) Anexos e foto de perfil (bucket privado) ------------------------------
insert into storage.buckets (id, name, public)
values ('imarcas-files', 'imarcas-files', false)
on conflict (id) do nothing;

drop policy if exists "imarcas membros arquivos" on storage.objects;
create policy "imarcas membros arquivos" on storage.objects
  for all to authenticated
  using (bucket_id = 'imarcas-files' and public.imarcas_eh_membro())
  with check (bucket_id = 'imarcas-files' and public.imarcas_eh_membro());

-- 7) Atualização em tempo real do quadro -----------------------------------
do $$
begin
  alter publication supabase_realtime add table public.imarcas_tasks;
exception when duplicate_object then null;
end $$;

-- 8) Liberar o seu login --------------------------------------------------
-- Troque o e-mail abaixo pelo e-mail que você usa pra entrar na Vitrine.
-- Pra liberar outra pessoa (ex.: Cris), repita o insert com o e-mail dela.
insert into public.imarcas_membros (auth_user_id, name, email)
select id, 'Lucas', email from auth.users
where email = 'TROQUE_PELO_SEU_EMAIL_DA_VITRINE'
on conflict (auth_user_id) do nothing;

-- Conferência: deve aparecer 1 linha com o seu e-mail.
select * from public.imarcas_membros;

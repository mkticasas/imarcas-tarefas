-- =====================================================================
-- iMarcas · Painel Mãe — clientes, pagamentos e bloqueio dos CRMs
-- Rodar no SQL Editor do Supabase da VITRINE, depois do supabase.sql.
-- Pode rodar de novo sem duplicar nada.
-- =====================================================================

-- 1) Clientes da iMarcas (cada um pode ter um CRM próprio) ---------------
create table if not exists public.imarcas_clients (
  id               uuid primary key default gen_random_uuid(),
  client_name      text not null,
  slug             text not null unique,
  category         text default 'crm',
  repo_url         text,
  whatsapp         text,
  supabase_url     text,
  supabase_key     text,
  service_role_key text,           -- não usado na iMarcas; mantido vazio
  status           text not null default 'trial',   -- trial | active | blocked
  due_date         date,
  grace_days       integer not null default 3,
  plan_value       numeric default 0,
  notes            text,
  created_at       timestamptz not null default now()
);

-- 2) Pagamentos registrados à mão --------------------------------------
create table if not exists public.imarcas_payments (
  id            uuid primary key default gen_random_uuid(),
  client_id     uuid not null references public.imarcas_clients(id) on delete cascade,
  paid_at       timestamptz not null default now(),
  amount        numeric default 0,
  next_due_date date,
  notes         text
);

-- 3) Só membros da iMarcas leem e editam -------------------------------
alter table public.imarcas_clients  enable row level security;
alter table public.imarcas_payments enable row level security;

drop policy if exists "imarcas membros clientes" on public.imarcas_clients;
create policy "imarcas membros clientes" on public.imarcas_clients
  for all to authenticated using (public.imarcas_eh_membro()) with check (public.imarcas_eh_membro());

drop policy if exists "imarcas membros pagamentos" on public.imarcas_payments;
create policy "imarcas membros pagamentos" on public.imarcas_payments
  for all to authenticated using (public.imarcas_eh_membro()) with check (public.imarcas_eh_membro());

-- 4) Consulta pública de status, usada pelo CRM de cada cliente ---------
-- Devolve só o necessário (nunca chaves nem valores). Bloqueia sozinho
-- quando passa do vencimento + dias de carência, sem precisar de servidor.
create or replace function public.imarcas_status_cliente(p_slug text)
returns json
language sql stable security definer set search_path = public
as $$
  select coalesce(
    (select json_build_object(
       'cliente',   c.client_name,
       'bloqueado', c.status = 'blocked'
                    or (c.status = 'active' and c.due_date is not null
                        and c.due_date + c.grace_days < current_date)
     )
     from public.imarcas_clients c where c.slug = p_slug),
    json_build_object('cliente', null, 'bloqueado', false)
  );
$$;

revoke all on function public.imarcas_status_cliente(text) from public;
grant execute on function public.imarcas_status_cliente(text) to anon, authenticated;

-- 5) Pelé Esquadrias já cadastrado (ajuste valor e vencimento no painel) --
insert into public.imarcas_clients (client_name, slug, category, whatsapp, status, due_date, notes)
values ('Pelé Esquadrias', 'pele-esquadrias', 'ouro', '5517992416696', 'trial',
        current_date + 7, 'Ajustar valor do plano e vencimento depois do pagamento.')
on conflict (slug) do nothing;

-- Conferência: deve mostrar a Pelé com bloqueado = false
select public.imarcas_status_cliente('pele-esquadrias');

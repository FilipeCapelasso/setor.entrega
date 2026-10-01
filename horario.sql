-- Rode UMA vez no Supabase: SQL Editor > New query > Run
alter table public.motos add column if not exists horario text;
create index if not exists motos_horario_idx on public.motos (horario);

-- Trava no banco: no máximo 2 motos por horário (vale para todos os computadores)
create or replace function public.limita_horario() returns trigger
language plpgsql as $$
begin
  if new.horario is not null then
    perform pg_advisory_xact_lock(hashtext(new.horario));
    if (select count(*) from public.motos
        where horario = new.horario and id is distinct from new.id) >= 2 then
      raise exception 'HORARIO_CHEIO';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_limita_horario on public.motos;
create trigger trg_limita_horario
before insert or update of horario on public.motos
for each row execute function public.limita_horario();

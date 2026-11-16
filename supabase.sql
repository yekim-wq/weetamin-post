-- 위타민 우체국: Supabase 설정
-- Supabase 대시보드 → SQL Editor → New query 에 전체를 붙여넣고 Run 하세요.
-- 방문자는 테이블에 직접 접근하지 못하고, 아래 함수(RPC)로만 편지를 쓰고 읽어요.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.letters (
  id         text primary key,
  to_name    text not null check (char_length(to_name) between 1 and 16),
  message    text not null check (char_length(message) between 1 and 60),
  from_name  text check (from_name is null or char_length(from_name) <= 16),
  stamp      text not null check (stamp in ('bil','col','d3k')),
  card       text not null default 'forest' check (char_length(card) <= 20),
  is_public  boolean not null default true,   -- 편지 벽 공개 여부 (작성자가 선택)
  hidden     boolean not null default false,  -- 운영자가 true로 바꾸면 어디에도 안 보임
  hearts     integer not null default 0 check (hearts >= 0),
  created_at timestamptz not null default now()
);

create index if not exists letters_wall_idx on public.letters (created_at desc) where is_public and not hidden;

-- 보안: 정책(policy)을 만들지 않으면 방문자는 테이블을 직접 읽거나 쓸 수 없어요.
alter table public.letters enable row level security;
revoke all on public.letters from anon, authenticated;

-- 1) 편지 보내기 → 8자리 편지 ID 반환
create or replace function public.send_letter(
  p_to text, p_msg text, p_from text, p_stamp text, p_card text, p_public boolean
) returns text
language plpgsql security definer set search_path = public, extensions as $$
declare
  chars constant text := 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  rnd bytea; v_id text; i int;
begin
  loop
    rnd := gen_random_bytes(8); v_id := '';
    for i in 0..7 loop
      v_id := v_id || substr(chars, 1 + (get_byte(rnd, i) % length(chars)), 1);
    end loop;
    exit when not exists (select 1 from letters where id = v_id);
  end loop;
  insert into letters (id, to_name, message, from_name, stamp, card, is_public)
  values (v_id, trim(p_to), trim(p_msg), nullif(trim(coalesce(p_from, '')), ''),
          p_stamp, coalesce(nullif(p_card, ''), 'forest'), coalesce(p_public, true));
  return v_id;
end $$;

-- 2) 받은 링크로 편지 하나 열기 (비공개 편지도 링크가 있으면 열림)
create or replace function public.get_letter(p_id text)
returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('to_name', to_name, 'message', message, 'from_name', from_name,
                           'stamp', stamp, 'card', card)
  from letters where id = p_id and not hidden;
$$;

-- 3) 편지 벽: 공개된 최신 편지 (보내는 사람 이름은 내보내지 않음)
create or replace function public.get_wall(p_limit int default 40)
returns table (id text, to_name text, message text, stamp text, hearts int, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select l.id, l.to_name, l.message, l.stamp, l.hearts, l.created_at
  from letters l where l.is_public and not l.hidden
  order by l.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 100);
$$;

-- 4) 지금까지 접수된 편지 수
create or replace function public.letter_count()
returns bigint
language sql stable security definer set search_path = public as $$
  select count(*) from letters where not hidden;
$$;

-- 5) 하트 +1 / -1 → 바뀐 하트 수 반환
create or replace function public.heart(p_id text, p_delta int)
returns int
language sql security definer set search_path = public as $$
  update letters set hearts = greatest(0, hearts + case when p_delta > 0 then 1 else -1 end)
  where id = p_id and is_public and not hidden
  returning hearts;
$$;

revoke all on function public.send_letter(text,text,text,text,text,boolean), public.get_letter(text),
  public.get_wall(int), public.letter_count(), public.heart(text,int) from public;
grant execute on function public.send_letter(text,text,text,text,text,boolean), public.get_letter(text),
  public.get_wall(int), public.letter_count(), public.heart(text,int) to anon, authenticated;

-- ── 운영자용 쿼리 예시 (필요할 때 SQL Editor에서 실행) ──
-- 하트 많은 순 TOP 10:   select id, to_name, message, hearts from letters where not hidden order by hearts desc limit 10;
-- 편지 숨기기:            update letters set hidden = true where id = '편지ID';

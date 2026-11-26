-- Aurenza Academy Community - initial database schema
-- Run in Supabase SQL Editor. Review before production deployment.

create type public.approval_status as enum ('pending','approved','rejected','suspended');
create type public.post_kind as enum ('discussion','job','certification','course','event','announcement');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 24 and username ~ '^[A-Za-z0-9_]+$'),
  full_name text not null,
  bio text default '' check (char_length(bio) <= 240),
  profession text default '',
  approval_status public.approval_status not null default 'pending',
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text not null default '',
  is_read_only boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  kind public.post_kind not null default 'discussion',
  title text not null check (char_length(title) between 3 and 160),
  body text not null check (char_length(body) between 1 and 10000),
  created_at timestamptz not null default now()
);
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);
create table public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  primary key (conversation_id,user_id)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 5000),
  created_at timestamptz not null default now()
);
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  message_id uuid references public.messages(id) on delete cascade,
  reason text not null check (char_length(reason) between 5 and 1000),
  status text not null default 'open' check (status in ('open','reviewed','actioned')),
  created_at timestamptz not null default now(),
  check (num_nonnulls(post_id,message_id)=1)
);

-- Bootstrap common rooms.
insert into public.rooms(name,description) values
 ('Introductions','Introduce yourself and your professional interests.'),
 ('Business Networking','Discuss ideas, partnerships and business growth.'),
 ('Certifications','Discuss professional certifications and exam preparation.'),
 ('Career Opportunities','Share verified jobs and career resources.'),
 ('Learning Resources','Exchange useful learning materials and knowledge.')
on conflict (name) do nothing;

-- Helper functions use SECURITY DEFINER to avoid recursive RLS policy checks.
create or replace function public.is_approved_member()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.approval_status='approved'); $$;
create or replace function public.is_community_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_admin=true and p.approval_status='approved'); $$;

create or replace function public.is_conversation_member(target_conversation uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.conversation_members cm where cm.conversation_id=target_conversation and cm.user_id=auth.uid()); $$;

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.posts enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- Members can see approved public profile fields only. Email is never stored in profiles.
create policy "approved members view approved profiles" on public.profiles for select
using (public.is_approved_member() and approval_status='approved' or id=auth.uid() or public.is_community_admin());
create policy "users create own pending profile" on public.profiles for insert
with check (id=auth.uid() and approval_status='pending' and is_admin=false);
create policy "users update own basic profile" on public.profiles for update
using (id=auth.uid() and approval_status='approved')
with check (id=auth.uid() and is_admin=false and approval_status='approved');
create policy "admins manage profiles" on public.profiles for all
using (public.is_community_admin()) with check (public.is_community_admin());

create policy "approved members read rooms" on public.rooms for select using (public.is_approved_member());
create policy "admins manage rooms" on public.rooms for all using (public.is_community_admin()) with check (public.is_community_admin());

create policy "approved members read posts" on public.posts for select using (public.is_approved_member());
create policy "approved members create posts" on public.posts for insert
with check (public.is_approved_member() and author_id=auth.uid());
create policy "authors edit own posts" on public.posts for update
using (author_id=auth.uid() and public.is_approved_member()) with check (author_id=auth.uid() and public.is_approved_member());
create policy "authors or admins delete posts" on public.posts for delete
using (author_id=auth.uid() or public.is_community_admin());

create policy "participants or admins view conversations" on public.conversations for select
using (public.is_conversation_member(id) or public.is_community_admin());
-- Conversation creation and participant enrollment are intentionally disabled from
-- browser clients until an atomic, server-validated RPC is added. This prevents
-- users from adding themselves to another member's private conversation.
create policy "participants view conversation members" on public.conversation_members for select
using (user_id=auth.uid() or public.is_conversation_member(conversation_id) or public.is_community_admin());
create policy "participants read messages" on public.messages for select
using (exists(select 1 from public.conversation_members cm where cm.conversation_id=messages.conversation_id and cm.user_id=auth.uid()) or public.is_community_admin());
create policy "participants send messages" on public.messages for insert
with check (sender_id=auth.uid() and public.is_approved_member() and exists(select 1 from public.conversation_members cm where cm.conversation_id=messages.conversation_id and cm.user_id=auth.uid()));

create policy "users create reports" on public.reports for insert
with check (reporter_id=auth.uid() and public.is_approved_member());
create policy "reporters and admins view reports" on public.reports for select
using (reporter_id=auth.uid() or public.is_community_admin());
create policy "admins update reports" on public.reports for update
using (public.is_community_admin()) with check (public.is_community_admin());

-- New auth users receive a pending profile. A client-side upsert can complete the profile fields.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  insert into public.profiles(id,username,full_name,bio,approval_status)
  values (
    new.id,
    coalesce(nullif(lower(new.raw_user_meta_data->>'username'),''),'member_'||substr(new.id::text,1,8)),
    coalesce(nullif(new.raw_user_meta_data->>'full_name',''),'New member'),
    coalesce(new.raw_user_meta_data->>'bio',''),
    'pending'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- IMPORTANT: Promote the first trusted administrator manually in the SQL editor:
-- update public.profiles set is_admin=true, approval_status='approved'
-- where id = (select id from auth.users where email='YOUR_ADMIN_EMAIL');
--
-- Production hardening still required before launch:
-- 1. Add server-side validation and rate limiting for registration, posting and messaging.
-- 2. Add a server-side RPC for atomic conversation creation and participant enrollment.
-- 3. Add moderation workflows and audit logging.
-- 4. Enable Supabase email confirmation and configure SMTP.
-- 5. Consider database constraints preventing non-admin changes to approval_status.

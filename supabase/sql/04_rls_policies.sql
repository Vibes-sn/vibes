alter table profiles enable row level security;
alter table events enable row level security;
alter table tickets enable row level security;
alter table follows enable row level security;
alter table event_likes enable row level security;
alter table vibes_stories enable row level security;

create policy "profiles read own"
on profiles for select
using (id = auth.uid());

create policy "profiles update own"
on profiles for update
using (id = auth.uid())
with check (id = auth.uid());

create policy "profiles insert own"
on profiles for insert
with check (id = auth.uid());

create policy "events read all"
on events for select
using (true);

create policy "events insert host only"
on events for insert
with check (
  auth.uid() is not null
  and host_id = auth.uid()
  and exists (
    select 1 from profiles
    where id = auth.uid() and role = 'host'
  )
);

create policy "events update host only"
on events for update
using (
  auth.uid() is not null
  and host_id = auth.uid()
  and exists (
    select 1 from profiles
    where id = auth.uid() and role = 'host'
  )
)
with check (
  auth.uid() is not null
  and host_id = auth.uid()
  and exists (
    select 1 from profiles
    where id = auth.uid() and role = 'host'
  )
);

create policy "tickets read own"
on tickets for select
using (user_id = auth.uid());

create policy "tickets insert own"
on tickets for insert
with check (user_id = auth.uid());

create policy "tickets update own"
on tickets for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "follows read all"
on follows for select
using (true);

create policy "follows insert own"
on follows for insert
with check (follower_id = auth.uid());

create policy "follows delete own"
on follows for delete
using (follower_id = auth.uid());

create policy "event likes read all"
on event_likes for select
using (true);

create policy "event likes insert own"
on event_likes for insert
with check (user_id = auth.uid());

create policy "event likes delete own"
on event_likes for delete
using (user_id = auth.uid());

create policy "vibes read all"
on vibes_stories for select
using (true);

create policy "vibes insert own"
on vibes_stories for insert
with check (user_id = auth.uid());

create policy "vibes delete own"
on vibes_stories for delete
using (user_id = auth.uid());

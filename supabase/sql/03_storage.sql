insert into storage.buckets (id, name, public)
values ('event_images', 'event_images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('vibe_media', 'vibe_media', true)
on conflict (id) do nothing;

create policy "public read event images"
on storage.objects for select
using (bucket_id = 'event_images');

create policy "public read vibe media"
on storage.objects for select
using (bucket_id = 'vibe_media');

create policy "authenticated upload event images"
on storage.objects for insert
with check (
  bucket_id = 'event_images'
  and auth.role() = 'authenticated'
);

create policy "authenticated upload vibe media"
on storage.objects for insert
with check (
  bucket_id = 'vibe_media'
  and auth.role() = 'authenticated'
);

create policy "authenticated update event images"
on storage.objects for update
using (bucket_id = 'event_images' and auth.role() = 'authenticated')
with check (bucket_id = 'event_images' and auth.role() = 'authenticated');

create policy "authenticated update vibe media"
on storage.objects for update
using (bucket_id = 'vibe_media' and auth.role() = 'authenticated')
with check (bucket_id = 'vibe_media' and auth.role() = 'authenticated');

create policy "authenticated delete event images"
on storage.objects for delete
using (bucket_id = 'event_images' and auth.role() = 'authenticated');

create policy "authenticated delete vibe media"
on storage.objects for delete
using (bucket_id = 'vibe_media' and auth.role() = 'authenticated');

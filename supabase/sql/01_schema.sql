create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  avatar_url text,
  role text check (role in ('viber', 'host')) default 'viber',
  phone text,
  is_verified boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists events (
  id uuid default gen_random_uuid() primary key,
  host_id uuid references profiles(id) on delete set null,
  title text not null,
  description text,
  event_date timestamp with time zone not null,
  location_name text not null,
  price numeric default 0,
  capacity int,
  image_url text,
  category text check (category in ('clubbing', 'concerts', 'lounge', 'expos')),
  is_published boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists tickets (
  id uuid default gen_random_uuid() primary key,
  event_id uuid references events(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  status text check (status in ('paid', 'used', 'cancelled')) default 'paid',
  qr_code_data text unique not null,
  payment_ref text,
  purchase_date timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists follows (
  follower_id uuid references profiles(id) on delete cascade,
  following_id uuid references profiles(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (follower_id, following_id)
);

create table if not exists event_likes (
  user_id uuid references profiles(id) on delete cascade,
  event_id uuid references events(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (user_id, event_id)
);

create table if not exists vibes_stories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  event_id uuid references events(id) on delete set null,
  media_url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  expires_at timestamp with time zone default timezone('utc'::text, now()) + interval '24 hours' not null
);

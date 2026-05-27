-- Expose PostGIS point coordinates as plain selectable floats.
-- ST_X = longitude, ST_Y = latitude. NULL location -> NULL coords.

alter table public.service_requests
  add column if not exists lat double precision
    generated always as (st_y(location::geometry)) stored,
  add column if not exists lng double precision
    generated always as (st_x(location::geometry)) stored;

alter table public.professional_profiles
  add column if not exists lat double precision
    generated always as (st_y(base_location::geometry)) stored,
  add column if not exists lng double precision
    generated always as (st_x(base_location::geometry)) stored;

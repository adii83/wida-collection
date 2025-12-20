-- Create a server-side RPC so Admin Dashboard statistics match real Supabase data
-- and are not affected by PostgREST max-rows limits.
--
-- Run this in Supabase SQL Editor.

create or replace function public.get_admin_statistics()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'total_orders', (select count(*) from public.orders),
    'pending_orders', (select count(*) from public.orders where lower(coalesce(status, '')) = 'pending'),
    'total_revenue', (select coalesce(sum(total_amount), 0) from public.orders where lower(coalesce(payment_status, '')) = 'paid'),
    'pending_refunds', (select count(*) from public.refunds where lower(coalesce(status, '')) = 'pending')
  );
$$;

revoke all on function public.get_admin_statistics() from public;
grant execute on function public.get_admin_statistics() to authenticated;

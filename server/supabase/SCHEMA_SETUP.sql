-- Abyssal Dominion: captured public schema for a NEW, EMPTY Supabase project.
-- Matches project eysiaedrtfcomyzqqkxj on 2026-11-16.
-- The auth/realtime/storage system schemas must be supplied by Supabase.
-- This is a reproducible schema script, NOT a data export or token backup.
BEGIN;
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;

CREATE TABLE public."captain_positions" (
  "account_id" uuid NOT NULL,
  "map_id" integer DEFAULT 0 NOT NULL,
  "pos_x" double precision DEFAULT 4200 NOT NULL,
  "pos_y" double precision DEFAULT 2900 NOT NULL,
  "heading" double precision DEFAULT 0 NOT NULL,
  "design_index" integer DEFAULT 0 NOT NULL,
  "route_sequence" bigint DEFAULT 0 NOT NULL,
  "online" boolean DEFAULT false NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."captain_progress" (
  "account_id" uuid NOT NULL,
  "level" integer DEFAULT 1 NOT NULL,
  "experience" bigint DEFAULT 0 NOT NULL,
  "gold" bigint DEFAULT 0 NOT NULL,
  "pearls" bigint DEFAULT 0 NOT NULL,
  "selected_ship" integer DEFAULT 0 NOT NULL,
  "ammunition" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "equipment" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."captain_settings" (
  "account_id" uuid NOT NULL,
  "graphics_mode" text DEFAULT 'classic_2d'::text NOT NULL,
  "double_tap_attack" boolean DEFAULT false NOT NULL,
  "auto_fire" boolean DEFAULT false NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."captains" (
  "account_id" uuid NOT NULL,
  "display_name" text NOT NULL,
  "guild_tag" text DEFAULT ''::text NOT NULL,
  "pirate_rank" smallint DEFAULT 0 NOT NULL,
  "battle_points" bigint DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "current_map_id" integer DEFAULT 0 NOT NULL
);

ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_design_index_check" CHECK (design_index >= 0 AND design_index <= 2048);
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_heading_check" CHECK (heading >= '-6.28319'::numeric::double precision AND heading <= 6.28319::double precision);
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_map_id_check" CHECK (map_id >= 0 AND map_id <= 42);
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_pos_x_check" CHECK (pos_x >= 40::double precision AND pos_x <= 8760::double precision);
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_pos_y_check" CHECK (pos_y >= 40::double precision AND pos_y <= 6360::double precision);
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_route_sequence_check" CHECK (route_sequence >= 0);
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_account_id_fkey" FOREIGN KEY (account_id) REFERENCES captains(account_id) ON DELETE CASCADE;
ALTER TABLE public."captain_positions" ADD CONSTRAINT "captain_positions_pkey" PRIMARY KEY (account_id);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_ammunition_check" CHECK (jsonb_typeof(ammunition) = 'object'::text);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_equipment_check" CHECK (jsonb_typeof(equipment) = 'object'::text);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_experience_check" CHECK (experience >= 0);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_gold_check" CHECK (gold >= 0);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_level_check" CHECK (level >= 1 AND level <= 10000);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_pearls_check" CHECK (pearls >= 0);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_selected_ship_check" CHECK (selected_ship >= 0);
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_account_id_fkey" FOREIGN KEY (account_id) REFERENCES captains(account_id) ON DELETE CASCADE;
ALTER TABLE public."captain_progress" ADD CONSTRAINT "captain_progress_pkey" PRIMARY KEY (account_id);
ALTER TABLE public."captain_settings" ADD CONSTRAINT "captain_settings_graphics_mode_check" CHECK (graphics_mode = ANY (ARRAY['classic_2d'::text, 'native_3d'::text]));
ALTER TABLE public."captain_settings" ADD CONSTRAINT "captain_settings_account_id_fkey" FOREIGN KEY (account_id) REFERENCES captains(account_id) ON DELETE CASCADE;
ALTER TABLE public."captain_settings" ADD CONSTRAINT "captain_settings_pkey" PRIMARY KEY (account_id);
ALTER TABLE public."captains" ADD CONSTRAINT "captains_battle_points_check" CHECK (battle_points >= 0);
ALTER TABLE public."captains" ADD CONSTRAINT "captains_current_map_id_check" CHECK (current_map_id >= 0 AND current_map_id <= 42);
ALTER TABLE public."captains" ADD CONSTRAINT "captains_display_name_check" CHECK (char_length(display_name) >= 3 AND char_length(display_name) <= 24);
ALTER TABLE public."captains" ADD CONSTRAINT "captains_guild_tag_check" CHECK (char_length(guild_tag) <= 8);
ALTER TABLE public."captains" ADD CONSTRAINT "captains_pirate_rank_check" CHECK (pirate_rank >= 0);
ALTER TABLE public."captains" ADD CONSTRAINT "captains_account_id_fkey" FOREIGN KEY (account_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."captains" ADD CONSTRAINT "captains_pkey" PRIMARY KEY (account_id);

CREATE INDEX captain_positions_map_online_idx ON public.captain_positions USING btree (map_id, updated_at DESC) WHERE (online = true);
CREATE OR REPLACE FUNCTION private.create_new_captain()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  requested_name text;
begin
  requested_name := trim(coalesce(new.raw_user_meta_data->>'username',''));
  if char_length(requested_name) < 3
     or char_length(requested_name) > 24
     or requested_name ~ '[[:cntrl:]]' then
    requested_name := 'Captain_' || substr(new.id::text,1,8);
  end if;
  insert into public.captains(account_id,display_name)
    values(new.id,requested_name)
    on conflict(account_id) do nothing;
  insert into public.captain_progress(account_id)
    values(new.id)
    on conflict(account_id) do nothing;
  insert into public.captain_positions(account_id)
    values(new.id)
    on conflict(account_id) do nothing;
  insert into public.captain_settings(account_id)
    values(new.id)
    on conflict(account_id) do nothing;
  return new;
end;
$function$;
REVOKE ALL ON FUNCTION private.create_new_captain() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER abyssal_auth_captain_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION private.create_new_captain();

ALTER TABLE public."captain_positions" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public."captain_positions" FROM anon, authenticated;
ALTER TABLE public."captain_progress" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public."captain_progress" FROM anon, authenticated;
ALTER TABLE public."captain_settings" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public."captain_settings" FROM anon, authenticated;
ALTER TABLE public."captains" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public."captains" FROM anon, authenticated;
GRANT SELECT ON public.captains, public.captain_progress, public.captain_positions, public.captain_settings TO authenticated;
GRANT INSERT, UPDATE ON public.captain_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.captains, public.captain_progress, public.captain_positions, public.captain_settings TO service_role;
CREATE POLICY "captain_positions_read_same_map" ON public."captain_positions" AS PERMISSIVE FOR SELECT TO authenticated USING (((account_id = ( SELECT auth.uid() AS uid)) OR (online AND (updated_at > (now() - '00:01:30'::interval)) AND (EXISTS ( SELECT 1
   FROM captains own
  WHERE ((own.account_id = ( SELECT auth.uid() AS uid)) AND (own.current_map_id = captain_positions.map_id)))))));
CREATE POLICY "captain_progress_read_self" ON public."captain_progress" AS PERMISSIVE FOR SELECT TO authenticated USING ((account_id = ( SELECT auth.uid() AS uid)));
CREATE POLICY "captain_settings_insert_self" ON public."captain_settings" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((account_id = ( SELECT auth.uid() AS uid)));
CREATE POLICY "captain_settings_read_self" ON public."captain_settings" AS PERMISSIVE FOR SELECT TO authenticated USING ((account_id = ( SELECT auth.uid() AS uid)));
CREATE POLICY "captain_settings_update_self" ON public."captain_settings" AS PERMISSIVE FOR UPDATE TO authenticated USING ((account_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((account_id = ( SELECT auth.uid() AS uid)));
CREATE POLICY "captains_read_self" ON public."captains" AS PERMISSIVE FOR SELECT TO authenticated USING ((account_id = ( SELECT auth.uid() AS uid)));
COMMIT;

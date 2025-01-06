--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10
-- Dumped by pg_dump version 15.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.characters (
    character_id integer NOT NULL,
    module_id integer,
    name character varying(100),
    "position" character varying(50),
    faction character varying(50),
    avatar_url character varying(255),
    background text,
    personality text,
    initial_attitude integer DEFAULT 50,
    secret_level integer,
    chat_prompt text
);


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    message_id integer NOT NULL,
    session_id integer NOT NULL,
    npc_name character varying(255) NOT NULL,
    content text NOT NULL,
    is_npc boolean NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: chat_messages_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_messages_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_messages_message_id_seq OWNED BY public.chat_messages.message_id;


--
-- Name: dialogue_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dialogue_history (
    dialogue_id integer NOT NULL,
    session_id integer,
    character_id integer,
    dialogue_content text,
    player_response text,
    discovered_secrets json,
    influence_changes json,
    dialogue_time timestamp without time zone
);


--
-- Name: ending_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ending_conditions (
    ending_id integer NOT NULL,
    module_id integer,
    ending_name character varying(100),
    ending_description text,
    required_sanity_range json,
    required_alienation_range json,
    required_faction_influence json,
    required_secrets json,
    required_actions json,
    ending_script text
);


--
-- Name: ending_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ending_triggers (
    trigger_id integer NOT NULL,
    ending_id integer,
    trigger_type character varying(50),
    trigger_condition text,
    trigger_value json
);


--
-- Name: game_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_actions (
    action_id integer NOT NULL,
    module_id integer,
    action_name character varying(100),
    action_type character varying(50),
    description text,
    risk_level integer,
    detection_chance integer,
    sanity_effect integer,
    alienation_effect integer,
    influence_effects json,
    required_skills json,
    success_outcome text,
    failure_outcome text
);


--
-- Name: game_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_phases (
    phase_id integer NOT NULL,
    module_id integer,
    phase_name character varying(100),
    phase_order integer,
    description text,
    required_progress integer,
    unlock_conditions json,
    available_actions json
);


--
-- Name: game_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_sessions (
    session_id integer DEFAULT nextval('public.game_session_id_seq'::regclass) NOT NULL,
    module_id integer,
    player_id integer,
    profession_id integer,
    current_phase_id integer,
    sanity_value integer DEFAULT 100,
    alienation_value integer DEFAULT 0,
    chen_influence integer DEFAULT 50,
    liu_influence integer DEFAULT 50,
    discovered_secrets json,
    completed_actions json,
    session_status character varying(20),
    start_time timestamp without time zone,
    last_save_time timestamp without time zone
);


--
-- Name: modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modules (
    module_id integer NOT NULL,
    title character varying(100),
    description text,
    player_min integer DEFAULT 3,
    player_max integer DEFAULT 5,
    duration_hours integer DEFAULT 8,
    difficulty character varying(20) DEFAULT 'medium'::character varying,
    theme character varying(100),
    create_time timestamp without time zone,
    cover_image_url character varying(255)
);


--
-- Name: monitoring_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monitoring_events (
    event_id integer NOT NULL,
    session_id integer,
    action_id integer,
    detection_roll integer,
    was_detected boolean,
    consequence_type character varying(50),
    consequence_description text,
    event_time timestamp without time zone
);


--
-- Name: player_characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_characters (
    player_character_id integer NOT NULL,
    player_id integer,
    module_id integer,
    profession_id integer,
    creation_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    current_sanity integer DEFAULT 60,
    current_alienation integer DEFAULT 60,
    inventory jsonb DEFAULT '{}'::jsonb,
    completed_phases jsonb DEFAULT '{}'::jsonb,
    current_status character varying(20) DEFAULT 'active'::character varying,
    session_id integer,
    avatar_url character varying
);


--
-- Name: player_characters_player_character_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.player_characters_player_character_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_characters_player_character_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.player_characters_player_character_id_seq OWNED BY public.player_characters.player_character_id;


--
-- Name: player_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_status (
    player_character_id integer NOT NULL,
    sanity_value integer DEFAULT 100,
    alienation_value integer DEFAULT 0,
    chen_influence integer DEFAULT 0,
    liu_influence integer DEFAULT 0,
    discovered_secrets text[] DEFAULT ARRAY[]::text[],
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    session_id integer
);


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.players (
    player_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp without time zone,
    profile_image_url character varying(255),
    bio text,
    total_play_time integer DEFAULT 0,
    achievements json DEFAULT '{}'::json
);


--
-- Name: players_player_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.players_player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: players_player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.players_player_id_seq OWNED BY public.players.player_id;


--
-- Name: professions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.professions (
    profession_id integer NOT NULL,
    module_id integer,
    name character varying(50),
    description text,
    initial_skills json,
    special_abilities text,
    starting_items json
);


--
-- Name: secrets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.secrets (
    secret_id integer NOT NULL,
    module_id integer,
    related_character_id integer,
    secret_type character varying(50),
    content text,
    sanity_loss integer,
    alienation_increase integer,
    discovery_difficulty integer,
    keywords json,
    unlock_conditions json
);


--
-- Name: chat_messages message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN message_id SET DEFAULT nextval('public.chat_messages_message_id_seq'::regclass);


--
-- Name: player_characters player_character_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_characters ALTER COLUMN player_character_id SET DEFAULT nextval('public.player_characters_player_character_id_seq'::regclass);


--
-- Name: players player_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players ALTER COLUMN player_id SET DEFAULT nextval('public.players_player_id_seq'::regclass);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (character_id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (message_id);


--
-- Name: dialogue_history dialogue_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_history
    ADD CONSTRAINT dialogue_history_pkey PRIMARY KEY (dialogue_id);


--
-- Name: ending_conditions ending_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ending_conditions
    ADD CONSTRAINT ending_conditions_pkey PRIMARY KEY (ending_id);


--
-- Name: ending_triggers ending_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ending_triggers
    ADD CONSTRAINT ending_triggers_pkey PRIMARY KEY (trigger_id);


--
-- Name: game_actions game_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_actions
    ADD CONSTRAINT game_actions_pkey PRIMARY KEY (action_id);


--
-- Name: game_phases game_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_phases
    ADD CONSTRAINT game_phases_pkey PRIMARY KEY (phase_id);


--
-- Name: game_sessions game_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- Name: monitoring_events monitoring_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_events
    ADD CONSTRAINT monitoring_events_pkey PRIMARY KEY (event_id);


--
-- Name: player_characters player_characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_pkey PRIMARY KEY (player_character_id);


--
-- Name: player_status player_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_status
    ADD CONSTRAINT player_status_pkey PRIMARY KEY (player_character_id);


--
-- Name: players players_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_email_key UNIQUE (email);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (player_id);


--
-- Name: players players_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_username_key UNIQUE (username);


--
-- Name: professions professions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professions
    ADD CONSTRAINT professions_pkey PRIMARY KEY (profession_id);


--
-- Name: secrets secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secrets
    ADD CONSTRAINT secrets_pkey PRIMARY KEY (secret_id);


--
-- Name: idx_chat_session_npc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_session_npc ON public.chat_messages USING btree (session_id, npc_name);


--
-- Name: characters characters_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: dialogue_history dialogue_history_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_history
    ADD CONSTRAINT dialogue_history_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(character_id);


--
-- Name: dialogue_history dialogue_history_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_history
    ADD CONSTRAINT dialogue_history_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: ending_conditions ending_conditions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ending_conditions
    ADD CONSTRAINT ending_conditions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: ending_triggers ending_triggers_ending_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ending_triggers
    ADD CONSTRAINT ending_triggers_ending_id_fkey FOREIGN KEY (ending_id) REFERENCES public.ending_conditions(ending_id);


--
-- Name: game_actions game_actions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_actions
    ADD CONSTRAINT game_actions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: game_phases game_phases_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_phases
    ADD CONSTRAINT game_phases_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: game_sessions game_sessions_current_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_current_phase_id_fkey FOREIGN KEY (current_phase_id) REFERENCES public.game_phases(phase_id);


--
-- Name: game_sessions game_sessions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: game_sessions game_sessions_profession_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_profession_id_fkey FOREIGN KEY (profession_id) REFERENCES public.professions(profession_id);


--
-- Name: monitoring_events monitoring_events_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_events
    ADD CONSTRAINT monitoring_events_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.game_actions(action_id);


--
-- Name: monitoring_events monitoring_events_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_events
    ADD CONSTRAINT monitoring_events_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: player_characters player_characters_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: player_characters player_characters_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(player_id);


--
-- Name: player_characters player_characters_profession_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_profession_id_fkey FOREIGN KEY (profession_id) REFERENCES public.professions(profession_id);


--
-- Name: player_characters player_characters_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: player_status player_status_player_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_status
    ADD CONSTRAINT player_status_player_character_id_fkey FOREIGN KEY (player_character_id) REFERENCES public.player_characters(player_character_id);


--
-- Name: player_status player_status_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_status
    ADD CONSTRAINT player_status_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: professions professions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professions
    ADD CONSTRAINT professions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: secrets secrets_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secrets
    ADD CONSTRAINT secrets_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: secrets secrets_related_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secrets
    ADD CONSTRAINT secrets_related_character_id_fkey FOREIGN KEY (related_character_id) REFERENCES public.characters(character_id);


--
-- PostgreSQL database dump complete
--


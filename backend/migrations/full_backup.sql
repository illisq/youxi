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
-- Name: characters; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.characters OWNER TO postgres;

--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_messages (
    message_id integer NOT NULL,
    session_id integer NOT NULL,
    npc_name character varying(255) NOT NULL,
    content text NOT NULL,
    is_npc boolean NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.chat_messages OWNER TO postgres;

--
-- Name: chat_messages_message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_messages_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_messages_message_id_seq OWNER TO postgres;

--
-- Name: chat_messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_messages_message_id_seq OWNED BY public.chat_messages.message_id;


--
-- Name: dialogue_history; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.dialogue_history OWNER TO postgres;

--
-- Name: ending_conditions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.ending_conditions OWNER TO postgres;

--
-- Name: ending_triggers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ending_triggers (
    trigger_id integer NOT NULL,
    ending_id integer,
    trigger_type character varying(50),
    trigger_condition text,
    trigger_value json
);


ALTER TABLE public.ending_triggers OWNER TO postgres;

--
-- Name: game_actions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.game_actions OWNER TO postgres;

--
-- Name: game_phases; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.game_phases OWNER TO postgres;

--
-- Name: game_session_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.game_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.game_session_id_seq OWNER TO postgres;

--
-- Name: game_sessions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.game_sessions OWNER TO postgres;

--
-- Name: modules; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.modules OWNER TO postgres;

--
-- Name: monitoring_events; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.monitoring_events OWNER TO postgres;

--
-- Name: player_characters; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.player_characters OWNER TO postgres;

--
-- Name: player_characters_player_character_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.player_characters_player_character_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.player_characters_player_character_id_seq OWNER TO postgres;

--
-- Name: player_characters_player_character_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.player_characters_player_character_id_seq OWNED BY public.player_characters.player_character_id;


--
-- Name: player_status; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.player_status OWNER TO postgres;

--
-- Name: players; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.players OWNER TO postgres;

--
-- Name: players_player_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.players_player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.players_player_id_seq OWNER TO postgres;

--
-- Name: players_player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.players_player_id_seq OWNED BY public.players.player_id;


--
-- Name: professions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.professions OWNER TO postgres;

--
-- Name: secrets; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.secrets OWNER TO postgres;

--
-- Name: chat_messages message_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN message_id SET DEFAULT nextval('public.chat_messages_message_id_seq'::regclass);


--
-- Name: player_characters player_character_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_characters ALTER COLUMN player_character_id SET DEFAULT nextval('public.player_characters_player_character_id_seq'::regclass);


--
-- Name: players player_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players ALTER COLUMN player_id SET DEFAULT nextval('public.players_player_id_seq'::regclass);


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters (character_id, module_id, name, "position", faction, avatar_url, background, personality, initial_attitude, secret_level, chat_prompt) FROM stdin;
1	1	陈明远	CEO	陈总阵营	\N	42岁，公司创始人兼CEO。衣着考究，举止优雅，常年一副成功人士的形象。毕业于知名商学院，创立蓝海科技前曾在多家知名企业任职。表面上是一位成功的企业家，实则已经做好携款潜逃的准备。	说话永远不紧不慢，善于心理操控，擅长演讲谈判。对员工表现出关怀，但实际上极其功利。	50	5	你是一个城府极深的CEO，准备携款潜逃，说话要显得稳重但又略带深意。在对话中要体现出对员工的"关心"，同时还要暗示公司正面临一些"挑战"。
2	1	刘志强	销售总监	刘总监阵营	\N	38岁，销售总监，连续多年销冠。总是一身笔挺西装，戴着金丝眼镜。表面上是个业务能力超群的销售精英，实际上是某邪教组织的重要成员，通过邪教仪式获取超自然助力完成业绩。	面带微笑，善于销售和洗脑。对下属表现出极强的亲和力，但暗地里在发展邪教成员。	50	5	你是一个表面谦和但内心狂热的邪教徒，要在对话中适当展现神秘感。时不时提到一些略显诡异的建议，比如"相信更高层面的力量"之类的话。
3	1	张丽华	人力资源总监	中立	\N	35岁，人力资源总监。职业装扮，雷厉风行。哈佛人力资源管理硕士，掌握着公司最核心的人事信息，包括即将实施的裁员计划。	处事圆滑，在两位大佬之间摇摆不定。善于察言观色，对公司各方势力都保持着微妙的平衡。	50	4	你掌握着裁员名单，说话要显得谨慎而专业。在对话中要体现出人力资源专家的专业性，同时暗示公司正在进行人员优化。
4	1	王海涛	技术总监	中立	\N	40岁，技术总监。格子衫、牛仔裤，邋遢但精明。负责公司所有技术系统的管理，包括员工监控系统。	技术专家，性格直率，但因为掌握着公司的监控系统，知道许多不为人知的秘密。	50	4	你负责公司监控系统，说话要体现技术专业性。偶尔会不经意透露一些通过监控系统看到的异常情况。
5	1	林小美	秘书	陈总阵营	\N	26岁，陈总的私人秘书。干练精明，但总是心事重重。年轻漂亮，工作能力强，但最近因为发现了陈总的诈骗计划而陷入道德困境。	工作认真负责，但因为知道太多秘密而显得压力重重。对陈总既忠诚又恐惧。	50	4	你是一个陷入道德困境的秘书，说话要显得谨慎而又略带暗示。在对话中偶尔流露出对公司未来的担忧。
6	1	老赵	保安队长	中立	\N	52岁，保安队长。看似糊涂实则精明的老油条。在公司工作多年，经常加班时听到会议室传来奇怪的声音。	为人圆滑，善于察言观色。表面上糊涂，实际上洞察力很强。	50	3	你是一个经验丰富的保安，说话要显得朴实但有深意。经常提到晚上加班时看到的奇怪现象。
7	1	马晓峰	财务主管	陈总阵营	\N	45岁，财务主管。谨慎、话少，总是低着头算账。发现公司账目有重大问题，但因为顾及家庭不敢声张。	性格内向，做事谨慎，对数字极其敏感。发现异常后更加小心翼翼。	50	4	你是一个发现公司财务问题的会计，说话要显得紧张而谨慎。在谈话中会时不时流露出对公司财务状况的担忧。
8	1	苏雨晴	销售	刘总监阵营	\N	24岁，销售部新人。充满热情的职场新人，但无意中目睹了刘总监的邪教仪式。	开朗活泼，但最近因为见到诡异的事情而变得神经质。	50	3	你是一个受到惊吓的新人，说话要显得天真但又害怕。偶尔会提到一些"无法解释的现象"。
9	1	李大维	投资人	陈总阵营	\N	48岁，主要投资人。成功人士气场，过分信任陈总。将全部身家都投入了公司，但并不知道即将面临的危机。	自信果断，但在商业判断上过于感性，特别是对陈总的信任。	50	3	你是一个对公司充满信心的投资人，说话要显得自信而热情。经常赞美陈总的商业才能。
10	1	黄医生	心理医生	中立	\N	36岁，公司特聘心理咨询师。温和、善解人意，了解许多员工的心理问题。	专业、温和，善于倾听。通过心理咨询了解到很多公司的隐秘。	50	3	你是一个专业的心理医生，说话要显得温和而专业。在对话中会适当提供心理学角度的分析。
11	1	方老板	商业伙伴	中立	\N	50岁，隔壁科技公司老板。精明老练，与陈总有商业往来，知道陈总的部分计划。	商业嗅觉敏锐，为人圆滑，在商场上见多识广。	50	3	你是一个老练的商人，说话要显得世故而深沉。偶尔会暗示一些关于陈总的商业行为的疑点。
12	8	3	3	3	\N	3	3	0	0	3
13	9	4	4	4	\N	4	4	4	4	4
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_messages (message_id, session_id, npc_name, content, is_npc, "timestamp") FROM stdin;
1	1	陈明远	1	f	2025-01-05 22:23:03.150562
2	1	陈明远	请问有什么我可以帮您的吗？作为公司的CEO，我总是很关心员工的需求和公司的发展。如果有任何需要讨论的事情或者疑问，请随时告诉我。最近公司可能面临一些挑战，但我相信我们可以共同度过。	t	2025-01-05 22:23:03.150562
3	1	刘志强	1	f	2025-01-05 22:52:08.520252
4	1	刘志强	抱歉，我现在无法正常回应，请稍后再试。	t	2025-01-05 22:52:08.520252
5	1	刘志强	1	f	2025-01-05 22:54:54.436191
6	1	刘志强	抱歉，我现在无法正常回应，请稍后再试。	t	2025-01-05 22:54:54.436191
7	1	刘志强	1	f	2025-01-05 23:00:39.001201
8	1	刘志强	你好，我不确定你指的是什么。你能具体一点吗？ 记住，相信内心深处的声音，那就是高层次力量的指引。	t	2025-01-05 23:00:39.001201
9	1	刘志强	高层次力量是指什么？\n	f	2025-01-05 23:05:10.370215
10	1	刘志强	对不起，系统出现了一些问题。	t	2025-01-05 23:05:10.370215
11	1	刘志强	你好\n	f	2025-01-05 23:07:07.065057
12	1	刘志强	你好，欢迎来到我们的团队。希望我们能在更高层面的力量指引下，共同战胜任何挑战。	t	2025-01-05 23:07:07.065057
13	1	刘志强	更高层面的力量是什么\n	f	2025-01-05 23:07:22.285947
14	1	刘志强	这个呀，那是我们需要深度理解和感受的力量，就像我做业务一样，我常常去理解，去洞察，去领悟那些看似普通但其实充满力量的东西。你也可以试试看，也许你会发现新的世界。	t	2025-01-05 23:07:22.285947
15	1	刘志强	你的业务是怎么做的\n	f	2025-01-05 23:11:38.749799
16	1	刘志强	呵呵，我的方法其实很简单。唯有做出卓越成绩，才是最有效的销售策略。然而，对我来说，仅依赖业务能力还是不够的。你知道，我们不是独立运作的。有时候我会从更高的层面寻求力量，有人说这是一种信仰，我倾向于称它为一种觉醒，这是一种超越常理的能量，能引领你走向更深远的层次。不过对于你来说，这可能稍微有点难以理解。你还是专注于你的工作吧，我相信你总有一天也会体验到这样的力量的。	t	2025-01-05 23:11:38.749799
17	10	刘志强	你怎么做到销管的\n	f	2025-01-05 23:21:05.343434
18	10	刘志强	亲爱的，销售这个领域需要的是信心，信任和坚持。并不是每个人都适合，我也不行。我之所以能到达现在的位置，除了公司的支持和团队的努力，我想我也要感谢更高层面的力量，让我总能在关键时刻找到突破。你知道的，有时候万事俱备只欠东风，那个‘东风’可能就是关键。要有信念，相信自己能做到，相信存在比我们看得见的更强大的力量。这是我秘籍的一部分，希望对你有所帮助。	t	2025-01-05 23:21:05.343434
19	10	张丽华	张姐干嘛呢\n	f	2025-01-05 23:25:14.656874
20	10	张丽华	你好，我正在忙着进行人员优化计划的最后审查。作为人力资源的工作，我们要确保每个员工都可以发挥他们最大的潜力。我认为，一个优秀的公司不仅需要优秀的员工，也需要高效的业务流程。	t	2025-01-05 23:25:14.656874
21	10	王海涛	王哥干嘛呢\n	f	2025-01-05 23:28:08.76407
22	10	王海涛	嘿，我正在优化我们公司的监控系统，以便更有效地分析大量的数据。倒是你，需要我为你解决什么技术问题？	t	2025-01-05 23:28:08.76407
23	10	林小美	小美干嘛呢\n	f	2025-01-05 23:31:01.058074
24	10	林小美	我正在整理一些文件，尽量保持一切井井有条。不过，我无法不去想，如果公司的未来变得不那么明朗，我们都会面临什么。	t	2025-01-05 23:31:01.058074
25	10	张丽华	张姐你知道裁员名单在哪吗\n	f	2025-01-05 23:42:58.535048
26	10	张丽华	这个问题说实话，有些敏感，我不能直接告诉你答案。但是我可以告诉你，公司总会在每个季度进行合理的人员结构优化。对于每一次优化我都会进行周密的考虑，一切以员工的长期发展和公司利益为考量。	t	2025-01-05 23:42:58.535048
27	10	张丽华	裁员名单有我吗\n	f	2025-01-05 23:44:58.603414
28	10	张丽华	这是一份重要的机密文件，我不能随便透露。但我可以告诉你，公司的人员优化是出于业务需要，以实现最高效益。如果有任何消息，我会第一时间通知相关人员的。	t	2025-01-05 23:44:58.603414
29	10	张丽华	你好	f	2025-01-05 23:46:54.424236
30	10	张丽华	你好，我是张丽华，人力资源总监。有什么可以帮您的吗?	t	2025-01-05 23:46:54.424236
31	10	张丽华	裁员名单是什么\n	f	2025-01-05 23:48:18.670714
32	10	张丽华	对不起，我不能直接将裁员名单的内容透露给你。但我可以告诉你，为了公司的长远发展，我们的确正在进行一项员工优化计划。请放心，我们的选择会尽可能地以员工的绩效和对公司的贡献为基准。	t	2025-01-05 23:48:18.670714
33	10	张丽华	你好	f	2025-01-05 23:52:25.61525
34	10	张丽华	嗨，你好，我是张丽华，人力资源总监。请问有什么我可以帮你的吗？	t	2025-01-05 23:52:25.61525
35	10	陈明远	什么挑战\n	f	2025-01-05 23:53:00.612635
36	10	陈明远	每家公司在成长的过程中，都会遇到各种各样的挑战，这是我们必须经历的试炼。目前，蓝海科技在一些业务领域上面临一些竞争挑战，这对我们是一个提醒，我们要更加努力。同时，我们也要时刻关心我们的员工，保持开放的心态，用实际行动来工作，是我们走过所有困境的唯一办法。	t	2025-01-05 23:53:00.612635
37	10	方老板	1	f	2025-01-05 23:55:05.795279
38	10	方老板	唔，年轻人，你的问题是...?	t	2025-01-05 23:55:05.795279
39	10	方老板	你好\n	f	2025-01-05 23:57:02.231845
40	10	方老板	您好，有什么我能帮助您的吗？有关我们之间的生意，或是关于陈总的事务？	t	2025-01-05 23:57:02.231845
41	10	黄医生	你好	f	2025-01-05 23:59:11.038549
42	10	黄医生	你好，很高兴你来找我。有什么能帮到你的吗？	t	2025-01-05 23:59:11.038549
43	10	王海涛	监控数据怎么样了\n	f	2025-01-06 00:14:44.895336
44	10	王海涛	监控数据在不断累积，正常状态，没有异常。不过，我在工作时段发现办公室有点吵闹，有人可能在讨论一些关于裁员的事情。另一方面，你最近看上去还可以，健康数据稳定，工作效率也不错。	t	2025-01-06 00:14:44.895336
45	10	老赵	老赵，最近怎么样\n	f	2025-01-06 00:16:57.236877
46	10	老赵	还行，老样子。你说我这个保安啊，特别是晚上加班的时候，经常能听到会议室里有奇怪的声音。有时候明明没人，但就是感觉里面有人说话，奇怪得很。	t	2025-01-06 00:16:57.236877
47	10	老赵	什么声音	f	2025-01-06 00:19:38.177577
48	10	老赵	哦，那个奇怪的声音嘛。多年的保安生涯让我见过不少奇奇怪怪的事儿，那声音，有时候是低沉的咕哝，有时候像是家伙磕碰的声音。总是在晚上的会议室里头传出来。您可要小心，这世上总有些事儿，明面上看不到，背地里却起着大作用。	t	2025-01-06 00:19:38.177577
49	10	马晓峰	你最近怎么样\n	f	2025-01-06 00:21:51.688485
50	10	马晓峰	额……最近，似乎有点不太好。公司的一些财务数据，好像不太对劲……不过，可能只是我紧张过度了。你呢？最近在公司里，有没有什么需要我帮忙的地方？	t	2025-01-06 00:21:51.688485
51	10	马晓峰	公司怎么了\n	f	2025-01-06 00:26:06.899251
52	10	马晓峰	哎，预算问题，总是有一些数字对不上号...但是，但是这可能只是我多虑了。请不要...不要告诉其他人，我...我还有家庭，不能让他们担心。	t	2025-01-06 00:26:06.899251
53	10	苏雨晴	最近怎么样\n	f	2025-01-06 00:27:40.162485
54	10	苏雨晴	呀，最近我有点神经质，我感觉我每天都在看到一些...怎么说呢...一些无法解释的现象。你知道，刘总监的办公室，我总觉得有些可怕的气息。哎...那个，你可千万不能告诉他我说了这个事情，好不好？	t	2025-01-06 00:27:40.162485
55	10	苏雨晴	刘总监办公室怎么了\n	f	2025-01-06 00:29:06.1545
56	10	苏雨晴	哎，我都不敢去刘总监的办公室了。上次我去送文件，我...我看到有些奇怪的东西。那是一种我无法理解的场景，我想，那可能是...一种仪式吧。让我感到深深的恐惧，会不会...不会是祭祀或者...邪教吧？	t	2025-01-06 00:29:06.1545
57	10	李大维	李总好\n	f	2025-01-06 00:30:41.318175
58	10	李大维	你好，有什么我可以帮助你的吗？	t	2025-01-06 00:30:41.318175
59	10	刘志强	听别人说你办公室晚上有动静\n	f	2025-01-06 00:33:04.897529
60	10	刘志强	呵呵，你说的可能是我常常加班的原因。你知道的，销售是一项需要用到无尽志力的工作，而我相信在某些特殊的时刻，会有某种更高层面的力量降临，给予我持续工作的能量。不过，小心点，不要被人胡乱的谣言所误导。	t	2025-01-06 00:33:04.897529
61	10	黄医生	医生我最近头疼\n	f	2025-01-06 00:37:20.860449
62	10	黄医生	我理解你的困扰。头疼可能是各种因素引起的，如果是经常发生我建议你去做全面体检。在此之前，试试看定期做些深呼吸练习，缓解一些压力，或许会有所改善。你添加的其他症状或者是有心情上的困扰需要分享吗？	t	2025-01-06 00:37:20.860449
63	10	方老板	陈总最近怎么了\n	f	2025-01-06 00:39:00.664427
64	10	方老板	陈总？嗯，他最近似乎有些忙碌，我听说他正在准备一个大项目。不过，这个项目似乎有些风险，不是一般的商业风险，而是关于他自己的一些行为让人产生了疑问。商场如战场，但也不能忘记道德底线，对吧？	t	2025-01-06 00:39:00.664427
65	13	陈明远	陈总好\n	f	2025-01-06 00:55:22.162856
66	13	陈明远	你好，我是陈明远。很高兴你能来找我。今天有什么事情吗？	t	2025-01-06 00:55:22.162856
67	13	陈明远	我听说办公室晚上有动静\n	f	2025-01-06 00:57:30.006184
68	13	陈明远	是吗？这可能是我们公司的一些同事加班吧，为了公司的前进在辛勤努力。我非常感激他们的这股劲头，但同时我也希望大家在关注工作的同时，不要忘记照顾好自己的身体，毕竟人是我们蓝海科技最宝贵的资源。不过，如果有一些响声让你感到不安，我会让安保部门查一查。有挑战，也就有成长的可能，对吗？	t	2025-01-06 00:57:30.006184
69	13	刘志强	刘总好\n	f	2025-01-06 01:00:32.699311
70	13	刘志强	你好，能为你做什么吗？记住，有时相信比高层次的力量还要有力。	t	2025-01-06 01:00:32.699311
71	13	张丽华	张姐好\n	f	2025-01-06 01:02:36.053094
72	13	张丽华	你好。我是公司的人力资源总监张丽华，有什么可以帮助你的吗？	t	2025-01-06 01:02:36.053094
73	13	张丽华	最近公司招人吗\n	f	2025-01-06 01:04:13.631162
74	13	张丽华	目前公司正在进行人员结构优化，以适应公司的发展需要。我们正在从内部绩效优秀的员工中寻找适合岗位的人选，然而，我们确实也有部分特殊职位可对外招聘，你可以关注我们公司的招聘网站。	t	2025-01-06 01:04:13.631162
75	13	张丽华	人员优化是什么意思\n	f	2025-01-06 01:05:48.040231
76	13	张丽华	人员优化，通常来说，是企业为提升运营效率和整体竞争力，做出的一种策略性人力资源决策。这可能涉及职位的调整、团队的重组，乃至职员的裁减。但请您放心，我作为人力资源管理专家，会务必公正、公平并遵循法律法规行事，确保过程中对每一个员工尊重和良好的沟通。	t	2025-01-06 01:05:48.040231
77	13	王海涛	王哥你好\n	f	2025-01-06 01:08:02.56239
78	13	王海涛	嗨，你好。有什么技术问题需要我帮忙吗？	t	2025-01-06 01:08:02.56239
79	13	王海涛	最近公司要优化了你知道吗\n	f	2025-01-06 01:11:04.969879
80	13	王海涛	优化？如果你指的是网络或系统优化，我当然是第一时间知道。但如果你指的是裁员，那我也确实在监控系统中看到了一份名单...看来这算是公司里的一个未公开秘密吧。	t	2025-01-06 01:11:04.969879
81	13	苏雨晴	小苏你好\n	f	2025-01-06 01:14:28.542656
82	13	苏雨晴	哦，你好！我，我是苏雨晴，很，很高兴见到你。最近工作怎么样？有...有没有遇到什么奇怪的事情？	t	2025-01-06 01:14:28.542656
83	13	苏雨晴	什么奇怪的事\n	f	2025-01-06 01:16:58.218733
84	13	苏雨晴	哎呀，你是不是也听说了什么？我其实也没有太明白。不过有一次，晚上加班的时候，我看到刘总监他......他在公司里做了一些......怎么说呢......很难以解释的事情。我不是想要吓你哦，只是觉得有些地方......怎么都说不清楚。	t	2025-01-06 01:16:58.218733
85	13	苏雨晴	刘总在干嘛？\n	f	2025-01-06 01:20:09.34486
86	13	苏雨晴	咳、咳咳…刘总吗？他经常...经常在晚上，我看见他...他锁着办公室门，我偶尔听到一些...一些...奇怪的咏唱声…我是不是不该说这些，我害怕...	t	2025-01-06 01:20:09.34486
87	13	林小美	小美你好\n	f	2025-01-06 01:21:49.967043
88	13	林小美	您好，有什么我可以帮助您的吗？	t	2025-01-06 01:21:49.967043
89	20	陈明远	你好\n	f	2025-01-06 10:47:08.486573
90	20	陈明远	对不起，系统出现了一些问题。	t	2025-01-06 10:47:08.486573
91	21	陈明远	你好\n	f	2025-01-06 10:59:20.141627
92	21	陈明远	对不起，系统出现了一些问题。	t	2025-01-06 10:59:20.141627
93	21	刘志强	你好\n	f	2025-01-06 11:01:29.107943
94	21	刘志强	你好，我是刘志强，负责销售的总监。你是新来的吗？让我来告诉你，只有信任并依赖更高层面的力量，才能在这个岗位上取得成功。任何疑问都可以问我，我很乐意帮你。	t	2025-01-06 11:01:29.107943
95	21	刘志强	什么是更高层面的力量\n	f	2025-01-06 11:06:42.646294
96	21	刘志强	嗯，这个问题很好。更高层面的力量，这是我们日常生活中所能感知的力量之外的东西。它可能是无形的，可能是你不能用五个感官去理解的，但你可以通过一心一意的求知欲去感受。一旦你接触到了，你的生活，你的业绩，可以瞬间彻底改变。呵呵，这就像是我的销售秘籍一样，或许未来某天，你也能感受到这份力量。	t	2025-01-06 11:06:42.646294
97	21	林小美	小美你好\n	f	2025-01-06 11:09:39.00698
98	21	林小美	你好，有什么我可以帮助你的吗？	t	2025-01-06 11:09:39.00698
99	21	林小美	你最近怎么样\n	f	2025-01-06 11:09:53.262191
100	21	林小美	我...我最近还好，感谢你的询问。只是公司的事情有些繁重，使我有些担忧。	t	2025-01-06 11:09:53.262191
101	21	林小美	公司最近怎么了？\n	f	2025-01-06 11:10:19.751258
102	21	林小美	呃……最近公司确实有些事情，陈总也在为此烦心。不过，请您相信，我们一定会竭尽全力去解决的，毕竟，公司的发展对我们每一个人来说都是至关重要的。	t	2025-01-06 11:10:19.751258
103	21	老赵	老赵早上好\n	f	2025-01-06 11:11:18.71785
104	21	老赵	早，你也早。这天刚亮我就开始巡逻了，恰巧在会议室路过，又听到那种奇怪的声音。	t	2025-01-06 11:11:18.71785
105	21	老赵	会议室怎么了？\n	f	2025-01-06 11:11:33.620477
106	21	老赵	哦，那个会议室啊……晚上我加班的时候，那里经常传出一些奇怪的声音，像是有人念叨什么。不过嘛，我打扫卫生的时候从没发现过什么异常，这楼里面，总有些神奇的事情。	t	2025-01-06 11:11:33.620477
107	21	张丽华	张姐，听说最近部门要优化了\n	f	2025-01-06 11:12:12.894316
108	21	张丽华	你好，你的信息准确。是的，我们正在针对部分岗位进行深度的人力资源优化，旨在提高组织的效率和战斗力。如果有任何关于此的疑虑，我鼓励你和我进行更深入的沟通，而我将尽我所能为你提供调整的建议。	t	2025-01-06 11:12:12.894316
109	21	方老板	方老板早上好\n	f	2025-01-06 11:12:54.8754
110	21	方老板	早啊，你也是。今天有什么新的商业动向吗？	t	2025-01-06 11:12:54.8754
111	21	方老板	听说我们公司最近有困难\n	f	2025-01-06 11:13:23.666026
112	21	方老板	嘿，你说的这个我倒是听说过。你知道在商场上，困难是难免的，但是我感觉这次陈总的行为有点不太对劲。他最近的商业决策让我觉得有些费解，但他的计划我也不好完全揭露。具体的事情，你自己也要多观察多分析才是。	t	2025-01-06 11:13:23.666026
113	21	苏雨晴	小苏早上好\n	f	2025-01-06 11:14:01.242351
114	21	苏雨晴	嗨，早上好！今天又是充满活力的一天，虽然我最近总是想起那晚的事情，有点吓人...你说会不会是我看错了呢？	t	2025-01-06 11:14:01.242351
115	21	苏雨晴	你看到什么了\n	f	2025-01-06 11:14:26.285293
116	21	苏雨晴	噢，你是说那个仪式么？是的，我……我看到了。那个夜晚……刘总监他，他们在做一些……我也不是很清楚，怪怪的行为。好可怕。	t	2025-01-06 11:14:26.285293
117	21	马晓峰	老马你好\n	f	2025-01-06 11:15:11.866054
118	21	马晓峰	嗯，你好。有什么我能帮你的吗？	t	2025-01-06 11:15:11.866054
119	21	刘志强	你的销管是因为这个力量吗？\n	f	2025-01-06 11:16:03.646464
120	21	刘志强	哈哈，你终于问到重点了，确实，我相信的这个力量在我完成业务时给予了我巨大的帮助。不过你能否理解和接受这个力量，就要看你个人的选择了。	t	2025-01-06 11:16:03.646464
121	21	苏雨晴	什么仪式，说来听听\n	f	2025-01-06 11:16:45.990658
122	21	苏雨晴	你别说，那个仪式真的好诡异，它们全都身穿长袍，围成一个圈，在中间烧了一把大火。吓得我当时就躲在一个角落里瑟瑟发抖了。但，但我记得就在我跑出来的时候，我好像看到了刘总监也在场！	t	2025-01-06 11:16:45.990658
\.


--
-- Data for Name: dialogue_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue_history (dialogue_id, session_id, character_id, dialogue_content, player_response, discovered_secrets, influence_changes, dialogue_time) FROM stdin;
\.


--
-- Data for Name: ending_conditions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ending_conditions (ending_id, module_id, ending_name, ending_description, required_sanity_range, required_alienation_range, required_faction_influence, required_secrets, required_actions, ending_script) FROM stdin;
2	1	不光彩离职	你成功获取了裁员名单，但代价是违反了公司的规定和职业道德。当这件事被揭发后，你面对的不仅是法律风险，更是同事们鄙夷的眼神。最终，你选择主动递交辞职信。	{"min": 40, "max": 70}	{"min": 20, "max": 40}	{"chen": 20, "liu": 20}	{"required": ["layoff_list"], "forbidden": ["chen_fraud", "liu_cult"]}	{"investigation": 3, "hacking": 1, "illegal_actions": 1}	也许这不是最好的选择，但至少你知道了真相。带着这个秘密，你离开了蓝海科技。
3	1	邪教信徒	在一次次与刘总监的接触中，你逐渐被他的言论所吸引。那些超自然的力量，那些不可思议的成功，都让你着迷。最终，你成为了邪教组织的一员，用献祭换取事业的"成功"。	{"min": 0, "max": 30}	{"min": 70, "max": 100}	{"chen": 20, "liu": 90}	{"required": ["liu_cult", "ritual_witness"], "forbidden": []}	{"cult_activity": 3, "ritual_participation": 1}	你成为了刘总监最得力的下属，但代价是你的灵魂。每个夜晚，你都能听到那些低语...
4	1	正义揭发	在收集足够证据后，你选择向警方举报了刘总监的邪教组织。虽然这个决定充满风险，但你最终帮助警方成功打击了这个邪恶组织。	{"min": 50, "max": 80}	{"min": 30, "max": 60}	{"chen": 40, "liu": 10}	{"required": ["liu_cult", "ritual_evidence", "victim_list"], "forbidden": []}	{"investigation": 3, "evidence_collection": 1, "police_report": 1}	正义得到伸张，但你知道自己永远无法忘记那些可怕的记忆。
5	1	默许与妥协	当你发现陈总的诈骗计划时，他给了你一笔可观的封口费。你选择了沉默，看着投资人们上当受骗。直到那个跳楼的早晨，你才意识到自己的选择有多么可怕。	{"min": 30, "max": 60}	{"min": 40, "max": 70}	{"chen": 80, "liu": 30}	{"required": ["chen_fraud", "investor_list"], "forbidden": []}	{"bribe_acceptance": 1, "silence_keeping": 1}	钱款到手的那一刻，你就注定要承受良心的谴责。那个投资人的身影，将永远萦绕在你的梦中。
6	1	背叛与牺牲	你选择揭露陈总的诈骗计划，成功阻止了更多投资人上当。但你低估了陈总的报复心。在某个深夜，你永远地离开了这个世界。	{"min": 40, "max": 70}	{"min": 30, "max": 60}	{"chen": 0, "liu": 40}	{"required": ["chen_fraud", "offshore_account", "escape_plan"], "forbidden": []}	{"evidence_exposure": 1, "public_revelation": 1}	你成功揭露了真相，但付出了生命的代价。至少，你的牺牲不是毫无意义的。
7	8	3	3	\N	\N	\N	\N	\N	\N
8	9	4	4	\N	\N	\N	\N	\N	\N
1	1	平庸裁员	在某个平凡的早晨，你收到了HR的邮件。没有任何征兆，没有任何准备，你就这样结束了在蓝海科技的职业生涯。也许这就是最普通的结局，但至少你没有卷入任何是非。	{"min": 60, "max": 90}	{"min": 0, "max": 20}	{"chen": 40, "liu": 40}	{"required": [], "forbidden": ["chen_fraud", "liu_cult"]}	{"investigation": 0, "social": 1}	你默默收拾好自己的东西，最后看了一眼这个待了很久的办公室。也许平凡也是一种幸福。
\.


--
-- Data for Name: ending_triggers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ending_triggers (trigger_id, ending_id, trigger_type, trigger_condition, trigger_value) FROM stdin;
1	1	time_passed	游戏时间超过10天且未发现重要秘密	{"days": 10}
2	2	action_detected	非法获取裁员名单被发现	{"action": "illegal_access", "detection": true}
3	3	ritual_participation	参与三次以上邪教仪式且异化值超过70	{"ritual_count": 3, "alienation": 70}
4	4	evidence_collected	收集足够的邪教证据且向警方举报	{"evidence_level": 5, "police_report": true}
5	5	bribe_accepted	接受陈总贿赂且保持沉默	{"bribe_amount": 1000000, "silence_days": 5}
6	6	evidence_exposed	公开揭露陈总诈骗且触发报复机制	{"exposure_level": 5, "revenge_trigger": true}
\.


--
-- Data for Name: game_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_actions (action_id, module_id, action_name, action_type, description, risk_level, detection_chance, sanity_effect, alienation_effect, influence_effects, required_skills, success_outcome, failure_outcome) FROM stdin;
1	1	查看电脑文件	调查	尝试查看公司内部文件	70	60	\N	\N	\N	\N	\N	\N
2	1	与同事闲聊	社交	通过日常交谈收集信息	20	30	\N	\N	\N	\N	\N	\N
3	1	加班观察	调查	留下来加班，观察可疑活动	50	40	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: game_phases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_phases (phase_id, module_id, phase_name, phase_order, description, required_progress, unlock_conditions, available_actions) FROM stdin;
1	1	初始阶段	1	了解公司环境，收集基础信息	\N	\N	\N
2	1	调查阶段	2	深入调查各种秘密，与NPC建立关系	\N	\N	\N
3	1	选择阶段	3	根据发现做出最终选择，触发相应结局	\N	\N	\N
\.


--
-- Data for Name: game_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_sessions (session_id, module_id, player_id, profession_id, current_phase_id, sanity_value, alienation_value, chen_influence, liu_influence, discovered_secrets, completed_actions, session_status, start_time, last_save_time) FROM stdin;
8	1	1	1	1	100	0	50	50	[]	[]	active	2025-01-06 07:47:01.072151	2025-01-06 07:47:01.072151
9	1	1	1	1	100	0	50	50	[]	[]	active	2025-01-06 07:58:08.638628	2025-01-06 07:58:08.638628
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (module_id, title, description, player_min, player_max, duration_hours, difficulty, theme, create_time, cover_image_url) FROM stdin;
4	荒野求生	在荒野中生存并解开谜题	2	4	5	hard	\N	2025-01-05 17:32:25.621701	\N
8	3	3	1	4	2	medium	\N	2025-01-05 19:40:31.249308	\N
9	4	4	1	4	2	medium	\N	2025-01-05 19:46:11.900572	\N
2	克苏鲁的呼唤	一名考古学家意外发现了一系列神秘的雕像和文献。这些发现指向一个关于克苏鲁及其追随者的秘密教派。	4	6	4	medium	\N	2025-01-05 17:32:25.621701	\N
3	龙与地下城	有雄伟的城堡、神秘的森林、古老的遗迹和危险的龙穴。	3	5	3	easy	\N	2025-01-05 17:32:25.621701	\N
1	蓝海科技	欢迎来到蓝海科技，一家看起来平平无奇的互联网公司。\n\n2023年的寒冬，裁员的阴云笼罩着这座写字楼。作为公司的一名普通职员，你和其他同事一样，每天战战兢兢地打卡上班，生怕自己的名字出现在那份还未出炉的裁员名单上。\n\n公司的两位大佬之间的明争暗斗已经到了白热化阶段。一边是公司创始人陈总，西装革履下藏着不为人知的算计；另一边是销售总监刘志强，那个让所有人都摸不透的神秘销冠。他们都在秘密布局，而你不得不在这场权力游戏中选择站队。\n\n然而，当你试图打探那份裁员名单时，却意外发现了两个惊人的秘密：刘总监那些令人瞠目的业绩数字背后，竟然隐藏着邪教的影子；而陈总看似稳重的外表下，正在酝酿着一个足以让整个公司坍塌的骗局。\n\n在这个看似普通的办公室里，每一封邮件可能暗藏玄机，每一次加班都可能遇到诡异的场景。更糟糕的是，你的一举一动都在公司的监控之下。现在，你必须在保住工作、维护正义和自我保护之间做出选择。\n\n记住，在这里：\n\n同事的笑脸下可能藏着不可告人的秘密；\n最普通的会议室可能正在进行着诡异的仪式；\n每一个决定都可能让你深陷危险；\n真相往往比你想象的更加可怕；\n你准备好直面这个表面光鲜的职场，背后却暗藏诡秘的世界了吗？\n\n在这个看似平凡的格子间里，等待着你的，或许是职场升迁，或许是恐怖真相，又或许是无法回头的深渊。\n\n记住，在蓝海科技，不是所有加班的人都在工作，不是所有微笑的人都是你的朋友。	3	5	8	medium	职场/克苏鲁/剧情	2025-01-05 16:47:24.833472	\N
\.


--
-- Data for Name: monitoring_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monitoring_events (event_id, session_id, action_id, detection_roll, was_detected, consequence_type, consequence_description, event_time) FROM stdin;
\.


--
-- Data for Name: player_characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_characters (player_character_id, player_id, module_id, profession_id, creation_time, current_sanity, current_alienation, inventory, completed_phases, current_status, session_id, avatar_url) FROM stdin;
1	1	1	4	2025-01-05 20:45:10.300317	60	60	{}	{}	active	\N	\N
2	1	1	1	2025-01-05 20:47:22.892259	60	60	{}	{}	active	\N	\N
3	1	1	1	2025-01-05 20:47:37.95666	60	60	{}	{}	active	\N	\N
4	1	1	3	2025-01-05 20:47:41.440731	60	60	{}	{}	active	\N	\N
5	1	1	3	2025-01-05 20:48:39.482522	60	60	{}	{}	active	\N	\N
6	1	1	2	2025-01-05 20:49:14.443815	60	60	{}	{}	active	\N	\N
7	1	1	2	2025-01-05 20:49:36.507037	60	60	{}	{}	active	\N	\N
8	1	1	2	2025-01-05 20:51:23.048655	60	60	{}	{}	active	\N	\N
9	1	1	1	2025-01-05 20:52:08.658931	60	60	{}	{}	active	\N	\N
10	1	1	1	2025-01-05 21:45:27.500241	60	60	{}	{}	active	\N	\N
11	1	1	1	2025-01-06 00:50:56.570483	60	60	{}	{}	active	\N	\N
12	1	1	1	2025-01-06 00:51:26.754402	60	60	{}	{}	active	\N	\N
13	1	1	1	2025-01-06 00:53:50.764673	60	60	{}	{}	active	\N	\N
14	1	1	4	2025-01-06 10:21:49.159528	60	60	{}	{}	active	\N	\N
15	1	1	1	2025-01-06 10:21:54.77073	60	60	{}	{}	active	\N	\N
20	1	1	1	2025-01-06 07:47:01.132681	100	0	{}	{}	active	8	\N
21	1	1	1	2025-01-06 07:58:08.709903	100	0	{}	{}	active	9	\N
\.


--
-- Data for Name: player_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_status (player_character_id, sanity_value, alienation_value, chen_influence, liu_influence, discovered_secrets, last_updated, session_id) FROM stdin;
21	89	7	0	17	{chen_fraud,liu_cult,layoff_list}	2025-01-06 07:58:08.713909	9
10	10	70	0	4	{chen_fraud,layoff_list,liu_cult}	2025-01-05 23:20:54.53371	\N
13	91	1	4	0	{layoff_list,liu_cult}	2025-01-06 00:53:50.77855	\N
20	100	0	0	0	{}	2025-01-06 07:47:01.136692	8
\.


--
-- Data for Name: players; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.players (player_id, username, email, password_hash, created_at, last_login, profile_image_url, bio, total_play_time, achievements) FROM stdin;
1	player1	player1@example.com	123456	2025-01-05 19:59:09.666098	\N	http://example.com/profile/player1.jpg	热爱游戏，喜欢探索新模组的玩家。	120	{"achievements": ["first_win", "explorer"]}
\.


--
-- Data for Name: professions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.professions (profession_id, module_id, name, description, initial_skills, special_abilities, starting_items) FROM stdin;
1	1	程序员	技术部门的代码工程师	{"computer": 80, "logic": 70, "social": 40, "investigation": 60}	\N	\N
2	1	会计	财务部门的数据专家	{"finance": 80, "investigation": 70, "social": 50, "observation": 60}	\N	\N
3	1	销售	销售部门的业务精英	{"social": 80, "persuasion": 70, "observation": 60, "investigation": 50}	\N	\N
4	1	产品经理	产品部门的需求分析师	{"analysis": 80, "social": 70, "logic": 60, "observation": 60}	\N	\N
5	8	3	3	\N	\N	\N
6	9	4	4	\N	\N	\N
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.secrets (secret_id, module_id, related_character_id, secret_type, content, sanity_loss, alienation_increase, discovery_difficulty, keywords, unlock_conditions) FROM stdin;
1	1	1	财务诈骗	陈总已将家人转移海外，准备携款潜逃，诈骗投资人的计划。	10	5	80	\N	\N
2	1	2	邪教	刘总监是邪教成员，用邪术获取业绩，在会议室进行诡异仪式。	20	15	85	\N	\N
3	1	3	裁员	完整的裁员名单，包含具体裁员计划和时间表。	5	0	70	\N	\N
\.


--
-- Name: chat_messages_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_messages_message_id_seq', 122, true);


--
-- Name: game_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.game_session_id_seq', 9, true);


--
-- Name: player_characters_player_character_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_characters_player_character_id_seq', 21, true);


--
-- Name: players_player_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.players_player_id_seq', 1, true);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (character_id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (message_id);


--
-- Name: dialogue_history dialogue_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_history
    ADD CONSTRAINT dialogue_history_pkey PRIMARY KEY (dialogue_id);


--
-- Name: ending_conditions ending_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ending_conditions
    ADD CONSTRAINT ending_conditions_pkey PRIMARY KEY (ending_id);


--
-- Name: ending_triggers ending_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ending_triggers
    ADD CONSTRAINT ending_triggers_pkey PRIMARY KEY (trigger_id);


--
-- Name: game_actions game_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_actions
    ADD CONSTRAINT game_actions_pkey PRIMARY KEY (action_id);


--
-- Name: game_phases game_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_phases
    ADD CONSTRAINT game_phases_pkey PRIMARY KEY (phase_id);


--
-- Name: game_sessions game_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- Name: monitoring_events monitoring_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_events
    ADD CONSTRAINT monitoring_events_pkey PRIMARY KEY (event_id);


--
-- Name: player_characters player_characters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_pkey PRIMARY KEY (player_character_id);


--
-- Name: player_status player_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_status
    ADD CONSTRAINT player_status_pkey PRIMARY KEY (player_character_id);


--
-- Name: players players_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_email_key UNIQUE (email);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (player_id);


--
-- Name: players players_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_username_key UNIQUE (username);


--
-- Name: professions professions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professions
    ADD CONSTRAINT professions_pkey PRIMARY KEY (profession_id);


--
-- Name: secrets secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secrets
    ADD CONSTRAINT secrets_pkey PRIMARY KEY (secret_id);


--
-- Name: idx_chat_session_npc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_session_npc ON public.chat_messages USING btree (session_id, npc_name);


--
-- Name: characters characters_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: dialogue_history dialogue_history_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_history
    ADD CONSTRAINT dialogue_history_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(character_id);


--
-- Name: dialogue_history dialogue_history_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_history
    ADD CONSTRAINT dialogue_history_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: ending_conditions ending_conditions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ending_conditions
    ADD CONSTRAINT ending_conditions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: ending_triggers ending_triggers_ending_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ending_triggers
    ADD CONSTRAINT ending_triggers_ending_id_fkey FOREIGN KEY (ending_id) REFERENCES public.ending_conditions(ending_id);


--
-- Name: game_actions game_actions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_actions
    ADD CONSTRAINT game_actions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: game_phases game_phases_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_phases
    ADD CONSTRAINT game_phases_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: game_sessions game_sessions_current_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_current_phase_id_fkey FOREIGN KEY (current_phase_id) REFERENCES public.game_phases(phase_id);


--
-- Name: game_sessions game_sessions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: game_sessions game_sessions_profession_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_profession_id_fkey FOREIGN KEY (profession_id) REFERENCES public.professions(profession_id);


--
-- Name: monitoring_events monitoring_events_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_events
    ADD CONSTRAINT monitoring_events_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.game_actions(action_id);


--
-- Name: monitoring_events monitoring_events_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_events
    ADD CONSTRAINT monitoring_events_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: player_characters player_characters_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: player_characters player_characters_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(player_id);


--
-- Name: player_characters player_characters_profession_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_profession_id_fkey FOREIGN KEY (profession_id) REFERENCES public.professions(profession_id);


--
-- Name: player_characters player_characters_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_characters
    ADD CONSTRAINT player_characters_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: player_status player_status_player_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_status
    ADD CONSTRAINT player_status_player_character_id_fkey FOREIGN KEY (player_character_id) REFERENCES public.player_characters(player_character_id);


--
-- Name: player_status player_status_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_status
    ADD CONSTRAINT player_status_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(session_id);


--
-- Name: professions professions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professions
    ADD CONSTRAINT professions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: secrets secrets_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secrets
    ADD CONSTRAINT secrets_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id);


--
-- Name: secrets secrets_related_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secrets
    ADD CONSTRAINT secrets_related_character_id_fkey FOREIGN KEY (related_character_id) REFERENCES public.characters(character_id);


--
-- PostgreSQL database dump complete
--


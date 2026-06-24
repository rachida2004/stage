--
-- PostgreSQL database dump
--

\restrict BaYpetEh4MJBlTqmhK8F6qS0tT63NPNUsZI59F1JSd2V7rXlf30iCwTgkXI64UI

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: categorie_base; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.categorie_base AS ENUM (
    'FAQ',
    'PROCEDURE',
    'SOLUTION',
    'GUIDE',
    'AUTRE'
);


ALTER TYPE public.categorie_base OWNER TO postgres;

--
-- Name: priorite; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.priorite AS ENUM (
    'FAIBLE',
    'MOYENNE',
    'ELEVEE',
    'URGENTE'
);


ALTER TYPE public.priorite OWNER TO postgres;

--
-- Name: statut_invitation; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.statut_invitation AS ENUM (
    'EN_ATTENTE',
    'PLANIFIEE',
    'EN_COURS',
    'TERMINEE',
    'NON_TRAITEE'
);


ALTER TYPE public.statut_invitation OWNER TO postgres;

--
-- Name: statut_reponse; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.statut_reponse AS ENUM (
    'EN_ATTENTE',
    'ACCEPTEE',
    'REFUSEE',
    'EXCUSEE'
);


ALTER TYPE public.statut_reponse OWNER TO postgres;

--
-- Name: statut_ticket; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.statut_ticket AS ENUM (
    'EN_ATTENTE',
    'EN_COURS',
    'EN_PAUSE',
    'RESOLU',
    'FERME'
);


ALTER TYPE public.statut_ticket OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: affectation_invitation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.affectation_invitation (
    id bigint NOT NULL,
    invitation_id bigint NOT NULL,
    agent_id bigint NOT NULL,
    responsable_principal boolean DEFAULT false NOT NULL,
    date_affectation timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.affectation_invitation OWNER TO postgres;

--
-- Name: affectation_invitation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.affectation_invitation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.affectation_invitation_id_seq OWNER TO postgres;

--
-- Name: affectation_invitation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.affectation_invitation_id_seq OWNED BY public.affectation_invitation.id;


--
-- Name: affectation_ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.affectation_ticket (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    agent_id bigint NOT NULL,
    responsable_principal boolean DEFAULT false NOT NULL,
    date_affectation timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.affectation_ticket OWNER TO postgres;

--
-- Name: affectation_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.affectation_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.affectation_ticket_id_seq OWNER TO postgres;

--
-- Name: affectation_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.affectation_ticket_id_seq OWNED BY public.affectation_ticket.id;


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_settings (
    cle character varying(255) NOT NULL,
    valeur character varying(255) NOT NULL
);


ALTER TABLE public.app_settings OWNER TO postgres;

--
-- Name: base_communication; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.base_communication (
    id bigint NOT NULL,
    titre character varying(255) NOT NULL,
    contenu text NOT NULL,
    categorie public.categorie_base DEFAULT 'AUTRE'::public.categorie_base NOT NULL,
    mots_cles text,
    date_creation timestamp without time zone DEFAULT now() NOT NULL,
    date_maj timestamp without time zone DEFAULT now() NOT NULL,
    auteur_id bigint,
    actif boolean DEFAULT true NOT NULL
);


ALTER TABLE public.base_communication OWNER TO postgres;

--
-- Name: base_communication_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.base_communication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.base_communication_id_seq OWNER TO postgres;

--
-- Name: base_communication_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.base_communication_id_seq OWNED BY public.base_communication.id;


--
-- Name: base_communication_ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.base_communication_ticket (
    id bigint NOT NULL,
    base_communication_id bigint NOT NULL,
    ticket_id bigint NOT NULL
);


ALTER TABLE public.base_communication_ticket OWNER TO postgres;

--
-- Name: base_communication_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.base_communication_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.base_communication_ticket_id_seq OWNER TO postgres;

--
-- Name: base_communication_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.base_communication_ticket_id_seq OWNED BY public.base_communication_ticket.id;


--
-- Name: communication; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.communication (
    id bigint NOT NULL,
    message character varying(255) NOT NULL,
    date timestamp without time zone DEFAULT now() NOT NULL,
    auteur_id bigint NOT NULL,
    ticket_id bigint NOT NULL
);


ALTER TABLE public.communication OWNER TO postgres;

--
-- Name: communication_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.communication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.communication_id_seq OWNER TO postgres;

--
-- Name: communication_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.communication_id_seq OWNED BY public.communication.id;


--
-- Name: invitation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invitation (
    id bigint NOT NULL,
    objet text NOT NULL,
    date_debut date NOT NULL,
    date_fin date NOT NULL,
    nombre_participant integer DEFAULT 0,
    statut character varying(255) DEFAULT 'EN_ATTENTE'::public.statut_invitation NOT NULL,
    visibilite character varying(255) DEFAULT 'PUBLIC'::character varying,
    date_creation timestamp without time zone DEFAULT now() NOT NULL,
    structure_emettrice bigint,
    lieu character varying(255),
    ampliation character varying(255),
    contenu text,
    numero_reference character varying(255),
    signataire_nom character varying(255),
    signataire_qualite character varying(255),
    ville character varying(255),
    mode_creation character varying(255)
);


ALTER TABLE public.invitation OWNER TO postgres;

--
-- Name: invitation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invitation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invitation_id_seq OWNER TO postgres;

--
-- Name: invitation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invitation_id_seq OWNED BY public.invitation.id;


--
-- Name: notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification (
    id bigint NOT NULL,
    message character varying(255) NOT NULL,
    date_envoi timestamp without time zone DEFAULT now() NOT NULL,
    canal character varying(255) DEFAULT 'INTERNE'::character varying,
    statut boolean DEFAULT false NOT NULL,
    categorie character varying(255) DEFAULT 'INVITATION'::character varying,
    resource_id character varying(255),
    action_label character varying(255),
    utilisateur_id bigint NOT NULL
);


ALTER TABLE public.notification OWNER TO postgres;

--
-- Name: notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_id_seq OWNER TO postgres;

--
-- Name: notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_id_seq OWNED BY public.notification.id;


--
-- Name: piece_jointe_invitation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.piece_jointe_invitation (
    id bigint NOT NULL,
    nom character varying(255) NOT NULL,
    type character varying(255),
    chemin character varying(255) NOT NULL,
    date_envoi timestamp without time zone DEFAULT now() NOT NULL,
    invitation_id bigint NOT NULL
);


ALTER TABLE public.piece_jointe_invitation OWNER TO postgres;

--
-- Name: piece_jointe_invitation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.piece_jointe_invitation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.piece_jointe_invitation_id_seq OWNER TO postgres;

--
-- Name: piece_jointe_invitation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.piece_jointe_invitation_id_seq OWNED BY public.piece_jointe_invitation.id;


--
-- Name: piece_jointe_ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.piece_jointe_ticket (
    id bigint NOT NULL,
    nom character varying(255) NOT NULL,
    type character varying(255),
    chemin character varying(255) NOT NULL,
    date_envoi timestamp without time zone DEFAULT now() NOT NULL,
    ticket_id bigint NOT NULL
);


ALTER TABLE public.piece_jointe_ticket OWNER TO postgres;

--
-- Name: piece_jointe_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.piece_jointe_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.piece_jointe_ticket_id_seq OWNER TO postgres;

--
-- Name: piece_jointe_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.piece_jointe_ticket_id_seq OWNED BY public.piece_jointe_ticket.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role (
    id bigint NOT NULL,
    nom character varying(255) NOT NULL,
    description character varying(255)
);


ALTER TABLE public.role OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_id_seq OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_id_seq OWNED BY public.role.id;


--
-- Name: service; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service (
    id bigint NOT NULL,
    nom character varying(255) NOT NULL,
    description character varying(255),
    structure_id bigint
);


ALTER TABLE public.service OWNER TO postgres;

--
-- Name: service_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_id_seq OWNER TO postgres;

--
-- Name: service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_id_seq OWNED BY public.service.id;


--
-- Name: structure; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.structure (
    id bigint NOT NULL,
    nom character varying(255) NOT NULL,
    adresse character varying(255),
    telephone character varying(255),
    email character varying(255)
);


ALTER TABLE public.structure OWNER TO postgres;

--
-- Name: structure_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.structure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.structure_id_seq OWNER TO postgres;

--
-- Name: structure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.structure_id_seq OWNED BY public.structure.id;


--
-- Name: structure_invitee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.structure_invitee (
    id bigint NOT NULL,
    invitation_id bigint NOT NULL,
    structure_id bigint NOT NULL,
    statut_reponse character varying(255) DEFAULT 'EN_ATTENTE'::public.statut_reponse NOT NULL,
    date_envoi timestamp without time zone DEFAULT now() NOT NULL,
    date_reponse timestamp without time zone,
    lettre_chemin character varying(255),
    lettre_generee boolean DEFAULT false NOT NULL,
    commentaire character varying(255)
);


ALTER TABLE public.structure_invitee OWNER TO postgres;

--
-- Name: structure_invitee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.structure_invitee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.structure_invitee_id_seq OWNER TO postgres;

--
-- Name: structure_invitee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.structure_invitee_id_seq OWNED BY public.structure_invitee.id;


--
-- Name: ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket (
    id bigint NOT NULL,
    date_creation timestamp without time zone DEFAULT now() NOT NULL,
    statut character varying(255) DEFAULT 'EN_ATTENTE'::public.statut_ticket NOT NULL,
    priorite character varying(255) DEFAULT 'MOYENNE'::public.priorite NOT NULL,
    solution text,
    structure_id bigint,
    createur_id bigint,
    description text NOT NULL,
    whatsapp character varying(20)
);


ALTER TABLE public.ticket OWNER TO postgres;

--
-- Name: ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ticket_id_seq OWNER TO postgres;

--
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;


--
-- Name: utilisateur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.utilisateur (
    user_id bigint NOT NULL,
    nom character varying(255) NOT NULL,
    prenom character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    telephone character varying(255),
    mot_de_passe character varying(255) NOT NULL,
    date_creation timestamp without time zone DEFAULT now() NOT NULL,
    iu character varying(255),
    actif boolean DEFAULT true NOT NULL,
    service_id bigint,
    structure_id bigint
);


ALTER TABLE public.utilisateur OWNER TO postgres;

--
-- Name: utilisateur_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.utilisateur_role (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE public.utilisateur_role OWNER TO postgres;

--
-- Name: utilisateur_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.utilisateur_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.utilisateur_role_id_seq OWNER TO postgres;

--
-- Name: utilisateur_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.utilisateur_role_id_seq OWNED BY public.utilisateur_role.id;


--
-- Name: utilisateur_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.utilisateur_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.utilisateur_user_id_seq OWNER TO postgres;

--
-- Name: utilisateur_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.utilisateur_user_id_seq OWNED BY public.utilisateur.user_id;


--
-- Name: affectation_invitation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_invitation ALTER COLUMN id SET DEFAULT nextval('public.affectation_invitation_id_seq'::regclass);


--
-- Name: affectation_ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_ticket ALTER COLUMN id SET DEFAULT nextval('public.affectation_ticket_id_seq'::regclass);


--
-- Name: base_communication id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication ALTER COLUMN id SET DEFAULT nextval('public.base_communication_id_seq'::regclass);


--
-- Name: base_communication_ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication_ticket ALTER COLUMN id SET DEFAULT nextval('public.base_communication_ticket_id_seq'::regclass);


--
-- Name: communication id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.communication ALTER COLUMN id SET DEFAULT nextval('public.communication_id_seq'::regclass);


--
-- Name: invitation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invitation ALTER COLUMN id SET DEFAULT nextval('public.invitation_id_seq'::regclass);


--
-- Name: notification id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification ALTER COLUMN id SET DEFAULT nextval('public.notification_id_seq'::regclass);


--
-- Name: piece_jointe_invitation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piece_jointe_invitation ALTER COLUMN id SET DEFAULT nextval('public.piece_jointe_invitation_id_seq'::regclass);


--
-- Name: piece_jointe_ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piece_jointe_ticket ALTER COLUMN id SET DEFAULT nextval('public.piece_jointe_ticket_id_seq'::regclass);


--
-- Name: role id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role ALTER COLUMN id SET DEFAULT nextval('public.role_id_seq'::regclass);


--
-- Name: service id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service ALTER COLUMN id SET DEFAULT nextval('public.service_id_seq'::regclass);


--
-- Name: structure id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure ALTER COLUMN id SET DEFAULT nextval('public.structure_id_seq'::regclass);


--
-- Name: structure_invitee id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure_invitee ALTER COLUMN id SET DEFAULT nextval('public.structure_invitee_id_seq'::regclass);


--
-- Name: ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);


--
-- Name: utilisateur user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur ALTER COLUMN user_id SET DEFAULT nextval('public.utilisateur_user_id_seq'::regclass);


--
-- Name: utilisateur_role id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur_role ALTER COLUMN id SET DEFAULT nextval('public.utilisateur_role_id_seq'::regclass);


--
-- Data for Name: affectation_invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affectation_invitation (id, invitation_id, agent_id, responsable_principal, date_affectation) FROM stdin;
2	1	7	f	2026-06-15 19:18:24.912564
3	1	6	t	2026-06-15 19:18:24.920565
4	4	6	t	2026-06-16 01:29:28.582328
5	7	3	f	2026-06-17 07:13:17.634259
6	5	3	f	2026-06-18 17:36:05.608605
7	9	3	f	2026-06-19 07:59:48.744414
9	19	3	f	2026-06-21 20:32:59.058331
10	19	5	f	2026-06-21 20:32:59.069333
\.


--
-- Data for Name: affectation_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affectation_ticket (id, ticket_id, agent_id, responsable_principal, date_affectation) FROM stdin;
1	2	8	t	2026-06-16 05:33:35.580889
2	2	3	t	2026-06-17 01:01:11.999607
3	3	3	t	2026-06-17 07:17:09.438908
4	3	9	t	2026-06-17 09:32:02.508788
5	3	5	t	2026-06-17 09:32:17.183809
6	3	4	t	2026-06-17 09:33:04.769264
7	5	3	t	2026-06-17 09:35:19.988088
8	6	5	t	2026-06-17 09:42:02.64565
9	14	3	t	2026-06-18 00:25:48.393431
11	13	3	t	2026-06-20 07:56:57.161888
12	17	3	t	2026-06-22 05:48:35.670751
\.


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_settings (cle, valeur) FROM stdin;
notificationsEmail	false
notificationsInternes	false
langue	Français
delaiMaxSansAffectation	48h
\.


--
-- Data for Name: base_communication; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.base_communication (id, titre, contenu, categorie, mots_cles, date_creation, date_maj, auteur_id, actif) FROM stdin;
\.


--
-- Data for Name: base_communication_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.base_communication_ticket (id, base_communication_id, ticket_id) FROM stdin;
\.


--
-- Data for Name: communication; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.communication (id, message, date, auteur_id, ticket_id) FROM stdin;
\.


--
-- Data for Name: invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invitation (id, objet, date_debut, date_fin, nombre_participant, statut, visibilite, date_creation, structure_emettrice, lieu, ampliation, contenu, numero_reference, signataire_nom, signataire_qualite, ville, mode_creation) FROM stdin;
1	boton	2026-06-15	2026-06-18	2	EN_COURS	PUBLIC	2026-06-15 06:54:30.07283	\N	ouaga	\N	\N	\N	\N	\N	\N	\N
4	rencontre	2026-06-16	2026-06-18	2	EN_COURS	PUBLIC	2026-06-16 01:28:28.482157	\N	ouaga	\N	\N	\N	\N	\N	\N	\N
7	conte	2026-06-18	2026-06-20	3	PLANIFIEE	PUBLIC	2026-06-16 05:00:45.237147	\N	kaya	\N	\N	\N	\N	\N	\N	\N
5	pancarte	2026-06-16	2026-06-19	3	EN_COURS	PUBLIC	2026-06-16 03:18:23.572308	\N	ddd	\N	\N	\N	\N	\N	\N	\N
8	ertyuio	2026-06-19	2026-06-20	2	EN_ATTENTE	PUBLIC	2026-06-19 06:54:46.228699	20	ouaga	geljd	k,edrtiyxuonp,kednbctviydhjlkb cjkbihety fogeydhjl  e		jusdjne	Le Secrétaire général	Ouagadougou	\N
9	kjlhgfhjk	2026-06-19	2026-06-20	0	EN_COURS	PUBLIC	2026-06-19 07:19:23.062371	\N						Le Secrétaire général	Ouagadougou	\N
10	jhgfdcghjkl	2026-06-21	2026-06-23	0	EN_ATTENTE	PUBLIC	2026-06-21 02:57:36.58626	\N	ljkhgj					Le Secrétaire général	Ouagadougou	ENREGISTRER
11	cgvhbsssss	2026-06-23	2026-06-27	0	EN_ATTENTE	PUBLIC	2026-06-21 03:13:55.09272	20						Le Secrétaire général	Ouagadougou	ENREGISTRER
12	nbvcvbn	2026-06-15	2026-06-26	0	EN_ATTENTE	PUBLIC	2026-06-21 03:24:42.897752	20						Le Secrétaire général	Ouagadougou	ENREGISTRER
13	lkjbh	2026-06-23	2026-06-27	0	EN_ATTENTE	PUBLIC	2026-06-21 03:45:36.153365	\N						Le Secrétaire général	Ouagadougou	ENREGISTRER
14	mlkjhgfxcghj	2026-06-15	2026-06-27	0	EN_ATTENTE	PUBLIC	2026-06-21 03:46:06.792016	21		\N	\N	\N	\N	\N	Ouagadougou	ENREGISTRER
15	nn,;	2026-06-20	2026-06-23	0	EN_ATTENTE	PUBLIC	2026-06-21 16:59:24.672013	\N	fcghjg					Le Secrétaire général	Ouagadougou	ENREGISTRER
16	kjhgvcxcv	2026-06-20	2026-06-27	0	EN_ATTENTE	PUBLIC	2026-06-21 17:09:29.578645	\N						Le Secrétaire général	Ouagadougou	ENREGISTRER
17	kljh	2026-06-22	2026-06-26	0	EN_ATTENTE	PUBLIC	2026-06-21 17:51:43.119087	\N						Le Secrétaire général	Ouagadougou	ENREGISTRER
18	kjhgcfhjk	2026-06-23	2026-06-24	0	EN_ATTENTE	PUBLIC	2026-06-21 17:58:01.281955	\N						Le Secrétaire général	Ouagadougou	ENREGISTRER
19	mlkjbhv	2026-06-23	2026-06-26	0	PLANIFIEE	PUBLIC	2026-06-21 17:58:50.425402	\N						Le Secrétaire général	Ouagadougou	ENREGISTRER
20	dfkljkhj	2026-06-15	2026-06-24	0	EN_ATTENTE	PUBLIC	2026-06-21 23:30:11.609315	\N	kljhgjk					Le Secrétaire général	Ouagadougou	CREER
21	gfdrtfyui	2026-06-22	2026-06-26	0	EN_ATTENTE	PUBLIC	2026-06-22 05:03:28.502358	\N		klmj_ynèèp	hgjkjnlbvfdxcgvhjkl\nùokmijluyhtrcdsxqzer-tèy_uçàii_ouyhtghfdghjklm		ghzertyuio	Le Secrétaire général	Ouagadougou	CREER
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (id, message, date_envoi, canal, statut, categorie, resource_id, action_label, utilisateur_id) FROM stdin;
2	Vous avez été affecté au ticket #5	2026-06-08 18:25:19.213392	INTERNE	f	TICKET	5	Voir	4
3	Vous avez été affecté au ticket #6	2026-06-08 18:28:23.769415	INTERNE	f	TICKET	6	Voir	5
4	Vous avez été affecté au ticket #7	2026-06-09 19:38:05.039272	INTERNE	f	TICKET	7	Voir	1
1	Vous avez été affecté au ticket #5	2026-06-07 03:10:21.304356	INTERNE	t	TICKET	5	Voir	3
5	Vous avez été affecté au ticket #8	2026-06-09 20:09:38.32325	INTERNE	f	TICKET	8	Voir	8
6	Vous avez été affecté au ticket #9	2026-06-09 21:25:19.375608	INTERNE	f	TICKET	9	Voir	5
7	Vous avez été affecté au ticket #10	2026-06-09 21:33:38.984882	INTERNE	f	TICKET	10	Voir	5
8	Vous avez été affecté au ticket #11	2026-06-09 22:49:45.064889	INTERNE	f	TICKET	11	Voir	8
9	Vous avez été affecté au ticket #12	2026-06-09 23:18:20.54557	INTERNE	f	TICKET	12	Voir	4
10	Vous avez été affecté au ticket #13	2026-06-10 05:49:25.986835	INTERNE	t	TICKET	13	Voir	3
11	Vous avez été affecté au ticket #14	2026-06-10 09:47:41.627917	INTERNE	f	TICKET	14	Voir	5
12	Vous avez été affecté au ticket #15	2026-06-10 20:15:24.907714	INTERNE	f	TICKET	15	Voir	7
19	Vous avez été affecté à l'invitation : cvbnk	2026-06-11 00:41:21.086004	INTERNE	f	INVITATION	14	Voir	5
20	Vous avez été affecté à l'invitation : cvbnk	2026-06-11 00:41:21.089998	INTERNE	f	INVITATION	14	Voir	6
25	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : dfghj	2026-06-11 00:44:45.573227	INTERNE	f	INVITATION	16	Voir	4
29	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : ghjk	2026-06-11 18:10:03.197979	INTERNE	f	INVITATION	7	Voir	4
31	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : LKJHGCFHJ	2026-06-11 18:11:37.601446	INTERNE	f	INVITATION	8	Voir	4
32	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : xghjklw	2026-06-11 18:12:15.453061	INTERNE	f	INVITATION	9	Voir	4
33	Vous avez été affecté à l'invitation : dfghj	2026-06-11 18:35:13.567461	INTERNE	f	INVITATION	16	Voir	4
34	Vous avez été affecté à l'invitation : dfghj	2026-06-11 18:35:13.578575	INTERNE	f	INVITATION	16	Voir	6
35	Vous avez été affecté à l'invitation : dfghj	2026-06-11 19:33:56.946118	INTERNE	f	INVITATION	16	Voir	4
36	Vous avez été affecté à l'invitation : dfghj	2026-06-11 19:33:56.953355	INTERNE	f	INVITATION	16	Voir	6
37	Vous avez été affecté à l'invitation : dfghj	2026-06-11 19:33:56.961337	INTERNE	f	INVITATION	16	Voir	5
38	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : x,	2026-06-11 19:46:18.708954	INTERNE	f	INVITATION	12	Voir	5
39	Vous avez été affecté à l'invitation : g fjkl	2026-06-11 19:49:46.878167	INTERNE	f	INVITATION	17	Voir	6
40	Vous avez été affecté au ticket #15	2026-06-11 19:50:44.441287	INTERNE	f	TICKET	15	Voir	5
41	Vous avez été affecté au ticket #15	2026-06-11 19:51:01.878016	INTERNE	f	TICKET	15	Voir	1
42	Vous avez été affecté à l'invitation : g fjkl	2026-06-11 20:22:46.706012	INTERNE	f	INVITATION	17	Voir	6
43	Vous avez été affecté à l'invitation : g fjkl	2026-06-11 20:22:46.711012	INTERNE	f	INVITATION	17	Voir	4
44	Vous avez été affecté au ticket #14	2026-06-11 23:18:58.431792	INTERNE	f	TICKET	14	Voir	7
45	Vous avez été affecté à l'invitation : LKJHGCFHJ	2026-06-11 23:19:32.592973	INTERNE	f	INVITATION	8	Voir	4
46	Vous avez été affecté à l'invitation : LKJHGCFHJ	2026-06-11 23:19:32.599986	INTERNE	f	INVITATION	8	Voir	7
47	Vous avez été affecté à l'invitation : g fjkl	2026-06-12 00:19:50.340914	INTERNE	f	INVITATION	17	Voir	4
48	Vous avez été affecté à l'invitation : g fjkl	2026-06-12 00:19:50.340914	INTERNE	f	INVITATION	17	Voir	6
49	Vous avez été affecté à l'invitation : g fjkl	2026-06-12 00:19:50.340914	INTERNE	f	INVITATION	17	Voir	7
51	Vous avez été affecté à l'invitation : g fjkl	2026-06-14 05:59:50.74522	INTERNE	f	INVITATION	17	Voir	6
52	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : xdfcvbn	2026-06-14 06:21:30.629978	INTERNE	f	INVITATION	18	Voir	5
53	Vous avez été affecté à l'invitation : kjhgj	2026-06-14 08:21:01.115736	INTERNE	f	INVITATION	25	Voir	5
54	Vous avez été affecté à l'invitation : aertyu	2026-06-14 08:35:25.236623	INTERNE	f	INVITATION	26	Voir	2
55	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : aertyu	2026-06-14 08:36:41.090501	INTERNE	f	INVITATION	26	Voir	2
56	Vous avez été affecté à l'invitation : fghj	2026-06-14 20:11:43.148379	INTERNE	f	INVITATION	27	Voir	10
58	Vous avez été affecté au ticket #16	2026-06-14 21:52:43.872952	INTERNE	f	TICKET	16	Voir	4
59	Vous avez été affecté à l'invitation : vhbjn	2026-06-14 21:58:21.059653	INTERNE	f	INVITATION	28	Voir	5
60	Vous avez été affecté à l'invitation : fxdcgvhbn,	2026-06-14 22:00:35.752696	INTERNE	f	INVITATION	23	Voir	6
57	Vous avez été affecté au ticket #16	2026-06-14 20:13:16.936463	INTERNE	t	TICKET	16	Voir	7
50	Vous avez été affecté à l'invitation : g fjkl	2026-06-14 05:59:50.73535	INTERNE	t	INVITATION	17	Voir	7
21	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : cvbnk	2026-06-11 00:41:21.093018	INTERNE	t	INVITATION	14	Voir	9
13	Vous avez été affecté à l'invitation : xcgvhbn	2026-06-11 00:20:55.45176	INTERNE	t	INVITATION	15	Voir	9
62	Vous avez été affecté au ticket #17	2026-06-15 03:59:23.19447	INTERNE	f	TICKET	17	Voir	7
64	Vous avez été affecté à l'invitation : conference	2026-06-15 03:59:56.574112	INTERNE	f	INVITATION	29	Voir	7
65	Vous avez été affecté à l'invitation : vhbjn	2026-06-15 04:01:05.137513	INTERNE	f	INVITATION	28	Voir	5
66	Vous avez été affecté à l'invitation : vhbjn	2026-06-15 04:01:05.16093	INTERNE	f	INVITATION	28	Voir	7
63	Vous avez été affecté à l'invitation : conference	2026-06-15 03:59:56.557217	INTERNE	t	INVITATION	29	Voir	9
61	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : conference	2026-06-15 03:50:25.729295	INTERNE	t	INVITATION	29	Voir	9
67	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : conference1	2026-06-15 05:07:59.212426	INTERNE	f	INVITATION	30	Voir	5
68	Vous avez été affecté à l'invitation : conference1	2026-06-15 05:07:59.224398	INTERNE	f	INVITATION	30	Voir	6
69	Vous avez été affecté à l'invitation : boton	2026-06-15 19:16:58.21019	INTERNE	f	INVITATION	1	Voir	7
70	Vous avez été affecté à l'invitation : boton	2026-06-15 19:18:24.916672	INTERNE	f	INVITATION	1	Voir	7
71	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : boton	2026-06-15 19:18:24.923566	INTERNE	f	INVITATION	1	Voir	6
72	⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : rencontre	2026-06-16 01:29:28.59032	INTERNE	f	INVITATION	4	Voir	6
73	Vous avez été affecté au ticket #2	2026-06-16 05:33:35.606685	INTERNE	f	TICKET	2	Voir	8
74	Vous avez été affecté au ticket #2	2026-06-17 01:01:12.086207	INTERNE	t	TICKET	2	Voir	3
75	Vous avez été affecté à l'invitation : conte	2026-06-17 07:13:17.670862	INTERNE	t	INVITATION	7	Voir	3
76	Vous avez été affecté au ticket #3	2026-06-17 07:17:09.454391	INTERNE	t	TICKET	3	Voir	3
77	Vous avez été affecté au ticket #3	2026-06-17 09:32:02.523789	INTERNE	f	TICKET	3	Voir	9
78	Vous avez été affecté au ticket #3	2026-06-17 09:32:17.196782	INTERNE	f	TICKET	3	Voir	5
79	Vous avez été affecté au ticket #3	2026-06-17 09:33:04.774732	INTERNE	f	TICKET	3	Voir	4
81	Vous avez été affecté au ticket #6	2026-06-17 09:42:02.650665	INTERNE	f	TICKET	6	Voir	5
80	Vous avez été affecté au ticket #5	2026-06-17 09:35:19.999641	INTERNE	t	TICKET	5	Voir	3
82	Vous avez été affecté au ticket #14	2026-06-18 00:25:48.410548	INTERNE	t	TICKET	14	Voir	3
84	Vous avez été affecté à l'invitation : pancarte	2026-06-18 17:36:05.614516	INTERNE	t	INVITATION	5	Voir	3
83	Vous avez été affecté au ticket #16	2026-06-18 17:35:07.831358	INTERNE	t	TICKET	16	Voir	3
85	Vous avez été affecté à l'invitation : kjlhgfhjk	2026-06-19 07:59:48.784419	INTERNE	t	INVITATION	9	Voir	3
86	Vous avez été affecté au ticket #13	2026-06-20 07:56:57.351219	INTERNE	t	TICKET	13	Voir	3
89	Vous avez été affecté à l'invitation : mlkjbhv	2026-06-21 20:32:59.07333	INTERNE	f	INVITATION	19	Voir	5
88	Vous avez été affecté à l'invitation : mlkjbhv	2026-06-21 20:32:59.06333	INTERNE	t	INVITATION	19	Voir	3
87	Vous avez été affecté à l'invitation : mlkjbhv	2026-06-21 20:32:24.925826	INTERNE	t	INVITATION	19	Voir	3
90	Vous avez été affecté au ticket #17	2026-06-22 05:48:35.759125	INTERNE	t	TICKET	17	Voir	3
\.


--
-- Data for Name: piece_jointe_invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piece_jointe_invitation (id, nom, type, chemin, date_envoi, invitation_id) FROM stdin;
1	invitation_28.pdf	application/pdf	invitations/1/35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28.pdf	2026-06-15 06:54:30.08294	1
4	35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (2).pdf	application/pdf	invitations/4/f09d0b13-f111-400f-9b0a-dcdb73fab61c_35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (2).pdf	2026-06-16 01:28:28.530154	4
5	35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (3).pdf	application/pdf	invitations/4/b14206e8-904d-4941-8d5c-c3cd6631c115_35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (3).pdf	2026-06-16 01:28:28.536152	4
6	35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (1).pdf	application/pdf	invitations/4/e9e65f62-3553-4d4d-b0af-ae4dd218741f_35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (1).pdf	2026-06-16 01:28:28.538155	4
7	35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (4).pdf	application/pdf	invitations/5/8770f262-8a04-4a02-9960-ea2be30190e2_35b9ef99-38ef-4389-a50f-2b9fe7fd639c_invitation_28 (4).pdf	2026-06-16 03:18:23.593344	5
9	invitation_5.pdf	application/pdf	invitations/7/c2c20b8f-1764-416b-84d7-1190876b36ea_invitation_5.pdf	2026-06-16 05:00:45.250341	7
10	invitation_30.pdf	application/pdf	invitations/8/99c2b855-be99-464e-a09e-57ddcdcee02a_invitation_30.pdf	2026-06-19 06:54:46.319709	8
11	A.png	image/png	invitations/21/2a940650-99eb-4c10-ab69-9bd0b1266fc6_A.png	2026-06-22 05:03:28.606929	21
\.


--
-- Data for Name: piece_jointe_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piece_jointe_ticket (id, nom, type, chemin, date_envoi, ticket_id) FROM stdin;
1	invitation_5.pdf	application/pdf	tickets/1/80bfc412-7c44-4fc3-a717-e419c4d20461_invitation_5.pdf	2026-06-16 05:29:22.695673	1
2	B.png	image/png	tickets/2/da11f8d5-d56b-4877-9737-a3d07f5d50b1_B.png	2026-06-16 05:31:49.693036	2
3	B.png	image/png	tickets/3/0c609640-4fef-47fd-b7f1-184625c46071_B.png	2026-06-17 07:16:25.429608	3
5	Capture d'écran 2026-04-13 140604.png	image/png	tickets/5/4df68ff8-9680-4643-9ef3-460308b12ad6_Capture d'écran 2026-04-13 140604.png	2026-06-17 09:34:36.052561	5
6	Capture d'écran 2026-04-09 112837.png	image/png	tickets/6/96cb62a9-82a9-4dc6-991e-b9090cb257a0_Capture d'écran 2026-04-09 112837.png	2026-06-17 09:41:45.343157	6
7	Capture d'écran 2026-04-09 112837.png	image/png	tickets/7/ecc08629-478c-44b3-b51e-55a27726061c_Capture d'écran 2026-04-09 112837.png	2026-06-17 09:55:23.973698	7
8	Capture d'écran 2026-04-09 112837.png	image/png	tickets/8/93e5fe80-d00d-47c4-a6bb-541eb03b9d85_Capture d'écran 2026-04-09 112837.png	2026-06-17 09:56:21.706841	8
9	Capture d'écran 2026-04-09 112837.png	image/png	tickets/12/8fe4329e-d1a3-46f4-a8fd-e01e67607e0f_Capture d'écran 2026-04-09 112837.png	2026-06-17 11:04:47.503078	12
10	Capture d'écran 2026-04-09 112837.png	image/png	tickets/13/8ec83f30-d4d6-4f3b-b360-ccc054f0eb01_Capture d'écran 2026-04-09 112837.png	2026-06-17 21:03:06.685113	13
11	A.png	image/png	tickets/14/95976e9f-dd59-489d-80be-0883dbcd0f1e_A.png	2026-06-17 21:10:48.019891	14
12	B.png	image/png	tickets/14/1944c450-762c-4128-8d06-5962b685321f_B.png	2026-06-17 21:10:48.026579	14
13	Capture d'écran 2026-03-25 094806.png	image/png	tickets/14/d25aec71-f9ea-468f-96eb-4e2d9a4bc3b2_Capture d'écran 2026-03-25 094806.png	2026-06-17 21:10:48.026579	14
14	C.png	image/png	tickets/14/6af7c8f2-d63c-49b6-aba4-0c28d7f05b8d_C.png	2026-06-17 21:10:48.035001	14
15	Capture d'écran 2026-03-25 094806.png	image/png	tickets/15/0f86d12f-3397-48ec-8906-84057e0fbab7_Capture d'écran 2026-03-25 094806.png	2026-06-18 17:32:54.016591	15
16	B.png	image/png	tickets/15/00289271-27e0-40bd-836b-573765a00d72_B.png	2026-06-18 17:32:54.023951	15
17	C.png	image/png	tickets/15/ae259374-1a65-4ea6-88a7-dade954ce230_C.png	2026-06-18 17:32:54.025971	15
26	A.png	image/png	tickets/17/f1196958-1d68-48e3-b5b2-8779aa2dc7d4_A.png	2026-06-22 01:34:02.315851	17
27	B.png	image/png	tickets/17/a13bd7f1-5a33-4e48-b799-420a00e09565_B.png	2026-06-22 01:34:02.320853	17
28	Capture d'écran 2026-06-21 160952.png	image/png	tickets/17/3e3acd5b-c4e1-4224-ba97-43e8504212b1_Capture d'écran 2026-06-21 160952.png	2026-06-22 01:34:02.321848	17
29	Capture d'écran 2026-06-21 165421.png	image/png	tickets/17/d6b3f285-dfb1-4e94-bf24-b6770162cb6d_Capture d'écran 2026-06-21 165421.png	2026-06-22 01:34:02.322851	17
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role (id, nom, description) FROM stdin;
1	ADMIN	AccÃ¨s complet
2	AGENT_DSI	Gestion invitations et tickets
3	SUPERVISEUR	Lecture et affectation
4	USAGER	CrÃ©ation tickets uniquement
\.


--
-- Data for Name: service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service (id, nom, description, structure_id) FROM stdin;
7	it	iert	\N
8	Unité de système d'information	USI	\N
9	SEST	Service Equipement et Support Technique	\N
10	SRS	le Service Réseaux et Systèmes	\N
\.


--
-- Data for Name: structure; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.structure (id, nom, adresse, telephone, email) FROM stdin;
20	commerce	ouaga	65748484	commerce@gmail.com
21	bureau	bobo	75896985	bureau@gmail.com
22	DSI	MESFPT	25252525	dsi@gmail.com
\.


--
-- Data for Name: structure_invitee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.structure_invitee (id, invitation_id, structure_id, statut_reponse, date_envoi, date_reponse, lettre_chemin, lettre_generee, commentaire) FROM stdin;
1	8	20	EN_ATTENTE	2026-06-19 06:54:46.303617	\N	\N	f	\N
2	9	21	EN_ATTENTE	2026-06-19 07:19:23.074521	\N	\N	f	\N
3	10	21	EN_ATTENTE	2026-06-21 02:57:36.685561	\N	\N	f	\N
4	11	20	EN_ATTENTE	2026-06-21 03:13:55.099342	\N	\N	f	\N
5	12	21	EN_ATTENTE	2026-06-21 03:24:42.929749	\N	\N	f	\N
6	13	21	EN_ATTENTE	2026-06-21 03:45:36.235815	\N	\N	f	\N
7	15	21	EN_ATTENTE	2026-06-21 16:59:24.760508	\N	\N	f	\N
8	16	21	EN_ATTENTE	2026-06-21 17:09:29.650376	\N	\N	f	\N
9	17	21	EN_ATTENTE	2026-06-21 17:51:43.179098	\N	\N	f	\N
10	18	21	EN_ATTENTE	2026-06-21 17:58:01.291955	\N	\N	f	\N
11	19	21	EN_ATTENTE	2026-06-21 17:58:50.434513	\N	\N	f	\N
12	20	22	EXCUSEE	2026-06-21 23:30:11.655173	\N	\N	f	\N
13	21	22	EN_ATTENTE	2026-06-22 05:03:28.590316	\N	\N	f	\N
14	21	21	EN_ATTENTE	2026-06-22 05:03:28.591226	\N	\N	f	\N
\.


--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, date_creation, statut, priorite, solution, structure_id, createur_id, description, whatsapp) FROM stdin;
1	2026-06-16 05:29:22.667885	EN_ATTENTE	MOYENNE	\N	\N	\N	djk	\N
2	2026-06-16 05:31:49.686064	EN_COURS	MOYENNE	\N	\N	\N	yujk	\N
3	2026-06-17 07:16:25.404322	EN_PAUSE	MOYENNE	\N	\N	3	sdfghjk	\N
11	2026-06-17 10:57:01.993226	EN_ATTENTE	MOYENNE	\N	\N	3	jksn	+22606031093
5	2026-06-17 09:34:36.045448	EN_PAUSE	MOYENNE	\N	\N	3	dfcghjk	+22606031093
9	2026-06-17 10:07:26.067231	EN_ATTENTE	MOYENNE	\N	\N	\N	bnk	+22606031093
10	2026-06-17 10:17:08.626071	EN_ATTENTE	MOYENNE	\N	\N	\N	ghjkl;	+22606031093
12	2026-06-17 11:04:47.419852	EN_ATTENTE	MOYENNE	\N	\N	\N	cvghjzkl	+22605686969
6	2026-06-17 09:41:45.336069	EN_PAUSE	MOYENNE	\N	\N	3	xcvbn	+26606031093
7	2026-06-17 09:55:23.967713	EN_ATTENTE	MOYENNE	\N	\N	\N	xghvbn	+22606031093
8	2026-06-17 09:56:21.699923	EN_ATTENTE	MOYENNE	\N	\N	\N	fghj	+22606031093
14	2026-06-17 21:10:47.701583	EN_PAUSE	MOYENNE	\N	\N	\N	teue	+22606031093
15	2026-06-18 17:32:53.902927	EN_ATTENTE	FAIBLE	\N	20	\N	dfghjk	\N
13	2026-06-17 21:03:06.598874	EN_COURS	MOYENNE	\N	\N	\N	hgfghj	+22606031093
17	2026-06-22 01:34:02.292781	EN_COURS	MOYENNE	\N	22	\N	poiuyu	78659854
\.


--
-- Data for Name: utilisateur; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateur (user_id, nom, prenom, email, telephone, mot_de_passe, date_creation, iu, actif, service_id, structure_id) FROM stdin;
2	Administrateur	SystŠme	admin@dsi.gov.bf	\N	$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWa	2026-06-02 22:43:30.2918	ADM-001	t	\N	\N
3	Admin	DSI	admin2@dsi.gov.bf	\N	$2a$10$a9eCuoE6YfaVu9jc3z1RHuDZ4jlTsiLXMK/k5AFLGzulU5jLD/Z2G	2026-06-02 22:52:48.08875	\N	t	\N	\N
4	konate	rachi	rachi1@gmail.com	\N	$2a$10$.PSKtKJTejrgQLYNq7e6l.d94cA3M/8yJAWTHyJFxmffmTCfR6wei	2026-06-03 13:13:24.60639	\N	t	\N	\N
5	barro	rachid	rachid@gmail.com	76546354	$2a$10$x9EnQJpMztr6vEuPN6BvX.G1zxV6WsD3VfGNp0OSg/GeQKQe.ql5C	2026-06-03 13:21:00.936637	1233	t	\N	\N
8	kone	rachi	kone@gmail.com	\N	$2a$10$zpVbSZXy0/AFzLElWvoKSe1xShtq2Xvt0iNN.aW8ye0yktnBg7NRW	2026-06-09 19:26:07.561549	\N	t	\N	\N
9	rachida	barro	rachidabarro@gmail.com	76847464	$2a$10$UHpIq24G/qOzuynyax7cMuJywrFaJpoCzDsBSvL4/A1819vwW2d8e	2026-06-09 23:16:42.856016	23	t	\N	\N
1	rachi	konte	rachi@gmail.com	54637383	$2a$10$X.J.YQwzP2zLhhk3LobZwORPc2C12p8aWXI6PH3I9TNaXPhouHH3y	2026-06-01 15:54:10.743005	1234	t	\N	\N
10	raz	ros	rosraz@gmail.com	\N	$2a$10$Hx.0iIjXgnMrFdlE3tbfRu3d33gSOBIsx3jXQHyOVixqQsTh4FdaG	2026-06-11 21:05:53.520787	\N	t	\N	\N
11	nomo	mom	nomo@gmail.com	\N	$2a$10$pzUs8C2BpV5wdith/OP9nOV9XBHVVerHzhT4Bx4UK5BxqOo4BWTx2	2026-06-14 19:15:54.146221	\N	t	\N	\N
7	barro	prenom	rachidabarro66@gmail.com	67847383	$2a$10$OLk2vwQyQ2zPDyiKJVIghuOButJArvAUWcaHAScz0rwDwYeHbaoZK	2026-06-09 01:17:40.932874	123	t	\N	\N
12	nnn	lk	nnn@gmail.com	\N	$2a$10$qyqHtCcA9QiM/RWUx9OFRuteLlbBmS762tHMp9DkAgnGb0bNxeo3u	2026-06-14 19:20:22.022311	\N	f	\N	\N
6	barro	rachi	rachidabarro98@mail.com	78674345	$2a$10$8zeyvxNk9YrYzl1Vsp/P.ulTUOlsd5zpiS98rfGvvRujMaDNGTQry	2026-06-09 01:10:57.386182	4354	f	\N	\N
\.


--
-- Data for Name: utilisateur_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateur_role (id, user_id, role_id) FROM stdin;
1	1	1
2	2	1
3	3	1
4	4	2
5	5	2
6	6	2
9	9	1
11	8	2
12	7	2
14	10	2
15	12	4
16	11	2
\.


--
-- Name: affectation_invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_invitation_id_seq', 10, true);


--
-- Name: affectation_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_ticket_id_seq', 12, true);


--
-- Name: base_communication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.base_communication_id_seq', 1, false);


--
-- Name: base_communication_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.base_communication_ticket_id_seq', 1, false);


--
-- Name: communication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.communication_id_seq', 1, false);


--
-- Name: invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invitation_id_seq', 21, true);


--
-- Name: notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_id_seq', 90, true);


--
-- Name: piece_jointe_invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piece_jointe_invitation_id_seq', 11, true);


--
-- Name: piece_jointe_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piece_jointe_ticket_id_seq', 29, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 4, true);


--
-- Name: service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_id_seq', 10, true);


--
-- Name: structure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.structure_id_seq', 22, true);


--
-- Name: structure_invitee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.structure_invitee_id_seq', 14, true);


--
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 17, true);


--
-- Name: utilisateur_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateur_role_id_seq', 16, true);


--
-- Name: utilisateur_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateur_user_id_seq', 12, true);


--
-- Name: affectation_invitation affectation_invitation_invitation_id_agent_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_invitation
    ADD CONSTRAINT affectation_invitation_invitation_id_agent_id_key UNIQUE (invitation_id, agent_id);


--
-- Name: affectation_invitation affectation_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_invitation
    ADD CONSTRAINT affectation_invitation_pkey PRIMARY KEY (id);


--
-- Name: affectation_ticket affectation_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_ticket
    ADD CONSTRAINT affectation_ticket_pkey PRIMARY KEY (id);


--
-- Name: affectation_ticket affectation_ticket_ticket_id_agent_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_ticket
    ADD CONSTRAINT affectation_ticket_ticket_id_agent_id_key UNIQUE (ticket_id, agent_id);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (cle);


--
-- Name: base_communication base_communication_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication
    ADD CONSTRAINT base_communication_pkey PRIMARY KEY (id);


--
-- Name: base_communication_ticket base_communication_ticket_base_communication_id_ticket_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication_ticket
    ADD CONSTRAINT base_communication_ticket_base_communication_id_ticket_id_key UNIQUE (base_communication_id, ticket_id);


--
-- Name: base_communication_ticket base_communication_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication_ticket
    ADD CONSTRAINT base_communication_ticket_pkey PRIMARY KEY (id);


--
-- Name: communication communication_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.communication
    ADD CONSTRAINT communication_pkey PRIMARY KEY (id);


--
-- Name: invitation invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT invitation_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: piece_jointe_invitation piece_jointe_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piece_jointe_invitation
    ADD CONSTRAINT piece_jointe_invitation_pkey PRIMARY KEY (id);


--
-- Name: piece_jointe_ticket piece_jointe_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piece_jointe_ticket
    ADD CONSTRAINT piece_jointe_ticket_pkey PRIMARY KEY (id);


--
-- Name: role role_nom_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_nom_key UNIQUE (nom);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: service service_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);


--
-- Name: structure_invitee structure_invitee_invitation_id_structure_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure_invitee
    ADD CONSTRAINT structure_invitee_invitation_id_structure_id_key UNIQUE (invitation_id, structure_id);


--
-- Name: structure_invitee structure_invitee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure_invitee
    ADD CONSTRAINT structure_invitee_pkey PRIMARY KEY (id);


--
-- Name: structure structure_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure
    ADD CONSTRAINT structure_pkey PRIMARY KEY (id);


--
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- Name: utilisateur utilisateur_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT utilisateur_email_key UNIQUE (email);


--
-- Name: utilisateur utilisateur_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT utilisateur_pkey PRIMARY KEY (user_id);


--
-- Name: utilisateur_role utilisateur_role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur_role
    ADD CONSTRAINT utilisateur_role_pkey PRIMARY KEY (id);


--
-- Name: utilisateur_role utilisateur_role_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur_role
    ADD CONSTRAINT utilisateur_role_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- Name: idx_affectation_inv; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_affectation_inv ON public.affectation_invitation USING btree (invitation_id);


--
-- Name: idx_affectation_tkt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_affectation_tkt ON public.affectation_ticket USING btree (ticket_id);


--
-- Name: idx_communication_ticket; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_communication_ticket ON public.communication USING btree (ticket_id);


--
-- Name: idx_invitation_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invitation_statut ON public.invitation USING btree (statut);


--
-- Name: idx_invitation_structure; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invitation_structure ON public.invitation USING btree (structure_emettrice);


--
-- Name: idx_notification_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notification_statut ON public.notification USING btree (statut);


--
-- Name: idx_notification_utilisateur; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notification_utilisateur ON public.notification USING btree (utilisateur_id);


--
-- Name: idx_structure_invitee_invitation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_structure_invitee_invitation ON public.structure_invitee USING btree (invitation_id);


--
-- Name: idx_structure_invitee_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_structure_invitee_statut ON public.structure_invitee USING btree (statut_reponse);


--
-- Name: idx_ticket_priorite; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_priorite ON public.ticket USING btree (priorite);


--
-- Name: idx_ticket_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_statut ON public.ticket USING btree (statut);


--
-- Name: idx_ticket_structure; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_structure ON public.ticket USING btree (structure_id);


--
-- Name: idx_utilisateur_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_utilisateur_email ON public.utilisateur USING btree (email);


--
-- Name: idx_utilisateur_service; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_utilisateur_service ON public.utilisateur USING btree (service_id);


--
-- Name: affectation_invitation affectation_invitation_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_invitation
    ADD CONSTRAINT affectation_invitation_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.utilisateur(user_id) ON DELETE CASCADE;


--
-- Name: affectation_invitation affectation_invitation_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_invitation
    ADD CONSTRAINT affectation_invitation_invitation_id_fkey FOREIGN KEY (invitation_id) REFERENCES public.invitation(id) ON DELETE CASCADE;


--
-- Name: affectation_ticket affectation_ticket_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_ticket
    ADD CONSTRAINT affectation_ticket_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.utilisateur(user_id) ON DELETE CASCADE;


--
-- Name: affectation_ticket affectation_ticket_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affectation_ticket
    ADD CONSTRAINT affectation_ticket_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(id) ON DELETE CASCADE;


--
-- Name: base_communication base_communication_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication
    ADD CONSTRAINT base_communication_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.utilisateur(user_id) ON DELETE SET NULL;


--
-- Name: base_communication_ticket base_communication_ticket_base_communication_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication_ticket
    ADD CONSTRAINT base_communication_ticket_base_communication_id_fkey FOREIGN KEY (base_communication_id) REFERENCES public.base_communication(id) ON DELETE CASCADE;


--
-- Name: base_communication_ticket base_communication_ticket_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_communication_ticket
    ADD CONSTRAINT base_communication_ticket_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(id) ON DELETE CASCADE;


--
-- Name: communication communication_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.communication
    ADD CONSTRAINT communication_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.utilisateur(user_id) ON DELETE CASCADE;


--
-- Name: communication communication_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.communication
    ADD CONSTRAINT communication_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(id) ON DELETE CASCADE;


--
-- Name: service fk_structure_service; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT fk_structure_service FOREIGN KEY (structure_id) REFERENCES public.structure(id) ON DELETE CASCADE;


--
-- Name: invitation invitation_structure_emettrice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT invitation_structure_emettrice_fkey FOREIGN KEY (structure_emettrice) REFERENCES public.structure(id) ON DELETE SET NULL;


--
-- Name: notification notification_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(user_id) ON DELETE CASCADE;


--
-- Name: piece_jointe_invitation piece_jointe_invitation_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piece_jointe_invitation
    ADD CONSTRAINT piece_jointe_invitation_invitation_id_fkey FOREIGN KEY (invitation_id) REFERENCES public.invitation(id) ON DELETE CASCADE;


--
-- Name: piece_jointe_ticket piece_jointe_ticket_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piece_jointe_ticket
    ADD CONSTRAINT piece_jointe_ticket_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(id) ON DELETE CASCADE;


--
-- Name: structure_invitee structure_invitee_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure_invitee
    ADD CONSTRAINT structure_invitee_invitation_id_fkey FOREIGN KEY (invitation_id) REFERENCES public.invitation(id) ON DELETE CASCADE;


--
-- Name: structure_invitee structure_invitee_structure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.structure_invitee
    ADD CONSTRAINT structure_invitee_structure_id_fkey FOREIGN KEY (structure_id) REFERENCES public.structure(id) ON DELETE CASCADE;


--
-- Name: ticket ticket_createur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_createur_id_fkey FOREIGN KEY (createur_id) REFERENCES public.utilisateur(user_id) ON DELETE SET NULL;


--
-- Name: ticket ticket_structure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_structure_id_fkey FOREIGN KEY (structure_id) REFERENCES public.structure(id) ON DELETE SET NULL;


--
-- Name: utilisateur_role utilisateur_role_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur_role
    ADD CONSTRAINT utilisateur_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE CASCADE;


--
-- Name: utilisateur_role utilisateur_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur_role
    ADD CONSTRAINT utilisateur_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.utilisateur(user_id) ON DELETE CASCADE;


--
-- Name: utilisateur utilisateur_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT utilisateur_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id) ON DELETE SET NULL;


--
-- Name: utilisateur utilisateur_structure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT utilisateur_structure_id_fkey FOREIGN KEY (structure_id) REFERENCES public.structure(id) ON DELETE SET NULL;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict BaYpetEh4MJBlTqmhK8F6qS0tT63NPNUsZI59F1JSd2V7rXlf30iCwTgkXI64UI


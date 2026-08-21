--
-- PostgreSQL database dump
--

\restrict wuFfvnIOmzSVZVw89TeUvfwh9eRULckRGJuPeU2HMbZksePz3UDJIYFto2MJCfI

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
    mode_creation character varying(255),
    alerte_delai_envoyee boolean,
    contenu_delta text
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
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissions (
    role_id bigint NOT NULL,
    permission character varying(255)
);


ALTER TABLE public.role_permissions OWNER TO postgres;

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
    whatsapp character varying(20),
    alerte_delai_envoyee boolean
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
3	18	21	t	2026-07-14 17:50:21.359945
4	18	5	f	2026-07-14 17:50:21.371141
5	22	21	t	2026-07-15 10:42:18.914813
6	22	5	f	2026-07-15 10:42:18.924776
\.


--
-- Data for Name: affectation_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affectation_ticket (id, ticket_id, agent_id, responsable_principal, date_affectation) FROM stdin;
4	7	5	t	2026-07-14 16:38:40.208158
5	7	6	t	2026-07-14 16:39:03.227689
6	7	21	t	2026-07-14 16:51:25.886293
12	15	21	t	2026-07-15 10:49:27.33212
19	8	5	t	2026-07-24 09:33:30.306113
21	21	5	t	2026-07-31 09:51:47.900104
\.


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_settings (cle, valeur) FROM stdin;
delaiMaxSansAffectation	48h
notificationsInternes	true
notificationsEmail	true
langue	Français
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

COPY public.invitation (id, objet, date_debut, date_fin, nombre_participant, statut, visibilite, date_creation, structure_emettrice, lieu, ampliation, contenu, numero_reference, signataire_nom, signataire_qualite, ville, mode_creation, alerte_delai_envoyee, contenu_delta) FROM stdin;
17	lkl	2026-07-14	2026-07-17	0	EN_ATTENTE	PUBLIC	2026-07-14 17:44:50.671509	32	haya	hjfcv; ghjh; tgjh;	Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.		kone gare	Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim ve"},{"insert":"niam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.","attributes":{"bold":true}},{"insert":"\\n\\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"},{"insert":" veniam, quis nostrud exercitation ullamco laboris nisi ","attributes":{"bold":true}},{"insert":"ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\\n\\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\\n"}]
19	;jv	2026-07-15	2026-07-17	0	EN_ATTENTE	PUBLIC	2026-07-15 06:45:13.290823	32		ncvb;vbb;jkkk	Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate\nvelit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non\nproident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit\nesse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in\nculpa qui officia deserunt mollit anim id est laborum.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut\naliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse\ncillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa\nqui officia deserunt mollit anim id est laborum.		rachid barro	Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate\\nvelit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non\\n"},{"insert":"proident, sunt in culpa qui officia deserunt mollit anim id est laborum.","attributes":{"bold":true}},{"insert":"\\n\\nLorem ipsum dol"},{"insert":"or sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"culpa qui officia deserunt mollit anim id est laborum.","attributes":{"bold":true}},{"insert":"\\n\\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut\\naliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse\\ncillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa\\nqui officia deserunt mollit anim id est laborum.\\n\\n"}]
20	kjb	2026-07-15	2026-07-17	0	EN_ATTENTE	PUBLIC	2026-07-15 06:59:32.121354	32			Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate\nvelit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non\nproident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit\nesse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in\nculpa qui officia deserunt mollit anim id est laborum.\njh\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut\naliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse\ncillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa\nqui officia deserunt mollit anim id est laborum.			Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate\\nvelit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non\\nproident, sunt in culpa qui officia deserunt mollit anim id est laborum.\\n\\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore\\net dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris\\nnisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit\\nesse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in\\nculpa qui officia deserunt mollit anim id est laborum.\\njh\\n\\n"},{"insert":"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa","attributes":{"bold":true}},{"insert":"\\n"},{"insert":"qui officia deserunt mollit anim id est laborum.","attributes":{"bold":true}},{"insert":"\\n\\n"}]
15	lkjbh	2026-07-10	2026-07-12	0	EN_ATTENTE	PUBLIC	2026-07-10 09:14:58.742371	32			Une branche technique : cette branche est consacrée à l’identification des besoins non fonctionnels. Elle prend en compte les différentes contraintes auxquelles l’application doit se conformer, notamment celles liées à l’intégration, au développement, à la sécurité, aux performances et à l’exploitation.\n\n\n  La phase de réalisation : cette phase s’appuie sur les résultats des deux branches précédentes pour concevoir et développer la solution. Elle englobe la conception préliminaire, la conception détaillée, le développement, les tests, ainsi que la recette finale, afin de garantir que la solution répondre aux besoins exprimés par les utilisateurs.\n\n\n\n\n\nDans cette partie, après avoir présenté le thème de notre étude, nous avons abordé la gestion de projet ainsi que la méthodologie retenue. Ces éléments nous permettant désormais de mieux cerner les exigences du travail à réaliser et les exigences du travail à réaliser et la démarche méthodologique à adopter pour sa mise en œuvre.\n\nhjhjj			Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":" Une branche technique : cette branche est consacrée à l’identification des besoins non fonctionnels. Elle prend en compte les différentes contraintes auxquelles l’application doit se conformer, notamment celles liées à l’intégration, au développement, à la sécurité, aux performances et à l’exploitation.\\n\\n\\n  La phase de réalisation : cette phase s’appuie sur les résultats des deux branches précédentes pour concevoir et développer la solution. Elle englobe la conception préliminaire, la conception détaillée, le développement, les tests, ainsi que la recette finale, afin de garantir que la solution répondre aux besoins exprimés par les utilisateurs.\\n\\n\\n\\n\\n\\n"},{"insert":"Dans cette partie, après avoir présenté","attributes":{"bold":true}},{"insert":" le thème de notre étude, nous avons abordé la gestion de projet ainsi que la méthodologie retenue. Ces éléments nous permettant désormais de mieux cerner les exigences du travail à réaliser et les exigences du travail à réaliser et la démarche méthodologique à adopter pour sa mise en œuvre.\\n\\nhjhjj"},{"insert":"\\n","attributes":{"align":"center"}},{"insert":"\\n\\n"}]
18	rencontre	2026-07-14	2026-07-16	2	EN_COURS	PUBLIC	2026-07-14 17:49:05.127945	22	kaya	\N	\N	\N	\N	\N	Ouagadougou	ENREGISTRER	f	\N
16	knk,nhb	2026-07-14	2026-07-17	3	EN_ATTENTE	PUBLIC	2026-07-14 17:41:07.927691	32	kaya	BJJH; hjbhh;iojn	obnkpurtr l,md,i\n,ccnnjd\n,cnsd		rachid barro	Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"obnkpurtr l,md,i","attributes":{"bold":true}},{"insert":"\\n","attributes":{"align":"center"}},{"insert":",ccnnjd\\n,cnsd\\n"}]
22	reunion	2026-07-15	2026-07-17	2	EN_COURS	PUBLIC	2026-07-15 10:41:25.599147	22	kay	\N	\N	\N	\N	\N	Ouagadougou	ENREGISTRER	f	\N
21	sgvjh	2026-07-15	2026-07-17	0	EN_ATTENTE	PUBLIC	2026-07-15 08:28:42.922152	32			« Pour vous faire mieux connaître d’où vient l’erreur de ceux qui blâment la volupté, et qui louent en quelque sorte la douleur, je vais entrer dans une explication plus étendue, et vous faire voir tout ce qui a été dit là-dessus par l’inventeur de la vérité, et, pour ainsi dire, par l’architecte de la vie heureuse.\n\n\n\nPersonne [dit Épicure] ne craint ni ne fuit la volupté en tant que volupté, mais en tant qu’elle attire de grandes douleurs à ceux qui ne savent pas en faire un usage modéré et raisonnable ; et personne n’aime ni ne recherche la douleur comme douleur, mais parce qu’il arrive quelquefois que, par le travail et par la peine, on parvienne à jouir d’une grande volupté. En effet, pour descendre jusqu’aux petites choses, qui de vous ne fait point quelque exercice pénible pour en retirer quelque sorte d’utilité ? Et qui pourrait justement blâmer, ou celui qui rechercherait une volupté qui ne pourrait être suivie de rien de fâcheux, ou celui qui éviterait une douleur dont il ne pourrait espérer aucun plaisir.\n\nAu contraire, nous blâmons avec raison et nous croyons dignes de mépris et de haine ceux qui, se laissant corrompre par les attraits d’une volupté présente, ne prévoient pas à combien de maux et de chagrins une passion aveugle les peut exposer.\n\nJ’en dis autant de ceux qui, par mollesse d’esprit, c’est-à-dire par la crainte de la peine et de la douleur, manquent aux devoirs de la vie. Et il est très facile de rendre raison de ce que j’avance. Car, lorsque nous sommes tout à fait libres, et que rien ne nous empêche de faire ce qui peut nous donner le plus de plaisir, nous pouvons nous livrer entièrement à la volupté et chasser toute sorte de douleur ; mais, dans les temps destinés aux devoirs de la société ou à la nécessité des affaires, souvent il faut faire divorce avec la volupté, et ne se point refuser à la peine.\n\nLa règle que suit en cela un homme sage, c’est de renoncer à de légères voluptés pour en avoir de plus grandes, et de savoir supporter des douleurs légères pour en éviter de plus fâcheuses. »			Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"« Pour vous faire mieux connaître d’où vient l’erreur de ceux qui blâment la volupté, et qui louent en quelque sorte la douleur, je vais entrer dans une explication plus étendue, et vous faire voir tout ce qui a été dit là-dessus par l’inventeur de la vérité, et, pour ainsi dire, par l’architecte de la vie heureuse.","attributes":{"bold":true}},{"insert":"\\n\\n\\n\\nPersonne [dit Épicure] ne craint ni ne fuit la volupté en tant que volupté, mais en tant qu’elle attire de grandes douleurs à ceux qui ne savent pas en faire un usage modéré et raisonnable ; et personne n’aime ni ne recherche la douleur comme douleur, mais parce qu’il arrive quelquefois que, par le travail et par la peine, on parvienne à jouir d’une grande volupté. En effet, pour descendre jusqu’aux petites choses, qui de vous ne fait point quelque exercice pénible pour en retirer quelque sorte d’utilité ? Et qui pourrait justement blâmer, ou celui qui rechercherait une volupté qui ne pourrait être suivie de rien de fâcheux, ou celui qui éviterait une douleur dont il ne pourrait espérer aucun plaisir.\\n\\nAu contraire, nous blâmons avec raison et nous croyons dignes de mépris et de haine ceux qui, se laissant corrompre par les attraits d’une volupté présente, ne prévoient pas à combien de maux et de chagrins une passion aveugle les peut exposer.\\n\\n"},{"insert":"J’en dis autant de ceux qui, par mollesse d’esprit, c’est-à-dire par la crainte de la peine et de la douleur, manquent aux devoirs de la vie. Et il est très facile de rendre raison de ce que j’avance. Car, lorsque nous sommes tout à fait libres, et que rien ne nous empêche de faire ce qui peut nous donner le plus de plaisir, nous pouvons nous livrer entièrement à la volupté et chasser toute sorte de douleur ; mais, dans les temps destinés aux devoirs de la société ou à la nécessité des affaires, souvent il faut faire divorce avec la volupté, et ne se point refuser à la peine.","attributes":{"italic":true}},{"insert":"\\n"},{"insert":"\\n","attributes":{"align":"center"}},{"insert":"La règle que suit en cela un homme sage, c’est de renoncer à de légères voluptés pour en avoir de plus grandes, et de savoir supporter des douleurs légères pour en éviter de plus fâcheuses. »"},{"insert":"\\n","attributes":{"align":"center"}}]
23	rencontre	2026-07-16	2026-07-18	4	EN_ATTENTE	PUBLIC	2026-07-15 10:47:19.170391	32	bobo	bdmp; bcmp	« Pour vous faire mieux connaître d’où vient l’erreur de ceux qui blâment la volupté, et qui louent en quelque sorte la douleur, je vais entrer dans une explication plus étendue, et vous faire voir tout ce qui a été dit là-dessus par l’inventeur de la vérité, et, pour ainsi dire, par l’architecte de la vie heureuse.\n\n\nPersonne [dit Épicure] ne craint ni ne fuit la volupté en tant que volupté, mais en tant qu’elle attire de grandes douleurs à ceux qui ne savent pas en faire un usage modéré et raisonnable ; et personne n’aime ni ne recherche la douleur comme douleur, mais parce qu’il arrive quelquefois que, par le travail et par la peine, on parvienne à jouir d’une grande volupté. En effet, pour descendre jusqu’aux petites choses, qui de vous ne fait point quelque exercice pénible pour en retirer quelque sorte d’utilité ? Et qui pourrait justement blâmer, ou celui qui rechercherait une volupté qui ne pourrait être suivie de rien de fâcheux, ou celui qui éviterait une douleur dont il ne pourrait espérer aucun plaisir.\n\nAu contraire, nous blâmons avec raison et nous croyons dignes de mépris et de haine ceux qui, se laissant corrompre par les attraits d’une volupté présente, ne prévoient pas à combien de maux et de chagrins une passion aveugle les peut exposer.	2026/0776	rachid barro	Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"« Pour vous faire mieux connaître d’où vient l’erreur de ceux qui blâment la volupté, et qui louent en quelque sorte la douleur, je vais entrer dans une explication plus étendue, et vous faire voir tout ce qui a été dit là-dessus par l’inventeur de la vérité, et, pour ainsi dire, par l’architecte de la vie heureuse.","attributes":{"bold":true}},{"insert":"\\n\\n\\nPersonne [dit Épicure] ne craint ni "},{"insert":"ne fuit la volupté","attributes":{"italic":true}},{"insert":" en tant que volupté, mais en tant qu’elle attire de grandes douleurs à ceux qui ne savent pas en faire un usage modéré et raisonnable ; et personne n’aime ni ne recherche la douleur comme douleur, mais parce qu’il arrive quelquefois que, par le travail et par la peine, on parvienne à jouir d’une grande volupté. En effet, pour descendre jusqu’aux petites choses, qui de vous ne fait point quelque exercice pénible pour en retirer quelque sorte d’utilité ? Et qui pourrait justement blâmer, ou celui qui rechercherait une volupté qui ne pourrait être suivie de rien de fâcheux, ou celui qui éviterait une douleur dont il ne pourrait espérer aucun plaisir.\\n\\nAu contraire, nous blâmons avec raison et nous croyons dignes de mépris et de haine ceux qui, se laissant corrompre par les attraits d’une volupté présente, ne prévoient pas à combien de maux et de chagrins une passion aveugle les peut exposer."},{"insert":"\\n","attributes":{"align":"center"}}]
24	,nb	2026-07-24	2026-07-25	0	EN_ATTENTE	PUBLIC	2026-07-24 11:22:52.059	32			bvcxhj,n;j,yèiukj			Le Secrétaire général	Ouagadougou	CREER	t	[{"insert":"bvcxhj,n;j,yèiukj\\n"}]
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (id, message, date_envoi, canal, statut, categorie, resource_id, action_label, utilisateur_id) FROM stdin;
705	🆕 Nouveau ticket créé : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-05 10:03:08.066494	INTERNE	f	TICKET	22	Voir	1
706	🆕 Nouveau ticket créé : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-05 10:03:08.111284	INTERNE	f	TICKET	22	Voir	2
708	🆕 Nouveau ticket créé : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-05 10:03:08.120921	INTERNE	f	TICKET	22	Voir	9
709	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:06:51.696175	INTERNE	f	TICKET	23	Voir	1
710	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:06:51.708615	INTERNE	f	TICKET	23	Voir	2
712	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:06:51.727538	INTERNE	f	TICKET	23	Voir	9
713	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:11:50.634182	INTERNE	f	TICKET	24	Voir	1
714	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:11:50.640373	INTERNE	f	TICKET	24	Voir	2
716	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:11:50.649386	INTERNE	f	TICKET	24	Voir	9
715	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:11:50.645398	INTERNE	t	TICKET	24	Voir	3
711	🆕 Nouveau ticket créé : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-05 10:06:51.719056	INTERNE	t	TICKET	23	Voir	3
707	🆕 Nouveau ticket créé : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-05 10:03:08.117991	INTERNE	t	TICKET	22	Voir	3
717	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #22 : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-07 10:11:00.78836	INTERNE	f	TICKET	22	Voir	1
718	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #22 : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-07 10:11:00.879083	INTERNE	f	TICKET	22	Voir	2
719	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #22 : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-07 10:11:00.884918	INTERNE	f	TICKET	22	Voir	3
720	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #22 : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-07 10:11:00.892048	INTERNE	f	TICKET	22	Voir	9
721	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #22 : [TEST] Ticket de test - integration assistant MESFPT - a ign…	2026-08-07 10:11:00.897306	INTERNE	f	TICKET	22	Voir	14
722	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #23 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-07 10:11:00.911544	INTERNE	f	TICKET	23	Voir	1
723	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #23 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-07 10:11:00.914065	INTERNE	f	TICKET	23	Voir	2
724	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #23 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-07 10:11:00.916111	INTERNE	f	TICKET	23	Voir	3
725	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #23 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-07 10:11:00.918129	INTERNE	f	TICKET	23	Voir	9
726	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #23 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-07 10:11:00.919878	INTERNE	f	TICKET	23	Voir	14
727	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #24 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-08 19:40:17.864757	INTERNE	f	TICKET	24	Voir	1
728	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #24 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-08 19:40:17.904273	INTERNE	f	TICKET	24	Voir	2
729	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #24 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-08 19:40:17.906955	INTERNE	f	TICKET	24	Voir	3
730	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #24 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-08 19:40:17.907998	INTERNE	f	TICKET	24	Voir	9
731	⏰ Le délai max sans affectation (48h) est dépassé pour le ticket #24 : Problème technique\n\nTicket généré par l'assistant de support…	2026-08-08 19:40:17.91006	INTERNE	f	TICKET	24	Voir	14
\.


--
-- Data for Name: piece_jointe_invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piece_jointe_invitation (id, nom, type, chemin, date_envoi, invitation_id) FROM stdin;
5	invitation_15 (2).pdf	application/pdf	invitations/16/611f798b-7cd4-47e8-843a-e191852fda85_invitation_15 (2).pdf	2026-07-14 17:41:07.990096	16
6	invitation_15 (2).pdf	application/pdf	invitations/17/507f23af-8e08-4c0d-8af0-ac65f655f3e4_invitation_15 (2).pdf	2026-07-14 17:44:50.69866	17
7	invitation_17.pdf	application/pdf	invitations/18/c3a625c6-a05d-4c28-844b-53edc8b99fd4_invitation_17.pdf	2026-07-14 17:49:05.163793	18
8	invitation_15 (2).pdf	application/pdf	invitations/18/2200dc1d-9166-4de7-9878-87a3fdd8910f_invitation_15 (2).pdf	2026-07-14 17:49:05.166789	18
9	invitation_12 (2).pdf	application/pdf	invitations/18/aa9fd5e8-7a38-4bf9-b037-2bc24e691480_invitation_12 (2).pdf	2026-07-14 17:49:05.169791	18
10	invitation_44 (2).pdf	application/pdf	invitations/18/b7f8f9de-7f6e-48bc-b1db-461dcb4c5cfd_invitation_44 (2).pdf	2026-07-14 17:49:05.172782	18
11	invitation_21.pdf	application/pdf	invitations/22/4d7757a7-bc3a-47e3-beba-d7446b667ca5_invitation_21.pdf	2026-07-15 10:41:25.631453	22
12	invitation_21.docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/22/6e32a5bd-c90a-4dda-8a5b-5ec4378289e0_invitation_21.docx	2026-07-15 10:41:25.633961	22
13	invitation_20.pdf	application/pdf	invitations/22/bfb936d2-c181-4ece-a8f9-9a10cfb6635b_invitation_20.pdf	2026-07-15 10:41:25.636116	22
14	invitation_20 (1).pdf	application/pdf	invitations/22/edefae06-274a-4967-8f93-e077f73a5e49_invitation_20 (1).pdf	2026-07-15 10:41:25.639121	22
15	invitation_21.pdf	application/pdf	invitations/23/23d08fd2-930a-4e91-85ba-c3e6bb8ac3e8_invitation_21.pdf	2026-07-15 10:47:19.189384	23
16	recepisse026467-097-03.pdf	application/pdf	invitations/24/761c41b8-a427-482b-a800-d2902b0f9803_recepisse026467-097-03.pdf	2026-07-24 11:22:52.135998	24
\.


--
-- Data for Name: piece_jointe_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piece_jointe_ticket (id, nom, type, chemin, date_envoi, ticket_id) FROM stdin;
35	A.png	image/png	tickets/21/67683a7e-208d-4656-9b7e-72d057cce264_A.png	2026-07-31 09:30:50.406743	21
8	WhatsApp Image 2026-07-12 at 08.47.26.jpeg	image/jpeg	tickets/7/ed2f5980-854b-4203-88aa-ee31bf7c2ec4_WhatsApp Image 2026-07-12 at 08.47.26.jpeg	2026-07-14 16:27:02.125857	7
9	WhatsApp Image 2026-07-12 at 08.47.02.jpeg	image/jpeg	tickets/7/3510a14c-2834-4d46-938f-94e6a720270d_WhatsApp Image 2026-07-12 at 08.47.02.jpeg	2026-07-14 16:27:02.133861	7
10	WhatsApp Image 2026-07-08 at 22.50.24.jpeg	image/jpeg	tickets/7/c5493acd-5fa1-4d46-89a6-4e7962a31536_WhatsApp Image 2026-07-08 at 22.50.24.jpeg	2026-07-14 16:27:02.136856	7
11	WhatsApp Image 2026-07-08 at 22.39.51.jpeg	image/jpeg	tickets/7/048b51ef-0c28-42b5-99e3-752d7d720ea3_WhatsApp Image 2026-07-08 at 22.39.51.jpeg	2026-07-14 16:27:02.138861	7
12	WhatsApp Image 2026-07-08 at 22.45.54.jpeg	image/jpeg	tickets/7/111cac4d-ffdc-4444-a0c5-a6c58473a2c0_WhatsApp Image 2026-07-08 at 22.45.54.jpeg	2026-07-14 16:27:02.139864	7
18	WhatsApp Image 2026-07-12 at 08.47.26.jpeg	image/jpeg	tickets/11/48b4f9be-48cf-48cd-9c4b-f219a1915fab_WhatsApp Image 2026-07-12 at 08.47.26.jpeg	2026-07-15 08:56:46.689221	11
19	WhatsApp Image 2026-07-12 at 08.47.02.jpeg	image/jpeg	tickets/11/6bdbb05a-952f-4e87-b700-7b656e394d4e_WhatsApp Image 2026-07-12 at 08.47.02.jpeg	2026-07-15 08:56:46.690522	11
27	WhatsApp Image 2026-07-12 at 08.47.26.jpeg	image/jpeg	tickets/15/24cb3f11-6b54-48a0-8c5b-bd4bade9ec79_WhatsApp Image 2026-07-12 at 08.47.26.jpeg	2026-07-15 10:49:08.085743	15
28	WhatsApp Image 2026-07-12 at 08.47.02.jpeg	image/jpeg	tickets/15/3e54e081-7dfc-436e-b254-a671dfbca94f_WhatsApp Image 2026-07-12 at 08.47.02.jpeg	2026-07-15 10:49:08.088122	15
29	WhatsApp Image 2026-07-08 at 22.50.24.jpeg	image/jpeg	tickets/15/be0602cd-5400-4a93-abe7-3d6b0df44a6e_WhatsApp Image 2026-07-08 at 22.50.24.jpeg	2026-07-15 10:49:08.089937	15
30	WhatsApp Image 2026-07-08 at 22.45.54.jpeg	image/jpeg	tickets/15/9c3cbda0-1236-4153-83d7-e09c76661e7c_WhatsApp Image 2026-07-08 at 22.45.54.jpeg	2026-07-15 10:49:08.089937	15
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role (id, nom, description) FROM stdin;
2	AGENT_DSI	Gestion invitations et tickets
3	SUPERVISEUR	Lecture et affectation
5	SECRETAIRE	gestion des invitations
1	ADMIN	Accès Complète au système
4	USAGER	Creation tickets uniquement
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permissions (role_id, permission) FROM stdin;
5	CREER_TICKET
\.


--
-- Data for Name: service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service (id, nom, description, structure_id) FROM stdin;
9	SEST	Service Equipement et Support Technique	22
10	SRS	le Service Réseaux et Systèmes	22
14	Secrétariat		22
13	SSQ	Le Service Sécurité et Qualité	22
12	SEA	Le Service Etudes et Applications	22
15	SAF	Le Service Administratif et Financier	22
7	USI	Urbaniste des Systèmes d'information	22
16	fhg		28
\.


--
-- Data for Name: structure; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.structure (id, nom, adresse, telephone, email) FROM stdin;
22	DSI	MESFPT	25252525	dsi@gmail.com
28	ecommerce	\N	\N	\N
32	Ministère de l'Enseignement Secondaire, de la Formation Professionnelle et Technique (MESFPT)	\N	\N	\N
\.


--
-- Data for Name: structure_invitee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.structure_invitee (id, invitation_id, structure_id, statut_reponse, date_envoi, date_reponse, lettre_chemin, lettre_generee, commentaire) FROM stdin;
45	15	22	EN_ATTENTE	2026-07-10 09:14:58.827982	\N	\N	f	\N
46	16	22	EN_ATTENTE	2026-07-14 17:41:07.968113	\N	\N	f	\N
47	17	22	EN_ATTENTE	2026-07-14 17:44:50.682527	\N	\N	f	\N
48	17	28	EN_ATTENTE	2026-07-14 17:44:50.685523	\N	\N	f	\N
49	19	22	EN_ATTENTE	2026-07-15 06:45:13.316812	\N	\N	f	\N
50	20	22	EN_ATTENTE	2026-07-15 06:59:32.149583	\N	\N	f	\N
51	21	22	EN_ATTENTE	2026-07-15 08:28:42.936119	\N	\N	f	\N
52	23	22	EN_ATTENTE	2026-07-15 10:47:19.182383	\N	\N	f	\N
53	23	28	EN_ATTENTE	2026-07-15 10:47:19.185382	\N	\N	f	\N
54	24	22	EN_ATTENTE	2026-07-24 11:22:52.116575	\N	\N	f	\N
\.


--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, date_creation, statut, priorite, solution, structure_id, createur_id, description, whatsapp, alerte_delai_envoyee) FROM stdin;
21	2026-07-31 09:30:50.309432	EN_COURS	ELEVEE	\N	22	3	imprimante	76767878	f
11	2026-07-15 08:56:46.674985	FERME	MOYENNE	debrancher puis rebrancher	22	3	probleme de cable reseau	76847464	t
22	2026-08-05 10:03:07.910974	EN_ATTENTE	MOYENNE	\N	\N	\N	[TEST] Ticket de test - integration assistant MESFPT - a ignorer/supprimer	\N	t
23	2026-08-05 10:06:51.653495	EN_ATTENTE	MOYENNE	\N	22	\N	Problème technique\n\nTicket généré par l'assistant de support technique.\n\nDemandeur : Test Madina\nEmail : test@mesfpt.bf\nTéléphone : 70000000\nService : DSI\n\nRésumé de l'échange :\n- Agent : je veux creer un ticket, mon ecran ne saffiche plus du tout\n- Assistant : Je vais transmettre ce problème à un technicien. Pour qu'il sache qui contacter et où intervenir, merci de renseigner vos coordonnées ci-dessous.\n\nOrigine : demande explicite de l'agent	\N	t
24	2026-08-05 10:11:50.610692	EN_ATTENTE	MOYENNE	\N	22	\N	Problème technique\n\nTicket généré par l'assistant de support technique.\n\nDemandeur : sibalo madina\nEmail : sibalomadina@gmail.com\nTéléphone : 67378432\nService : DSI\n\nRésumé de l'échange :\n- Agent : ma moto est en panne\n- Assistant : Je n'ai pas de fiche de dépannage pour ce type de problème. Un technicien va prendre le relais.\n\nOrigine : aucune fiche de dépannage disponible pour ce sujet	\N	t
7	2026-07-14 16:27:02.066015	RESOLU	MOYENNE	kjlhnss,xns	22	\N	imprimante	06031093	f
15	2026-07-15 10:49:08.054894	EN_COURS	MOYENNE	\N	22	\N	pc marche pas	76787634	f
8	2026-07-15 01:32:53.78368	EN_COURS	ELEVEE	\N	22	\N	jhvc	76876564	f
\.


--
-- Data for Name: utilisateur; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateur (user_id, nom, prenom, email, telephone, mot_de_passe, date_creation, iu, actif, service_id, structure_id) FROM stdin;
2	Administrateur	SystŠme	admin@dsi.gov.bf	\N	$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWa	2026-06-02 22:43:30.2918	ADM-001	t	\N	\N
5	barro	rachid	rachid@gmail.com	76546354	$2a$10$x9EnQJpMztr6vEuPN6BvX.G1zxV6WsD3VfGNp0OSg/GeQKQe.ql5C	2026-06-03 13:21:00.936637	1233	t	\N	\N
8	kone	rachi	kone@gmail.com	\N	$2a$10$zpVbSZXy0/AFzLElWvoKSe1xShtq2Xvt0iNN.aW8ye0yktnBg7NRW	2026-06-09 19:26:07.561549	\N	t	\N	\N
27	barro	fadila	fadila@gmail.com	\N	$2a$10$lAuyOxJtRmmCAOq3KT1SCOtY9Ny/EBcSm0Wka454yFi2HI1sQy7m2	2026-07-15 20:47:41.712112	\N	t	10	22
24	KORGO	Kadigueta	kadiguetakorgo77@gmail.com	64154748	$2a$10$Lc7.uLKOM4.5FzIiWpOnTe8pLcOvMsiMDlqy1bNZKK3j4U.Bkg0Ai	2026-07-15 09:33:31.4031	N010203	t	\N	\N
4	konate	rachi	rachi1@gmail.com	\N	$2a$10$.PSKtKJTejrgQLYNq7e6l.d94cA3M/8yJAWTHyJFxmffmTCfR6wei	2026-06-03 13:13:24.60639	\N	t	10	22
10	raz	ros	rosraz@gmail.com	\N	$2a$10$Hx.0iIjXgnMrFdlE3tbfRu3d33gSOBIsx3jXQHyOVixqQsTh4FdaG	2026-06-11 21:05:53.520787	\N	t	\N	\N
11	nomo	mom	nomo@gmail.com	\N	$2a$10$pzUs8C2BpV5wdith/OP9nOV9XBHVVerHzhT4Bx4UK5BxqOo4BWTx2	2026-06-14 19:15:54.146221	\N	t	\N	\N
12	nnn	lk	nnn@gmail.com	\N	$2a$10$qyqHtCcA9QiM/RWUx9OFRuteLlbBmS762tHMp9DkAgnGb0bNxeo3u	2026-06-14 19:20:22.022311	\N	f	\N	\N
13	konte	fatou	fatou@gmail.com	67584949	$2a$10$7rQfi5Y0QXd5qGnRB8r.VeA5dI11LGURFnvNZKfxIzkd/Pjb9HTvO	2026-06-27 22:49:46.156695	874894	t	\N	\N
3	Admin	DSI	admin2@dsi.gov.bf	\N	$2a$10$a9eCuoE6YfaVu9jc3z1RHuDZ4jlTsiLXMK/k5AFLGzulU5jLD/Z2G	2026-06-02 22:52:48.08875	\N	f	\N	\N
1	rachi	konte	rachi@gmail.com	54637383	$2a$10$X.J.YQwzP2zLhhk3LobZwORPc2C12p8aWXI6PH3I9TNaXPhouHH3y	2026-06-01 15:54:10.743005	1234	f	\N	\N
9	rachida	barro	rachidabarro@gmail.com	76847464	$2a$10$UHpIq24G/qOzuynyax7cMuJywrFaJpoCzDsBSvL4/A1819vwW2d8e	2026-06-09 23:16:42.856016	23	f	\N	\N
14	barro	rachida	rachidabarro98@gmail.com	\N	$2a$10$7WlHCKymUIZ6DxBiJan.CegynLpwo4pBFtKBShHgUuKadQOK3HobC	2026-06-29 20:47:45.889961	\N	t	\N	\N
15	konate	fati	fati@gmail.com	67898989	$2a$10$lEWEG3qdc/KIwTmVln23k.QDkg4D3AFmjAZOXX4JOGoxzzjGo/QjC	2026-06-30 09:54:10.053875	876767	t	\N	\N
17	mlkjhgc	kjhgc	jkhgfd@gmail.com	54656567	$2a$10$PNwyujsuW9wX/F07aQrDfez90vPjscuFfj8qqNs1lRNpdBSTODhBe	2026-07-01 20:11:18.07546	\N	t	\N	\N
16					$2a$10$E8iDm2qhreqdb.aZ7yLWsOsoTQUlh9C6JzjRCqsxxQ0FRRNx3k/3W	2026-07-01 13:31:15.885897	\N	f	\N	\N
18	sanogo	rachi	sanogo@gmail.com	76876564	$2a$10$LRXWFdcqu98birOcvaOcy.kHVOCr5DrcRtkTk.1z9322GHK55nQ/m	2026-07-04 13:23:04.71785	3456	t	\N	\N
6	barro	rachi	rachidabarro98@mail.com	78674345	$2a$10$8zeyvxNk9YrYzl1Vsp/P.ulTUOlsd5zpiS98rfGvvRujMaDNGTQry	2026-06-09 01:10:57.386182	4354	t	\N	\N
7	barro	prenom	rachidabarro66@gmail.com	67847383	$2a$10$q6XABO/VplgXkTzs8mdcHOtJhZQzwt4Cj/StbKBeX1LN2w/6g0SsK	2026-06-09 01:17:40.932874	123	f	\N	\N
19	blll	isisbb	zongoismael48@gmail.com	76199145	$2a$10$JCdrnpRPElkunBC8iaT0SeF3kitt5jBUxy6Cxi388ilF/DB2ntdRm	2026-07-09 13:52:22.998981	\N	t	\N	\N
20	toto	ali	ali@gmail.com	76654534	$2a$10$L0ygnscqnoJfl0j8laU7deks/GbZd1vPZZMn9klxZFBywp3SeCFQG	2026-07-14 16:23:34.196279	34456	t	\N	\N
21	ali	toto	almissikindo7@gmail.com	\N	$2a$10$LFCeNiuOh5j1PuQe1CH3veTgY/ovgmLg0PZLiVSmcRy2rmNqmMAy2	2026-07-14 16:50:50.087589	\N	t	\N	\N
22	titi	toto	toto@gmail.com	56789098	$2a$10$HSQ.fvVl7iAGiZos.oC5zuI9QjrdChZLLrPC3Tvs5B32mPb/RTFpi	2026-07-15 01:24:48.038186	34655	t	\N	\N
23	layla	kone	hamadyleylatou@gmail.com	73805108	$2a$10$k1qpxeBTuKWQ2nbUNHkX2OQHSH68wX6Kzaq0L709viEJI.a4WCJz6	2026-07-15 09:02:45.960085	4565	t	\N	\N
25	konate	rachi	konate@gmail.com	67656765	$2a$10$k8LyOrq0nw4i7lIAh.zY/usMyl4GOvWV0wN68YMeztgVA5BCDj6oa	2026-07-15 10:36:59.321697	6756	t	\N	\N
26	OUEDRAOGO	Adolphe	adolphe.ouedraogo@formationpro.gov.bf	\N	$2a$10$/jYjK8mzIS2Tm.TlczTv9uLcVtmaYGHoZdW3OQ5IyXUXWIfE205/q	2026-07-15 10:54:49.059961	\N	t	\N	\N
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
17	13	4
18	14	5
19	15	4
20	16	4
21	17	4
22	18	4
23	19	4
24	20	4
25	21	2
26	22	4
27	23	4
28	24	4
29	25	4
30	26	2
31	27	2
\.


--
-- Name: affectation_invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_invitation_id_seq', 6, true);


--
-- Name: affectation_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_ticket_id_seq', 21, true);


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

SELECT pg_catalog.setval('public.invitation_id_seq', 24, true);


--
-- Name: notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_id_seq', 731, true);


--
-- Name: piece_jointe_invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piece_jointe_invitation_id_seq', 16, true);


--
-- Name: piece_jointe_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piece_jointe_ticket_id_seq', 35, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 5, true);


--
-- Name: service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_id_seq', 16, true);


--
-- Name: structure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.structure_id_seq', 34, true);


--
-- Name: structure_invitee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.structure_invitee_id_seq', 54, true);


--
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 24, true);


--
-- Name: utilisateur_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateur_role_id_seq', 31, true);


--
-- Name: utilisateur_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateur_user_id_seq', 27, true);


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
-- Name: role_permissions fklodb7xh4a2xjv39gc3lsop95n; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fklodb7xh4a2xjv39gc3lsop95n FOREIGN KEY (role_id) REFERENCES public.role(id);


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

\unrestrict wuFfvnIOmzSVZVw89TeUvfwh9eRULckRGJuPeU2HMbZksePz3UDJIYFto2MJCfI


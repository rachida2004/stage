--
-- PostgreSQL database dump
--

\restrict d96Ojm2I3DkKd25Opo7j7rwPoCQhri05n3drK92Ld70awsuZKsBIfTyVx3mOgaE

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
    structure_emettrice bigint
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
    description text NOT NULL
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
\.


--
-- Data for Name: affectation_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affectation_ticket (id, ticket_id, agent_id, responsable_principal, date_affectation) FROM stdin;
1	5	3	t	2026-06-07 03:10:21.213169
2	5	4	t	2026-06-08 18:25:19.202032
3	6	5	t	2026-06-08 18:28:23.76241
4	7	1	t	2026-06-09 19:38:04.996411
5	8	8	t	2026-06-09 20:09:38.278303
7	9	5	t	2026-06-09 21:25:19.367504
8	10	5	t	2026-06-09 21:33:38.978869
9	11	8	t	2026-06-09 22:49:45.059903
10	12	4	t	2026-06-09 23:18:20.539539
11	13	3	t	2026-06-10 05:49:25.901474
12	14	5	t	2026-06-10 09:47:41.618806
13	15	7	t	2026-06-10 20:15:24.900223
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

COPY public.invitation (id, objet, date_debut, date_fin, nombre_participant, statut, visibilite, date_creation, structure_emettrice) FROM stdin;
4	d	2026-06-02	2026-06-27	0	EN_ATTENTE	PUBLIC	2026-06-03 09:39:51.154846	\N
5	g	2026-06-16	2026-06-27	0	EN_ATTENTE	PUBLIC	2026-06-03 11:00:56.485296	\N
6	qss	2026-06-12	2026-06-26	0	EN_ATTENTE	PUBLIC	2026-06-04 11:02:25.242992	\N
7	ghjk	2026-06-08	2026-06-10	0	EN_ATTENTE	PUBLIC	2026-06-08 18:32:18.303401	\N
8	LKJHGCFHJ	2026-06-09	2026-06-26	2	EN_ATTENTE	PUBLIC	2026-06-09 01:27:23.776136	\N
9	xghjklw	2026-06-09	2026-06-26	0	EN_ATTENTE	PUBLIC	2026-06-09 22:46:40.296999	\N
10	bvnvjkd	2026-06-10	2026-06-25	0	EN_ATTENTE	PUBLIC	2026-06-10 08:47:05.459443	\N
11	wxcvbn	2026-06-10	2026-06-18	0	EN_ATTENTE	PUBLIC	2026-06-10 08:57:23.86118	\N
12	x,	2026-06-24	2026-06-18	0	EN_ATTENTE	PUBLIC	2026-06-10 09:36:19.968002	\N
14	cvbnk	2026-06-10	2026-06-26	0	EN_ATTENTE	PUBLIC	2026-06-10 11:31:19.972371	\N
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
\.


--
-- Data for Name: piece_jointe_invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piece_jointe_invitation (id, nom, type, chemin, date_envoi, invitation_id) FROM stdin;
1	images.jpg	image/jpeg	invitations/4/56ff8164-5ad7-4d57-a635-8f903bda54a2_images.jpg	2026-06-03 09:39:51.246035	4
2	PROTOCOLE UNIVERSITE AUBE NOUVELLE2 (3).docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/5/da36bad0-464b-430a-b47b-f3b3b0efb40e_PROTOCOLE UNIVERSITE AUBE NOUVELLE2 (3).docx	2026-06-03 11:00:56.535841	5
3	logo.jpg	image/jpeg	invitations/6/81dbf3ce-0a21-4896-bcd4-71c3fec00634_logo.jpg	2026-06-04 11:02:25.312881	6
4	images.jpg	image/jpeg	invitations/7/c35e8ec8-44d1-4c52-89e2-1d186c4d68db_images.jpg	2026-06-08 18:32:18.316399	7
5	PROTOCOLE UNIVERSITE AUBE NOUVELLE2.docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/8/73b06cbf-f9f0-4a5d-9486-c9a3c0e3bf09_PROTOCOLE UNIVERSITE AUBE NOUVELLE2.docx	2026-06-09 01:27:23.799131	8
6	PROTOCOLE UNIVERSITE AUBE NOUVELLE2 (2).docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/8/3450a89f-4737-4742-98ea-4fa602a7f263_PROTOCOLE UNIVERSITE AUBE NOUVELLE2 (2).docx	2026-06-09 01:27:23.808791	8
7	PROTOCOLE UNIVERSITE AUBE NOUVELLE2.docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/9/15c6d9bf-3d9d-4ce6-a4ad-5a482499baf4_PROTOCOLE UNIVERSITE AUBE NOUVELLE2.docx	2026-06-09 22:46:40.303428	9
8	invitation_9.docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/10/156c565e-c725-4cdd-96cf-32e1996dee8a_invitation_9.docx	2026-06-10 08:47:05.499948	10
9	invitation_9.pdf	application/pdf	invitations/10/2879516e-f5f4-47a7-8d1d-186e1bee4111_invitation_9.pdf	2026-06-10 08:47:05.506948	10
10	invitation_9.pdf	application/pdf	invitations/11/0ccca1fb-e8b4-479d-ad9d-9bd4bf3707a8_invitation_9.pdf	2026-06-10 08:57:23.867174	11
11	invitation_9.docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/11/753957d5-2328-4293-82f2-2c3aeb10e559_invitation_9.docx	2026-06-10 08:57:23.868189	11
12	invitation_9.pdf	application/pdf	invitations/12/61780227-e8ee-4916-9cfd-14b6821f7f50_invitation_9.pdf	2026-06-10 09:36:20.022315	12
13	invitation_12.docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	invitations/14/bb16d6fc-cfae-4daa-b84d-99485e753658_invitation_12.docx	2026-06-10 11:31:20.016225	14
\.


--
-- Data for Name: piece_jointe_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piece_jointe_ticket (id, nom, type, chemin, date_envoi, ticket_id) FROM stdin;
6	invitation_5 (4).docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	tickets/6/b50ccc4d-94df-4d84-a7aa-d589407ca590_invitation_5 (4).docx	2026-06-07 03:11:23.59826	6
7	route.txt	text/plain	tickets/7/44109c74-6878-40d1-b536-b4e642b4fa5d_route.txt	2026-06-09 01:28:19.444576	7
8	route.txt	text/plain	tickets/8/32391c7c-ea8f-46f0-9a75-eb782f26b804_route.txt	2026-06-09 06:36:07.249224	8
9	route.txt	text/plain	tickets/9/5bf8c370-a4bf-465a-afa3-0cbf87bc620d_route.txt	2026-06-09 06:42:58.302853	9
10	images.jpg	image/jpeg	tickets/10/519e5939-8b8d-4c5c-aa40-426ccdc52335_images.jpg	2026-06-09 21:33:17.006975	10
11	route.txt	text/plain	tickets/11/3031a5b6-c866-4113-8677-313d67c04b58_route.txt	2026-06-09 22:48:59.727127	11
12	route.txt	text/plain	tickets/12/8261bc54-f48a-4c9a-866c-63fc791cf92b_route.txt	2026-06-09 23:17:56.617498	12
13	route.txt	text/plain	tickets/13/e95d5a4e-1b6a-46c3-bc53-e9c018839e2a_route.txt	2026-06-10 05:40:16.879344	13
14	invitation_10.pdf	application/pdf	tickets/14/0d9e468d-2d81-490a-850f-f5c0485ff408_invitation_10.pdf	2026-06-10 09:47:26.022076	14
15	invitation_12.pdf	application/pdf	tickets/15/1d53828b-c2ff-428b-a2c4-41e84f64c5a0_invitation_12.pdf	2026-06-10 20:15:06.670094	15
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
1	Statistique	Service des statistiques	\N
2	DMP	Direction des marchÃ©s publics	\N
3	RH	Ressources humaines	\N
4	BCMP	Bureau de coordination	\N
\.


--
-- Data for Name: structure; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.structure (id, nom, adresse, telephone, email) FROM stdin;
1	DSI MinistÃ¨re BF	Ouagadougou, Burkina Faso	+226 25 30 00 00	dsi@ministere.gov.bf
2	ANSI	Ouagadougou, Burkina Faso	+226 25 31 00 00	contact@ansi.bf
3	MATD	Ouagadougou, Burkina Faso	+226 25 32 00 00	contact@matd.gov.bf
4	ARCEP	Ouagadougou, Burkina Faso	+226 25 33 00 00	contact@arcep.bf
\.


--
-- Data for Name: structure_invitee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.structure_invitee (id, invitation_id, structure_id, statut_reponse, date_envoi, date_reponse, lettre_chemin, lettre_generee, commentaire) FROM stdin;
\.


--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, date_creation, statut, priorite, solution, structure_id, createur_id, description) FROM stdin;
5	2026-06-05 18:09:52.190194	FERME	MOYENNE	\N	\N	\N	higuhj
6	2026-06-07 03:11:23.577189	FERME	MOYENNE	\N	\N	\N	cvbn,
7	2026-06-09 01:28:19.43358	EN_COURS	MOYENNE	\N	\N	\N	KJHVCXCHJK
8	2026-06-09 06:36:07.168293	EN_COURS	MOYENNE	\N	\N	\N	jkxlc
9	2026-06-09 06:42:58.288157	EN_COURS	MOYENNE	\N	\N	\N	vcbn,k
10	2026-06-09 21:33:16.99241	EN_COURS	MOYENNE	\N	\N	\N	jbn,b
11	2026-06-09 22:48:59.720012	EN_COURS	MOYENNE	\N	\N	\N	wdfgh
12	2026-06-09 23:17:56.602588	EN_COURS	MOYENNE	\N	\N	\N	BJ DN
13	2026-06-10 05:40:16.806509	EN_COURS	MOYENNE	\N	\N	\N	jgvbn,
14	2026-06-10 09:47:25.99907	EN_PAUSE	MOYENNE	\N	\N	\N	dgjhk
15	2026-06-10 20:15:06.621289	EN_COURS	MOYENNE	\N	\N	\N	bhjkn,
\.


--
-- Data for Name: utilisateur; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateur (user_id, nom, prenom, email, telephone, mot_de_passe, date_creation, iu, actif, service_id, structure_id) FROM stdin;
2	Administrateur	SystŠme	admin@dsi.gov.bf	\N	$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWa	2026-06-02 22:43:30.2918	ADM-001	t	\N	\N
3	Admin	DSI	admin2@dsi.gov.bf	\N	$2a$10$a9eCuoE6YfaVu9jc3z1RHuDZ4jlTsiLXMK/k5AFLGzulU5jLD/Z2G	2026-06-02 22:52:48.08875	\N	t	\N	\N
4	konate	rachi	rachi1@gmail.com	\N	$2a$10$.PSKtKJTejrgQLYNq7e6l.d94cA3M/8yJAWTHyJFxmffmTCfR6wei	2026-06-03 13:13:24.60639	\N	t	\N	\N
5	barro	rachid	rachid@gmail.com	76546354	$2a$10$x9EnQJpMztr6vEuPN6BvX.G1zxV6WsD3VfGNp0OSg/GeQKQe.ql5C	2026-06-03 13:21:00.936637	1233	t	\N	\N
7	barro	prenom	rachidabarro66@gmail.com	67847383	$2a$10$rBz9wXxBhoiC//FUVHCbm.VWY6.Z1D8vmjlqG0HpHvII./CqHpwme	2026-06-09 01:17:40.932874	123	t	\N	\N
8	kone	rachi	kone@gmail.com	\N	$2a$10$zpVbSZXy0/AFzLElWvoKSe1xShtq2Xvt0iNN.aW8ye0yktnBg7NRW	2026-06-09 19:26:07.561549	\N	t	\N	\N
9	rachida	barro	rachidabarro@gmail.com	76847464	$2a$10$UHpIq24G/qOzuynyax7cMuJywrFaJpoCzDsBSvL4/A1819vwW2d8e	2026-06-09 23:16:42.856016	23	t	\N	\N
1	rachi	konte	rachi@gmail.com	54637383	$2a$10$X.J.YQwzP2zLhhk3LobZwORPc2C12p8aWXI6PH3I9TNaXPhouHH3y	2026-06-01 15:54:10.743005	1234	t	\N	\N
6	barro	rachi	rachidabarro98@mail.com	78674345	$2a$10$8zeyvxNk9YrYzl1Vsp/P.ulTUOlsd5zpiS98rfGvvRujMaDNGTQry	2026-06-09 01:10:57.386182	4354	t	\N	\N
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
7	7	4
8	8	3
9	9	1
\.


--
-- Name: affectation_invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_invitation_id_seq', 1, false);


--
-- Name: affectation_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affectation_ticket_id_seq', 14, true);


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

SELECT pg_catalog.setval('public.invitation_id_seq', 14, true);


--
-- Name: notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_id_seq', 12, true);


--
-- Name: piece_jointe_invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piece_jointe_invitation_id_seq', 13, true);


--
-- Name: piece_jointe_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piece_jointe_ticket_id_seq', 15, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 4, true);


--
-- Name: service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_id_seq', 4, true);


--
-- Name: structure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.structure_id_seq', 4, true);


--
-- Name: structure_invitee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.structure_invitee_id_seq', 1, false);


--
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 15, true);


--
-- Name: utilisateur_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateur_role_id_seq', 9, true);


--
-- Name: utilisateur_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.utilisateur_user_id_seq', 9, true);


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

\unrestrict d96Ojm2I3DkKd25Opo7j7rwPoCQhri05n3drK92Ld70awsuZKsBIfTyVx3mOgaE


SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA gn_commons;


SET search_path = gn_commons, pg_catalog;
SET default_with_oids = false;


-------------
--FUNCTIONS--
-------------


CREATE OR REPLACE FUNCTION check_entity_field_exist(myentity character varying)
  RETURNS boolean AS
$BODY$
--Function that allows to check if the field of an entity of a table type exists. Parameter : 'schema.table.field'
--USAGE : SELECT gn_commons.check_entity_field_exist('schema.table.field');
  DECLARE
    entity_array character varying(255)[];
  BEGIN
    entity_array = string_to_array(myentity,'.');
      IF entity_array[3] IN(SELECT column_name FROM information_schema.columns WHERE table_schema = entity_array[1] AND table_name = entity_array[2] AND column_name = entity_array[3] ) THEN
        RETURN true;
      END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
--USAGE : SELECT gn_commons.check_entity_field_exist('pr_occtax.t_releves_occtax.id_releve_occtax');


CREATE OR REPLACE FUNCTION check_entity_value_exist(myentity character varying, myvalue integer)
  RETURNS boolean AS
$BODY$
--Function that allows to check if a value exists in the field of a table type.
--USAGE : SELECT gn_commons.check_entity_value_exist('schema.table.field', value);
  DECLARE
    entity_array character varying(255)[];
    r record;
    _row_ct integer;
  BEGIN
    -- Cas particulier quand on insère le média avant l'entité
    IF myvalue = -1 Then
	    RETURN TRUE;
    END IF;

    entity_array = string_to_array(myentity,'.');
    EXECUTE 'SELECT '||entity_array[3]|| ' FROM '||entity_array[1]||'.'||entity_array[2]||' WHERE '||entity_array[3]||'=' ||myvalue INTO r;
    GET DIAGNOSTICS _row_ct = ROW_COUNT;
      IF _row_ct > 0 THEN
        RETURN true;
      END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
--USAGE
--SELECT gn_commons.check_entity_value_exist('pr_occtax.t_releves_occtax.id_releve_occtax', 2);

CREATE OR REPLACE FUNCTION get_table_location_id(myschema text, mytable text)
  RETURNS integer AS
$BODY$
DECLARE
	theidtablelocation int;
BEGIN
--Retrouver dans gn_commons.bib_tables_location l'id (PK) de la table passée en paramètre
  SELECT INTO theidtablelocation id_table_location FROM gn_commons.bib_tables_location
	WHERE "schema_name" = myschema AND "table_name" = mytable;
  RETURN theidtablelocation;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
--USAGE
--SELECT gn_commons.get_table_location_id('pr_occtax', 't_releves_occtax');

CREATE OR REPLACE FUNCTION get_uuid_field_name(myschema text, mytable text)
  RETURNS text AS
$BODY$
DECLARE
	theuuidfieldname character varying(50);
BEGIN
--Retrouver dans gn_commons.bib_tables_location le nom du champs UUID de la table passée en paramètre
  SELECT INTO theuuidfieldname uuid_field_name FROM gn_commons.bib_tables_location
	WHERE "schema_name" = myschema AND "table_name" = mytable;
  RETURN theuuidfieldname;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
--USAGE
--SELECT gn_commons.get_uuid_field_name('pr_occtax', 't_occurrences_occtax');

CREATE OR REPLACE FUNCTION gn_commons.fct_trg_add_default_validation_status()
  RETURNS trigger AS
$BODY$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theidtablelocation int;
	theuuidfieldname character varying(50);
	theuuid uuid;
  thecomment text := 'auto = default value';
BEGIN
  --Retrouver l'id de la table source stockant l'enregistrement en cours de validation
	SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
  --Retouver le nom du champ stockant l'uuid de l'enregistrement en cours de validation
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
  --Récupérer l'uuid de l'enregistrement en cours de validation
	EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
  --Insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_validations (id_table_location,uuid_attached_row,id_nomenclature_valid_status,id_validator,validation_comment,validation_date)
  VALUES(
    theidtablelocation,
    theuuid,
    ref_nomenclatures.get_default_nomenclature_value('STATUT_VALID'), --comme la fonction est générique, cette valeur par défaut doit exister et est la même pour tous les modules
    null,
    thecomment,
    NOW()
  );
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION fct_trg_log_changes()
  RETURNS trigger AS
$BODY$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theidtablelocation int;
	theuuidfieldname character varying(50);
	theuuid uuid;
	theoperation character(1);
	thecontent json;
BEGIN
	--Retrouver l'id de la table source stockant l'enregistrement à tracer
	SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
	--Retouver le nom du champ stockant l'uuid de l'enregistrement à tracer
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
	--Retrouver la première lettre du type d'opération (C, U, ou D)
	SELECT INTO theoperation LEFT(TG_OP,1);
	--Construction du JSON du contenu de l'enregistrement tracé
	IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		--Construction du JSON
		thecontent :=  row_to_json(NEW.*);
		--Récupérer l'uuid de l'enregistrement à tracer
		EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
	ELSIF (TG_OP = 'DELETE') THEN
		--Construction du JSON
		thecontent :=  row_to_json(OLD.*);
		--Récupérer l'uuid de l'enregistrement à tracer
		EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING OLD;
	END IF;
  --Insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_history_actions (id_table_location,uuid_attached_row,operation_type,operation_date,table_content)
  VALUES(
    theidtablelocation,
    theuuid,
    theoperation,
    NOW(),
    thecontent
  );
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION get_default_parameter(myparamname text, myidorganisme integer DEFAULT 0)
  RETURNS text AS
$BODY$
    DECLARE
        theparamvalue text;
-- Function that allows to get value of a parameter depending on his name and organism
-- USAGE : SELECT gn_commons.get_default_parameter('taxref_version');
-- OR      SELECT gn_commons.get_default_parameter('uuid_url_value', 2);
  BEGIN
    IF myidorganisme IS NOT NULL THEN
      SELECT INTO theparamvalue parameter_value FROM gn_commons.t_parameters WHERE parameter_name = myparamname AND id_organism = myidorganisme LIMIT 1;
    ELSE
      SELECT INTO theparamvalue parameter_value FROM gn_commons.t_parameters WHERE parameter_name = myparamname LIMIT 1;
    END IF;
    RETURN theparamvalue;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION gn_commons.is_in_period(
    dateobs date,
    datebegin date,
    dateend date)
  RETURNS boolean
IMMUTABLE
LANGUAGE plpgsql
AS $$
DECLARE
day_obs int;
begin_day int;
end_day int;
test int; 
--Function to check if a date (dateobs) is in a period (datebegin, dateend)
--USAGE : SELECT gn_commons.is_in_period(dateobs, datebegin, dateend);
BEGIN
day_obs = extract(doy FROM dateobs);--jour de la date passée
begin_day = extract(doy FROM datebegin);--jour début
end_day = extract(doy FROM dateend); --jour fin
test = end_day - begin_day; --test si la période est sur 2 année ou pas
--si on est sur 2 années
IF test < 0 then
	IF day_obs BETWEEN begin_day AND 366 OR day_obs BETWEEN 1 AND end_day THEN RETURN true;
	END IF;
-- si on est dans la même année
else 
	IF day_obs BETWEEN begin_day AND end_day THEN RETURN true;
	END IF;
END IF;
	RETURN false;	
END;
$$;

-------------
--TABLES--
-------------

CREATE TABLE t_parameters (
    id_parameter integer NOT NULL,
    id_organism integer,
    parameter_name character varying(100) NOT NULL,
    parameter_desc text,
    parameter_value text NOT NULL,
    parameter_extra_value character varying(255)
);
COMMENT ON TABLE t_parameters IS 'Allow to manage content configuration depending on organism or not (CRUD depending on privileges).';
CREATE SEQUENCE t_parameters_id_parameter_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_parameters_id_parameter_seq OWNED BY t_parameters.id_parameter;
ALTER TABLE ONLY t_parameters ALTER COLUMN id_parameter SET DEFAULT nextval('t_parameters_id_parameter_seq'::regclass);
SELECT pg_catalog.setval('t_parameters_id_parameter_seq', 1, false);


CREATE TABLE bib_tables_location
(
  id_table_location integer NOT NULL,
  table_desc character varying(255),
  schema_name character varying(50) NOT NULL,
  table_name character varying(50) NOT NULL,
  pk_field character varying(50) NOT NULL,
  uuid_field_name character varying(50) NOT NULL
);

CREATE SEQUENCE bib_tables_location_id_table_location_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bib_tables_location_id_table_location_seq OWNED BY bib_tables_location.id_table_location;
ALTER TABLE ONLY bib_tables_location ALTER COLUMN id_table_location SET DEFAULT nextval('bib_tables_location_id_table_location_seq'::regclass);
SELECT pg_catalog.setval('bib_tables_location_id_table_location_seq', 1, false);


CREATE TABLE t_medias
(
  id_media integer NOT NULL,
  unique_id_media uuid NOT NULL DEFAULT public.uuid_generate_v4(),
  id_nomenclature_media_type integer NOT NULL,
  id_table_location integer NOT NULL,
  uuid_attached_row uuid NOT NULL,
  title_fr character varying(255),
  title_en character varying(255),
  title_it character varying(255),
  title_es character varying(255),
  title_de character varying(255),
  media_url character varying(255),
  media_path character varying(255),
  author character varying(100),
  description_fr text,
  description_en text,
  description_it text,
  description_es text,
  description_de text,
  is_public boolean NOT NULL DEFAULT true
);
COMMENT ON COLUMN t_medias.id_nomenclature_media_type IS 'Correspondance nomenclature GEONATURE = TYPE_MEDIA (117)';

CREATE SEQUENCE t_medias_id_media_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_medias_id_media_seq OWNED BY t_medias.id_media;
ALTER TABLE ONLY t_medias ALTER COLUMN id_media SET DEFAULT nextval('t_medias_id_media_seq'::regclass);
SELECT pg_catalog.setval('t_medias_id_media_seq', 1, false);


CREATE TABLE t_validations
(
  id_validation integer NOT NULL,
  --unique_id_validation uuid NOT NULL DEFAULT public.uuid_generate_v4(),
  id_table_location integer NOT NULL,
  uuid_attached_row uuid NOT NULL,
  id_nomenclature_valid_status integer, --DEFAULT get_default_nomenclature_value(101),
  id_validator integer,
  validation_comment text,
  validation_date timestamp without time zone
);
--COMMENT ON COLUMN t_validations.unique_id_validation IS 'Un uuid est nécessaire pour tracer l''historique des validations dans "tracked_objects_actions"';
COMMENT ON COLUMN t_validations.id_table_location IS 'FK vers la table où se trouve l''enregistrement validé';
COMMENT ON COLUMN t_validations.uuid_attached_row IS 'Uuid de l''enregistrement validé';
COMMENT ON COLUMN t_validations.id_nomenclature_valid_status IS 'Correspondance nomenclature INPN = statut_valid (101)';
COMMENT ON COLUMN t_validations.id_validator IS 'Fk vers l''id_role (utilisateurs.t_roles) du validateur';
COMMENT ON COLUMN t_validations.validation_comment IS 'Commentaire concernant la validation';
COMMENT ON COLUMN t_validations.validation_date IS 'Date de la validation';

CREATE SEQUENCE t_validations_id_validation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_validations_id_validation_seq OWNED BY t_validations.id_validation;
ALTER TABLE ONLY t_validations ALTER COLUMN id_validation SET DEFAULT nextval('t_validations_id_validation_seq'::regclass);
SELECT pg_catalog.setval('t_validations_id_validation_seq', 1, false);


CREATE TABLE t_history_actions
(
  id_history_action integer NOT NULL,
  id_table_location integer NOT NULL,
  uuid_attached_row uuid NOT NULL,
  operation_type character (1), --I, U ou D
  operation_date timestamp without time zone,
  --id_digitiser integer,
  table_content json
);
COMMENT ON COLUMN t_history_actions.id_table_location IS 'FK vers la table où se trouve l''enregistrement tracé';
COMMENT ON COLUMN t_history_actions.uuid_attached_row IS 'Uuid de l''enregistrement tracé';
COMMENT ON COLUMN t_history_actions.operation_type IS 'Type d''événement tracé (Create, Update, Delete)';
COMMENT ON COLUMN t_history_actions.operation_date IS 'Date de l''événement';
--COMMENT ON COLUMN t_history_actions.id_digitiser IS 'Nom de l''utilisateur logué ayant généré l''événement tracé';
COMMENT ON COLUMN t_history_actions.table_content IS 'Contenu au format json de l''événement tracé. On enregistre le NEW pour CREATE et UPDATE. LE OLD (ou rien?) pour le DELETE.';

CREATE SEQUENCE t_history_actions_id_history_action_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_history_actions_id_history_action_seq OWNED BY t_history_actions.id_history_action;
ALTER TABLE ONLY t_history_actions ALTER COLUMN id_history_action SET DEFAULT nextval('t_history_actions_id_history_action_seq'::regclass);
SELECT pg_catalog.setval('t_history_actions_id_history_action_seq', 1, false);


CREATE TABLE t_modules(
  id_module integer NOT NULL,
  module_name character varying(255) NOT NULL,
  module_label character varying(255) NOT NULL,
  module_picto character varying(255),
  module_desc text,
  module_group character varying(50),
  module_url character(255) NOT NULL,
  module_target character(10),
  module_comment text,
  active_frontend boolean NOT NULL,
  active_backend boolean NOT NULL
);
COMMENT ON COLUMN t_modules.id_module IS 'PK mais aussi FK vers la table "utilisateurs.t_applications". ATTENTION de ne pas utiliser l''identifiant d''une application existante dans cette table et qui ne serait pas un module de GeoNature';
COMMENT ON COLUMN t_modules.module_url IS 'URL absolue vers le chemin de l''application. On peux ainsi référencer des modules externes avec target = "blank".';
COMMENT ON COLUMN t_modules.module_target IS 'Value = NULL ou "blank". On peux ainsi référencer des modules externes et les ouvrir dans un nouvel onglet.';
-- Ne surtout pas créer de séquence sur cette table pour associer librement id_module et id_application.

---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_parameters
    ADD CONSTRAINT pk_t_parameters PRIMARY KEY (id_parameter);

ALTER TABLE ONLY bib_tables_location
    ADD CONSTRAINT pk_bib_tables_location PRIMARY KEY (id_table_location);

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT pk_t_medias PRIMARY KEY (id_media);

ALTER TABLE ONLY t_validations
    ADD CONSTRAINT pk_t_validations PRIMARY KEY (id_validation);

ALTER TABLE ONLY t_history_actions
    ADD CONSTRAINT pk_t_history_actions PRIMARY KEY (id_history_action);

ALTER TABLE ONLY t_modules
    ADD CONSTRAINT pk_t_modules PRIMARY KEY (id_module);


----------------
--FOREIGN KEYS--
----------------

ALTER TABLE ONLY t_parameters
    ADD CONSTRAINT fk_t_parameters_bib_organismes FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT fk_t_medias_media_type FOREIGN KEY (id_nomenclature_media_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_bib_tables_location FOREIGN KEY (id_table_location) REFERENCES bib_tables_location (id_table_location) ON UPDATE CASCADE;

ALTER TABLE ONLY t_validations
    ADD CONSTRAINT fk_t_validations_t_roles FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_validations
  ADD CONSTRAINT fk_t_validations_bib_tables_location FOREIGN KEY (id_table_location) REFERENCES bib_tables_location (id_table_location) ON UPDATE CASCADE;

ALTER TABLE ONLY t_validations
    ADD CONSTRAINT fk_t_validations_valid_status FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_history_actions
  ADD CONSTRAINT fk_t_history_actions_bib_tables_location FOREIGN KEY (id_table_location) REFERENCES bib_tables_location (id_table_location) ON UPDATE CASCADE;

--ALTER TABLE ONLY t_history_actions
    --ADD CONSTRAINT fk_t_history_actions_t_roles FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_modules
  ADD CONSTRAINT fk_t_modules_utilisateurs_t_applications FOREIGN KEY (id_module) REFERENCES utilisateurs.t_applications (id_application) ON UPDATE CASCADE;


---------------
--CONSTRAINTS--
---------------

--TODO revoir ces 2 fonctions qui ne fonctionnent plus car 'entity_name' a été déplacé et réorganisé dans t_tables_location
--ALTER TABLE ONLY t_medias
  --ADD CONSTRAINT fk_t_medias_check_entity_exist CHECK (check_entity_field_exist(entity_name));

--ALTER TABLE ONLY t_medias
  --ADD CONSTRAINT fk_t_medias_check_entity_value CHECK (check_entity_value_exist(entity_name,entity_value));

ALTER TABLE t_medias
  ADD CONSTRAINT check_t_medias_media_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_media_type,'TYPE_MEDIA')) NOT VALID;


ALTER TABLE t_validations
  ADD CONSTRAINT check_t_validations_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_valid_status,'STATUT_VALID')) NOT VALID;


ALTER TABLE t_history_actions
  ADD CONSTRAINT check_t_history_actions_operation_type CHECK (operation_type IN('I','U','D'));


------------
--TRIGGERS--
------------

CREATE TRIGGER tri_log_changes_t_medias
  AFTER INSERT OR UPDATE OR DELETE
  ON t_medias
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();


---------
--DATAS--
---------
-- On ne défini pas d'id pour la PK, la séquence s'en charge
INSERT INTO bib_tables_location (table_desc, schema_name, table_name, pk_field, uuid_field_name) VALUES
('Regroupement de tous les médias de GeoNature', 'gn_commons', 't_medias', 'id_media', 'unique_id_media')
;

INSERT INTO t_parameters (id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value) VALUES
(0,'taxref_version','Version du référentiel taxonomique','Taxref V11.0',NULL)
,(0,'local_srid','Valeur du SRID local','2154',NULL)
,(0,'annee_ref_commune', 'Année du référentiel géographique des communes utilisé', '2017', NULL)
;


---------
--VIEWS--
---------

CREATE VIEW gn_commons.v_meta_actions_on_object AS
WITH insert_a AS (
	SELECT
		id_history_action, id_table_location, uuid_attached_row, operation_type, operation_date, (table_content -> 'id_digitiser')::text::int as id_creator
	FROM gn_commons.t_history_actions
	WHERE operation_type = 'I'
),
delete_a AS (
	SELECT
		id_history_action, id_table_location, uuid_attached_row, operation_type, operation_date
	FROM gn_commons.t_history_actions
	WHERE operation_type = 'D'
),
last_update_a AS (
	SELECT DISTINCT ON (uuid_attached_row)
		id_history_action, id_table_location, uuid_attached_row, operation_type, operation_date
	FROM gn_commons.t_history_actions
	WHERE operation_type = 'U'
	ORDER BY uuid_attached_row, operation_date DESC
)
SELECT
	i.id_table_location, i.uuid_attached_row, i.operation_date as meta_create_date, i.id_creator, u.operation_date as meta_update_date,
	d.operation_date as meta_delete_date
FROM insert_a i
LEFT OUTER JOIN last_update_a u ON i.uuid_attached_row = u.uuid_attached_row
LEFT OUTER JOIN delete_a d ON i.uuid_attached_row = d.uuid_attached_row;

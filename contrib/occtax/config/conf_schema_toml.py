'''
   Spécification du schéma toml des paramètres de configurations
'''

from marshmallow import Schema, fields

class MapListConfig(Schema):
    pass



class ReleveFormConfig(Schema):
    date_min = fields.Boolean(missing=True)
    date_max = fields.Boolean(missing=True)
    hour_min = fields.Boolean(missing=True)
    hour_max = fields.Boolean(missing=True)
    altitude_min = fields.Boolean(missing=True)
    altitude_max = fields.Boolean(missing=True)
    obs_technique = fields.Boolean(missing=False)
    group_type = fields.Boolean(missing=False)
    comment = fields.Boolean(missing=True)

class OccurrenceFormConfig(Schema):
      obs_method = fields.Boolean(missing=True)
      bio_condition = fields.Boolean(missing=True)
      bio_status = fields.Boolean(missing=True)
      naturalness = fields.Boolean(missing=True)
      exist_proof = fields.Boolean(missing=True)
      observation_status = fields.Boolean(missing=True)
      diffusion_level = fields.Boolean(missing=False)
      blurring = fields.Boolean(missing=False)
      determiner = fields.Boolean(missing=True)
      determination_method = fields.Boolean(missing=True)
      sample_number_proof = fields.Boolean(missing=True)
      digital_proof = fields.Boolean(missing=True)
      non_digital_proof = fields.Boolean(missing=True)
      source_status = fields.Boolean(missing=False)
      comment = fields.Boolean(missing=True)

class CountingFormConfig(Schema):
      life_stage = fields.Boolean(missing=True)
      sex = fields.Boolean(missing=True)
      obj_count = fields.Boolean(missing=True)
      type_count = fields.Boolean(missing=True)
      count_min = fields.Boolean(missing=True)
      count_max = fields.Boolean(missing=True)
      validation_status = fields.Boolean(missing=False)

class FormConfig(Schema):
    releve = fields.Nested(ReleveFormConfig, missing=dict())
    occurrence = fields.Nested(OccurrenceFormConfig, missing=dict())
    counting = fields.Nested(CountingFormConfig, missing=dict())

default_map_list_conf = [
    { "prop": "taxons", "name": "Taxon" },
    { "prop": "date_min", "name": "Date début" },
    { "prop": "observateurs", "name": "Observateurs" },
    { "prop": "dataset_name", "name": "Jeu de données" }
  ]

available_maplist_column = [
    { "prop": "altitude_max", "name": "altitude_max" },
    { "prop": "altitude_min", "name": "altitude_min" },
    { "prop": "comment", "name": "Commentaire" },
    { "prop": "date_max", "name": "Date fin" },
    { "prop": "date_min", "name": "Date début" },
    { "prop": "id_dataset", "name": "ID dataset" },
    { "prop": "id_digitiser", "name": "ID rédacteur" },
    { "prop": "id_releve_occtax", "name": "ID relevé" },
    { "prop": "observateurs", "name": "observateurs" },
    { "prop": "taxons", "name": "taxons" }
]

default_columns_export = [
  "permId",
  "statObs",
  "nomCite",
  "dateDebut",
  "dateFin",
  "heureDebut",
  "heureFin",
  "altMax",
  "altMin",
  "cdNom",
  "cdRef",
  "dateDet",
  "comment",
  "dSPublique",
  "statSource",
  "idOrigine",
  "refBiblio",
  "obsMeth",
  "ocEtatBio",
  "ocNat",
  "ocSex",
  "ocStade",
  "ocBiogeo",
  "ocStatBio",
  "preuveOui",
  "ocMethDet",
  "preuvNum",
  "preuvNoNum",
  "obsCtx",
  "permIdGrp",
  "methGrp",
  "typGrp",
  "denbrMax",
  "denbrMin",
  "objDenbr",
  "typDenbr",
  "obsId",
  "obsNomOrg",
  "detId",
  "detNomOrg",
  "orgGestDat",
  "WKT",
  "natObjGeo"
 ]

 

available_export_format = ['csv', 'geojson', 'shapefile']

list_messages = {"emptyMessage": "Aucune donnée à afficher", "totalMessage": "Relevé(s) au total"}

export_message = """
<p> <b> Attention: </b> </br>
Vous vous apprêtez à télécharger les données de la <b>recherche courante. </b> </p>
"""

class GnModuleSchemaConf(Schema):
    form_fields = fields.Nested(FormConfig, missing=dict())
    observers_txt = fields.Boolean(missing=False)
    export_view_name = fields.String(missing='export_occtax_dlb')
    export_geom_columns_name = fields.String(missing="geom_4326")
    export_id_column_name = fields.String(missing="permId")
    export_srid = fields.Integer(missing=4326)
    export_available_format = fields.List(fields.String(), missing=available_export_format)
    export_columns = fields.List(fields.String(), missing=default_columns_export)
    export_message = fields.String(missing=export_message)
    list_messages = fields.Dict(missing=list_messages)
    digital_proof_validator = fields.Boolean(missing=True)
    releve_map_zoom_level = fields.Integer(missing=6)
    id_taxon_list = fields.Integer(missing=100)
    id_observers_list = fields.Integer(missing=1)
    default_maplist_columns = fields.List(fields.Dict(), missing=default_map_list_conf)
    available_maplist_column = fields.List(fields.Dict(), missing=available_maplist_column)
    MAX_EXPORT_NUMBER = fields.Integer(missing=50000)
    



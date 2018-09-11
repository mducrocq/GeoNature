'''
    Description des options de configuration
'''

import os

from marshmallow import Schema, fields
from marshmallow.validate import OneOf, Regexp
from geonature.core.gn_synthese.synthese_config import (
    DEFAULT_SYNTHESE_COLUMNS,
    DEFAULT_TAXONOMIC_COLUMNS,
    DEFAULT_NOMENCLATURE_COLUMNS,
    DEFAULT_LIST_COLUMN
)


class CasUserSchemaConf(Schema):
    URL = fields.Url(
        missing='https://inpn.mnhn.fr/authentication/information'
    )
    ID = fields.String(
        missing='mon_id'
    )
    PASSWORD = fields.String(
        missing='mon_pass'
    )


class CasSchemaConf(Schema):
    CAS_AUTHENTIFICATION = fields.Boolean(missing='false')
    CAS_URL_LOGIN = fields.Url(
        missing='https://preprod-inpn.mnhn.fr/auth/login'
    )
    CAS_URL_LOGOUT = fields.Url(
        missing='https://preprod-inpn.mnhn.fr/auth/logout'
    )
    CAS_URL_VALIDATION = fields.String(
        missing='https://preprod-inpn.mnhn.fr/auth/serviceValidate'
    )
    CAS_USER_WS = fields.Nested(CasUserSchemaConf, missing=dict())
    USERS_CAN_SEE_ORGANISM_DATA = fields.Boolean(missing=False)


class RightsSchemaConf(Schema):
    NOTHING = fields.Integer(missing=0)
    MY_DATA = fields.Integer(missing=1)
    MY_ORGANISM_DATA = fields.Integer(missing=2)
    ALL_DATA = fields.Integer(missing=3)


class GnPySchemaConf(Schema):
    SQLALCHEMY_DATABASE_URI = fields.String(
        required=True,
        validate=Regexp(
            '^postgresql:\/\/.*:.*@[^:]+:\w+\/\w+$',
            0,
            """Database uri is invalid ex:
             postgresql://monuser:monpass@server:port/db_name"""
        )
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = fields.Boolean(missing=False)
    SESSION_TYPE = fields.String(missing='filesystem')
    SECRET_KEY = fields.String(required=True)
    COOKIE_EXPIRATION = fields.Integer(missing=7200)
    COOKIE_AUTORENEW = fields.Boolean(missing=True)
    TRAP_ALL_EXCEPTIONS = fields.Boolean(missing=False)

    UPLOAD_FOLDER = fields.String(missing='static/medias')
    BASE_DIR = fields.String(
        missing=os.path.dirname(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
    )


class GnFrontEndConf(Schema):
    PROD_MOD = fields.Boolean(missing=True)
    DISPLAY_FOOTER = fields.Boolean(missing=True)
    MULTILINGUAL = fields.Boolean(missing=False)


class SyntheseExportColumn(Schema):
    TAXONOMIC_COLUMNS = fields.List(fields.String(), missing=DEFAULT_TAXONOMIC_COLUMNS)
    SYNTHESE_COLUMNS = fields.List(fields.String(), missing=DEFAULT_SYNTHESE_COLUMNS)
    NOMENCLATURE_COLUMNS = fields.List(fields.String(), missing=DEFAULT_NOMENCLATURE_COLUMNS)


class Synthese(Schema):
    AREA_FILTERS = fields.List(fields.Dict, missing=[{"label": "Communes", "id_type": 101}])
    LIST_COLUMNS = fields.List(fields.Dict, missing=DEFAULT_LIST_COLUMN)
    EXPORT_COLUMNS = fields.Nested(
        SyntheseExportColumn,
        missing=dict()
    )
    EXPORT_FORMAT = fields.List(fields.String(), missing=['csv', 'geojson', 'shapefile'])
    # Liste des id attributs Taxhub à afficher sur la fiche détaile de la synthese
    # et sur les filtres taxonomiques avancés
    ID_ATTRIBUT_TAXHUB = fields.List(fields.Integer(), missing=[1, 2])


class MailErrorConf(Schema):
    MAIL_ON_ERROR = fields.Boolean(missing=False)
    MAIL_HOST = fields.String(missing="")
    HOST_PORT = fields.Integer(missing=465)
    MAIL_FROM = fields.String(missing="")
    MAIL_USERNAME = fields.String(missing="")
    MAIL_PASS = fields.String(missing="")
    MAIL_TO = fields.List(fields.String(), missing=list())


class GnGeneralSchemaConf(Schema):
    appName = fields.String(missing='GeoNature2')
    DEFAULT_LANGUAGE = fields.String(missing='fr')
    PASS_METHOD = fields.String(
        missing='hash',
        validate=OneOf(['hash', 'md5'])
    )
    DEBUG = fields.Boolean(missing=False)
    URL_APPLICATION = fields.Url(required=True)
    API_ENDPOINT = fields.Url(required=True)
    API_TAXHUB = fields.Url(required=True)
    LOCAL_SRID = fields.Integer(required=True, missing=2154)
    ID_APPLICATION_GEONATURE = fields.Integer(missing=14)
    XML_NAMESPACE = fields.String(missing="{http://inpn.mnhn.fr/mtd}")
    MTD_API_ENDPOINT = fields.Url(missing="https://preprod-inpn.mnhn.fr/mtd")
    CAS = fields.Nested(CasSchemaConf, missing=dict())
    RIGHTS = fields.Nested(RightsSchemaConf, missing=dict())
    FRONTEND = fields.Nested(GnFrontEndConf, missing=dict())
    MAILERROR = fields.Nested(MailErrorConf, missing=dict())
    SYNTHESE = fields.Nested(Synthese, missing=dict())
    ENABLE_NOMENCLATURE_TAXONOMIC_FILTERS = fields.Boolean(missing=True)


class ManifestSchemaConf(Schema):
    package_format_version = fields.String(required=True)
    module_name = fields.String(required=True)
    module_version = fields.String(required=True)
    min_geonature_version = fields.String(required=True)
    max_geonature_version = fields.String(required=True)
    exclude_geonature_versions = fields.List(fields.String)


class ManifestSchemaProdConf(Schema):
    # module_path = fields.String(required=True)
    module_name = fields.String(required=True)


class GnModuleProdConf(Schema):
    api_url = fields.String(required=True)
    id_application = fields.Integer(required=True)

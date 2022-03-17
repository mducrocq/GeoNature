"""add table gn_synthese.bib_reports_types

Revision ID: 095da7bc6667
Revises: 1dbc45309d6e
Create Date: 2022-03-17 10:57:34.730596

"""
from alembic import op
import sqlalchemy as sa
from utils_flask_sqla.migrations.utils import logger

# revision identifiers, used by Alembic.
revision = '095da7bc6667'
down_revision = '1dbc45309d6e'
branch_labels = None
depends_on = None


def upgrade():
    logger.info("Create bib_reports_types table...")
    op.execute("""
    CREATE TABLE gn_synthese.bib_reports_types (
        id_type SERIAL NOT NULL PRIMARY KEY,
        type VARCHAR NOT NULL
    )
    """)
    op.execute("""
    INSERT INTO gn_synthese.bib_reports_types (id_type, type)
    VALUES 
        (1, 'discussion'),
        (2, 'alert'),
        (3, 'pin')
    """)
    pass


def downgrade():
    logger.info("Drop table bib_reports_types...")
    op.execute("DROP TABLE IF EXISTS gn_synthese.bib_reports_types")
    pass

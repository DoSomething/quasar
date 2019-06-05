from setuptools import setup, find_packages

with open('requirements.txt') as f:
    requirements = f.read().splitlines()

setup(
    name="quasar",
    version="2019.6.5.1",
    packages=find_packages(),
    install_requires=requirements,
    entry_points={
        'console_scripts': [
            'bertly_create = quasar.bertly:create',
            'bertly_refresh = quasar.bertly:refresh',
            'campaign_info_recreate = quasar.campaign_info:create',
            'campaign_info_refresh = quasar.campaign_info:refresh',
            'campaign_activity_create = quasar.campaign_activity:create',
            'campaign_activity_refresh = quasar.campaign_activity:refresh',
            'cio_consume = quasar.cio_consumer:main',
            'cio_import = quasar.cio_import_scratch_records:cio_import',
            'cio_bounced_backfill = quasar.cio_bounced_backfill:main',
            'cio_sent_backfill = quasar.cio_sent_backfill:main',
            'etl_monitoring = quasar.etl_monitoring:run_monitoring',
            'gambit_messages_create = quasar.gambit:create_gambit_messages',
            'gambit_messages_refresh = quasar.gambit:refresh_gambit_messages',
            'gtm_retention_create = quasar.create_gtm_retention:main',
            'gtm_retention_refresh = quasar.refresh_gtm_retention:main',
            'mam_retention_create = quasar.create_mam_retention:main',
            'mam_retention_refresh = quasar.refresh_mam_retention:main',
            'mel_create = quasar.mel:create',
            'mel_refresh = quasar.mel:refresh',
            'northstar_backfill = quasar.northstar_to_user_table:backfill',
            'northstar_full_backfill = quasar.northstar_to_user_table_full_backfill:backfill',
            'phoenix_events_refresh = quasar.refresh_phoenix_events:main',
            'phoenix_events_create = quasar.create_phoenix_events:main',
            'post_actions_create = quasar.create_post_actions:main',
            'rogue_ghost_killer = quasar.ghost_killer:main',
            'users_create = quasar.create_derived_users:main',
            'users_refresh = quasar.refresh_derived_users:main',
            'user_activity_create = quasar.user_activity:create',
            'user_activity_refresh = quasar.user_activity:refresh'
        ],
    },
    author="",
    author_email="",
    description="",
    license="MIT",
    keywords=[],
    url="",
    classifiers=[
    ],
)

import sys
from .config import config
from . import database


def main():
   db, cur = database.connect({'conv': database.dec_to_float_converter()})

   # Populate Array with all mobile values from Phoenix DB
   cur.execute("DROP TABLE users_and_activities.mobile_campaign_id_lookup_lite")
   db.commit()
   cur.execute("""CREATE TABLE users_and_activities.mobile_campaign_id_lookup_lite
                  select
                  mc.`mobile_campaign_id`, mc.`run_nid`
                  from users_and_activities.`mobile_campaign_id_lookup` mc
                  where mc.`run_nid` is not null
                  group by mc.`mobile_campaign_id`""")
   db.commit()
   cur.execute("DROP TABLE users_and_activities.mobile_master_lookup_lite")
   db.commit()
   cur.execute("""CREATE TABLE users_and_activities.mobile_master_lookup_lite
                  SELECT
                  ms.phone_number as `ms_phone_number`,
                  ms.activated_at as `ms_activated_at`,
                  mc.run_nid as `mc_run_id`,
                  n.title as `n_title`,
                  mu.uid as `mu_uid`,
                  mu.created_at as `mu_created_at`
                  from users_and_activities.mobile_subscriptions ms
                  left outer join users_and_activities.mobile_campaign_id_lookup_lite mc
                  on ms.campaign_id = mc.mobile_campaign_id
                  left outer join dosomething.node n
                  on n.nid = mc.run_nid
                  left outer join users_and_activities.mobile_user_lookup mu
                  on mu.phone_number = ms.phone_number
                  where mc.run_nid is not null""")
   db.commit()
   cur.close()
   db.close()

if __name__ == "__main__":
   main()
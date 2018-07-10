from .database import Database


def main():
    db = Database()
    print('Refreshing Bertly Clicks materialized view.')
    db.query('REFRESH MATERIALIZED VIEW public.bertly_clicks')


if __name__ == "__main__":
    main()
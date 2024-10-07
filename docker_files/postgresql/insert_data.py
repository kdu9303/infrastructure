from dotenv import load_dotenv
import os
import pandas as pd
import numpy as np
import psycopg2
from psycopg2.extras import execute_values


load_dotenv(dotenv_path="../venv/.env")
user = os.getenv("POSTGRESQL_USER")
password = os.getenv("POSTGRESQL_PASSWORD")
if not password:
    raise ValueError("secret파일을 못 찾았습니다.")


# create table
def create_table(conn, table_name: str):
    with conn.cursor() as curs:
        create_table = f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                name                VARCHAR(1),
                pcode               VARCHAR(7),
                new_pcode       VARCHAR(7),
                CONSTRAINT {table_name}_pk PRIMARY KEY (name, pcode)
            );
        """
        curs.execute(create_table)
        conn.commit()
        print(f"테이블 <{table_name}> 생성 완료")


def insert_data(conn, file_path: str, table_name: str, *columns):
    with conn.cursor() as curs:
        df = transform(extract(file_path))
        values = [tuple(row) for row in df.to_numpy()]
        query = f"INSERT INTO {table_name} ({','.join(columns)}) VALUES %s"
        execute_values(curs, query, values, page_size=1000)
        print("데이터 인서트 완료")
        conn.commit()


def extract(file_path: str, header=None, index_col=False, parse_dates: list = None) -> pd.DataFrame:
    return pd.read_csv(
        file_path,
        header=header,
        index_col=index_col,
        parse_dates=parse_dates
        # date_parser="%Y-%m-%d",
    )


def transform(df: pd.DataFrame) -> pd.DataFrame:
    # df[[1, 3, 5]] = df[[1, 3, 5]].apply(pd.to_datetime, format='%Y-%m-%d', errors='coerce')
    df = df.replace({np.NaN: None})
    return df


def main():
    conn = psycopg2.connect(
        host="localhost", dbname="test1", user=user, password=password
    )
    table_name = "postalhistory"
    file_path = f"./data/csv_files/{table_name}.csv"
    column_names = ["name", "pcode", "new_pcode"]

    # create_table(conn, table_name)
    insert_data(conn, file_path, table_name, *column_names)
    conn.close()


if __name__ == "__main__":
    main()

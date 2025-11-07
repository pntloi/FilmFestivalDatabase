import mysql.connector as mc
import pandas as pd


CONF = {
    'user': 'root',
    'password': 'password',
    'host': 'localhost',
    'database': 'dbs'
}

def connect():
    try:
        conn = mc.connect(**CONF)
        if conn.is_connected():
            print("Connected to MySQL database")
            return conn
    except mc.Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None
    


def df_print(cur):
    rows = cur.fetchall()
    cols = [desc[0] for desc in cur.description]
    df = pd.DataFrame(rows, columns=cols)
    print(df)
    
def get_data(conn, query, params=None):
    with conn.cursor() as cur:
        cur.execute(query, params)
        df_print(cur)
        print("\n")
        
def retrieveFromPart3(conn):
    # Q1. List films which is >= 150 minutes long ORDER BY length descending
        print("Q1. List films which is >= 150 minutes long ORDER BY length descending")
        Q1 = """
        SELECT filmID, title, year, duration
        FROM Film
        WHERE duration >= 150
        ORDER BY duration DESC;
        """
        get_data(conn, Q1)
    # Q2. Get all ceremonies which organized more than 2 days
        print("Q2. Get all ceremonies which organized more than 2 days")
        Q2 = """
        SELECT festivalID, ceremonyYear, startDate, endDate, DATEDIFF(endDate, startDate) AS organizedDays
        FROM YearlyCeremony
        WHERE DATEDIFF(endDate, startDate) > 2
        ORDER BY organizedDays DESC;
        """
        get_data(conn, Q2)
    
    # Q8. Studio with the most expensive film
        print("Q8. Studio with the most expensive film")
        Q8 = """
        SELECT s.studioName, f.title, p.cost
        FROM Produce p
        LEFT JOIN Studio s ON p.studioID = s.studioID
        LEFT JOIN Film f ON p.filmID = f.filmID
        WHERE (p.studioID, p.cost) in (
            SELECT p2.studioID, max(p2.cost)
            FROM Produce p2
            group by p2.studioID
        )
        ORDER BY p.cost DESC;
        """
        get_data(conn, Q8)
        
    # Q9. The film that have the duration higher than the average duration of all films
        print("Q9. The film that have the duration higher than the average duration of all films")
        Q9 = """
        SELECT f.filmID, f.title, f.genre, f.duration
        FROM Film f
        WHERE f.duration > (SELECT avg(f2.duration) FROM Film f2)
        ORDER BY f.duration DESC;
        """
        get_data(conn, Q9)
        
def execute_query(conn, queries):
    cur = conn.cursor()
    for query in queries:
        print(f"Executing: {query}")
        cur.execute(query)
    conn.commit()
    
def insert_data(conn):
    # Insert data into Film/Studio/Produce tables
    insert_queries = [
        "INSERT INTO Film(filmID,title,year,genre,duration) VALUES('ttZZZ0001','Mini Test',2022,'Short',10)",
        "INSERT INTO Studio(studioID,studioName,country,foundedYear,type) VALUES('coZZZ0001','Tiny Studio','USA',2020,'Indie')",
        "INSERT INTO Produce(filmID,studioID,cost) VALUES('ttZZZ0001','coZZZ0001',5000)"
    ]
    execute_query(conn, insert_queries)
    
def update_data(conn):
    # Update the cost of the film which has filmID 'ttZZZ0001' and studioID 'coZZZ0001' to 600000
    update_queries = [
        "UPDATE Produce SET cost=600000 WHERE filmID='ttZZZ0001' AND studioID='coZZZ0001'"
    ]
    execute_query(conn, update_queries)
    
def delete_data(conn):
    # Delete the data which has filmID 'ttZZZ0001' from Produce, Film and Studio tables
    delete_queries = [
        "DELETE FROM Produce WHERE filmID='ttZZZ0001'",
        "DELETE FROM Film WHERE filmID='ttZZZ0001'",
        "DELETE FROM Studio WHERE studioID='coZZZ0001'"
    ]
    execute_query(conn, delete_queries)

def select_data(conn):
    select_query = """
        SELECT f.title, s.studioName, p.cost
        FROM Produce p JOIN Film f ON f.filmID=p.filmID
                        JOIN Studio s ON s.studioID=p.studioID
        WHERE p.filmID='ttZZZ0001'
        """
    print("Get inserted data:")
    get_data(conn, select_query)
    
def main():
    conn = connect()
    try:
        MENU = {
            "1": ("Retrieve data from part 3", retrieveFromPart3),
            "2": ("Insert data", insert_data),
            "3": ("Update data", update_data),
            "4": ("Delete data", delete_data),
            "5": ("Select data", select_data),
            "6": ("Exit", None)
        }
        
        while True:
            for k in sorted(MENU):
                print(f"{k}. {MENU[k][0]}")
            choice = input("Select option: ").strip()
            if choice == "6":
                break
            fn = MENU.get(choice, (None, None))[1]
            if fn:
                fn(conn)
            else:
                print("Invalid option.")
        
    except mc.Error as e:
        print(f"Error executing query: {e}")
    finally:
        conn.close()
        

if __name__ == "__main__":
    main()
    
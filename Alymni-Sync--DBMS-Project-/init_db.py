
import mysql.connector
import os
from dotenv import load_dotenv

load_dotenv()

# Config without database
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'charset': 'utf8mb4'
}

def init_database():
    print("Connecting to MySQL server...")
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Read schema file
        print("Reading schema file...")
        with open('alumni_sync_schema.sql', 'r', encoding='utf8') as f:
            lines = f.readlines()
            
        print("Parsing and executing SQL statements...")
        
        current_delimiter = ";"
        current_statement = ""
        
        for line in lines:
            stripped_line = line.strip()
            
            # Skip comments and empty lines inside normal sql but keep them in triggers/procedures?
            # Better to just process delimiters logic
            
            if stripped_line.startswith("--") or not stripped_line:
                # If we are building a statement (e.g. inside a stored proc), we might want to keep newlines
                # For now, minimal preservation
                continue

            if stripped_line.upper().startswith("DELIMITER"):
                current_delimiter = stripped_line.split()[1]
                continue
                
            current_statement += line
            
            if stripped_line.endswith(current_delimiter):
                # Remove delimiter from the end
                # Be careful if delimiter is length > 1 like //
                
                # Check if statement ends with delimiter
                # Note: current_statement has newlines
                
                # Naive check: does the stripped line end with delimiter?
                if stripped_line.endswith(current_delimiter):
                    # Remove the delimiter from the statement string for execution
                    # execute() usually expects clean SQL without "END //" usually just "END" ?
                    # Actually mysql connector execute() expects standard SQL. DELIMITER is a client command.
                    # Creating a trigger: CREATE TRIGGER ... END
                    # We should remove the delimiter chars from the very end of current_statement
                    
                    clean_stmt = current_statement.strip()
                    if clean_stmt.endswith(current_delimiter):
                        clean_stmt = clean_stmt[:-len(current_delimiter)]
                    
                    clean_stmt = clean_stmt.strip()
                    
                    if clean_stmt:
                        try:
                            # print(f"Executing: {clean_stmt[:50]}...")
                            cursor.execute(clean_stmt)
                        except mysql.connector.Error as err:
                             if err.errno == 1007: # Can't create db; database exists warning
                                pass
                             elif err.errno == 1050: # Table exists warning
                                pass
                             else:
                                print(f"Error executing statement: {err}")
                                # print(f"Statement: {clean_stmt}")

                    current_statement = ""
        
        conn.commit()
        print("Database initialized successfully.")
        
        # Automatically populate initial data
        print("\n" + "="*50)
        print("Populating initial data...")
        print("="*50)
        try:
            from populate_data import populate_data
            populate_data()
            print("\n" + "="*50)
            print("Setup complete! Database is ready to use.")
            print("="*50)
        except Exception as e:
            print(f"Warning: Data population failed: {e}")
            print("You can manually run populate_data.py later.")
        
    except mysql.connector.Error as err:
        print(f"Connection failed: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    init_database()

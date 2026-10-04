"""
Clean database reset script
This drops the entire database and recreates it from scratch
"""
import mysql.connector
import os
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'charset': 'utf8mb4'
}

print("WARNING: This will completely delete and recreate the alumni_sync database!")
print("Connecting to MySQL...")

try:
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    # Drop database completely
    print("Dropping database...")
    cursor.execute("DROP DATABASE IF EXISTS alumni_sync")
    
    # Create fresh database
    print("Creating fresh database...")
    cursor.execute("CREATE DATABASE alumni_sync CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
    
    conn.commit()
    print("✓ Database reset complete!")
    print("\nNext steps:")
    print("1. Run: python init_db.py")
    print("2. Run: python populate_data.py")
    
except mysql.connector.Error as err:
    print(f"Error: {err}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()

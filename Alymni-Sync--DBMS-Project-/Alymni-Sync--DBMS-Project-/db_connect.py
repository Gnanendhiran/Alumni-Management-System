"""
Database Connection Module for Alumni Sync
This module handles all database connections to MySQL.
"""

import mysql.connector
from mysql.connector import Error

import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Database Configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'alumni_sync'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci'
}


def get_db_connection():
    """
    Creates and returns a new database connection.
    Returns None if connection fails.
    """
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        if connection.is_connected():
            return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None


def close_connection(connection):
    """Safely closes a database connection."""
    if connection and connection.is_connected():
        connection.close()


def execute_query(query, params=None, fetch=True):
    """
    Executes a query and returns results.
    
    Args:
        query: SQL query string
        params: Tuple of parameters for the query
        fetch: If True, fetch and return results. If False, commit changes.
    
    Returns:
        List of results if fetch=True, else last inserted ID or affected rows.
    """
    connection = get_db_connection()
    if not connection:
        return None
    
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params or ())
        
        if fetch:
            result = cursor.fetchall()
            return result
        else:
            connection.commit()
            return cursor.lastrowid if cursor.lastrowid else cursor.rowcount
    except Error as e:
        print(f"Database error: {e}")
        return None
    finally:
        if cursor:
            cursor.close()
        close_connection(connection)

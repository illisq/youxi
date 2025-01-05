import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

load_dotenv()

# PostgreSQL connection using psycopg2
def get_db_connection():
    try:
        print(f"Connecting to database: {os.getenv('DB_NAME')} at {os.getenv('DB_HOST')} with user {os.getenv('DB_USER')}")
        
        return psycopg2.connect(
            host=os.getenv("DB_HOST", "localhost"),
            database=os.getenv("DB_NAME", "trpg_db"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD"),
            port=5432
        )
    except Exception as e:
        print(f"Error connecting to the database:")
        print(f"Host: {os.getenv('DB_HOST', 'localhost')}")
        print(f"Database: {os.getenv('DB_NAME', 'trpg_db')}")
        print(f"User: {os.getenv('DB_USER', 'postgres')}")
        print(f"Error details: {str(e)}")
        raise

# SQLAlchemy setup
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency for SQLAlchemy
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() 
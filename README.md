Database Systems - Assignment 2

Course: Database Systems (HK251)

Topic: Amazon E-commerce Database & Application



📖 Introduction

This project is a database design and application prototype simulating the core functionalities of Amazon.com. It handles complex relationships between Buyers, Sellers, and Products, enforcing strict business rules (like "Ship-after-funds") using MySQL Triggers and Stored Procedures.

The system includes:

Strict Data Integrity: Regex-based alphanumeric IDs (e.g., USR123456).

Automated Logic: Triggers for inventory updates and financial constraints.

Application Layer: A Python-based interface for managing transactions.



⚙️ Prerequisites

Before running the project, ensure you have the following installed:

MySQL Server (8.0 or higher)

Python (3.8 or higher)

MySQL Connector/Python (or required libraries for app.py)



🗄️ Database Setup

To set up the database, you must execute the SQL scripts in the following specific order to ensure dependencies (tables > data > procedures > triggers) are respected.

Open your MySQL Client (Workbench, Command Line, etc.).

Execute the files in order:

Step 1: Create the schema and tables

source amazon.sql;

Step 2: Activate Database Triggers

source trigger.sql;

Step 3: Load Stored Procedures and Functions

source pro.sql; -- (Refers to function.sql)

Step 4: Populate initial data

source insert.sql;


🚀 Running the Application

Once the database is ready, you can launch the Python application.

Install Dependencies
Ensure you have the required Python libraries installed:

pip install mysql-connector-python flask


Run the App
Navigate to the project directory and execute:

python app.py


Access the Interface
Open your web browser and go to:
http://127.0.0.1:5001


👥 Contributors

Nguyễn Trần Trọng Tuyên - 2353283

Ngô Quốc Hưng - 2352432

Trương Phước Minh Hoàng - 2352359

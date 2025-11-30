Database Systems - Assignment 2

Course: Database Systems (HK251)

Prerequisites

MySQL Server (8.0 or higher)

Python (3.8 or higher)

MySQL Connector/Python (or required libraries for app.py)

Database Setup

To set up the database, execute the SQL scripts (amazon, insert, pro, trigger).

Open your MySQL Client (Workbench, Command Line, etc.).

Execute the files in order:

Step 1: Create the schema and tables.

source amazon.sql;


Step 2: Populate initial data.

source insert.sql;


Step 3: Load Stored Procedures and Functions.

source pro.sql; -- (Refers to function.sql)


Step 4: Activate Database Triggers.

source trigger.sql;


Running the Application

Once the database is ready, launch the Python application.


Run the App:
Navigate to the project directory and execute:

python app.py


Access the Interface:
Open your web browser of choice and go to:

[http://127.0.0.1:5001](http://127.0.0.1:5001)


Contributors

Nguyễn Trần Trọng Tuyên 2353283
Ngô Quốc Hưng 2352432
Trương Phước Minh Hoàng 2352359

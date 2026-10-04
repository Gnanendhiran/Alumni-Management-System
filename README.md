# 🎓 Alumni Sync

A full-stack alumni engagement platform built with **Flask** and **MySQL** — alumni & student directories, a job board, event management, and a reference/mentorship request system, all behind role-based authentication.

![Python](https://img.shields.io/badge/Python-3.8+-blue)
![Flask](https://img.shields.io/badge/Flask-Backend-black)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

**Alumni Sync** replaces scattered spreadsheets and WhatsApp groups with one centralized, role-based platform connecting alumni and students. It's built on a **normalized MySQL schema** — every entity (users, profiles, jobs, events, references) lives in its own table linked by foreign keys, with the whole data layer isolated behind a single `db_connect.py` module.

## ✨ Key Features

- 🔐 Secure authentication — hashed passwords, session-based login, role-based access (Admin / Alumni / Guest)
- 👤 Searchable alumni & student directory
- 💼 Job board — postings, applications, and status tracking
- 📅 Event creation & registration
- 📝 Reference & mentorship request workflow between students and alumni
- 📢 Institution-wide announcements

📄 Full ER diagram, system architecture and design notes: [`docs/Alumni_Sync_Project_Report.pdf`](docs/Alumni_Sync_Project_Report.pdf)

## 🛠️ Tech Stack

**Backend:** Python, Flask, Jinja2 · **Database:** MySQL (`mysql-connector-python`) · **Frontend:** HTML5, CSS3, JavaScript · **Auth:** Werkzeug password hashing · **Config:** python-dotenv

## ▶️ Run Locally

**Windows — one command:**
```bash
git clone https://github.com/Gnanendhiran/AlumniSync.git
cd AlumniSync
setup_and_run.bat
```
This creates a virtual environment, installs dependencies, scaffolds a `.env` file, optionally initializes the database, and starts the app.

**Manual / cross-platform:**
```bash
git clone https://github.com/Gnanendhiran/AlumniSync.git
cd AlumniSync

python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate

pip install -r requirements.txt
```

Create a `.env` file:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=alumni_sync
SECRET_KEY=your-secret-key
```

```bash
python init_db.py       # builds the schema and seeds sample data
python app.py            # starts the server
```

App runs at **http://127.0.0.1:5000**

**Useful scripts:** `check_db.py` sanity-checks your data · `clean_db.py` drops and recreates the database from scratch.

## 📁 Project Structure

```
AlumniSync/
├── app.py                     # Flask app & routes
├── db_connect.py              # Central MySQL connection + query helper
├── init_db.py                 # Schema setup (runs the .sql file + seeds data)
├── populate_data.py           # Sample data seeding
├── check_db.py                # Database sanity checks
├── clean_db.py                # Full database reset
├── alumni_sync_schema.sql     # Complete database schema
├── requirements.txt
├── setup_and_run.bat          # One-click Windows setup & run
├── static/                    # CSS, JS, uploads
├── templates/                 # Jinja2 HTML templates
└── docs/
    └── Alumni_Sync_Project_Report.pdf   # Project report + ER diagram
```

## 👨‍💻 Author

**Gnanendhiran V** — [GitHub](https://github.com/Gnanendhiran)

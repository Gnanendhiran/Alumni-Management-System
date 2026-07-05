@echo off
setlocal
echo ==========================================
echo Alumni Sync - Local Setup & Run Script
echo ==========================================

REM Define VENV path
set "VENV_DIR=.venv"

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in your PATH.
    echo Please install Python 3.8+ and try again.
    pause
    exit /b
)

REM 1. Check/Create Virtual Environment
if exist "%VENV_DIR%\" (
    echo [1/3] Virtual environment found.Using it...
) else (
    echo [1/3] Creating virtual environment...
    python -m venv %VENV_DIR%
    if %errorlevel% neq 0 (
        echo Error creating virtual environment.
        pause
        exit /b
    )
)

REM 2. Install Dependencies
echo [2/3] Installing dependencies...
"%VENV_DIR%\Scripts\pip" install -r requirements.txt
if %errorlevel% neq 0 (
    echo Error installing dependencies.
    pause
    exit /b
)

REM 3. Check Configuration
echo.
echo [3/3] Checking configuration...
if not exist .env (
    echo Warning: .env file not found! Creating one from defaults...
    (
        echo DB_HOST=localhost
        echo DB_USER=root
        echo DB_PASSWORD=
        echo DB_NAME=alumni_sync
        echo SECRET_KEY=dev-secret-key
    ) > .env
    echo Created .env file. Please edit it with your database credentials.
    pause
)

REM 4. Database Initialization Check
echo.
echo Checking database setup...
echo If this is your first time running the app, you should initialize the database.
echo.
choice /C YN /M "Do you want to initialize/reset the database"
if errorlevel 2 goto skip_db_init
if errorlevel 1 goto run_db_init

:run_db_init
echo.
echo Initializing database...
"%VENV_DIR%\Scripts\python" init_db.py
if %errorlevel% neq 0 (
    echo.
    echo Database initialization failed!
    echo Please check your database credentials in .env file.
    pause
    exit /b
)
goto start_app

:skip_db_init
echo Skipping database initialization...

:start_app
REM 5. Run Application
echo.
echo Starting Application...
echo Access the app at http://127.0.0.1:5000
echo Press Ctrl+C to stop the server.
echo.

"%VENV_DIR%\Scripts\python" app.py

if %errorlevel% neq 0 (
    echo.
    echo Application crashed or stopped.
    echo If you see an error above, please report it.
)
pause

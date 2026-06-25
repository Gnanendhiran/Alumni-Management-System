
from db_connect import execute_query
from werkzeug.security import generate_password_hash
from datetime import datetime, timedelta

def populate_data():
    print("Populating Campuses...")
    # Campus: United International University
    execute_query("""
        INSERT INTO campuses (name, code, address, is_active) 
        VALUES (%s, %s, %s, 1)
        ON DUPLICATE KEY UPDATE name=VALUES(name)
    """, ("United International University", "UIU", "Dhaka, Bangladesh"), fetch=False)
    
    campus_id = execute_query("SELECT id FROM campuses WHERE code = 'UIU'")[0]['id']
    
    print("Populating Degrees...")
    # Degrees: CSE, EEE, BSDS, BBA
    degrees_list = [
        ("Bachelor of Science in Computer Science and Engineering", "CSE", "bachelor"),
        ("Bachelor of Science in Electrical and Electronic Engineering", "EEE", "bachelor"),
        ("Bachelor of Science in Data Science", "BSDS", "bachelor"),
        ("Bachelor of Business Administration", "BBA", "bachelor")
    ]
    
    for name, abbr, level in degrees_list:
        execute_query("""
            INSERT INTO degrees (name, abbreviation, level, is_active) 
            VALUES (%s, %s, %s, 1)
            ON DUPLICATE KEY UPDATE name=VALUES(name)
        """, (name, abbr, level), fetch=False)
        
    # Get a degree ID
    degree_id = execute_query("SELECT id FROM degrees WHERE abbreviation = 'CSE'")[0]['id']

    print("Populating Sample Users...")
    # Admin user creation removed - not required for this project
    # If you need an admin in the future, you can manually create one in the database
    
    # 2. Alumni
    alumni_pass = generate_password_hash("user123")
    # Check if user exists
    existing_alumni = execute_query("SELECT id FROM users WHERE email = 'alumni@example.com'")
    if existing_alumni:
        alumni_id = existing_alumni[0]['id']
    else:
        alumni_id = execute_query("""
            INSERT INTO users (email, password_hash, role_id, status) VALUES (%s, %s, 2, 'active')
        """, ("alumni@example.com", alumni_pass), fetch=False)
    
    if alumni_id:
        # Create Profile
        execute_query("""
            INSERT INTO alumni_profiles (user_id, first_name, last_name, student_id, phone, degree_id, campus_id, graduation_year, current_company, current_job_title)
            VALUES (%s, 'John', 'Doe', '011233001', '01700000000', %s, %s, 2023, 'Google', 'Software Engineer')
            ON DUPLICATE KEY UPDATE first_name=VALUES(first_name)
        """, (alumni_id, degree_id, campus_id), fetch=False)

    # 3. Student
    student_pass = generate_password_hash("user123")
    existing_student = execute_query("SELECT id FROM users WHERE email = 'student@example.com'")
    if existing_student:
        student_id = existing_student[0]['id']
    else:
        student_id = execute_query("""
            INSERT INTO users (email, password_hash, role_id, status) VALUES (%s, %s, 3, 'active')
        """, ("student@example.com", student_pass), fetch=False)
    
    if student_id:
        execute_query("""
            INSERT INTO student_profiles (user_id, first_name, last_name, student_id, phone, degree_id, campus_id, expected_graduation_year, current_semester)
            VALUES (%s, 'Jane', 'Smith', '011241001', '01800000000', %s, %s, 2026, 'Spring 2024')
            ON DUPLICATE KEY UPDATE first_name=VALUES(first_name)
        """, (student_id, degree_id, campus_id), fetch=False)

    print("Populating Sample Content...")
    # Sample Job
    if alumni_id:
        execute_query("""
            INSERT INTO job_postings (posted_by, title, company_name, job_type, location, description, requirements, salary_min,salary_max, target_audience, status)
            VALUES (%s, 'Junior Software Engineer', 'TechnoNext', 'full_time', 'Dhaka', 'We are looking for a junior dev.', 'Python, SQL', 30000, 50000, 'all', 'open')
ON DUPLICATE KEY UPDATE title=VALUES(title)
        """, (alumni_id,), fetch=False)
    
    # Sample Event (slug is required)
    execute_query("""
        INSERT INTO events (title, slug, description, start_date, start_time, venue, visibility, status, created_by)
        VALUES ('Alumni Reunion 2026', 'alumni-reunion-2026', 'Annual grand reunion.', CURDATE() + INTERVAL 30 DAY, '10:00:00', 'UIU Campus', 'all', 'published', 1)
        ON DUPLICATE KEY UPDATE title=VALUES(title)
    """, fetch=False)

    # Sample Announcement
    if alumni_id:
        execute_query("""
            INSERT INTO announcements (title, content, target_audience, status, created_by)
            VALUES ('Welcome to the new portal!', 'We are excited to launch the new Alumni Sync portal.', 'all', 'published', %s)
            ON DUPLICATE KEY UPDATE title=VALUES(title)
        """, (alumni_id,), fetch=False)

    print("Data population complete.")

if __name__ == "__main__":
    populate_data()

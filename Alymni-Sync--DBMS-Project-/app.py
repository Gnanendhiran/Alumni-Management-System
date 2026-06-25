"""
Alumni Sync - Main Flask Application
This is the main entry point for the Alumni Management System.
"""

from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from functools import wraps
import os
from datetime import datetime, timedelta
from db_connect import execute_query, get_db_connection, close_connection

# =====================================================
# APP CONFIGURATION
# =====================================================

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

# =====================================================
# CUSTOM JINJA2 FILTERS
# =====================================================

@app.template_filter('format_time')
def format_time_filter(value, format='%I:%M %p'):
    """Format time values - handles both datetime and timedelta objects."""
    if value is None:
        return ''
    
    # If it's a timedelta (TIME column from MySQL), convert to datetime
    if isinstance(value, timedelta):
        # Convert timedelta to hours, minutes
        total_seconds = int(value.total_seconds())
        hours = (total_seconds // 3600) % 24
        minutes = (total_seconds % 3600) // 60
        # Create a datetime object for today with this time
        value = datetime.now().replace(hour=hours, minute=minutes, second=0, microsecond=0)
    
    # Now format as datetime
    if isinstance(value, datetime):
        return value.strftime(format)
    
    return str(value)

@app.template_filter('format_date')
def format_date_filter(value, format='%b %d, %Y'):
    """Format date values - handles datetime and date objects."""
    if value is None:
        return ''
    
    if isinstance(value, (datetime, type(datetime.now().date()))):
        return value.strftime(format)
    
    return str(value)

# File Upload Configuration
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'static', 'uploads')
ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max

# Ensure upload directories exist
os.makedirs(os.path.join(UPLOAD_FOLDER, 'cvs'), exist_ok=True)
os.makedirs(os.path.join(UPLOAD_FOLDER, 'photos'), exist_ok=True)


def allowed_file(filename):
    """Check if file extension is allowed."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# =====================================================
# AUTHENTICATION DECORATORS
# =====================================================

def login_required(f):
    """Decorator to require login for routes."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function


def alumni_required(f):
    """Decorator to require alumni role."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'alumni':
            flash('This page is only accessible to alumni.', 'warning')
            return redirect(url_for('home'))
        return f(*args, **kwargs)
    return decorated_function


# =====================================================
# PUBLIC ROUTES
# =====================================================

@app.route('/')
def home():
    """Homepage with dashboard overview."""
    # Get upcoming events (show all published events on home page)
    events = execute_query("""
    SELECT * FROM events 
    WHERE start_date >= CURDATE() AND status = 'published' AND is_deleted = 0
    ORDER BY start_date ASC LIMIT 5
    """)
    
    # Get recent job postings
    jobs = execute_query("""
        SELECT * FROM job_postings 
        WHERE status = 'open' AND is_deleted = 0 
        ORDER BY created_at DESC LIMIT 5
    """)
    
    # Get stats
    stats = execute_query("""
        SELECT 
            (SELECT COUNT(*) FROM alumni_profiles WHERE is_deleted = 0) as alumni_count,
            (SELECT COUNT(*) FROM student_profiles WHERE is_deleted = 0) as student_count,
            (SELECT COUNT(*) FROM job_postings WHERE status = 'open' AND is_deleted = 0) as jobs_count,
            (SELECT COUNT(*) FROM events WHERE status = 'published' AND is_deleted = 0) as events_count
    """)
    
    return render_template('home.html', events=events, jobs=jobs, stats=stats[0] if stats else {})


@app.route('/about')
def about():
    """About page with institution information."""
    about_info = execute_query("SELECT * FROM about_page WHERE is_current = 1 LIMIT 1")
    institution = execute_query("SELECT * FROM institution_info WHERE is_active = 1 LIMIT 1")
    return render_template('about.html', 
                           about=about_info[0] if about_info else {}, 
                           institution=institution[0] if institution else {})


# =====================================================
# AUTHENTICATION ROUTES
# =====================================================

@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login page."""
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        user = execute_query("""
            SELECT u.*, r.name as role_name 
            FROM users u 
            JOIN roles r ON u.role_id = r.id 
            WHERE u.email = %s AND u.is_deleted = 0
        """, (email,))
        
        if user and check_password_hash(user[0]['password_hash'], password):
            if user[0]['status'] == 'active':
                session['user_id'] = user[0]['id']
                session['email'] = user[0]['email']
                session['role'] = user[0]['role_name']
                flash('Login successful!', 'success')
                return redirect(url_for('dashboard'))
            else:
                flash('Your account is pending approval.', 'warning')
        else:
            flash('Invalid email or password.', 'danger')
    
    return render_template('login.html')


# Dummy API Validation
def validate_registration_simulated(data):
    """
    Simulates an external API call to validate user registration.
    In a real scenario, this would check against university records.
    For this project, it returns True (approved) for all requests.
    """
    # Simulate API latency or check
    return True

@app.route('/register', methods=['GET', 'POST'])
def register():
    """User registration page."""
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        user_type = request.form.get('user_type')  # 'student' or 'alumni'
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        
        # Common optional fields
        phone = request.form.get('phone')
        gender = request.form.get('gender')
        degree_id = request.form.get('degree_id')
        campus_id = request.form.get('campus_id')
        
        # Type specific fields
        student_id = request.form.get('student_id') # For both for verification match
        graduation_year = request.form.get('graduation_year') if user_type == 'alumni' else None
        expected_graduation_year = request.form.get('expected_graduation_year') if user_type == 'student' else None
        current_semester = request.form.get('current_semester') if user_type == 'student' else None
        
        # Validation
        if password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return redirect(url_for('register'))
        
        # Check if email exists
        existing = execute_query("SELECT id FROM users WHERE email = %s", (email,))
        if existing:
            flash('Email already registered.', 'danger')
            return redirect(url_for('register'))
            
        # Call Dummy API for validation
        if not validate_registration_simulated(request.form):
            flash('Registration validation failed. Please contact support.', 'danger')
            return redirect(url_for('register'))
        
        # Create user - DIRECTLY ACTIVE (No Admin Approval needed per new requirement)
        password_hash = generate_password_hash(password)
        role_id = 2 if user_type == 'alumni' else 3  # 2=alumni, 3=guest (student)
        
        user_id = execute_query("""
            INSERT INTO users (email, password_hash, role_id, status) 
            VALUES (%s, %s, %s, 'active')
        """, (email, password_hash, role_id), fetch=False)
        
        if user_id:
            # Create profile based on user type with ALL fields
            if user_type == 'alumni':
                execute_query("""
                    INSERT INTO alumni_profiles 
                    (user_id, first_name, last_name, student_id, gender, phone, degree_id, campus_id, graduation_year) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (user_id, first_name, last_name, student_id, gender, phone, degree_id, campus_id, graduation_year), fetch=False)
            else:
                execute_query("""
                    INSERT INTO student_profiles 
                    (user_id, first_name, last_name, student_id, gender, phone, degree_id, campus_id, expected_graduation_year, current_semester) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (user_id, first_name, last_name, student_id, gender, phone, degree_id, campus_id, expected_graduation_year, current_semester), fetch=False)
            
            flash('Registration successful! Welcome to Alumni Sync.', 'success')
            return redirect(url_for('login'))
        else:
            flash('Registration failed. Please try again.', 'danger')
    
    # Get Metadata for Dropdowns
    degrees = execute_query("SELECT * FROM degrees WHERE is_active = 1 ORDER BY name")
    campuses = execute_query("SELECT * FROM campuses WHERE is_active = 1 ORDER BY name")
    
    return render_template('register.html', degrees=degrees, campuses=campuses)


@app.route('/logout')
def logout():
    """Logout user."""
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('home'))


# =====================================================
# DASHBOARD ROUTES
# =====================================================

@app.route('/dashboard')
@login_required
def dashboard():
    """User dashboard based on role."""
    user_id = session.get('user_id')
    role = session.get('role')
    
    if role == 'alumni':
        profile = execute_query("""
            SELECT * FROM alumni_profiles WHERE user_id = %s AND is_deleted = 0
        """, (user_id,))
        my_jobs = execute_query("""
            SELECT * FROM job_postings WHERE posted_by = %s AND is_deleted = 0
            ORDER BY created_at DESC
        """, (user_id,))
        my_events = execute_query("""
            SELECT * FROM events WHERE created_by = %s AND is_deleted = 0
            ORDER BY start_date DESC
        """, (user_id,))
        my_announcements = execute_query("""
            SELECT * FROM announcements WHERE created_by = %s AND is_deleted = 0
            ORDER BY created_at DESC
        """, (user_id,))
        return render_template('dashboard_alumni.html', 
                               profile=profile[0] if profile else {}, 
                               my_jobs=my_jobs,
                               my_events=my_events,
                               my_announcements=my_announcements)
    else:
        profile = execute_query("""
            SELECT * FROM student_profiles WHERE user_id = %s AND is_deleted = 0
        """, (user_id,))
        my_applications = execute_query("""
            SELECT ja.*, jp.title, jp.company_name 
            FROM job_applications ja 
            JOIN job_postings jp ON ja.job_posting_id = jp.id 
            WHERE ja.applicant_id = %s AND ja.is_deleted = 0
            ORDER BY ja.created_at DESC
        """, (user_id,))
        my_events = execute_query("""
            SELECT e.*, er.status as registration_status, er.created_at as registered_at
            FROM event_registrations er
            JOIN events e ON er.event_id = e.id
            WHERE er.user_id = %s AND e.is_deleted = 0
            ORDER BY e.start_date ASC
        """, (user_id,))
        return render_template('dashboard_student.html', 
                               profile=profile[0] if profile else {}, 
                               applications=my_applications,
                               my_events=my_events)


# =====================================================
# JOB BOARD ROUTES
# =====================================================

@app.route('/jobs')
@login_required
def jobs():
    """Job board listing all open positions."""
    search = request.args.get('search', '')
    job_type = request.args.get('type', '')
    
    query = """
    SELECT jp.*, u.email as poster_email,
            (SELECT CONCAT(first_name, ' ', last_name) FROM alumni_profiles WHERE user_id = jp.posted_by) as poster_name,
            (SELECT COUNT(*) FROM job_applications WHERE job_posting_id = jp.id AND is_deleted = 0) as applications_count
    FROM job_postings jp
    JOIN users u ON jp.posted_by = u.id
    WHERE jp.status = 'open' AND jp.is_deleted = 0
    """
    
    params = []
    
    # NOTE: Removed target_audience filtering - ALL users can VIEW all jobs
    # Application restrictions are enforced in the apply_job route
    
    if search:
        query += " AND (jp.title LIKE %s OR jp.company_name LIKE %s OR jp.description LIKE %s)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param, search_param])
    
    if job_type:
        query += " AND jp.job_type = %s"
        params.append(job_type)
    
    query += " ORDER BY jp.created_at DESC"
    
    job_listings = execute_query(query, tuple(params) if params else None)
    return render_template('jobs.html', jobs=job_listings, search=search, job_type=job_type)


@app.route('/jobs/<int:job_id>')
@login_required
def job_detail(job_id):
    """View details of a specific job."""
    job = execute_query("""
    SELECT jp.*, u.email as poster_email,
            (SELECT CONCAT(first_name, ' ', last_name) FROM alumni_profiles WHERE user_id = jp.posted_by) as poster_name,
            (SELECT COUNT(*) FROM job_applications WHERE job_posting_id = jp.id AND is_deleted = 0) as applications_count
    FROM job_postings jp
    JOIN users u ON jp.posted_by = u.id
    WHERE jp.id = %s AND jp.is_deleted = 0
    """, (job_id,))
    
    if not job:
        flash('Job not found.', 'warning')
        return redirect(url_for('jobs'))
    
    skills = execute_query("""
        SELECT skill_name FROM job_posting_skills WHERE job_posting_id = %s
    """, (job_id,))
    
    # Check if user is the poster to show applicants
    is_poster = False
    applicants = []
    if 'user_id' in session and session['user_id'] == job[0]['posted_by']:
        is_poster = True
        applicants = execute_query("""
            SELECT ja.*, u.email, 
                   COALESCE(ap.first_name, sp.first_name) as first_name,
                   COALESCE(ap.last_name, sp.last_name) as last_name,
                   COALESCE(ap.profile_photo, sp.profile_photo) as profile_photo,
                   COALESCE(ap.id, sp.id) as profile_id,
                   CASE WHEN ap.id IS NOT NULL THEN 'alumni' ELSE 'student' END as profile_type
            FROM job_applications ja
            JOIN users u ON ja.applicant_id = u.id
            LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
            LEFT JOIN student_profiles sp ON u.id = sp.user_id
            WHERE ja.job_posting_id = %s AND ja.is_deleted = 0
            ORDER BY ja.applied_at DESC
        """, (job_id,))
    
    # Increment view count for all viewers (not just poster)
    execute_query("UPDATE job_postings SET views_count = views_count + 1 WHERE id = %s", (job_id,), fetch=False)

    return render_template('job_detail.html', job=job[0], skills=skills, is_poster=is_poster, applicants=applicants)


@app.route('/jobs/create', methods=['GET', 'POST'])
@login_required
@alumni_required
def create_job():
    """Create a new job posting."""
    if request.method == 'POST':
        title = request.form.get('title')
        company_name = request.form.get('company_name')
        job_type = request.form.get('job_type')
        location = request.form.get('location')
        description = request.form.get('description')
        requirements = request.form.get('requirements')
        salary_min = request.form.get('salary_min') or None
        salary_max = request.form.get('salary_max') or None
        deadline = request.form.get('deadline') or None
        vacancies = request.form.get('vacancies') or 1
        skills = request.form.get('skills', '').split(',')
        
        target_audience = request.form.get('target_audience', 'all')
        
        job_id = execute_query("""
            INSERT INTO job_postings 
            (posted_by, title, company_name, job_type, location, description, requirements, 
             salary_min, salary_max, application_deadline, vacancies, target_audience, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'open')
        """, (session['user_id'], title, company_name, job_type, location, 
              description, requirements, salary_min, salary_max, deadline, vacancies, target_audience), fetch=False)
        
        # Add skills
        for skill in skills:
            skill = skill.strip()
            if skill:
                execute_query("""
                    INSERT INTO job_posting_skills (job_posting_id, skill_name) VALUES (%s, %s)
                """, (job_id, skill), fetch=False)
        
        flash('Job posted successfully!', 'success')
        return redirect(url_for('jobs'))
    
    return render_template('create_job.html')


@app.route('/jobs/<int:job_id>/apply', methods=['GET', 'POST'])
@login_required
def apply_job(job_id):
    """Apply for a job."""
    job = execute_query("SELECT * FROM job_postings WHERE id = %s AND status = 'open'", (job_id,))
    if not job:
        flash('Job not found or no longer accepting applications.', 'warning')
        return redirect(url_for('jobs'))
    
    # Check if user is the job poster
    if job[0]['posted_by'] == session.get('user_id'):
        flash('You cannot apply for your own job posting.', 'warning')
        return redirect(url_for('job_detail', job_id=job_id))
    
    # Check if user's role is eligible for this job
    user_role = session.get('role')
    target_audience = job[0]['target_audience']
    
    can_apply = False
    if target_audience == 'all':
        can_apply = True
    elif target_audience == 'alumni_only' and user_role == 'alumni':
        can_apply = True
    elif target_audience == 'students_only' and user_role in ['guest', 'student']:
        can_apply = True
    
    if not can_apply:
        if target_audience == 'alumni_only':
            flash('This job is only open to alumni. Students cannot apply.', 'warning')
        elif target_audience == 'students_only':
            flash('This job is only open to students. Alumni cannot apply.', 'warning')
        return redirect(url_for('job_detail', job_id=job_id))
    
    # Check if already applied
    existing = execute_query("""
        SELECT id FROM job_applications WHERE job_posting_id = %s AND applicant_id = %s
    """, (job_id, session['user_id']))
    
    if existing:
        flash('You have already applied for this job.', 'info')
        return redirect(url_for('job_detail', job_id=job_id))
    
    if request.method == 'POST':
        cover_letter = request.form.get('cover_letter')
        expected_salary = request.form.get('expected_salary') or None
        
        # Handle CV upload
        cv_path = None
        if 'cv_file' in request.files:
            file = request.files['cv_file']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(f"{session['user_id']}_{job_id}_{file.filename}")
                cv_path = os.path.join('uploads', 'cvs', filename)
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], 'cvs', filename))
        
        execute_query("""
            INSERT INTO job_applications 
            (job_posting_id, applicant_id, cv_upload, cover_letter, expected_salary)
            VALUES (%s, %s, %s, %s, %s)
        """, (job_id, session['user_id'], cv_path, cover_letter, expected_salary), fetch=False)
        
        flash('Application submitted successfully!', 'success')
        return redirect(url_for('dashboard'))
    
    return render_template('apply_job.html', job=job[0])


# =====================================================
# EVENTS ROUTES
# =====================================================

@app.route('/events')
@login_required
def events():
    """List all upcoming events."""
    query = """
        SELECT e.*, 
               (SELECT COUNT(*) FROM event_registrations WHERE event_id = e.id AND status = 'registered') as registrations
        FROM events e
        WHERE e.start_date >= CURDATE() AND e.status = 'published' AND e.is_deleted = 0
    """
    
    # Show ALL events to everyone (registration restrictions still apply)
    query += " ORDER BY e.start_date ASC"
    
    event_list = execute_query(query)
    return render_template('events.html', events=event_list)


@app.route('/events/<int:event_id>')
@login_required
def event_detail(event_id):
    """View event details."""
    event = execute_query("""
        SELECT e.*, 
               (SELECT COUNT(*) FROM event_registrations WHERE event_id = e.id AND status = 'registered') as registrations
        FROM events e
        WHERE e.id = %s AND e.is_deleted = 0
    """, (event_id,))
    
    if not event:
        flash('Event not found.', 'warning')
        return redirect(url_for('events'))
    
    # Check if user is registered
    is_registered = False
    if 'user_id' in session:
        reg = execute_query("""
            SELECT id FROM event_registrations 
            WHERE event_id = %s AND user_id = %s AND status = 'registered'
        """, (event_id, session['user_id']))
        is_registered = bool(reg)
    
    # Check if user is event creator to show registrants
    is_creator = False
    registrants = []
    if 'user_id' in session and session['user_id'] == event[0]['created_by']:
        is_creator = True
        registrants = execute_query("""
            SELECT er.*, u.email,
                   COALESCE(ap.first_name, sp.first_name) as first_name,
                   COALESCE(ap.last_name, sp.last_name) as last_name,
                   COALESCE(ap.id, sp.id) as profile_id,
                   CASE WHEN ap.id IS NOT NULL THEN 'alumni' ELSE 'student' END as profile_type
            FROM event_registrations er
            JOIN users u ON er.user_id = u.id
            LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
            LEFT JOIN student_profiles sp ON u.id = sp.user_id
            WHERE er.event_id = %s AND er.status = 'registered'
            ORDER BY er.created_at DESC
        """, (event_id,))
    
    return render_template('event_detail.html', event=event[0], is_registered=is_registered,
                           is_creator=is_creator, registrants=registrants)


@app.route('/events/<int:event_id>/register', methods=['POST'])
@login_required
def register_event(event_id):
    """Register for an event."""
    # Get event details to check visibility
    event = execute_query("""
        SELECT * FROM events WHERE id = %s AND status = 'published' AND is_deleted = 0
    """, (event_id,))
    
    if not event:
        flash('Event not found.', 'warning')
        return redirect(url_for('events'))
    
    # Check if user's role is eligible for this event
    user_role = session.get('role')
    visibility = event[0]['visibility']
    
    can_register = False
    if visibility in ['all', 'public']:
        can_register = True
    elif visibility == 'alumni_only' and user_role == 'alumni':
        can_register = True
    elif visibility == 'students_only' and user_role in ['guest', 'student']:
        can_register = True
    
    if not can_register:
        if visibility == 'alumni_only':
            flash('This event is only open to alumni. Students cannot register.', 'warning')
        elif visibility == 'students_only':
            flash('This event is only open to students. Alumni cannot register.', 'warning')
        return redirect(url_for('event_detail', event_id=event_id))
    
    # Check if already registered
    existing = execute_query("""
        SELECT id FROM event_registrations WHERE event_id = %s AND user_id = %s
    """, (event_id, session['user_id']))
    
    if existing:
        flash('You are already registered for this event.', 'info')
    else:
        execute_query("""
            INSERT INTO event_registrations (event_id, user_id, status) VALUES (%s, %s, 'registered')
        """, (event_id, session['user_id']), fetch=False)
        flash('Successfully registered for the event!', 'success')
    
    return redirect(url_for('event_detail', event_id=event_id))


@app.route('/events/create', methods=['GET', 'POST'])
@login_required
def create_event():
    """Create a new event (Alumni & Student)."""
    if request.method == 'POST':
        title = request.form.get('title')
        description = request.form.get('description')
        start_date = request.form.get('start_date')
        start_time = request.form.get('start_time') or None
        end_date = request.form.get('end_date') or None
        end_time = request.form.get('end_time') or None
        venue = request.form.get('venue')
        
        visibility = request.form.get('visibility', 'all')
        
        # Simple slug generation
        import random, string
        slug = "".join(random.choices(string.ascii_lowercase + string.digits, k=10))
        
        execute_query("""
            INSERT INTO events (title, slug, description, start_date, start_time, end_date, end_time,
                                venue, visibility, status, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'published', %s)
        """, (title, slug, description, start_date, start_time, end_date, end_time,
              venue, visibility, session['user_id']), fetch=False)
        
        flash('Event created successfully!', 'success')
        return redirect(url_for('events'))
        
    return render_template('create_event.html')


@app.route('/announcements/create', methods=['GET', 'POST'])
@login_required
def create_announcement():
    """Create a new announcement (Alumni & Student)."""
    if request.method == 'POST':
        title = request.form.get('title')
        content = request.form.get('content')
        target_audience = request.form.get('target_audience', 'all')
        
        execute_query("""
            INSERT INTO announcements (title, content, target_audience, status, created_by)
            VALUES (%s, %s, %s, 'published', %s)
        """, (title, content, target_audience, session['user_id']), fetch=False)
        
        flash('Announcement posted successfully!', 'success')
        return redirect(url_for('announcements'))
        
    return render_template('create_announcement.html')


# =====================================================
# ALUMNI DIRECTORY ROUTES
# =====================================================

@app.route('/alumni')
@login_required
def alumni_directory():
    """Browse alumni directory."""
    search = request.args.get('search', '')
    skill = request.args.get('skill', '')
    
    query = """
        SELECT ap.*, d.name as degree_name, c.name as campus_name
        FROM alumni_profiles ap
        JOIN users u ON ap.user_id = u.id
        LEFT JOIN degrees d ON ap.degree_id = d.id
        LEFT JOIN campuses c ON ap.campus_id = c.id
        WHERE u.status = 'active' AND u.is_deleted = 0 AND ap.is_deleted = 0
    """
    params = []
    
    if search:
        query += " AND (ap.first_name LIKE %s OR ap.last_name LIKE %s OR ap.current_company LIKE %s)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param, search_param])
    
    if skill:
        query += """ AND ap.id IN (
            SELECT alumni_profile_id FROM alumni_skills WHERE skill_name LIKE %s
        )"""
        params.append(f"%{skill}%")
    
    query += " ORDER BY ap.first_name ASC"
    
    alumni_list = execute_query(query, tuple(params) if params else None)
    return render_template('alumni_directory.html', alumni=alumni_list, search=search, skill=skill)


@app.route('/alumni/<int:profile_id>')
@login_required
def alumni_profile(profile_id):
    """View an alumni's profile."""
    alumni = execute_query("""
        SELECT ap.*, d.name as degree_name, c.name as campus_name, u.email
        FROM alumni_profiles ap
        JOIN users u ON ap.user_id = u.id
        LEFT JOIN degrees d ON ap.degree_id = d.id
        LEFT JOIN campuses c ON ap.campus_id = c.id
        WHERE ap.id = %s AND ap.is_deleted = 0
    """, (profile_id,))
    
    if not alumni:
        flash('Profile not found.', 'warning')
        return redirect(url_for('alumni_directory'))
    
    skills = execute_query("""
        SELECT skill_name, proficiency_level FROM alumni_skills WHERE alumni_profile_id = %s
    """, (profile_id,))
    
    work_history = execute_query("""
        SELECT * FROM alumni_work_history 
        WHERE alumni_profile_id = %s AND is_deleted = 0 
        ORDER BY is_current DESC, start_date DESC
    """, (profile_id,))
    
    # Increment view count only if viewer is not the profile owner
    current_user_id = session.get('user_id')
    if current_user_id != alumni[0]['user_id']:
        execute_query("UPDATE alumni_profiles SET profile_views = profile_views + 1 WHERE id = %s", 
                      (profile_id,), fetch=False)
    
    return render_template('alumni_profile.html', alumni=alumni[0], skills=skills, work_history=work_history)


# =====================================================
# PROFILE MANAGEMENT ROUTES
# =====================================================

@app.route('/profile/edit', methods=['GET', 'POST'])
@login_required
def edit_profile():
    """Edit user profile."""
    user_id = session.get('user_id')
    role = session.get('role')
    
    if role == 'alumni':
        profile = execute_query("SELECT * FROM alumni_profiles WHERE user_id = %s", (user_id,))
        template = 'edit_profile_alumni.html'
        table = 'alumni_profiles'
    else:
        profile = execute_query("SELECT * FROM student_profiles WHERE user_id = %s", (user_id,))
        template = 'edit_profile_student.html'
        table = 'student_profiles'
    
    if not profile:
        # Should not happen for logged in users if registration works, but safe fallback
        flash('Profile not found. Please contact support.', 'danger')
        return redirect(url_for('dashboard'))

    if request.method == 'POST':
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        phone = request.form.get('phone')
        bio = request.form.get('bio')
        linkedin_url = request.form.get('linkedin_url')
        
        # Handle photo upload
        photo_path = profile[0].get('profile_photo')
        if 'profile_photo' in request.files:
            file = request.files['profile_photo']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(f"{user_id}_profile_{file.filename}")
                photo_path = f"uploads/photos/{filename}"  # Use forward slashes for web paths
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], 'photos', filename))
        
        if role == 'alumni':
            current_job_title = request.form.get('current_job_title')
            current_company = request.form.get('current_company')
            
            # Handle privacy settings (email always visible, only phone has setting)
            show_phone = 1 if request.form.get('show_phone') else 0
            
            # Handle Skills update
            skills_input = request.form.get('skills', '')
            # Delete existing skills
            execute_query("DELETE FROM alumni_skills WHERE alumni_profile_id = %s", (profile[0]['id'],), fetch=False)
            # Add new skills
            skill_list = [s.strip() for s in skills_input.split(',') if s.strip()]
            for skill in skill_list:
                execute_query("INSERT INTO alumni_skills (alumni_profile_id, skill_name) VALUES (%s, %s)", 
                              (profile[0]['id'], skill), fetch=False)

            execute_query(f"""
                UPDATE {table} 
                SET first_name = %s, last_name = %s, phone = %s, bio = %s, 
                    linkedin_url = %s, profile_photo = %s, current_job_title = %s, current_company = %s,
                    show_phone = %s
                WHERE user_id = %s
            """, (first_name, last_name, phone, bio, linkedin_url, photo_path, 
                  current_job_title, current_company, show_phone, user_id), fetch=False)
        else:
            # Student fields
            date_of_birth = request.form.get('date_of_birth') or None
            nationality = request.form.get('nationality')
            gender = request.form.get('gender')
            
            execute_query(f"""
                UPDATE {table} 
                SET first_name = %s, last_name = %s, phone = %s, bio = %s, 
                    linkedin_url = %s, profile_photo = %s, date_of_birth = %s, nationality = %s, gender = %s
                WHERE user_id = %s
            """, (first_name, last_name, phone, bio, linkedin_url, photo_path, date_of_birth, nationality, gender, user_id), fetch=False)
        
        flash('Profile updated successfully!', 'success')
        return redirect(url_for('dashboard'))
    
    # Get degrees and campuses for dropdowns
    degrees = execute_query("SELECT * FROM degrees WHERE is_active = 1")
    campuses = execute_query("SELECT * FROM campuses WHERE is_active = 1")
    
    # Get user skills if alumni
    user_skills = ""
    if role == 'alumni':
        skills_data = execute_query("SELECT skill_name FROM alumni_skills WHERE alumni_profile_id = %s", (profile[0]['id'],))
        user_skills = ", ".join([s['skill_name'] for s in skills_data])
    
    return render_template(template, profile=profile[0] if profile else {}, 
                           degrees=degrees, campuses=campuses, user_skills=user_skills)


@app.route('/delete_account', methods=['POST'])
@login_required
def delete_account():
    """Permanently delete user account."""
    user_id = session.get('user_id')
    
    # Soft delete (or hard delete based on preference, here using soft delete flags on children, user table login block)
    # Actually, user requested "Delete Account option", usually implies complete removal or deactivation. 
    # Schema has is_deleted.
    
    execute_query("UPDATE users SET is_deleted = 1, status = 'blocked' WHERE id = %s", (user_id,), fetch=False)
    # Also mark profile as deleted
    execute_query("UPDATE alumni_profiles SET is_deleted = 1 WHERE user_id = %s", (user_id,), fetch=False)
    execute_query("UPDATE student_profiles SET is_deleted = 1 WHERE user_id = %s", (user_id,), fetch=False)
    
    session.clear()
    flash('Your account has been deleted. We are sorry to see you go.', 'info')
    return redirect(url_for('home'))

@app.route('/forgot-password')
def forgot_password():
    return render_template('forgot_password.html')


# =====================================================
# DELETE ROUTES
# =====================================================

@app.route('/jobs/<int:job_id>/delete', methods=['POST'])
@login_required
def delete_job(job_id):
    """Delete a job posting (only by the poster)."""
    job = execute_query("SELECT * FROM job_postings WHERE id = %s", (job_id,))
    
    if not job:
        flash('Job not found.', 'warning')
        return redirect(url_for('dashboard'))
    
    if job[0]['posted_by'] != session['user_id']:
        flash('You can only delete your own job postings.', 'danger')
        return redirect(url_for('dashboard'))
    
    execute_query("UPDATE job_postings SET is_deleted = 1, deleted_at = NOW() WHERE id = %s", (job_id,), fetch=False)
    flash('Job posting deleted successfully.', 'success')
    return redirect(url_for('dashboard'))


@app.route('/events/<int:event_id>/delete', methods=['POST'])
@login_required
def delete_event(event_id):
    """Delete an event (only by the creator)."""
    event = execute_query("SELECT * FROM events WHERE id = %s", (event_id,))
    
    if not event:
        flash('Event not found.', 'warning')
        return redirect(url_for('dashboard'))
    
    if event[0]['created_by'] != session['user_id']:
        flash('You can only delete your own events.', 'danger')
        return redirect(url_for('dashboard'))
    
    execute_query("UPDATE events SET is_deleted = 1, deleted_at = NOW() WHERE id = %s", (event_id,), fetch=False)
    flash('Event deleted successfully.', 'success')
    return redirect(url_for('dashboard'))


@app.route('/announcements/<int:announcement_id>/delete', methods=['POST'])
@login_required  
def delete_announcement(announcement_id):
    """Delete an announcement (only by the creator)."""
    announcement = execute_query("SELECT * FROM announcements WHERE id = %s", (announcement_id,))
    
    if not announcement:
        flash('Announcement not found.', 'warning')
        return redirect(url_for('dashboard'))
    
    if announcement[0]['created_by'] != session['user_id']:
        flash('You can only delete your own announcements.', 'danger')
        return redirect(url_for('dashboard'))
    
    execute_query("UPDATE announcements SET is_deleted = 1, deleted_at = NOW() WHERE id = %s", (announcement_id,), fetch=False)
    flash('Announcement deleted successfully.', 'success')
    return redirect(url_for('dashboard'))


# =====================================================
# ANNOUNCEMENTS ROUTE
# =====================================================

@app.route('/announcements')
@login_required
def announcements():
    """View announcements."""
    query = """
        SELECT a.*, 
               u.email as author_email,
               COALESCE(ap.phone, sp.phone) as author_phone,
               ap.current_company as author_company,
               COALESCE(CONCAT(ap.first_name, ' ', ap.last_name), CONCAT(sp.first_name, ' ', sp.last_name)) as author_name
        FROM announcements a
        JOIN users u ON a.created_by = u.id
        LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
        LEFT JOIN student_profiles sp ON u.id = sp.user_id
        WHERE a.status = 'published' AND a.is_deleted = 0 
        AND (a.expire_at IS NULL OR a.expire_at > NOW())
    """
    
    # Filter by Target Audience
    role = session.get('role')
    if role == 'student' or role == 'guest':
        query += " AND (target_audience = 'all' OR target_audience = 'students_only')"
    elif role == 'alumni':
        query += " AND (target_audience = 'all' OR target_audience = 'alumni_only')"
        
    query += " ORDER BY is_pinned DESC, created_at DESC"
    
    announcement_list = execute_query(query)
    return render_template('announcements.html', announcements=announcement_list)


# =====================================================
# STUDENT DIRECTORY ROUTES
# =====================================================

@app.route('/students')
@login_required
def student_directory():
    """Browse student directory."""
    search = request.args.get('search', '')
    degree_filter = request.args.get('degree', '')
    
    query = """
        SELECT sp.*, d.name as degree_name, c.name as campus_name
        FROM student_profiles sp
        JOIN users u ON sp.user_id = u.id
        LEFT JOIN degrees d ON sp.degree_id = d.id
        LEFT JOIN campuses c ON sp.campus_id = c.id
        WHERE u.status = 'active' AND u.is_deleted = 0 AND sp.is_deleted = 0
    """
    params = []
    
    if search:
        query += " AND (sp.first_name LIKE %s OR sp.last_name LIKE %s OR sp.student_id LIKE %s)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param, search_param])
    
    if degree_filter:
        query += " AND sp.degree_id = %s"
        params.append(degree_filter)
    
    query += " ORDER BY sp.first_name ASC"
    
    students_list = execute_query(query, tuple(params) if params else None)
    degrees = execute_query("SELECT * FROM degrees WHERE is_active = 1 ORDER BY name")
    
    return render_template('student_directory.html', students=students_list, 
                           search=search, degrees=degrees, degree_filter=degree_filter)


@app.route('/students/<int:profile_id>')
@login_required
def student_profile(profile_id):
    """View a student's profile."""
    student = execute_query("""
        SELECT sp.*, d.name as degree_name, c.name as campus_name, u.email
        FROM student_profiles sp
        JOIN users u ON sp.user_id = u.id
        LEFT JOIN degrees d ON sp.degree_id = d.id
        LEFT JOIN campuses c ON sp.campus_id = c.id
        WHERE sp.id = %s AND sp.is_deleted = 0
    """, (profile_id,))
    
    if not student:
        flash('Profile not found.', 'warning')
        return redirect(url_for('student_directory'))
    
    # Increment view count only if viewer is not the profile owner
    current_user_id = session.get('user_id')
    if current_user_id != student[0]['user_id']:
        execute_query("UPDATE student_profiles SET profile_views = profile_views + 1 WHERE id = %s", 
                      (profile_id,), fetch=False)
    
    return render_template('student_profile.html', student=student[0])


# =====================================================
# MESSAGING ROUTES
# =====================================================

@app.route('/messages')
@login_required
def messages_inbox():
    """View message inbox."""
    user_id = session.get('user_id')
    
    # Get conversations where user is involved
    conversations = execute_query("""
        SELECT c.*, m.content as last_message, m.created_at as last_message_at,
               m.sender_id as last_sender_id,
               CASE 
                   WHEN c.user_one_id = %s THEN c.user_two_id
                   ELSE c.user_one_id
               END as other_user_id,
               COALESCE(
                   CONCAT(ap.first_name, ' ', ap.last_name),
                   CONCAT(sp.first_name, ' ', sp.last_name)
               ) as other_user_name,
               COALESCE(ap.profile_photo, sp.profile_photo) as other_user_photo
        FROM conversations c
        LEFT JOIN messages m ON c.id = m.conversation_id AND m.id = (
            SELECT id FROM messages WHERE conversation_id = c.id 
            ORDER BY created_at DESC LIMIT 1
        )
        JOIN users u ON (CASE WHEN c.user_one_id = %s THEN c.user_two_id ELSE c.user_one_id END) = u.id
        LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
        LEFT JOIN student_profiles sp ON u.id = sp.user_id
        WHERE (c.user_one_id = %s OR c.user_two_id = %s)
        ORDER BY m.created_at DESC
    """, (user_id, user_id, user_id, user_id))
    
    return render_template('messages_inbox.html', conversations=conversations)


@app.route('/messages/compose/<int:recipient_id>', methods=['GET', 'POST'])
@login_required
def compose_message(recipient_id):
    """Compose and send a message."""
    if request.method == 'POST':
        content = request.form.get('message')
        sender_id = session.get('user_id')
        
        if not content:
            flash('Message cannot be empty.', 'warning')
            return redirect(url_for('compose_message', recipient_id=recipient_id))
        
        # Find or create conversation
        conversation = execute_query("""
            SELECT * FROM conversations 
            WHERE (user_one_id = %s AND user_two_id = %s) 
               OR (user_one_id = %s AND user_two_id = %s)
        """, (sender_id, recipient_id, recipient_id, sender_id))
        
        if conversation:
            conversation_id = conversation[0]['id']
        else:
            # Create new conversation
            conversation_id = execute_query("""
                INSERT INTO conversations (user_one_id, user_two_id, last_message_at)
                VALUES (%s, %s, NOW())
            """, (sender_id, recipient_id), fetch=False)
        
        # Insert message
        execute_query("""
            INSERT INTO messages (conversation_id, sender_id, content)
            VALUES (%s, %s, %s)
        """, (conversation_id, sender_id, content), fetch=False)
        
        # Update conversation last_message_at
        execute_query("""
            UPDATE conversations SET last_message_at = NOW() WHERE id = %s
        """, (conversation_id,), fetch=False)
        
        flash('Message sent successfully!', 'success')
        return redirect(url_for('view_conversation', conversation_id=conversation_id))
    
    # GET request - show compose form
    recipient = execute_query("""
        SELECT u.*, 
               COALESCE(ap.first_name, sp.first_name) as first_name,
               COALESCE(ap.last_name, sp.last_name) as last_name
        FROM users u
        LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
        LEFT JOIN student_profiles sp ON u.id = sp.user_id
        WHERE u.id = %s
    """, (recipient_id,))
    
    if not recipient:
        flash('User not found.', 'warning')
        return redirect(url_for('messages_inbox'))
    
    return render_template('compose_message.html', recipient=recipient[0])


@app.route('/messages/<int:conversation_id>')
@login_required
def view_conversation(conversation_id):
    """View a conversation thread."""
    user_id = session.get('user_id')
    
    # Get conversation
    conversation = execute_query("""
        SELECT c.*, 
               CASE WHEN c.user_one_id = %s THEN c.user_two_id ELSE c.user_one_id END as other_user_id,
               COALESCE(
                   CONCAT(ap.first_name, ' ', ap.last_name),
                   CONCAT(sp.first_name, ' ', sp.last_name)
               ) as other_user_name
        FROM conversations c
        JOIN users u ON (CASE WHEN c.user_one_id = %s THEN c.user_two_id ELSE c.user_one_id END) = u.id
        LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
        LEFT JOIN student_profiles sp ON u.id = sp.user_id
        WHERE c.id = %s AND (c.user_one_id = %s OR c.user_two_id = %s)
    """, (user_id, user_id, conversation_id, user_id, user_id))
    
    if not conversation:
        flash('Conversation not found.', 'warning')
        return redirect(url_for('messages_inbox'))
    
    # Get messages
    messages_list = execute_query("""
        SELECT m.*, 
               COALESCE(
                   CONCAT(ap.first_name, ' ', ap.last_name),
                   CONCAT(sp.first_name, ' ', sp.last_name)
               ) as sender_name
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
        LEFT JOIN student_profiles sp ON u.id = sp.user_id
        WHERE m.conversation_id = %s
        ORDER BY m.created_at ASC
    """, (conversation_id,))
    
    # Mark messages as read
    execute_query("""
        UPDATE messages SET is_read = 1, read_at = NOW()
        WHERE conversation_id = %s AND sender_id != %s AND is_read = 0
    """, (conversation_id, user_id), fetch=False)
    
    return render_template('view_conversation.html', 
                           conversation=conversation[0], 
                           messages=messages_list)


# =====================================================
# CV DOWNLOAD ROUTE
# =====================================================

@app.route('/download/cv/<int:application_id>')
@login_required
def download_cv(application_id):
    """Download CV for a job application."""
    # Get the application
    application = execute_query("""
        SELECT ja.*, jp.posted_by
        FROM job_applications ja
        JOIN job_postings jp ON ja.job_posting_id = jp.id
        WHERE ja.id = %s
    """, (application_id,))
    
    if not application:
        flash('Application not found.', 'warning')
        return redirect(url_for('jobs'))
    
    # Check if user is the job poster
    if session.get('user_id') != application[0]['posted_by']:
        flash('You do not have permission to download this CV.', 'warning')
        return redirect(url_for('jobs'))
    
    # Get CV path
    cv_path = application[0]['cv_upload']
    if not cv_path:
        flash('No CV uploaded for this application.', 'warning')
        return redirect(url_for('jobs'))
    
    # Construct full file path
    from flask import send_file
    import os
    full_path = os.path.join(app.static_folder, cv_path)
    
    # Check if file exists
    if not os.path.exists(full_path):
        flash('CV file not found on server.', 'error')
        return redirect(url_for('jobs'))
    
    # Send file with download header
    filename = os.path.basename(cv_path)
    return send_file(full_path, as_attachment=True, download_name=filename)


# =====================================================
# RUN APPLICATION
# =====================================================

if __name__ == '__main__':
    app.run(debug=True, port=5000)

-- =====================================================
-- ALUMNI SYNC - ALUMNI MANAGEMENT SYSTEM DATABASE
-- Production-Ready MySQL Schema (InnoDB, 3NF Normalized)
-- Created: January 7, 2026
-- =====================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS alumni_sync
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE alumni_sync;

-- Drop views first to avoid reference errors
DROP VIEW IF EXISTS vw_alumni_by_skill;
DROP VIEW IF EXISTS vw_alumni_engagements;
-- Add any other views that exist

-- Drop tables in reverse dependency order to avoid foreign key errors
DROP TABLE IF EXISTS event_speakers;
DROP TABLE IF EXISTS alumni_engagements;
DROP TABLE IF EXISTS admin_activity_log;
DROP TABLE IF EXISTS reference_requests;
DROP TABLE IF EXISTS job_applications;
DROP TABLE IF EXISTS job_posting_skills;
DROP TABLE IF EXISTS job_postings;
DROP TABLE IF EXISTS alumni_skills;
DROP TABLE IF EXISTS alumni_work_history;
DROP TABLE IF EXISTS comment_likes;
DROP TABLE IF EXISTS post_comments;
DROP TABLE IF EXISTS post_likes;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS alumni_achievements;
DROP TABLE IF EXISTS event_reminders;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS report_logs;
DROP TABLE IF EXISTS verification_queue;
DROP TABLE IF EXISTS contact_messages;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS about_page_revisions;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS media_files;
DROP TABLE IF EXISTS profile_views;
DROP TABLE IF EXISTS password_reset_tokens;
DROP TABLE IF EXISTS about_quick_links;
DROP TABLE IF EXISTS about_feature_cards;
DROP TABLE IF EXISTS about_sections;
DROP TABLE IF EXISTS message_attachments;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS follows;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS alumni_profiles;
DROP TABLE IF EXISTS student_profiles;
DROP TABLE IF EXISTS event_registrations;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS announcements;
DROP TABLE IF EXISTS institution_info;
DROP TABLE IF EXISTS about_page;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS degrees;
DROP TABLE IF EXISTS campuses;

-- =====================================================
-- CORE USER & AUTHENTICATION TABLES
-- =====================================================

-- Roles Table
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL
) ENGINE=InnoDB;

-- Insert default roles
INSERT INTO roles (name, description) VALUES
('admin', 'Full control over system data and verification'),
('alumni', 'Verified users with full interaction rights'),
('guest', 'Read-only access to public pages');

-- Users Table (Core Authentication)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL DEFAULT 2,
    status ENUM('pending', 'active', 'rejected', 'blocked') DEFAULT 'pending',
    email_verified_at TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role_id)
) ENGINE=InnoDB;

-- Password Reset Tokens
CREATE TABLE password_reset_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_expires (user_id, expires_at)
) ENGINE=InnoDB;

-- Email Verification Tokens
CREATE TABLE email_verification_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    verified_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_token (token)
) ENGINE=InnoDB;

-- =====================================================
-- ALUMNI PROFILE TABLES
-- =====================================================

-- Campuses / Branches
CREATE TABLE campuses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    address TEXT,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL
) ENGINE=InnoDB;

-- Degrees / Programs
CREATE TABLE degrees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    abbreviation VARCHAR(50),
    level ENUM('diploma', 'bachelor', 'master', 'phd', 'certificate') NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL
) ENGINE=InnoDB;



-- Alumni Profiles
CREATE TABLE alumni_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    
    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NULL,
    date_of_birth DATE NULL,
    nationality VARCHAR(100) NULL,
    profile_photo VARCHAR(500) NULL,
    cover_photo VARCHAR(500) NULL,
    
    -- Academic History
    degree_id INT NULL,
    graduation_year YEAR NULL,
    campus_id INT NULL,
    student_id VARCHAR(50) NULL,
    
    -- Professional Information
    current_job_title VARCHAR(255) NULL,
    current_company VARCHAR(255) NULL,
    industry VARCHAR(100) NULL,
    bio TEXT NULL,
    
    -- Contact Information
    phone VARCHAR(20) NULL,
    website VARCHAR(255) NULL,
    linkedin_url VARCHAR(255) NULL,
    
    -- Privacy Settings
    show_email TINYINT(1) DEFAULT 0,
    show_phone TINYINT(1) DEFAULT 0,
    show_dob TINYINT(1) DEFAULT 0,
    profile_visibility ENUM('public', 'alumni_only', 'private') DEFAULT 'alumni_only',
    
    -- Statistics
    profile_views INT DEFAULT 0,
    
    -- Audit Fields
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (degree_id) REFERENCES degrees(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (campus_id) REFERENCES campuses(id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Search Indexes
    INDEX idx_name (first_name, last_name),
    INDEX idx_graduation (graduation_year),
    INDEX idx_campus (campus_id),
    INDEX idx_degree (degree_id),
    INDEX idx_job (current_job_title),
    INDEX idx_company (current_company),
    FULLTEXT INDEX ft_search (first_name, last_name, current_job_title, current_company, bio)
) ENGINE=InnoDB;


-- Student Profiles
CREATE TABLE student_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    
    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NULL,
    date_of_birth DATE NULL,
    nationality VARCHAR(100) NULL,
    profile_photo VARCHAR(500) NULL,
    cover_photo VARCHAR(500) NULL,
    
    -- Academic Information
    student_id VARCHAR(50) NULL,
    degree_id INT NULL,
    campus_id INT NULL,
    expected_graduation_year YEAR NULL,
    current_semester VARCHAR(50) NULL,
    cgpa DECIMAL(3,2) NULL,
    
    -- Contact Information
    phone VARCHAR(20) NULL,
    website VARCHAR(255) NULL,
    linkedin_url VARCHAR(255) NULL,
    
    -- Bio / About
    bio TEXT NULL,
    
    -- Privacy & Stats
    profile_visibility ENUM('public', 'students_only', 'alumni_only', 'private') DEFAULT 'students_only',
    profile_views INT DEFAULT 0,
    
    -- Audit
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (degree_id) REFERENCES degrees(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (campus_id) REFERENCES campuses(id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX idx_name (first_name, last_name),
    INDEX idx_student_id (student_id),
    INDEX idx_degree (degree_id),
    INDEX idx_campus (campus_id)
) ENGINE=InnoDB;

-- Alumni Skills (Many-to-Many)
CREATE TABLE alumni_skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alumni_profile_id INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    proficiency_level ENUM('beginner', 'intermediate', 'advanced', 'expert') DEFAULT 'intermediate',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (alumni_profile_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_alumni_skill (alumni_profile_id, skill_name)
) ENGINE=InnoDB;

-- Profile Views Log
CREATE TABLE profile_views (
    id INT AUTO_INCREMENT PRIMARY KEY,
    profile_id INT NOT NULL,
    viewer_id INT NULL,
    viewer_ip VARCHAR(45) NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (profile_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (viewer_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_profile_date (profile_id, viewed_at)
) ENGINE=InnoDB;

-- =====================================================
-- FOLLOW / CONNECTION SYSTEM
-- =====================================================

CREATE TABLE follows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_follow (follower_id, following_id),
    INDEX idx_follower (follower_id),
    INDEX idx_following (following_id)
) ENGINE=InnoDB;

-- =====================================================
-- POSTS, LIKES & COMMENTS (Social Feed)
-- =====================================================

-- Posts
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    media_url VARCHAR(500) NULL,
    media_type ENUM('image', 'video', 'document', 'link') NULL,
    visibility ENUM('public', 'alumni_only', 'private') DEFAULT 'alumni_only',
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    is_pinned TINYINT(1) DEFAULT 0,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_visibility (visibility),
    INDEX idx_created (created_at DESC),
    FULLTEXT INDEX ft_content (content)
) ENGINE=InnoDB;

-- Post Likes
CREATE TABLE post_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_like (post_id, user_id),
    INDEX idx_post (post_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB;

-- Post Comments
CREATE TABLE post_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    parent_comment_id INT NULL,
    content TEXT NOT NULL,
    likes_count INT DEFAULT 0,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES post_comments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_post (post_id),
    INDEX idx_user (user_id),
    INDEX idx_parent (parent_comment_id)
) ENGINE=InnoDB;

-- Comment Likes
CREATE TABLE comment_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    comment_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (comment_id) REFERENCES post_comments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_comment_like (comment_id, user_id)
) ENGINE=InnoDB;

-- =====================================================
-- MESSAGING SYSTEM
-- =====================================================

-- Conversations (for one-to-one messaging)
CREATE TABLE conversations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_one_id INT NOT NULL,
    user_two_id INT NOT NULL,
    last_message_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_one_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_two_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_conversation (user_one_id, user_two_id),
    INDEX idx_user_one (user_one_id),
    INDEX idx_user_two (user_two_id)
) ENGINE=InnoDB;

-- Messages
CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT NOT NULL,
    sender_id INT NOT NULL,
    content TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    read_at TIMESTAMP NULL,
    is_deleted_by_sender TINYINT(1) DEFAULT 0,
    is_deleted_by_receiver TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_conversation (conversation_id),
    INDEX idx_sender (sender_id),
    INDEX idx_read (is_read),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

-- =====================================================
-- NOTIFICATIONS SYSTEM
-- =====================================================

CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('message', 'follow', 'like', 'comment', 'event', 'announcement', 'verification', 'system') NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NULL,
    reference_type VARCHAR(50) NULL,
    reference_id INT NULL,
    is_read TINYINT(1) DEFAULT 0,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_user_read (user_id, is_read),
    INDEX idx_type (type),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =====================================================
-- EVENTS MODULE
-- =====================================================

-- Events
CREATE TABLE events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NULL,
    short_description VARCHAR(500) NULL,
    cover_image VARCHAR(500) NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    start_time TIME NULL,
    end_time TIME NULL,
    venue VARCHAR(255) NULL,
    venue_address TEXT NULL,
    is_online TINYINT(1) DEFAULT 0,
    online_link VARCHAR(500) NULL,
    max_attendees INT NULL,
    registration_deadline DATETIME NULL,
    is_registration_required TINYINT(1) DEFAULT 1,
    visibility ENUM('public', 'alumni_only', 'students_only', 'all') DEFAULT 'all',
    status ENUM('draft', 'published', 'cancelled', 'completed') DEFAULT 'draft',
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_date (start_date),
    INDEX idx_status (status),
    INDEX idx_slug (slug),
    FULLTEXT INDEX ft_event (title, description)
) ENGINE=InnoDB;

-- Event Registrations
CREATE TABLE event_registrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    status ENUM('registered', 'attended', 'cancelled', 'no_show') DEFAULT 'registered',
    registration_notes TEXT NULL,
    attended_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_registration (event_id, user_id),
    INDEX idx_event (event_id),
    INDEX idx_user (user_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Event Reminders
CREATE TABLE event_reminders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    remind_before_hours INT NOT NULL DEFAULT 24,
    is_sent TINYINT(1) DEFAULT 0,
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- ANNOUNCEMENTS
-- =====================================================

CREATE TABLE announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    target_audience ENUM('all', 'alumni_only', 'students_only') DEFAULT 'all',
    is_pinned TINYINT(1) DEFAULT 0,
    publish_at TIMESTAMP NULL,
    expire_at TIMESTAMP NULL,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_status (status),
    INDEX idx_publish (publish_at),
    INDEX idx_priority (priority)
) ENGINE=InnoDB;

-- =====================================================
-- ABOUT ALUMNI CMS PAGE
-- =====================================================

-- About Page Main Content
CREATE TABLE about_page (
    id INT AUTO_INCREMENT PRIMARY KEY,
    page_title VARCHAR(255) NOT NULL,
    hero_image VARCHAR(500) NULL,
    hero_subtitle VARCHAR(500) NULL,
    main_content LONGTEXT NULL,
    status ENUM('draft', 'published') DEFAULT 'draft',
    is_current TINYINT(1) DEFAULT 0,
    version INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- About Page Quick Links
CREATE TABLE about_quick_links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    about_page_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    url VARCHAR(500) NOT NULL,
    icon VARCHAR(100) NULL,
    display_order INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (about_page_id) REFERENCES about_page(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_order (display_order)
) ENGINE=InnoDB;

-- About Page Feature Cards
CREATE TABLE about_feature_cards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    about_page_id INT NOT NULL,
    icon VARCHAR(100) NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    link VARCHAR(500) NULL,
    display_order INT DEFAULT 0,
    status ENUM('draft', 'published') DEFAULT 'published',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (about_page_id) REFERENCES about_page(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_order (display_order)
) ENGINE=InnoDB;

-- About Page Rich Text Sections
CREATE TABLE about_sections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    about_page_id INT NOT NULL,
    section_title VARCHAR(255) NOT NULL,
    section_content LONGTEXT NOT NULL,
    has_read_more TINYINT(1) DEFAULT 0,
    read_more_content LONGTEXT NULL,
    display_order INT DEFAULT 0,
    status ENUM('draft', 'published') DEFAULT 'published',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (about_page_id) REFERENCES about_page(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_order (display_order)
) ENGINE=InnoDB;

-- About Page Revision History
CREATE TABLE about_page_revisions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    about_page_id INT NOT NULL,
    revision_data JSON NOT NULL,
    revision_note VARCHAR(500) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NULL,
    
    FOREIGN KEY (about_page_id) REFERENCES about_page(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- COMPANY / INSTITUTION INFORMATION
-- =====================================================

CREATE TABLE institution_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    abbreviation VARCHAR(50) NULL,
    description TEXT NULL,
    logo VARCHAR(500) NULL,
    favicon VARCHAR(500) NULL,
    address TEXT NULL,
    city VARCHAR(100) NULL,
    country VARCHAR(100) NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(255) NULL,
    website VARCHAR(255) NULL,
    facebook_url VARCHAR(255) NULL,
    twitter_url VARCHAR(255) NULL,
    linkedin_url VARCHAR(255) NULL,
    instagram_url VARCHAR(255) NULL,
    youtube_url VARCHAR(255) NULL,
    founded_year YEAR NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL
) ENGINE=InnoDB;

-- =====================================================
-- FEEDBACK & CONTACT MESSAGES
-- =====================================================

CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NULL,
    category ENUM('general', 'bug_report', 'feature_request', 'complaint', 'suggestion', 'other') DEFAULT 'general',
    message TEXT NOT NULL,
    status ENUM('new', 'in_progress', 'resolved', 'closed') DEFAULT 'new',
    admin_notes TEXT NULL,
    resolved_by INT NULL,
    resolved_at TIMESTAMP NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_status (status),
    INDEX idx_category (category),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- Contact Messages
CREATE TABLE contact_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NULL,
    subject VARCHAR(255) NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    read_at TIMESTAMP NULL,
    read_by INT NULL,
    replied_at TIMESTAMP NULL,
    replied_by INT NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (read_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (replied_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_read (is_read),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =====================================================
-- ADMIN DASHBOARD & STATISTICS
-- =====================================================

-- Dashboard Statistics Cache
CREATE TABLE dashboard_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stat_key VARCHAR(100) NOT NULL UNIQUE,
    stat_value INT DEFAULT 0,
    stat_date DATE NULL,
    last_calculated_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- User Verification Queue (Admin Approvals)
CREATE TABLE verification_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    submitted_documents JSON NULL,
    verification_notes TEXT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    reviewed_by INT NULL,
    reviewed_at TIMESTAMP NULL,
    rejection_reason TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

-- Admin Activity Log
CREATE TABLE admin_activity_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NULL,
    entity_id INT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(500) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_admin (admin_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =====================================================
-- SESSION MANAGEMENT
-- =====================================================

CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    device_info VARCHAR(500) NULL,
    ip_address VARCHAR(45) NULL,
    expires_at TIMESTAMP NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_token (session_token),
    INDEX idx_user (user_id),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB;

-- =====================================================
-- MEDIA / FILE UPLOADS
-- =====================================================

CREATE TABLE media_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    file_name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_size INT NOT NULL,
    mime_type VARCHAR(100) NULL,
    entity_type VARCHAR(50) NULL,
    entity_id INT NULL,
    is_public TINYINT(1) DEFAULT 0,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB;

-- =====================================================
-- JOB POSTINGS & INTERNSHIP BOARD (Feature 6)
-- =====================================================

-- Job Postings (Alumni can post internships and jobs for students)
CREATE TABLE job_postings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    posted_by INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    company_logo VARCHAR(500) NULL,
    job_type ENUM('internship', 'full_time', 'part_time', 'contract', 'remote') NOT NULL,
    location VARCHAR(255) NULL,
    is_remote TINYINT(1) DEFAULT 0,
    description TEXT NOT NULL,
    requirements TEXT NULL,
    responsibilities TEXT NULL,
    salary_min DECIMAL(12,2) NULL,
    salary_max DECIMAL(12,2) NULL,
    target_audience ENUM('all', 'alumni_only', 'students_only') DEFAULT 'all',
    salary_currency VARCHAR(10) DEFAULT 'BDT',
    experience_level ENUM('entry', 'mid', 'senior', 'lead', 'any') DEFAULT 'any',
    application_deadline DATE NULL,
    application_email VARCHAR(255) NULL,
    application_url VARCHAR(500) NULL,
    vacancies INT DEFAULT 1,
    status ENUM('draft', 'open', 'closed', 'filled', 'expired') DEFAULT 'draft',
    views_count INT DEFAULT 0,
    applications_count INT DEFAULT 0,
    is_featured TINYINT(1) DEFAULT 0,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (posted_by) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_posted_by (posted_by),
    INDEX idx_job_type (job_type),
    INDEX idx_status (status),
    INDEX idx_deadline (application_deadline),
    INDEX idx_company (company_name),
    FULLTEXT INDEX ft_job_search (title, company_name, description, requirements)
) ENGINE=InnoDB;

-- Job Posting Required Skills
CREATE TABLE job_posting_skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_posting_id INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    is_required TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (job_posting_id) REFERENCES job_postings(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_job_skill (job_posting_id, skill_name)
) ENGINE=InnoDB;

-- Job Applications (Students apply to job postings)
CREATE TABLE job_applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_posting_id INT NOT NULL,
    applicant_id INT NOT NULL,
    cv_upload VARCHAR(500) NULL,
    application_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    applied_at DATETIME GENERATED ALWAYS AS (application_date) STORED,
    cover_letter TEXT NULL,
    portfolio_url VARCHAR(500) NULL,
    linkedin_url VARCHAR(500) NULL,
    expected_salary DECIMAL(12,2) NULL,
    availability_date DATE NULL,
    status ENUM('pending', 'reviewed', 'shortlisted', 'interviewed', 'offered', 'hired', 'rejected', 'withdrawn') DEFAULT 'pending',
    recruiter_notes TEXT NULL,
    reviewed_by INT NULL,
    reviewed_at TIMESTAMP NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (job_posting_id) REFERENCES job_postings(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (applicant_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY unique_application (job_posting_id, applicant_id),
    INDEX idx_job (job_posting_id),
    INDEX idx_applicant (applicant_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- =====================================================
-- REFERENCE SUPPORT SYSTEM (Feature 2)
-- =====================================================

-- Reference Requests (Students request references/guidance from alumni)
CREATE TABLE reference_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    requester_id INT NOT NULL,
    alumni_id INT NOT NULL,
    purpose ENUM('job_reference', 'internship_reference', 'career_guidance', 'mentorship', 'industry_insight', 'other') NOT NULL,
    target_company VARCHAR(255) NULL,
    target_position VARCHAR(255) NULL,
    message TEXT NOT NULL,
    status ENUM('pending', 'accepted', 'declined', 'completed') DEFAULT 'pending',
    response_message TEXT NULL,
    responded_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    rating INT NULL CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (alumni_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_requester (requester_id),
    INDEX idx_alumni (alumni_id),
    INDEX idx_status (status),
    INDEX idx_purpose (purpose)
) ENGINE=InnoDB;

-- =====================================================
-- ALUMNI HIRING/ENGAGEMENT SYSTEM (Feature 3)
-- =====================================================

-- Alumni Engagements (University hires alumni for activities)
CREATE TABLE alumni_engagements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alumni_id INT NOT NULL,
    engagement_type ENUM('speaker', 'trainer', 'mentor', 'judge', 'panelist', 'workshop_instructor', 'consultant', 'other') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    event_id INT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    duration_hours DECIMAL(5,2) NULL,
    venue VARCHAR(255) NULL,
    is_paid TINYINT(1) DEFAULT 0,
    compensation DECIMAL(12,2) NULL,
    compensation_currency VARCHAR(10) DEFAULT 'BDT',
    status ENUM('proposed', 'confirmed', 'in_progress', 'completed', 'cancelled') DEFAULT 'proposed',
    admin_notes TEXT NULL,
    alumni_feedback TEXT NULL,
    rating INT NULL CHECK (rating >= 1 AND rating <= 5),
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_by INT NULL,
    
    FOREIGN KEY (alumni_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_alumni (alumni_id),
    INDEX idx_type (engagement_type),
    INDEX idx_status (status),
    INDEX idx_event (event_id),
    INDEX idx_dates (start_date, end_date)
) ENGINE=InnoDB;

-- Event Speakers (Link alumni as speakers/trainers to specific events)
CREATE TABLE event_speakers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    alumni_id INT NOT NULL,
    role ENUM('keynote_speaker', 'guest_speaker', 'panelist', 'trainer', 'moderator', 'judge') NOT NULL,
    topic VARCHAR(255) NULL,
    session_title VARCHAR(255) NULL,
    session_description TEXT NULL,
    session_start_time TIME NULL,
    session_end_time TIME NULL,
    bio_override TEXT NULL,
    photo_override VARCHAR(500) NULL,
    display_order INT DEFAULT 0,
    status ENUM('invited', 'confirmed', 'declined', 'presented') DEFAULT 'invited',
    invitation_sent_at TIMESTAMP NULL,
    confirmed_at TIMESTAMP NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (alumni_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_event_speaker (event_id, alumni_id),
    INDEX idx_event (event_id),
    INDEX idx_alumni (alumni_id),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- =====================================================
-- ALUMNI PROFILE HISTORY (Feature 7 Enhancement)
-- =====================================================

-- Alumni Work History (Full employment history tracking)
CREATE TABLE alumni_work_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alumni_profile_id INT NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    job_title VARCHAR(255) NOT NULL,
    location VARCHAR(255) NULL,
    employment_type ENUM('full_time', 'part_time', 'contract', 'internship', 'freelance') DEFAULT 'full_time',
    industry VARCHAR(100) NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    is_current TINYINT(1) DEFAULT 0,
    description TEXT NULL,
    responsibilities TEXT NULL,
    achievements TEXT NULL,
    display_order INT DEFAULT 0,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (alumni_profile_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_alumni (alumni_profile_id),
    INDEX idx_company (company_name),
    INDEX idx_current (is_current),
    INDEX idx_dates (start_date, end_date)
) ENGINE=InnoDB;

-- Alumni Achievements (Certifications, awards, publications)
CREATE TABLE alumni_achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alumni_profile_id INT NOT NULL,
    achievement_type ENUM('certification', 'award', 'publication', 'patent', 'project', 'volunteer', 'honor', 'other') NOT NULL,
    title VARCHAR(255) NOT NULL,
    issuer VARCHAR(255) NULL,
    issue_date DATE NULL,
    expiry_date DATE NULL,
    credential_id VARCHAR(255) NULL,
    credential_url VARCHAR(500) NULL,
    description TEXT NULL,
    media_url VARCHAR(500) NULL,
    display_order INT DEFAULT 0,
    is_verified TINYINT(1) DEFAULT 0,
    verified_at TIMESTAMP NULL,
    verified_by INT NULL,
    is_deleted TINYINT(1) DEFAULT 0,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (alumni_profile_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_alumni (alumni_profile_id),
    INDEX idx_type (achievement_type),
    INDEX idx_date (issue_date)
) ENGINE=InnoDB;

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATING COUNTS
-- =====================================================

DELIMITER //

-- Trigger to update post likes count on insert
CREATE TRIGGER tr_post_like_insert
AFTER INSERT ON post_likes
FOR EACH ROW
BEGIN
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
END//

-- Trigger to update post likes count on delete
CREATE TRIGGER tr_post_like_delete
AFTER DELETE ON post_likes
FOR EACH ROW
BEGIN
    UPDATE posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
END//

-- Trigger to update post comments count on insert
CREATE TRIGGER tr_post_comment_insert
AFTER INSERT ON post_comments
FOR EACH ROW
BEGIN
    UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
END//

-- Trigger to update post comments count on delete
CREATE TRIGGER tr_post_comment_delete
AFTER DELETE ON post_comments
FOR EACH ROW
BEGIN
    UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
END//

-- Trigger to update comment likes count
CREATE TRIGGER tr_comment_like_insert
AFTER INSERT ON comment_likes
FOR EACH ROW
BEGIN
    UPDATE post_comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
END//

CREATE TRIGGER tr_comment_like_delete
AFTER DELETE ON comment_likes
FOR EACH ROW
BEGIN
    UPDATE post_comments SET likes_count = likes_count - 1 WHERE id = OLD.comment_id;
END//

-- Trigger to update conversation last_message_at
CREATE TRIGGER tr_message_insert
AFTER INSERT ON messages
FOR EACH ROW
BEGIN
    UPDATE conversations SET last_message_at = NEW.created_at WHERE id = NEW.conversation_id;
END//

DELIMITER ;

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- Active Alumni View
CREATE VIEW vw_active_alumni AS
SELECT 
    u.id AS user_id,
    u.email,
    u.status,
    ap.first_name,
    ap.last_name,
    CONCAT(ap.first_name, ' ', ap.last_name) AS full_name,
    ap.profile_photo,
    ap.current_job_title,
    ap.current_company,
    d.name AS degree_name,
    ap.graduation_year,
    c.name AS campus_name,
    ap.profile_views,
    ap.created_at
FROM users u
JOIN alumni_profiles ap ON u.id = ap.user_id
LEFT JOIN degrees d ON ap.degree_id = d.id
LEFT JOIN campuses c ON ap.campus_id = c.id
WHERE u.status = 'active' 
  AND u.is_deleted = 0 
  AND ap.is_deleted = 0;

-- Dashboard Statistics View (Updated with new features)
CREATE VIEW vw_dashboard_stats AS
SELECT
    (SELECT COUNT(*) FROM users WHERE status = 'active' AND is_deleted = 0) AS active_members,
    (SELECT COUNT(*) FROM users WHERE status = 'pending' AND is_deleted = 0) AS pending_members,
    (SELECT COUNT(*) FROM users WHERE is_deleted = 0) AS total_users,
    (SELECT COUNT(*) FROM posts WHERE is_deleted = 0) AS total_posts,
    (SELECT COUNT(*) FROM events WHERE status = 'published' AND is_deleted = 0) AS active_events,
    (SELECT COUNT(*) FROM feedback WHERE status = 'new') AS new_feedback,
    (SELECT COUNT(*) FROM job_postings WHERE status = 'open' AND is_deleted = 0) AS open_jobs,
    (SELECT COUNT(*) FROM job_applications WHERE status = 'pending' AND is_deleted = 0) AS pending_applications,
    (SELECT COUNT(*) FROM reference_requests WHERE status = 'pending' AND is_deleted = 0) AS pending_references,
    (SELECT COUNT(*) FROM alumni_engagements WHERE status IN ('proposed', 'confirmed') AND is_deleted = 0) AS active_engagements;

-- Upcoming Events View
CREATE VIEW vw_upcoming_events AS
SELECT 
    e.*,
    (SELECT COUNT(*) FROM event_registrations WHERE event_id = e.id AND status = 'registered') AS registration_count
FROM events e
WHERE e.start_date >= CURDATE()
  AND e.status = 'published'
  AND e.is_deleted = 0
ORDER BY e.start_date ASC;

-- =====================================================
-- VIEWS FOR NEW FEATURES
-- =====================================================

-- Open Job Postings View (Feature 6)
CREATE VIEW vw_open_jobs AS
SELECT 
    jp.*,
    u.email AS poster_email,
    ap.first_name AS poster_first_name,
    ap.last_name AS poster_last_name,
    ap.current_company AS poster_company,
    (SELECT COUNT(*) FROM job_applications WHERE job_posting_id = jp.id AND is_deleted = 0) AS total_applications,
    (SELECT GROUP_CONCAT(jps.skill_name SEPARATOR ', ') 
     FROM job_posting_skills jps 
     WHERE jps.job_posting_id = jp.id) AS required_skills
FROM job_postings jp
JOIN users u ON jp.posted_by = u.id
LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
WHERE jp.status = 'open' 
  AND jp.is_deleted = 0
  AND (jp.application_deadline IS NULL OR jp.application_deadline >= CURDATE());

-- Alumni by Domain/Skill View (Feature 1)
CREATE VIEW vw_alumni_by_skill AS
SELECT 
    ap.id AS profile_id,
    ap.user_id,
    CONCAT(ap.first_name, ' ', ap.last_name) AS full_name,
    ap.profile_photo,
    ap.current_job_title,
    ap.current_company,
    ap.industry,
    als.skill_name AS skill_name,
    als.proficiency_level,
    ap.graduation_year,
    d.name AS degree_name
FROM alumni_profiles ap
JOIN alumni_skills als ON ap.id = als.alumni_profile_id
LEFT JOIN degrees d ON ap.degree_id = d.id
JOIN users u ON ap.user_id = u.id
WHERE u.status = 'active' 
  AND u.is_deleted = 0 
  AND ap.is_deleted = 0;

-- Pending Reference Requests View (Feature 2)
CREATE VIEW vw_pending_references AS
SELECT 
    rr.*,
    req_u.email AS requester_email,
    req_ap.first_name AS requester_first_name,
    req_ap.last_name AS requester_last_name,
    alum_u.email AS alumni_email,
    alum_ap.first_name AS alumni_first_name,
    alum_ap.last_name AS alumni_last_name,
    alum_ap.current_company AS alumni_company,
    alum_ap.current_job_title AS alumni_job_title
FROM reference_requests rr
JOIN users req_u ON rr.requester_id = req_u.id
LEFT JOIN alumni_profiles req_ap ON req_u.id = req_ap.user_id
JOIN users alum_u ON rr.alumni_id = alum_u.id
LEFT JOIN alumni_profiles alum_ap ON alum_u.id = alum_ap.user_id
WHERE rr.status = 'pending' 
  AND rr.is_deleted = 0;

-- Alumni Engagements Summary View (Feature 3)
CREATE VIEW vw_alumni_engagements AS
SELECT 
    ae.id,
    ae.event_id,
    ae.alumni_id,
    ae.engagement_type,
    ae.status,
    ae.alumni_feedback AS feedback,
    ae.created_at,
    ap.first_name,
    ap.last_name,
    CONCAT(ap.first_name, ' ', ap.last_name) AS alumni_name,
    ap.current_job_title,
    ap.current_company,
    e.title AS event_title,
    e.start_date AS event_date
FROM alumni_engagements ae
JOIN users u ON ae.alumni_id = u.id
LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
LEFT JOIN events e ON ae.event_id = e.id
WHERE ae.is_deleted = 0;

-- Event Speakers View (Feature 5 Enhancement)
CREATE VIEW vw_event_speakers AS
SELECT 
    es.*,
    e.title AS event_title,
    e.start_date,
    e.venue,
    ap.first_name,
    ap.last_name,
    CONCAT(ap.first_name, ' ', ap.last_name) AS speaker_name,
    ap.current_job_title,
    ap.current_company,
    ap.profile_photo
FROM event_speakers es
JOIN events e ON es.event_id = e.id
JOIN users u ON es.alumni_id = u.id
LEFT JOIN alumni_profiles ap ON u.id = ap.user_id
WHERE es.is_deleted = 0 
  AND e.is_deleted = 0;

-- Alumni Work History View (Feature 7)
CREATE VIEW vw_alumni_careers AS
SELECT 
    awh.*,
    ap.first_name,
    ap.last_name,
    CONCAT(ap.first_name, ' ', ap.last_name) AS alumni_name,
    ap.user_id,
    u.email
FROM alumni_work_history awh
JOIN alumni_profiles ap ON awh.alumni_profile_id = ap.id
JOIN users u ON ap.user_id = u.id
WHERE awh.is_deleted = 0 
  AND ap.is_deleted = 0;

-- =====================================================
-- TRIGGERS FOR NEW TABLES
-- =====================================================

DELIMITER //

-- Trigger to update job_postings applications_count on insert
CREATE TRIGGER tr_job_application_insert
AFTER INSERT ON job_applications
FOR EACH ROW
BEGIN
    UPDATE job_postings SET applications_count = applications_count + 1 WHERE id = NEW.job_posting_id;
END//

-- Trigger to update job_postings applications_count on delete
CREATE TRIGGER tr_job_application_delete
AFTER DELETE ON job_applications
FOR EACH ROW
BEGIN
    UPDATE job_postings SET applications_count = applications_count - 1 WHERE id = OLD.job_posting_id;
END//

DELIMITER ;

-- =====================================================
-- INITIAL DATA SETUP
-- =====================================================

-- Insert default institution info
INSERT INTO institution_info (name, abbreviation, description, email) VALUES
('Alumni Sync University', 'ASU', 'A leading institution committed to excellence in education and alumni engagement.', 'info@alumnisync.edu');

-- Insert default about page
INSERT INTO about_page (page_title, hero_subtitle, main_content, status, is_current, created_by) VALUES
('About Alumni Sync', 'Connecting graduates, building futures', 'Welcome to Alumni Sync - your gateway to staying connected with your alma mater and fellow graduates.', 'published', 1, NULL);

-- Insert sample campuses
INSERT INTO campuses (name, code) VALUES
('Main Campus', 'MAIN'),
('Downtown Campus', 'DTN'),
('North Campus', 'NORTH');

-- Insert sample degrees
INSERT INTO degrees (name, abbreviation, level) VALUES
('Bachelor of Science in Computer Science', 'BSc CS', 'bachelor'),
('Bachelor of Business Administration', 'BBA', 'bachelor'),
('Master of Business Administration', 'MBA', 'master'),
('Master of Science in Information Technology', 'MSc IT', 'master'),
('Doctor of Philosophy', 'PhD', 'phd');





-- ==============================
-- HR System Sample SQL
-- ==============================

-- Drop tables if they exist (for re-runs)
DROP TABLE IF EXISTS resumes;
DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS candidates;
DROP TABLE IF EXISTS job_titles;

-- Table: Job Titles
CREATE TABLE job_titles (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Candidates
CREATE TABLE candidates (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(30),
    gender VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Applications
CREATE TABLE applications (
    id SERIAL PRIMARY KEY,
    candidate_id INTEGER REFERENCES candidates(id) ON DELETE CASCADE,
    job_title_id INTEGER REFERENCES job_titles(id) ON DELETE SET NULL,
    application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'applied',  -- applied/interviewed/hired/rejected
    expected_salary INTEGER,
    is_salary_negotiable BOOLEAN,
    work_shifts VARCHAR(10),
    exceptional_customer_service VARCHAR(10),
    how_did_you_hear TEXT
);

-- Table: Resumes
CREATE TABLE resumes (
    id SERIAL PRIMARY KEY,
    application_id INTEGER REFERENCES applications(id) ON DELETE CASCADE,
    file_name VARCHAR(255),
    file_path VARCHAR(255),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data for job_titles
INSERT INTO job_titles (title, department) VALUES
  ('Full Stack Web Developer', 'IT'),
  ('Certified Accountant', 'Finance'),
  ('Operations Manager', 'Operations'),
  ('Graphic Designer', 'Marketing');

-- Sample data for candidates
INSERT INTO candidates (first_name, last_name, email, phone, gender) VALUES
  ('Ahsan', 'Ali', 'ahsan.ali@email.com', '+923001234567', 'Male'),
  ('Fatima', 'Noor', 'fatima.noor@email.com', '+923009876543', 'Female'),
  ('Usman', 'Rashid', 'usman.rashid@email.com', '+923001112233', 'Male');

-- Sample data for applications
INSERT INTO applications (candidate_id, job_title_id, expected_salary, is_salary_negotiable, work_shifts, exceptional_customer_service, how_did_you_hear)
VALUES
  (1, 1, 80000, TRUE, 'Yes', 'Yes', 'Through a friend'),
  (2, 2, 90000, FALSE, 'No', 'Other', 'LinkedIn'),
  (3, 4, 70000, TRUE, 'Yes', 'Yes', 'Company Website');

-- Sample data for resumes
INSERT INTO resumes (application_id, file_name, file_path)
VALUES
  (1, 'ahsan_ali_cv.pdf', '/resumes/ahsan_ali_cv.pdf'),
  (2, 'fatima_noor_cv.pdf', '/resumes/fatima_noor_cv.pdf'),
  (3, 'usman_rashid_cv.pdf', '/resumes/usman_rashid_cv.pdf');

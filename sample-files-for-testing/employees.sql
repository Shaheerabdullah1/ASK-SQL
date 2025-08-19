-- Sample Employee Database
-- This creates a simple employees table with sample data

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(50),
    position VARCHAR(50),
    salary INTEGER,
    score INTEGER,
    hire_date DATE
);

INSERT INTO employees (id, name, email, department, position, salary, score, hire_date) VALUES
(1, 'John Smith', 'john.smith@company.com', 'Engineering', 'Software Engineer', 75000, 19, '2022-01-15'),
(2, 'Sarah Johnson', 'sarah.johnson@company.com', 'Marketing', 'Marketing Manager', 65000, 22, '2021-03-10'),
(3, 'Mike Davis', 'mike.davis@company.com', 'Engineering', 'Senior Developer', 85000, 25, '2020-11-05'),
(4, 'Lisa Wilson', 'lisa.wilson@company.com', 'HR', 'HR Specialist', 55000, 19, '2023-02-20'),
(5, 'David Brown', 'david.brown@company.com', 'Sales', 'Sales Representative', 60000, 18, '2022-07-12'),
(6, 'Emily Chen', 'emily.chen@company.com', 'Engineering', 'Software Engineer', 72000, 23, '2021-09-18'),
(7, 'Robert Taylor', 'robert.taylor@company.com', 'Finance', 'Financial Analyst', 68000, 20, '2022-04-03'),
(8, 'Maria Garcia', 'maria.garcia@company.com', 'Marketing', 'Content Creator', 52000, 19, '2023-01-08'),
(9, 'James Miller', 'james.miller@company.com', 'Engineering', 'DevOps Engineer', 78000, 24, '2021-12-14'),
(10, 'Anna Anderson', 'anna.anderson@company.com', 'Sales', 'Sales Manager', 70000, 21, '2020-08-22'),
(11, 'Tom Wilson', 'tom.wilson@company.com', 'Engineering', 'Junior Developer', 55000, 17, '2023-03-15'),
(12, 'Jessica Lee', 'jessica.lee@company.com', 'HR', 'HR Manager', 75000, 26, '2019-05-30'),
(13, 'Kevin Zhang', 'kevin.zhang@company.com', 'Finance', 'Accountant', 58000, 19, '2022-10-08'),
(14, 'Rachel Green', 'rachel.green@company.com', 'Marketing', 'Digital Marketer', 54000, 20, '2023-04-12'),
(15, 'Daniel Kim', 'daniel.kim@company.com', 'Engineering', 'Software Architect', 95000, 28, '2018-12-01'),
(16, 'Michelle Rodriguez', 'michelle.rodriguez@company.com', 'Sales', 'Sales Representative', 61000, 19, '2022-11-25'),
(17, 'Alex Thompson', 'alex.thompson@company.com', 'Engineering', 'Full Stack Developer', 80000, 22, '2021-06-07'),
(18, 'Samantha Clark', 'samantha.clark@company.com', 'Finance', 'Financial Manager', 82000, 25, '2020-02-14'),
(19, 'Ryan Martinez', 'ryan.martinez@company.com', 'Marketing', 'SEO Specialist', 50000, 18, '2023-05-20'),
(20, 'Jennifer White', 'jennifer.white@company.com', 'HR', 'Recruiter', 52000, 19, '2022-08-16');

-- Add some additional tables for more complex queries
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    budget INTEGER,
    manager_id INTEGER
);

INSERT INTO departments (id, name, budget, manager_id) VALUES
(1, 'Engineering', 500000, 15),
(2, 'Marketing', 200000, 2),
(3, 'Sales', 300000, 10),
(4, 'HR', 150000, 12),
(5, 'Finance', 180000, 18);

DROP TABLE IF EXISTS projects;

CREATE TABLE projects (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INTEGER,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);

INSERT INTO projects (id, name, department_id, start_date, end_date, status) VALUES
(1, 'Mobile App Development', 1, '2023-01-01', '2023-12-31', 'In Progress'),
(2, 'Marketing Campaign Q4', 2, '2023-10-01', '2023-12-31', 'Planning'),
(3, 'Sales Process Automation', 3, '2023-06-01', '2023-11-30', 'In Progress'),
(4, 'Employee Training Program', 4, '2023-03-01', '2023-09-30', 'Completed'),
(5, 'Budget Planning 2024', 5, '2023-11-01', '2024-01-31', 'In Progress');
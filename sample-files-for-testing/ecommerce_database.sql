-- E-Commerce Database with Multiple Tables
-- This demonstrates various table relationships and complex queries

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Create Departments table
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    manager_id INTEGER
);

-- Create Employees table
CREATE TABLE employees (
    emp_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    hire_date DATE,
    dept_id INTEGER,
    salary DECIMAL(10,2),
    position VARCHAR(50)
);

-- Create Categories table
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    description TEXT,
    parent_category_id INTEGER
);

-- Create Products table
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    category_id INTEGER,
    supplier_name VARCHAR(100),
    created_date DATE
);

-- Create Customers table
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE
);

-- Create Orders table
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    shipping_address TEXT,
    employee_id INTEGER
);

-- Create Order Items table (junction table)
CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0.00
);

-- Insert sample data into Departments
INSERT INTO departments (dept_id, dept_name, location, manager_id) VALUES
(1, 'Sales', 'New York', 101),
(2, 'Marketing', 'Los Angeles', 102),
(3, 'Engineering', 'San Francisco', 103),
(4, 'Customer Service', 'Chicago', 104),
(5, 'Finance', 'New York', 105);

-- Insert sample data into Employees
INSERT INTO employees (emp_id, first_name, last_name, email, phone, hire_date, dept_id, salary, position) VALUES
(101, 'John', 'Smith', 'john.smith@company.com', '555-0101', '2020-01-15', 1, 75000.00, 'Sales Manager'),
(102, 'Sarah', 'Johnson', 'sarah.johnson@company.com', '555-0102', '2019-03-22', 2, 68000.00, 'Marketing Manager'),
(103, 'Mike', 'Chen', 'mike.chen@company.com', '555-0103', '2018-06-10', 3, 95000.00, 'Engineering Manager'),
(104, 'Lisa', 'Davis', 'lisa.davis@company.com', '555-0104', '2021-02-08', 4, 55000.00, 'Customer Service Manager'),
(105, 'Robert', 'Wilson', 'robert.wilson@company.com', '555-0105', '2017-11-30', 5, 82000.00, 'Finance Manager'),
(106, 'Emily', 'Brown', 'emily.brown@company.com', '555-0106', '2020-07-12', 1, 52000.00, 'Sales Representative'),
(107, 'David', 'Miller', 'david.miller@company.com', '555-0107', '2021-01-18', 2, 48000.00, 'Marketing Specialist'),
(108, 'Jennifer', 'Garcia', 'jennifer.garcia@company.com', '555-0108', '2019-09-05', 3, 78000.00, 'Software Engineer'),
(109, 'Michael', 'Rodriguez', 'michael.rodriguez@company.com', '555-0109', '2020-12-03', 4, 45000.00, 'Customer Support'),
(110, 'Amanda', 'Martinez', 'amanda.martinez@company.com', '555-0110', '2021-04-20', 5, 58000.00, 'Financial Analyst');

-- Insert sample data into Categories
INSERT INTO categories (category_id, category_name, description, parent_category_id) VALUES
(1, 'Electronics', 'Electronic devices and gadgets', NULL),
(2, 'Computers', 'Desktop and laptop computers', 1),
(3, 'Smartphones', 'Mobile phones and accessories', 1),
(4, 'Clothing', 'Apparel and fashion items', NULL),
(5, 'Men''s Clothing', 'Clothing for men', 4),
(6, 'Women''s Clothing', 'Clothing for women', 4),
(7, 'Home & Garden', 'Home improvement and garden items', NULL),
(8, 'Books', 'Books and educational materials', NULL);

-- Insert sample data into Products
INSERT INTO products (product_id, product_name, description, price, stock_quantity, category_id, supplier_name, created_date) VALUES
(1, 'Laptop Pro 15', 'High-performance laptop with 16GB RAM', 1299.99, 25, 2, 'TechCorp', '2023-01-15'),
(2, 'Smartphone X', 'Latest model smartphone with 128GB storage', 799.99, 50, 3, 'MobileTech', '2023-02-01'),
(3, 'Desktop Gaming PC', 'Gaming computer with high-end graphics', 1899.99, 15, 2, 'GameTech', '2023-01-20'),
(4, 'Wireless Headphones', 'Noise-canceling wireless headphones', 249.99, 75, 1, 'AudioPlus', '2023-02-10'),
(5, 'Men''s T-Shirt', 'Cotton t-shirt in various colors', 19.99, 200, 5, 'FashionCo', '2023-01-05'),
(6, 'Women''s Dress', 'Elegant summer dress', 59.99, 80, 6, 'StyleWear', '2023-02-15'),
(7, 'Coffee Maker', 'Automatic drip coffee maker', 89.99, 30, 7, 'KitchenPro', '2023-01-25'),
(8, 'Programming Book', 'Learn Python programming', 39.99, 100, 8, 'BookPublisher', '2023-02-05'),
(9, 'Tablet 10', '10-inch tablet with stylus', 399.99, 40, 1, 'TabletTech', '2023-01-30'),
(10, 'Garden Tools Set', 'Complete set of garden tools', 129.99, 60, 7, 'GardenSupply', '2023-02-20');

-- Insert sample data into Customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, city, country, registration_date) VALUES
(1, 'Alice', 'Johnson', 'alice.johnson@email.com', '555-1001', '123 Main St', 'New York', 'USA', '2022-01-15'),
(2, 'Bob', 'Williams', 'bob.williams@email.com', '555-1002', '456 Oak Ave', 'Los Angeles', 'USA', '2022-02-20'),
(3, 'Carol', 'Brown', 'carol.brown@email.com', '555-1003', '789 Pine Rd', 'Chicago', 'USA', '2022-03-10'),
(4, 'David', 'Davis', 'david.davis@email.com', '555-1004', '321 Elm St', 'Houston', 'USA', '2022-04-05'),
(5, 'Eva', 'Miller', 'eva.miller@email.com', '555-1005', '654 Maple Dr', 'Phoenix', 'USA', '2022-05-12'),
(6, 'Frank', 'Wilson', 'frank.wilson@email.com', '555-1006', '987 Cedar Ln', 'Philadelphia', 'USA', '2022-06-18'),
(7, 'Grace', 'Moore', 'grace.moore@email.com', '555-1007', '147 Birch St', 'San Antonio', 'USA', '2022-07-22'),
(8, 'Henry', 'Taylor', 'henry.taylor@email.com', '555-1008', '258 Spruce Ave', 'San Diego', 'USA', '2022-08-30'),
(9, 'Iris', 'Anderson', 'iris.anderson@email.com', '555-1009', '369 Walnut Rd', 'Dallas', 'USA', '2022-09-15'),
(10, 'Jack', 'Thomas', 'jack.thomas@email.com', '555-1010', '741 Chestnut Dr', 'San Jose', 'USA', '2022-10-08');

-- Insert sample data into Orders
INSERT INTO orders (order_id, customer_id, order_date, total_amount, status, shipping_address, employee_id) VALUES
(1, 1, '2023-03-01', 1299.99, 'completed', '123 Main St, New York', 106),
(2, 2, '2023-03-02', 849.98, 'completed', '456 Oak Ave, Los Angeles', 106),
(3, 3, '2023-03-03', 1959.98, 'shipped', '789 Pine Rd, Chicago', 107),
(4, 4, '2023-03-04', 269.98, 'completed', '321 Elm St, Houston', 106),
(5, 5, '2023-03-05', 59.99, 'pending', '654 Maple Dr, Phoenix', 107),
(6, 6, '2023-03-06', 489.98, 'completed', '987 Cedar Ln, Philadelphia', 106),
(7, 7, '2023-03-07', 129.99, 'shipped', '147 Birch St, San Antonio', 107),
(8, 8, '2023-03-08', 39.99, 'completed', '258 Spruce Ave, San Diego', 106),
(9, 9, '2023-03-09', 319.98, 'pending', '369 Walnut Rd, Dallas', 107),
(10, 10, '2023-03-10', 1519.98, 'completed', '741 Chestnut Dr, San Jose', 106);

-- Insert sample data into Order Items
INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount) VALUES
(1, 1, 1, 1, 1299.99, 0.00),
(2, 2, 2, 1, 799.99, 0.00),
(3, 2, 4, 1, 249.99, 50.00),
(4, 3, 3, 1, 1899.99, 0.00),
(5, 3, 5, 3, 19.99, 0.00),
(6, 4, 4, 1, 249.99, 0.00),
(7, 4, 5, 1, 19.99, 0.00),
(8, 5, 6, 1, 59.99, 0.00),
(9, 6, 9, 1, 399.99, 0.00),
(10, 6, 7, 1, 89.99, 0.00),
(11, 7, 10, 1, 129.99, 0.00),
(12, 8, 8, 1, 39.99, 0.00),
(13, 9, 4, 1, 249.99, 0.00),
(14, 9, 5, 1, 19.99, 50.00),
(15, 10, 1, 1, 1299.99, 0.00),
(16, 10, 4, 1, 249.99, 30.00);
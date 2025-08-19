-- Improved SQL File for Cars Database
-- Create Table: Cars with better constraints
CREATE TABLE Cars (
    id INT PRIMARY KEY AUTO_INCREMENT,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL CHECK (year >= 1900 AND year <= YEAR(CURDATE()) + 1),
    color VARCHAR(20) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    mileage DECIMAL(8, 1) NOT NULL CHECK (mileage >= 0),
    fuel_type VARCHAR(20) NOT NULL CHECK (fuel_type IN ('Gasoline', 'Diesel', 'Electric', 'Hybrid'))
);

-- Insert sample data into Cars table
INSERT INTO Cars (make, model, year, color, price, mileage, fuel_type)
VALUES
('Toyota', 'Camry', 2021, 'Blue', 25000.00, 15000.5, 'Gasoline'),
('Honda', 'Civic', 2020, 'Black', 22000.00, 18000.0, 'Gasoline'),
('Ford', 'Mustang', 2019, 'Red', 35000.00, 12000.0, 'Gasoline'),
('Chevrolet', 'Malibu', 2018, 'Silver', 18000.00, 25000.8, 'Gasoline'),
('BMW', 'X5', 2022, 'White', 60000.00, 5000.0, 'Diesel'),
('Audi', 'Q7', 2021, 'Grey', 55000.00, 8000.2, 'Diesel'),
('Nissan', 'Altima', 2020, 'Green', 19000.00, 22000.0, 'Gasoline'),
('Mercedes-Benz', 'C-Class', 2021, 'Blue', 45000.00, 10000.0, 'Gasoline'),
('Hyundai', 'Elantra', 2019, 'Yellow', 17000.00, 27000.6, 'Gasoline'),
('Tesla', 'Model 3', 2021, 'Black', 45000.00, 10000.0, 'Electric');

-- QUERY SECTION: Read-only queries (safe to run multiple times)
-- 1. Select all cars in the table
SELECT * FROM Cars;

-- 2. Select all cars with price greater than $30,000
SELECT * FROM Cars
WHERE price > 30000;

-- 3. Select all cars with 'Gasoline' fuel type and year greater than 2019
SELECT * FROM Cars
WHERE fuel_type = 'Gasoline' AND year > 2019;

-- 4. Find the average price of all cars
SELECT AVG(price) AS average_price FROM Cars;

-- 5. Find the total mileage of all cars
SELECT SUM(mileage) AS total_mileage FROM Cars;

-- 6. Find the car with the highest price
SELECT * FROM Cars
ORDER BY price DESC
LIMIT 1;

-- 7. Find the cars with the lowest mileage
SELECT * FROM Cars
ORDER BY mileage ASC
LIMIT 1;

-- 8. Count the number of cars with 'Electric' fuel type
SELECT COUNT(*) AS electric_cars_count FROM Cars
WHERE fuel_type = 'Electric';

-- 9. Group cars by fuel type with average price
SELECT fuel_type, COUNT(*) as count, AVG(price) as avg_price
FROM Cars
GROUP BY fuel_type;

-- 10. Find cars within a specific price range
SELECT * FROM Cars
WHERE price BETWEEN 20000 AND 50000;

-- DATA MODIFICATION SECTION: Run these carefully, preferably on a backup
-- WARNING: These queries modify data - use with caution!

-- Update the price of 'Tesla Model 3' to $47,000
-- UPDATE Cars
-- SET price = 47000.00
-- WHERE make = 'Tesla' AND model = 'Model 3';

-- Delete cars older than the year 2020 (commented out for safety)
-- DELETE FROM Cars
-- WHERE year < 2020;

-- Add indexes for better performance on frequently queried columns
CREATE INDEX idx_make_model ON Cars(make, model);
CREATE INDEX idx_year ON Cars(year);
CREATE INDEX idx_price ON Cars(price);
CREATE INDEX idx_fuel_type ON Cars(fuel_type);
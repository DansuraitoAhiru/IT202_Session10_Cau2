create database cau2;
use cau2;

CREATE TABLE Patients (
    Patient_ID INT AUTO_INCREMENT PRIMARY KEY,
    Full_Name VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) UNIQUE,
    Age INT,
    Address VARCHAR(255)
);

DELIMITER //

CREATE PROCEDURE SeedPatients()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 500000 DO
        INSERT INTO Patients (Full_Name, Phone, Age, Address)
        VALUES (CONCAT('Patient ', i), CONCAT('090', i), FLOOR(RAND()*100), 'Ho Chi Minh City');
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

-- Gọi procedure để nạp dữ liệu
CALL SeedPatients();

create index idx_phone_patient on Patients(phone);

explain analyze
select * from Patients
where Phone = '0901';
-- '-> Rows fetched before execution  (cost=0..0 rows=1) (actual time=200e-6..200e-6 rows=1 loops=1)\n'

-- Đo tốc độ ghi (INSERT)
-- Khi CÓ INDEX
SET @start = NOW();

INSERT INTO Patients (Full_Name, Phone, Age, Address)
SELECT 
    CONCAT('Test ', n),
    CONCAT('08', LPAD(n, 8, '0')),
    FLOOR(RAND()*100),
    'Test City'
FROM (
    SELECT @i := @i + 1 AS n
    FROM information_schema.tables, (SELECT @i := 0) t
    LIMIT 1000
) tmp;

SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW()) AS time_with_index;
-- kết quả ra là 1000000 hiểu là 1,000,000 microseconds = 1s nghĩa là Insert 1000 dòng (có index) sẽ mất ~ 1 giây

truncate Patients;
drop index idx_phone_patient on Patients;

-- Khi KHÔNG có INDEX
SET @start = NOW();

INSERT INTO Patients (Full_Name, Phone, Age, Address)
SELECT 
    CONCAT('Test ', n),
    CONCAT('08', LPAD(n, 8, '0')),
    FLOOR(RAND()*100),
    'Test City'
FROM (
    SELECT @i := @i + 1 AS n
    FROM information_schema.tables, (SELECT @i := 0) t
    LIMIT 1000
) tmp;

SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW()) AS time_without_index;
-- kết quả là 0 nghĩa là Insert 1000 dòng (ko có index) chỉ mất có chút thời gian cực kì nhỏ

-- Nhận xét:
-- Index giúp tăng tốc độ truy vấn dữ liệu, đặc biệt với bảng lớn
-- Tuy nhiên, nó làm giảm hiệu năng ghi dữ liệu do phải tạo mới, cập nhật index liên tục
-- Nên cơ bản thì vẫn phải cân nhắc sử dụng index phù hợp tùy theo mục đích (đọc hay ghi nhiều)

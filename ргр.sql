DROP DATABASE RGR;
CREATE DATABASE RGR;
USE RGR;
DROP TABLE IF EXISTS Klienty, Sotrudniki, Blyuda, Zakazy, Zakazannye_blyuda;


CREATE TABLE Klienty (
    Klient_ID INT AUTO_INCREMENT PRIMARY KEY,
    Imya VARCHAR(50),
    Familiya VARCHAR(50),
    Nomer_telefona VARCHAR(15)
);

CREATE TABLE Sotrudniki (
    Sotrudnik_ID INT AUTO_INCREMENT PRIMARY KEY,
    Imya VARCHAR(50),
    Dolzhnost VARCHAR(50),
    Zarplata DECIMAL(10, 2)
);

CREATE TABLE Blyuda (
    Blyudo_ID INT AUTO_INCREMENT PRIMARY KEY,
    Nazvanie VARCHAR(200),
    Opisanie TEXT,
    Cena DECIMAL(10, 2)
);

CREATE TABLE Zakazy (
    Zakaz_ID INT AUTO_INCREMENT PRIMARY KEY,
    Data_zakaza DATE,
    Summa_zakaza DECIMAL(10, 2), 
    Status_zakaza VARCHAR(50),
    Klient_ID INT,
    FOREIGN KEY (Klient_ID) REFERENCES Klienty(Klient_ID)
);

CREATE TABLE Zakazannye_blyuda (
    Zakaz_ID INT,
    Blyudo_ID INT,
    Kolichestvo INT,
    Stoimost_blyuda DECIMAL(10, 2),
    FOREIGN KEY (Zakaz_ID) REFERENCES Zakazy(Zakaz_ID),
    FOREIGN KEY (Blyudo_ID) REFERENCES Blyuda(Blyudo_ID)
);


INSERT INTO Klienty (Imya, Familiya, Nomer_telefona)
VALUES 
('Иван', 'Иванов', '123-456-7890'),
('Андрей', 'Попов', '987-654-3210'),
('Елена', 'Новикова', '999-888-7776'),
('Сергей', 'Козлов', '777-555-3332'),
('Ольга', 'Гапонова', '555-444-2228'),
('Максим', 'Федоров', '333-222-1114'),
('Наталья', 'Соколова', '222-111-0000'),
('Иван', 'Петров', '111-000-9996'),
('Мария', 'Смирнова', '123-456-7890'),
('Алексей', 'Сидоров', '111-222-3333');

INSERT INTO Sotrudniki (Imya, Dolzhnost, Zarplata)
VALUES 
('Анна', 'Официант', 40000.00),
('Петр', 'Повар', 80000.00),
('Егор', 'Официант', 40000.00),
('Иван', 'Повар', 80000.00),
('Екатерина', 'Бариста', 50000.00),
('Дмитрий', 'Помощник_повара', 50000.00),
('Ольга', 'Менеджер_по_закупкам', 75000.00),
('Михаил', 'Администратор', 85000.00),
('Петр', 'Шеф-повар', 100000.00),
('Мария', 'Уборщица', 30000.00);
       
INSERT INTO Blyuda (Nazvanie, Opisanie, Cena)
VALUES 
('Паста карбонара', 'Спагетти с беконом и сливочным соусом', 450.00),
('Стейк', 'Говяжий стейк с приправами', 900.00),
('Рыбный плов ', 'Ароматный плов с кусочками свежей рыбы и овощами', 600.00),
('Суп-гаспачо', 'Охлажденный томатный суп с огурцами, перцем и луком', 350.00),
('Пицца Маргарита', ' Традиционная пицца с томатным соусом, моцареллой и свежими помидорами.', 650.00),
('Десерт Тирамису', 'Классический итальянский десерт с маскарпоне, кофе и бисквитом', 400.00),
('Ризотто с креветками', 'Итальянский рис, приготовленный с креветками, шпинатом и пармезаном', 700.00),
('Курица терияки', 'Кусочки курицы, обжаренные в соусе терияки, подается с запеченными овощами', 900.00),
('Фруктовый салат', 'Смесь свежих фруктов с добавлением клубники, киви и мятного сиропа', 400.00),
('Салат Цезарь', 'Салат с курицей, сыром и соусом Цезарь', 550.00);

INSERT INTO Zakazy (Data_zakaza, Status_zakaza, Klient_ID)
VALUES 
('2023-12-23', 'Ожидает обработки', 1),
('2023-12-22', 'Выполнен', 2),
('2023-12-21', 'В процессе', 3),
('2023-12-18', 'Выполнен', 1),
('2023-12-17', 'Ожидает обработки', 2),
('2023-12-16', 'Ожидает обработки', 3),
('2023-12-15', 'Выполнен', 4),
('2023-12-14', 'В процессе', 5);       

INSERT INTO Zakazannye_blyuda (Zakaz_ID, Blyudo_ID, Kolichestvo)
VALUES 
(1, 1, 2),
(2, 3, 1),
(3, 3, 3),
(4, 3, 1),
(5, 4, 2),
(6, 5, 3),
(7, 2, 1),
(8, 6, 2),
(8, 5, 1);

SET SQL_SAFE_UPDATES = 0;

-- Функция для автоматического заполнения сумм заказанных блюд
UPDATE Zakazannye_blyuda zb
JOIN Blyuda b ON zb.Blyudo_ID = b.Blyudo_ID
SET zb.Stoimost_blyuda = b.Cena * zb.Kolichestvo;

-- Функция для заполнения общей стоимости заказа
UPDATE Zakazy z
SET z.Summa_zakaza = (
    SELECT COALESCE(SUM(zb.Stoimost_blyuda), 0)
    FROM Zakazannye_blyuda zb
    WHERE zb.Zakaz_ID = z.Zakaz_ID
);

SET SQL_SAFE_UPDATES = 1;

-- Триггеры на удаление
DELIMITER //

CREATE TRIGGER before_delete_Zakazy
BEFORE DELETE ON Zakazy
FOR EACH ROW
BEGIN
    DECLARE countZakazannye_blyuda INT;
    SELECT COUNT(*) INTO countZakazannye_blyuda FROM Zakazannye_blyuda WHERE Zakaz_ID = OLD.Zakaz_ID;
    IF countZakazannye_blyuda > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Нельзя удалить этот заказ. Существуют связанные записи в таблице Zakazannye_blyuda.';
    END IF;
END//

CREATE TRIGGER before_delete_Blyuda
BEFORE DELETE ON Blyuda
FOR EACH ROW
BEGIN
    DECLARE countZakazannye_blyuda INT;
    SELECT COUNT(*) INTO countZakazannye_blyuda FROM Zakazannye_blyuda WHERE Blyudo_ID = OLD.Blyudo_ID;
    IF countZakazannye_blyuda > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Нельзя удалить это блюдо. Существуют связанные записи в таблице Zakazannye_blyuda.';
    END IF;
END//

DELIMITER ;

-- Триггеры на обновление
DELIMITER //
CREATE TRIGGER zakazy_update BEFORE UPDATE ON Zakazy
FOR EACH ROW 
BEGIN
    DECLARE total DECIMAL(10, 2);
    SELECT COALESCE(SUM(zb.Stoimost_blyuda), 0) INTO total
    FROM Zakazannye_blyuda zb
    WHERE zb.Zakaz_ID = NEW.Zakaz_ID;

    SET NEW.Summa_zakaza = total; -- Обновляем сумму заказа после изменения в Zakazannye_blyuda
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER zakazannye_blyuda_update BEFORE UPDATE ON Zakazannye_blyuda
FOR EACH ROW 
BEGIN
    SET NEW.Stoimost_blyuda = (SELECT b.Cena * NEW.Kolichestvo FROM Blyuda b WHERE b.Blyudo_ID = NEW.Blyudo_ID);
END //
DELIMITER ;

-- Триггеры на добавление

DELIMITER //
CREATE TRIGGER date_insert BEFORE INSERT ON Zakazy
FOR EACH ROW
BEGIN

    IF NEW.Data_zakaza > CURDATE()
    THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data_zakaza не может быть создано в будущем.';
	END IF;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER klienty_insert BEFORE INSERT ON Klienty
FOR EACH ROW 
BEGIN
    DECLARE client_count INT;
    SELECT COUNT(*) INTO client_count FROM Klienty WHERE Klient_ID = NEW.Klient_ID;
    IF client_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Данный Klient_ID уже существует';
    END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER sotrudniki_insert BEFORE INSERT ON Sotrudniki
FOR EACH ROW 
BEGIN
    DECLARE position_count INT;
    SELECT COUNT(*) INTO position_count FROM Sotrudniki WHERE Sotrudnik_ID = NEW.Sotrudnik_ID;
    IF position_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Данный Sotrudnik_ID уже существует';
    END IF;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER blyuda_insert BEFORE INSERT ON Blyuda
FOR EACH ROW 
BEGIN
    IF NEW.Cena < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Цена не может быть отрицательной';
    END IF;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER zakazy_insert BEFORE INSERT ON Zakazy
FOR EACH ROW 
BEGIN
    IF NEW.Summa_zakaza < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сумма заказа не может быть отрицательной';
    END IF;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER zakazannye_blyuda_insert BEFORE INSERT ON Zakazannye_blyuda
FOR EACH ROW 
BEGIN
    IF NEW.Kolichestvo <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Количество должно быть больше 0';
    END IF;
END //
DELIMITER ;

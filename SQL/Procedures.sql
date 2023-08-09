DROP PROCEDURE IF EXISTS delete_by_id $$
DROP PROCEDURE IF EXISTS insert_transaction $$
DROP PROCEDURE IF EXISTS custom_category $$
DROP PROCEDURE IF EXISTS add_account $$
DROP PROCEDURE IF EXISTS delete_account $$
DROP PROCEDURE IF EXISTS delete_category $$
DROP PROCEDURE IF EXISTS check_balance $$
DROP PROCEDURE IF EXISTS Passbook $$
DROP PROCEDURE IF EXISTS category_wise_spending $$
DROP PROCEDURE IF EXISTS monthly_categorywise_spending $$
DROP PROCEDURE IF EXISTS monthwise_spending $$
DROP PROCEDURE IF EXISTS monthwise_income $$
DROP PROCEDURE IF EXISTS monthwise_saving $$
DROP PROCEDURE IF EXISTS search_transaction $$

CREATE PROCEDURE search_transaction(
    IN input_description VARCHAR(50)
) BEGIN 
    SELECT
        *
    FROM 
        `passbook`
    WHERE 
        LOWER(`Description`) LIKE CONCAT('%', LOWER(input_description), '%');
END $$

-- Displays the balance of given account name
CREATE PROCEDURE check_balance (
    IN input_acc_name VARCHAR(30)
) BEGIN 
    SELECT 
        *
    FROM 
        `account balance`
    WHERE 
        `Account Name` = input_acc_name;
END $$

-- Lists all transactions between startdate and enddate;
CREATE PROCEDURE Passbook (
    IN startdate DATE,
    IN enddate DATE
) BEGIN 
    IF (startdate > enddate) THEN
        SIGNAL SQLSTATE '60000' SET MESSAGE_TEXT = 'Invalid dates';
    END IF;

    SELECT 
        * 
    FROM 
        `passbook` 
    WHERE 
        `Date of Transaction` BETWEEN startdate AND enddate;
END $$

-- Gives the category wise spending between startdate and enddate
CREATE PROCEDURE category_wise_spending (
    IN startdate DATE,
    IN enddate DATE
) BEGIN 
    IF (startdate > enddate) THEN
        SIGNAL SQLSTATE '60000' SET MESSAGE_TEXT = 'Invalid dates';
    END IF;

    SELECT 
        category_id AS `Category ID`,
        category_name AS `Category`, 
        IFNULL(sum(amount), 0) AS `Spent`
    FROM 
        transactions JOIN categories USING (category_id) 
    WHERE  
        transaction_type = 'D' AND 
        transactions.tdate BETWEEN startdate AND enddate 
    GROUP BY 
        category_name, category_id
    ORDER BY 
        sum(amount) DESC, category_id;
END $$

CREATE PROCEDURE monthly_categorywise_spending (
    IN startdate DATE,
    IN enddate DATE
) BEGIN 
    IF (startdate > enddate) THEN
        SIGNAL SQLSTATE '60000' SET MESSAGE_TEXT = 'Invalid dates';
    END IF;

    IF (YEAR(enddate) > YEAR(startdate)) THEN
        SELECT 
            `Year`,
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Category`,
            `Spent`
        FROM 
            `monthly expenditure category wise` 
        WHERE 
            `Year` BETWEEN YEAR(startdate) + 1 AND YEAR(enddate) - 1 
            OR (`Year` = YEAR(startdate) AND `Month` >= MONTH(startdate)) 
            OR (`Year` = YEAR(enddate) AND `Month` <= MONTH(enddate));
    ELSE 
        SELECT 
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Category`,
            `Spent`
        FROM 
            `monthly expenditure category wise` 
        WHERE 
            `Year` = YEAR(startdate) AND 
            `Month` BETWEEN MONTH(startdate) AND MONTH(enddate);
    END IF;
END $$

CREATE PROCEDURE monthwise_spending (
    IN startdate DATE,
    IN enddate DATE
) BEGIN 
    IF (startdate > enddate) THEN
        SIGNAL SQLSTATE '60000' SET MESSAGE_TEXT = 'Invalid dates';
    END IF;

    IF (YEAR(enddate) > YEAR(startdate)) THEN
        SELECT 
            `Year`,
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Spent`
        FROM 
            `month wise expenditure` 
        WHERE 
            `Year` BETWEEN YEAR(startdate) + 1 AND YEAR(enddate) - 1 
            OR (`Year` = YEAR(startdate) AND `Month` >= MONTH(startdate))
            OR (`Year` = YEAR(enddate) AND `Month` <= MONTH(enddate));
    ELSE 
        SELECT 
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Spent`
        FROM 
            `month wise expenditure` 
        WHERE 
            `Year` = YEAR(startdate) AND 
            `Month` BETWEEN MONTH(startdate) AND MONTH(enddate);
    END IF;
END $$

CREATE PROCEDURE monthwise_income (
    IN startdate DATE,
    IN enddate DATE
) BEGIN 
    IF (startdate > enddate) THEN
        SIGNAL SQLSTATE '60000' SET MESSAGE_TEXT = 'Invalid dates';
    END IF;

    IF (YEAR(enddate) > YEAR(startdate)) THEN
        SELECT 
            `Year`,
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Income`
        FROM 
            `month wise income` 
        WHERE 
            `Year` BETWEEN YEAR(startdate) + 1 AND YEAR(enddate) - 1 
            OR (`Year` = YEAR(startdate) AND `Month` >= MONTH(startdate))
            OR (`Year` = YEAR(enddate) AND `Month` <= MONTH(enddate));
    ELSE 
        SELECT 
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Income`
        FROM 
            `month wise income` 
        WHERE 
            `Year` = YEAR(startdate) AND 
            `Month` BETWEEN MONTH(startdate) AND MONTH(enddate);
    END IF;
END $$

CREATE PROCEDURE monthwise_saving (
    IN startdate DATE,
    IN enddate DATE
) BEGIN 
    IF (startdate > enddate) THEN
        SIGNAL SQLSTATE '60000' SET MESSAGE_TEXT = 'Invalid dates';
    END IF;

    IF (YEAR(enddate) > YEAR(startdate)) THEN
        SELECT 
            `Year`,
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Savings`
        FROM 
            `monthly savings` 
        WHERE 
            `Year` BETWEEN YEAR(startdate) + 1 AND YEAR(enddate) - 1 
            OR (`Year` = YEAR(startdate) AND `Month` >= MONTH(startdate))
            OR (`Year` = YEAR(enddate) AND `Month` <= MONTH(enddate));
    ELSE 
        SELECT DISTINCT
            MONTHNAME(CONCAT('2000-', `Month`, '-01')) AS `Month`,
            `Savings`
        FROM 
            `monthly savings` 
        WHERE 
            `Year` = YEAR(startdate) AND 
            `Month` BETWEEN MONTH(startdate) AND MONTH(enddate);
    END IF;
END $$

CREATE PROCEDURE delete_by_id(in input_id INT)
BEGIN 
    DELETE 
    FROM transactions
    WHERE transactions.id = input_id;
END $$

CREATE PROCEDURE insert_transaction(
    IN input_date DATE, 
    IN input_desc VARCHAR(50), 
    IN input_categ VARCHAR(30), 
    IN input_amt DECIMAL(10, 2),
    IN input_type VARCHAR(1),
    IN input_account VARCHAR(30)
) BEGIN 
    DECLARE acc_id, cat_id INT;
    
    SET acc_id := (
        SELECT account_id FROM accounts
        WHERE acc_name = input_account
    ); 
    
    IF input_categ IS NOT NULL THEN 
        SET cat_id := (
            SELECT category_id 
            FROM categories 
            WHERE category_name = input_categ
        );
    ELSE 
        SET cat_id := NULL;
    END IF;

    INSERT INTO transactions (
        tdate,
        tdescription,
        category_id,
        amount,
        transaction_type,
        account_id 
    ) VALUES (
        input_date,
        input_desc,
        cat_id,
        input_amt,
        input_type,
        acc_id
    );
END $$ 

CREATE PROCEDURE add_account(
    IN input_acc_name VARCHAR(30), 
    IN input_acc_mode VARCHAR(10)
) BEGIN 
    INSERT INTO accounts 
        (acc_name, mode) 
    VALUES 
        (input_acc_name, input_acc_mode);
END $$

CREATE PROCEDURE custom_category(
    IN input_category VARCHAR(30)
) BEGIN 
    INSERT INTO categories 
        (category_name) 
    VALUES
        (input_category);
END $$

CREATE PROCEDURE delete_account(
    IN input_acc_name VARCHAR(30)
) BEGIN 
    DELETE 
    FROM accounts 
    WHERE accounts.acc_name = input_acc_name;
END $$


CREATE PROCEDURE delete_category(
    IN input_category_name VARCHAR(30)
) BEGIN 
    DELETE 
    FROM categories 
    WHERE categories.category_name = input_category_name;
END $$

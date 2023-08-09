DROP TRIGGER IF EXISTS date_of_transaction $$
DROP TRIGGER IF EXISTS category_of_transaction $$
DROP TRIGGER IF EXISTS change_balance $$
DROP TRIGGER IF EXISTS no_neg_balance $$
DROP TRIGGER IF EXISTS restore_balance $$
DROP TRIGGER IF EXISTS delete_category $$

CREATE TRIGGER date_of_transaction 
BEFORE INSERT ON transactions 
FOR EACH ROW 
BEGIN 
    IF NEW.tdate IS NULL THEN 
        SET NEW.tdate := CURDATE(); 
    END IF; 
END $$ 

CREATE TRIGGER category_of_transaction 
BEFORE INSERT ON transactions 
FOR EACH ROW 
BEGIN 
    IF (NEW.category_id IS NULL) OR (NEW.category_id = 1 AND NEW.transaction_type = 'D') THEN 
        SET NEW.category_id := 18; 
    ELSEIF NEW.transaction_type = 'C' THEN 
        SET NEW.category_id := 1; 
    END IF; 
END $$

CREATE TRIGGER change_balance 
AFTER INSERT ON transactions 
FOR EACH ROW 
BEGIN 
    IF NEW.transaction_type = 'D' THEN 
        UPDATE accounts 
        SET accounts.balance := (balance - NEW.amount) 
        WHERE accounts.account_id = NEW.account_id; 
    ELSEIF NEW.transaction_type = 'C' THEN 
        UPDATE accounts 
        SET balance := (balance + NEW.amount) 
        WHERE accounts.account_id = NEW.account_id; 
    ELSE 
        SIGNAL SQLSTATE '50000' 
        SET MESSAGE_TEXT = 'Incorrect Type of Transaction'; 
    END IF; 
END $$

CREATE TRIGGER no_neg_balance 
BEFORE INSERT ON transactions 
FOR EACH ROW 
BEGIN 
    IF (NEW.amount > (SELECT balance
                     FROM accounts
                     WHERE accounts.account_id = NEW.account_id))
                     AND NEW.transaction_type = 'D' 
        THEN SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Not enough balance';
    END IF;
END $$

CREATE TRIGGER restore_balance 
AFTER DELETE ON transactions 
FOR EACH ROW 
BEGIN 
    IF OLD.transaction_type = 'D' THEN 
        UPDATE accounts 
        SET balance := balance + OLD.amount 
        WHERE accounts.account_id = OLD.account_id;
    ELSEIF OLD.transaction_type = 'C' THEN
        UPDATE accounts 
        SET balance := balance - OLD.amount 
        WHERE accounts.account_id = OLD.account_id;
    END IF;
END $$

-- Didn't use ON DELETE CASCADE because it won't activate
-- `restore_balance` on child rows that were deleted.  
CREATE TRIGGER delete_category 
BEFORE DELETE ON categories 
FOR EACH ROW 
BEGIN 
    DELETE 
    FROM transactions 
    WHERE transactions.category_id = OLD.category_id;
END $$

DROP FUNCTION IF EXISTS TTYPE;

CREATE FUNCTION TTYPE(
    transaction_type VARCHAR(1)
) RETURNS VARCHAR(6) DETERMINISTIC  
BEGIN 
    IF (transaction_type = 'D') THEN 
        RETURN 'Debit';
    ELSE 
        RETURN 'Credit';
    END IF;
END $$
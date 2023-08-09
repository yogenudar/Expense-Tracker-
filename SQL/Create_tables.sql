DROP TABLE IF EXISTS categories, accounts, transactions;

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT,
    category_name VARCHAR(30),
    PRIMARY KEY (category_id)
);

CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT,
    acc_name VARCHAR(30),
    mode VARCHAR(10),
    balance DECIMAL(10, 2) DEFAULT 0,
    CHECK (balance >= 0),
    PRIMARY KEY (account_id)
);

CREATE TABLE transactions (
    id INT AUTO_INCREMENT,
    tdate DATE,
    tdescription VARCHAR(50),
    category_id INT,
    amount DECIMAL(10,2),
    CHECK (amount >= 0),
    transaction_type VARCHAR(1),
    account_id INT,
    CONSTRAINT FK_trans_categ 
    FOREIGN KEY (category_id) 
    REFERENCES categories(category_id),
    CONSTRAINT FK_trans_acc
    FOREIGN KEY (account_id) 
    REFERENCES accounts(account_id) 
    ON DELETE CASCADE,
    PRIMARY KEY (id)
);
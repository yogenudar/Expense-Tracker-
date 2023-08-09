import getpass
import os

from dotenv import load_dotenv
from mysql.connector import connect, connection, MySQLConnection
from mysql.connector.cursor import MySQLCursor
from mysql.connector.errors import ProgrammingError

load_dotenv()

mysql_host = os.getenv('MYSQL_HOST')
mysql_port = os.getenv('MYSQL_port')
debug = os.getenv('DEBUG')
auto_Commit = False if debug != 1 else True

if debug != '1':
    # debug=False
    password = getpass.getpass(prompt='Enter Password')
else:
    password = 'test123'


def first_run():
    global cursor

    cursor.execute('''CREATE DATABASE expenses''')
    cursor.execute('''USE expenses''')

    delimiter: list = [';', '$$', ';', '$$', ';']

    for i, _ in enumerate([
        open('./SQL/Create_tables.sql'),
        open('./SQL/Triggers.sql'),
        open('./SQL/Insert_into.sql'),
        open('./SQL/Procedures.sql'),
        open('./SQL/Views.sql')
    ]):
        for query in _.read().split(delimiter[i]):
            if len(query) != 0:
                cursor.execute(query + ';')

    connection.commit()


connection = connect(
    host=mysql_host,
    user='root',
    passwd=password,
)
connection.autocommit = auto_Commit
cursor = connection.cursor()

try:
    cursor.execute('''USE expenses''')

except ProgrammingError as e:
    if e.errno == 1049:
        first_run()
    else:
        raise e
finally:
    cursor.close()


class Transactions(object):
    def __init__(self, conn: MySQLConnection):
        self.conn = conn
        self.cur: MySQLCursor = conn.cursor()

    def insert_transac(self, date: str, desc: str, category: str, amt: float, amt_type: str, acc: str):
        self.cur.callproc('insert_transaction', [date, desc, category, amt, amt_type, acc])


class Passbook(object):

    def __init__(self, conn: MySQLConnection):
        self.conn = conn
        self.cur: MySQLCursor = conn.cursor()

    # TODO
    def view_transactions(self, **kwargs):
        need_sorted = kwargs.get('sort')
        if need_sorted != None:
            sort_by = kwargs.get('sort_by')


# * Database is named as expenses
# * Inside database are three tables

# * Here is the Schema

# categories (
#     category_id INT AUTO_INCREMENT,
#     category_name VARCHAR(30),
#     PRIMARY KEY (category_id)
# );

# accounts (
#     account_id INT AUTO_INCREMENT,
#     acc_name VARCHAR(30),
#     mode VARCHAR(10),
#     balance DECIMAL(10, 2) DEFAULT 0,
#     CHECK (balance >= 0),
#     PRIMARY KEY (account_id)
# );

"""
transactions (
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
    REFERENCES accounts(account_id),
    PRIMARY KEY (id)
);
"""

# ! We don't Insert to or Query the tables directyly.
# ! The insertion is handled by Stored procedures.

""" 
* PROCEDURE insert_transaction
@param input_date DATE: Date of transaction. If left NULL, it takes current date
@param input_desc VARCHAR(50): Description of transaction
@param input_categ VARCHAR(30): Category of Transaction. 
    IF NULL, it defaults to 'other' for transaction type 'D'. 
    Or 'Income' for transaction type 'C'
@param input_amt DECIMAL(10, 2): Amount for the Transaction
@param input_type VARCHAR(1): Transaction Type
@param input_account VARCHAR(30): Account name for transaction
"""

"""
* PROCEDURE add_account(
@param input_acc_name: New Account name
@param input_acc_mode: New Account mode (cash | card | bank)
"""

"""
* PROCEDURE custom_category(
@param input_category: New cateogry to be created
"""

# ! The Querying is handled through VIEWS

"""
* VIEW `Account Balance`
Gives Result as `Account Name` and `Balance`
TODO Use WHERE Clause to get account balance of only one account
"""

"""
* VIEW Passbook
Shows all transactions in the database formatted and Joined with other tables
TODO Use WHERE clause to limit the outputs to specific dates
"""

"""
* VIEW `Monthly Expenditure Category Wise`
Shows all expenses Grouped by year, then month, then category.
TODO use WHERE clause to show expenditure for a particular year or between specific dates.
"""

"""
* VIEW `Month wise expenditure`
Shows how much money was spent in each month
TODO use WHERE clause to show monthly expenditure from start date to end date
"""

"""
* VIEW `Month wise income`
Shows how much money was Credited in each month
TODO use WHERE clasue to show monthly income from start date to end date
"""

"""
* VIEW `Category wise expenditure`
shows expenditure category wise
TODO use WHERE clause to show category wise expenditure from start date to end date
"""

"""
* VIEW `monthly savings`
shows different between credit and debit grouped by year, then month
TODO use WHERE clause to show monthly savings from start date to end date
"""
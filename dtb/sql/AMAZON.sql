CREATE DATABASE AMAZON;
USE AMAZON;

-- 1. User table:
CREATE TABLE Usr(
    User_ID         VARCHAR(9)  NOT NULL,
    User_name       VARCHAR(50) NOT NULL,          -- khớp bài 1
    Email           VARCHAR(255),
    Hashed_password VARCHAR(255) NOT NULL,         -- khớp bài 1
    Display_name    VARCHAR(255),
    Account_status  CHAR(12)    NOT NULL,
    Created_at      DATE        NOT NULL,
    Updated_at      DATE,
    Phone_number    VARCHAR(20),
    PRIMARY KEY (User_ID),
    CONSTRAINT CHK_User_ID
        CHECK (User_ID REGEXP '^[A-Z0-9]+$')
);

-- 2. Buyer table:
CREATE TABLE Buyer(
    Buyer_ID VARCHAR(9) NOT NULL,
    User_ID  VARCHAR(9) NOT NULL,
    PRIMARY KEY (Buyer_ID),
    CONSTRAINT FK_Buyer_User_ID
        FOREIGN KEY (User_ID) REFERENCES Usr(User_ID),
    -- Check Buyer_ID
    CONSTRAINT CHK_Buyer_ID
        CHECK (Buyer_ID REGEXP '^[A-Z0-9]+$')
);

-- 3. Administrator table:
CREATE TABLE Administrator(
    User_ID   VARCHAR(9)  NOT NULL,
    Previlege VARCHAR(20) NOT NULL,
    PRIMARY KEY (User_ID),
    CONSTRAINT FK_Administrator_User_ID
        FOREIGN KEY (User_ID) REFERENCES Usr(User_ID)
);

-- 17. Category table:
CREATE TABLE Category(
    Category_ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    Hierarchy   VARCHAR(255),
    PRIMARY KEY(Category_ID)
);

-- 15. Product table:
CREATE TABLE Product(
    ASIN            VARCHAR(10)   NOT NULL,
    Product_title   VARCHAR(255),
    Category_ID     INT UNSIGNED          NOT NULL,
    Brand           VARCHAR(20),
    Description     TEXT,
    Manufacturer_ID VARCHAR(9)   NOT NULL,
    Flex_attribute  VARCHAR(255),
    Weight          DECIMAL(6,2),
    Dimensions      TEXT,
    PRIMARY KEY(ASIN),
    CONSTRAINT FK_Product_Category_ID
        FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID),
    -- Check ASIN length & format
    CONSTRAINT CHK_ASIN_Length
        CHECK (CHAR_LENGTH(ASIN) = 10),
    CONSTRAINT CHK_ASIN_Format
        CHECK (ASIN REGEXP '^[A-Z0-9]+$'),
    -- Check Weight
    CONSTRAINT CHK_Weight
        CHECK (Weight IS NULL OR Weight >= 0),
    -- Check Manufacturer_ID
    CONSTRAINT CHK_Manufacturer_ID
        CHECK (Manufacturer_ID REGEXP '^[A-Z0-9]+$')
);

-- 5. Order table:
CREATE TABLE Ordr(
    Order_ID        VARCHAR(9) NOT NULL,
    Buyer_ID        VARCHAR(9) NOT NULL,
    ASIN            VARCHAR(10) NOT NULL,  -- thêm cho khớp bài 1
    Tax_context     VARCHAR(12),
    Shipping_speed  VARCHAR(12),
    PRIMARY KEY (Order_ID),
    CONSTRAINT FK_Ordr_Buyer_ID 
        FOREIGN KEY (Buyer_ID) REFERENCES Buyer(Buyer_ID),
    CONSTRAINT FK_Ordr_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN)
);


-- 6. Cart table:
CREATE TABLE Cart(
    Cart_ID VARCHAR(9) NOT NULL,
    ASIN    VARCHAR(10) NOT NULL,
    Cart_name VARCHAR(255) NULL,
    PRIMARY KEY (Cart_ID),
    CONSTRAINT FK_Cart_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN),
    -- Check Cart_ID
    CONSTRAINT CHK_Cart_ID
        CHECK (Cart_ID REGEXP '^[A-Z0-9]+$')
);

-- 7. Cart Item table:
CREATE TABLE Cart_Item(
    Cart_ID      VARCHAR(9) NOT NULL,
    Cart_Item_ID VARCHAR(9) NOT NULL,
    ASIN         VARCHAR(10) NOT NULL,
    Quantity     INT        DEFAULT 0,
    PRIMARY KEY(Cart_Item_ID),
    CONSTRAINT FK_Cart_Item_Cart_ID
        FOREIGN KEY (Cart_ID) REFERENCES Cart(Cart_ID),
    CONSTRAINT FK_Cart_Item_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN),
    -- Check Cart_Item_ID
    CONSTRAINT CHK_Cart_Item_ID
        CHECK (Cart_Item_ID REGEXP '^[A-Z0-9]+$'),
    -- Check Quantity
    CONSTRAINT CHK_Quantity_Cart_Item
        CHECK (Quantity >= 0)
);

-- 8. Order Item table:
CREATE TABLE Order_Item(
    Order_ID      VARCHAR(9) NOT NULL,
    Order_Item_ID VARCHAR(9) NOT NULL,
    ASIN          VARCHAR(10) NOT NULL,
    Discount      VARCHAR(9),
    Currency      CHAR(3)    NOT NULL,
    Quantity      INT        DEFAULT 0,
    Unit_price    DECIMAL(10,2),
    PRIMARY KEY (Order_Item_ID),
    CONSTRAINT FK_Order_Item_Order_ID
        FOREIGN KEY (Order_ID) REFERENCES Ordr(Order_ID),
    CONSTRAINT FK_Order_Item_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN),
    -- Check Order_Item_ID
    CONSTRAINT CHK_Order_Item_ID
        CHECK (Order_Item_ID REGEXP '^[A-Z0-9]+$'),
    -- Check Quantity
    CONSTRAINT CHK_Quantity_Order_Item
        CHECK (Quantity >= 0),
    -- Check Unit_price
    CONSTRAINT CHK_Unit_price_Order_Item
        CHECK (Unit_price IS NULL OR Unit_price >= 0),
    -- Check Currency
    CONSTRAINT CHK_Order_Item_Currency
        CHECK (Currency IN ('USD','EUR','VND'))
);

-- 10. Product Review table:
CREATE TABLE Product_review(
    Product_review_ID VARCHAR(9) NOT NULL,
    Buyer_ID          VARCHAR(9) NOT NULL,
    ASIN              VARCHAR(10) NOT NULL,
    Star_rating       DECIMAL(2,1),
    Free_text_content TEXT,
    Timestamp         DATETIME,
    Moderation_flag   VARCHAR(9),
    PRIMARY KEY (Product_review_ID),
    CONSTRAINT FK_Product_review_Buyer_ID
        FOREIGN KEY (Buyer_ID) REFERENCES Buyer(Buyer_ID),
    CONSTRAINT FK_Product_review_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN),
    -- Check Product_review_ID
    CONSTRAINT CHK_Product_review_ID
        CHECK (Product_review_ID REGEXP '^[A-Z0-9]+$'),
    -- Check Star_rating: 1..5
    CONSTRAINT CHK_Star_rating
        CHECK (Star_rating IS NULL OR (Star_rating >= 1 AND Star_rating <= 5)),
    -- Check Moderation_flag
    CONSTRAINT CHK_Moderation_flag
        CHECK (Moderation_flag IN ('Pending','Reported','Auto-flagged','Approved','Rejected'))
);

-- 11. Refund table:
CREATE TABLE Refund(
    Refund_ID        VARCHAR(9) NOT NULL,
    Order_ID         VARCHAR(9) NOT NULL,
    Refund_amount    DECIMAL,
    Reason           TEXT,
    Posting_timestamp DATE,
    PRIMARY KEY (Refund_ID),
    CONSTRAINT FK_Refund_Order_ID
        FOREIGN KEY (Order_ID) REFERENCES Ordr(Order_ID),
    -- Check Refund_ID
    CONSTRAINT CHK_Refund_ID
        CHECK (Refund_ID REGEXP '^[A-Z0-9]+$'),
    -- Check Refund_amount
    CONSTRAINT CHK_Refund_amount
        CHECK (Refund_amount IS NULL OR Refund_amount >= 0)
);

-- 12. Seller table:
CREATE TABLE Seller(
    Seller_ID       VARCHAR(9)   NOT NULL,
    Legal_name      VARCHAR(255),
    Storefront_name VARCHAR(255),
    Email           VARCHAR(255),
    Operation_status VARCHAR(9),
    PRIMARY KEY(Seller_ID),
    -- Check Seller_ID
    CONSTRAINT CHK_Seller_ID
        CHECK (Seller_ID REGEXP '^[A-Z0-9]+$'),
    -- Check Legal_name (chỉ chữ cái, đơn giản)
    CONSTRAINT CHK_Legal_name
        CHECK (Legal_name IS NULL OR Legal_name REGEXP '^[A-Za-z]+$'),
    -- Check Operation_status
    CONSTRAINT CHK_Operation_status
        CHECK (Operation_status IN ('ACTIVE','INACTIVE'))
);

-- 13. Offer table:
CREATE TABLE Offer(
    Offer_ID          VARCHAR(9) NOT NULL,
    Seller_ID         VARCHAR(9) NOT NULL,
    Product_review_ID VARCHAR(9),
    ASIN              VARCHAR(10) NOT NULL,
    Item_condition    VARCHAR(20),
    Price             DECIMAL(10,2),
    Currency          CHAR(3)    NOT NULL,
    Fulfill_method    VARCHAR(20),
    Handling_time     INT,
    Inventory_pos     INT,
    PRIMARY KEY (Offer_ID),
    CONSTRAINT FK_Offer_Seller_ID
        FOREIGN KEY (Seller_ID) REFERENCES Seller(Seller_ID),
    CONSTRAINT FK_Offer_Product_review_ID
        FOREIGN KEY (Product_review_ID) REFERENCES Product_review(Product_review_ID),
    CONSTRAINT FK_Offer_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN),
    -- Check Offer_ID
    CONSTRAINT CHK_Offer_ID
        CHECK (Offer_ID REGEXP '^[A-Z0-9]+$'),
    -- Price > 0 (nếu có)
    CONSTRAINT CHK_Offer_Price_Positive
        CHECK (Price IS NULL OR Price > 0),
    -- Inventory không âm
    CONSTRAINT CHK_Offer_Inventory_nonneg
        CHECK (Inventory_pos IS NULL OR Inventory_pos >= 0),
    -- Handling_time không âm
    CONSTRAINT CHK_Offer_Handling_nonneg
        CHECK (Handling_time IS NULL OR Handling_time >= 0),
    -- Currency
    CONSTRAINT CHK_Offer_Currency
        CHECK (Currency IN ('USD','EUR','VND'))
);

-- 14. Product Catalog table:
CREATE TABLE Catalog(
    Catalog_ID   VARCHAR(9)  NOT NULL,
    Catalog_name VARCHAR(12),
    PRIMARY KEY(Catalog_ID),
    -- Check Catalog_ID
    CONSTRAINT CHK_Catalog_ID
        CHECK (Catalog_ID REGEXP '^[A-Z0-9]+$')
);

-- 16. Media Asset table:
CREATE TABLE Media(
    ASIN          VARCHAR(10) NOT NULL PRIMARY KEY,
    Primary_image TEXT, -- saved by URL
    CONSTRAINT FK_Media_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN)
);

-- 18. Wishlist table:
CREATE TABLE Wishlist(
    Wishlist_ID VARCHAR(9) NOT NULL,
    Buyer_ID    VARCHAR(9) NOT NULL,
    PRIMARY KEY (Wishlist_ID),
    CONSTRAINT FK_Wishlist_Buyer_ID
        FOREIGN KEY (Buyer_ID) REFERENCES Buyer(Buyer_ID),
    -- Wishlist_ID phải dạng WIS + 6 chữ số
    CONSTRAINT CHK_Wishlist_ID
        CHECK (Wishlist_ID REGEXP '^WIS[0-9]{6}$')
);


-- 19. Wishlist Item table:
CREATE TABLE Wishlist_item(
    Wishlist_item_ID VARCHAR(9) NOT NULL,
    Wishlist_ID      VARCHAR(9) NOT NULL,
    ASIN             VARCHAR(10) NOT NULL,
    Quantity         INT,
    Priority         INT,
    Short_note       TEXT,
    PRIMARY KEY(Wishlist_item_ID),
    CONSTRAINT FK_Wishlist_item_Wishlist_ID
        FOREIGN KEY(Wishlist_ID) REFERENCES Wishlist(Wishlist_ID),
    CONSTRAINT FK_Wishlist_item_ASIN
        FOREIGN KEY (ASIN) REFERENCES Product(ASIN),
    -- Check Wishlist_item_ID
    CONSTRAINT CHK_Wishlist_item_ID
        CHECK (Wishlist_item_ID REGEXP '^[A-Z0-9]+$'),
    -- Check Quantity
    CONSTRAINT CHK_Quantity_Wishlist_item
        CHECK (Quantity IS NULL OR Quantity >= 0),
    -- Check Priority
    CONSTRAINT CHK_Priority
        CHECK (Priority IS NULL OR Priority >= 0)
);

ALTER TABLE Cart_Item
  ADD COLUMN Offer_ID VARCHAR(9) NULL AFTER ASIN,
  ADD CONSTRAINT FK_Cart_Item_Offer_ID
    FOREIGN KEY (Offer_ID) REFERENCES Offer(Offer_ID),
  ADD CONSTRAINT CHK_Cart_Item_Offer_ID
    CHECK (Offer_ID IS NULL OR Offer_ID REGEXP '^[A-Z0-9]+$');

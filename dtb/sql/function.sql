USE AMAZON;

-- =============================================
-- 1. HELPER FUNCTION: ID GENERATOR
-- Generates random 9-character alphanumeric IDs (A-Z, 0-9)
-- Required because your schema uses VARCHAR(9) IDs.
-- =============================================
DROP FUNCTION IF EXISTS generate_id;
DELIMITER //
CREATE FUNCTION generate_id() 
RETURNS VARCHAR(9)
DETERMINISTIC
BEGIN
    DECLARE chars_str VARCHAR(36) DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE random_id VARCHAR(9) DEFAULT '';
    DECLARE i INT DEFAULT 0;
    
    WHILE i < 9 DO
        SET random_id = CONCAT(random_id, SUBSTRING(chars_str, FLOOR(1 + RAND() * 36), 1));
        SET i = i + 1;
    END WHILE;
    
    RETURN random_id;
END //
DELIMITER ;

-- =============================================
-- 2. FUNCTION: CHECK TOTAL STOCK
-- Returns the total inventory available for a Product (ASIN)
-- across all sellers who are listing it.
-- =============================================
DROP FUNCTION IF EXISTS get_total_stock;
DELIMITER //
CREATE FUNCTION get_total_stock(input_asin VARCHAR(10)) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_qty INT;
    
    SELECT SUM(Inventory_pos) INTO total_qty
    FROM `Offer`
    WHERE ASIN = input_asin 
      AND Inventory_pos > 0;
      
    RETURN IFNULL(total_qty, 0);
END //
DELIMITER ;

-- =============================================
-- 3. PROCEDURE: REGISTER BUYER
-- Creates a new User and Buyer profile.
-- =============================================
DROP PROCEDURE IF EXISTS register_buyer;
DELIMITER //
CREATE PROCEDURE register_buyer(
    IN p_username VARCHAR(50),
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_display_name VARCHAR(255),
    IN p_phone VARCHAR(20)
)
BEGIN
    DECLARE new_user_id VARCHAR(9);
    DECLARE new_buyer_id VARCHAR(9);

    -- Validation: Ensure username/email are not empty
    IF p_username = '' OR p_email = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Username and Email cannot be empty.';
    END IF;

    START TRANSACTION;
        SET new_user_id = generate_id();
        SET new_buyer_id = generate_id();
        
        -- Insert into User table (Table is `Usr` in schema)
        INSERT INTO `Usr` (
            User_ID, User_name, Email, Hashed_password, Display_name, 
            Account_status, Created_at, Updated_at, Phone_number
        ) VALUES (
            new_user_id, p_username, p_email, p_password, p_display_name, 
            'Active', CURDATE(), CURDATE(), p_phone
        );
        
        -- Insert into Buyer table
        INSERT INTO `Buyer` (Buyer_ID, User_ID)
        VALUES (new_buyer_id, new_user_id);
        
    COMMIT;
    
    SELECT 'Success' AS Status, new_user_id AS UserID, new_buyer_id AS BuyerID;
END //
DELIMITER ;

-- =============================================
-- 4. PROCEDURE: FIND TOP RATED PRODUCTS
-- Purpose: Finds products of a specific brand that meet a minimum rating.
-- =============================================
DROP PROCEDURE IF EXISTS find_top_rated_products_by_brand;
DELIMITER //
CREATE PROCEDURE find_top_rated_products_by_brand(
    IN p_brand_name VARCHAR(255),
    IN p_min_rating DECIMAL(2,1)
)
BEGIN
    -- Validation
    IF p_min_rating < 1 OR p_min_rating > 5 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Rating threshold must be between 1 and 5.';
    END IF;

    -- Complex Query
    SELECT 
        p.ASIN,
        p.Product_title,
        AVG(r.Star_rating) AS Average_Rating, 
        COUNT(r.Product_review_ID) AS Total_Reviews
    FROM `Product` p
    JOIN `Product_review` r ON p.ASIN = r.ASIN
    WHERE p.Brand = p_brand_name              
    GROUP BY p.ASIN, p.Product_title           
    HAVING AVG(r.Star_rating) >= p_min_rating  
    ORDER BY Average_Rating DESC;              
END //
DELIMITER ;

-- =============================================
-- 5. PROCEDURE: ADD TO CART
-- Adds items to a cart. Creates the cart if it doesn't exist.
-- =============================================
DROP PROCEDURE IF EXISTS add_to_cart;
DELIMITER //
CREATE PROCEDURE add_to_cart(
    IN p_buyer_id VARCHAR(9),
    IN p_asin VARCHAR(10),
    IN p_quantity INT
)
BEGIN
    DECLARE v_cart_id VARCHAR(9);
    DECLARE v_cart_item_id VARCHAR(9);
    DECLARE v_exists INT DEFAULT 0;
    
    -- Simulate session cart ID for this example
    SET v_cart_id = generate_id(); 
    
    -- Create Cart Header if not exists
    INSERT IGNORE INTO `Cart` (Cart_ID, ASIN) VALUES (v_cart_id, p_asin);

    -- Check if item is already in cart
    SELECT COUNT(*) INTO v_exists 
    FROM `Cart_Item` 
    WHERE Cart_ID = v_cart_id AND ASIN = p_asin;
    
    IF v_exists > 0 THEN
        UPDATE `Cart_Item` 
        SET Quantity = Quantity + p_quantity 
        WHERE Cart_ID = v_cart_id AND ASIN = p_asin;
    ELSE
        SET v_cart_item_id = generate_id();
        INSERT INTO `Cart_Item` (Cart_ID, Cart_Item_ID, ASIN, Quantity)
        VALUES (v_cart_id, v_cart_item_id, p_asin, p_quantity);
    END IF;

    SELECT 'Item Added' AS Message, v_cart_id AS CartID;
END //
DELIMITER ;

-- =============================================
-- 6. PROCEDURE: PLACE ORDER (CHECKOUT)
-- Moves items from Cart -> Order.
-- Checks stock levels and decreases inventory.
-- =============================================
DROP PROCEDURE IF EXISTS place_order;
DELIMITER //
CREATE PROCEDURE place_order(
    IN p_buyer_id VARCHAR(9),
    IN p_cart_id VARCHAR(9),
    IN p_payment_method VARCHAR(12),
    IN p_currency CHAR(3)
)
BEGIN
    DECLARE v_order_id VARCHAR(9);
    DECLARE v_payment_id VARCHAR(9);
    DECLARE v_total_amount INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_asin VARCHAR(10);
    DECLARE v_qty INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_order_item_id VARCHAR(9);
    DECLARE v_stock_available INT;
    DECLARE v_primary_asin VARCHAR(9);

    -- Cursor to loop through cart items
    DECLARE cur_cart CURSOR FOR 
        SELECT ASIN, Quantity FROM `Cart_Item` WHERE Cart_ID = p_cart_id;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SELECT 'Transaction Failed: Order could not be placed.' AS Error;
    END;

    START TRANSACTION;
        
        -- Pick a "Main" ASIN for the Order Header
        SELECT ASIN INTO v_primary_asin FROM `Cart_Item` WHERE Cart_ID = p_cart_id LIMIT 1;
        
        IF v_primary_asin IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cart is empty.';
        END IF;

        SET v_order_id = generate_id();
        
        -- Insert Order Header
        INSERT INTO `Ordr` (Order_ID, Buyer_ID, ASIN, Tax_context, Shipping_speed)
        VALUES (v_order_id, p_buyer_id, v_primary_asin, 'Standard', 'Standard');
        
        -- Process Items
        OPEN cur_cart;
        read_loop: LOOP
            FETCH cur_cart INTO v_asin, v_qty;
            IF done THEN
                LEAVE read_loop;
            END IF;
            
            -- Check Stock
            SET v_stock_available = get_total_stock(v_asin);
            IF v_stock_available < v_qty THEN
                CLOSE cur_cart;
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for one or more items.';
            END IF;
            
            -- Find best price
            SELECT MIN(Price) INTO v_unit_price 
            FROM `Offer` 
            WHERE ASIN = v_asin AND Inventory_pos >= v_qty;
            
            IF v_unit_price IS NULL THEN SET v_unit_price = 0; END IF;

            -- Create Order Item
            SET v_order_item_id = generate_id();
            INSERT INTO `Order_Item` (
                Order_ID, Order_Item_ID, ASIN, Discount, Currency, Quantity, Unit_price
            ) VALUES (
                v_order_id, v_order_item_id, v_asin, '0', p_currency, v_qty, v_unit_price
            );
            
            -- Add to total
            SET v_total_amount = v_total_amount + (v_unit_price * v_qty);
            
            -- Update Inventory
            UPDATE `Offer` 
            SET Inventory_pos = Inventory_pos - v_qty 
            WHERE ASIN = v_asin AND Price = v_unit_price 
            LIMIT 1;
            
        END LOOP;
        CLOSE cur_cart;
        
        -- Create Payment Record (Pending)
        SET v_payment_id = generate_id();
        INSERT INTO `Payment` (
            Payment_ID, Buyer_ID, Order_ID, Payment_method, Amount, Currency, Settlement_status
        ) VALUES (
            v_payment_id, p_buyer_id, v_order_id, p_payment_method, v_total_amount, p_currency, 'Pending'
        );
        
        -- Empty the Cart
        DELETE FROM `Cart_Item` WHERE Cart_ID = p_cart_id;
        DELETE FROM `Cart` WHERE Cart_ID = p_cart_id;
        
    COMMIT;
    
    SELECT 'Order Placed Successfully' AS Status, v_order_id AS OrderID, v_total_amount AS TotalAmount;
END //
DELIMITER ;

-- =============================================
-- 7. PROCEDURE: PROCESS PAYMENT
-- Updates payment status (e.g., simulates a bank callback)
-- =============================================
DROP PROCEDURE IF EXISTS process_payment;
DELIMITER //
CREATE PROCEDURE process_payment(
    IN p_order_id VARCHAR(9),
    IN p_status VARCHAR(12) -- 'Settled', 'Failed'
)
BEGIN
    UPDATE `Payment`
    SET Settlement_status = p_status 
    WHERE Order_ID = p_order_id;
    
    SELECT 'Payment Status Updated' AS Message;
END //
DELIMITER ;

-- =============================================
-- 8. PROCEDURE: CREATE SHIPMENT
-- Ensures payment is 'Settled' before shipping.
-- =============================================
DROP PROCEDURE IF EXISTS create_shipment;
DELIMITER //
CREATE PROCEDURE create_shipment(
    IN p_order_id VARCHAR(9),
    IN p_carrier VARCHAR(12),
    IN p_method VARCHAR(12)
)
BEGIN
    DECLARE v_payment_status VARCHAR(12);
    DECLARE v_shipment_id VARCHAR(9);
    
    -- Check if payment is settled
    SELECT Settlement_status INTO v_payment_status 
    FROM `Payment`
    WHERE Order_ID = p_order_id 
    ORDER BY Amount DESC LIMIT 1;
    
    IF v_payment_status = 'Settled' THEN
        SET v_shipment_id = generate_id();
        
        INSERT INTO `Shipment` (
            Shipment_ID, Order_ID, Ship_date, Carrier_level, Ship_from_method
        ) VALUES (
            v_shipment_id, p_order_id, CURDATE(), p_carrier, p_method
        );
        
        SELECT 'Shipment Created' AS Status, v_shipment_id AS ShipmentID;
    ELSE
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Cannot ship order. Payment is not settled.';
    END IF;
END //
DELIMITER ;

-- =============================================
-- 9. PROCEDURE: REPORT REVENUE BY BRAND
-- Tính tổng doanh thu (Total_Revenue) theo Brand
-- Chỉ tính các Order có Payment.Settlement_status = 'Settled'
-- p_min_revenue: ngưỡng doanh thu tối thiểu để lọc (dùng trong HAVING)
-- =============================================

DROP PROCEDURE IF EXISTS report_revenue;
DELIMITER //
CREATE PROCEDURE report_revenue(
    IN p_min_revenue DECIMAL(18,2)
)
BEGIN
    /*
      Kết quả:
      - Brand
      - total_orders  : số lượng đơn hàng (distinct Order_ID)
      - total_units   : tổng số lượng sản phẩm bán ra
      - total_revenue : tổng doanh thu (Unit_price * Quantity)
    */

    SELECT 
        p.Brand,
        COUNT(DISTINCT o.Order_ID)                      AS total_orders,
        SUM(oi.Quantity)                                AS total_units,
        SUM(oi.Unit_price * oi.Quantity)                AS total_revenue
    FROM Ordr o
    JOIN Order_Item oi ON o.Order_ID = oi.Order_ID
    JOIN Product   p  ON oi.ASIN   = p.ASIN
    JOIN Payment   pay ON pay.Order_ID = o.Order_ID
    WHERE pay.Settlement_status = 'Settled'
    GROUP BY p.Brand
    HAVING SUM(oi.Unit_price * oi.Quantity) >= p_min_revenue
    ORDER BY total_revenue DESC;
END //
DELIMITER ;

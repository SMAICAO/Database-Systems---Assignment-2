-- trigger.sql
-- Triggers cho các semantic constraints của AMAZON

USE AMAZON;

-- ========================================================
-- 0. Thêm cột dẫn xuất cho Order_Item (Line_total)
--    (Quantity * Unit_price)
--    Chạy 1 lần sau khi đã CREATE TABLE Order_Item
-- ========================================================
ALTER TABLE Order_Item
    ADD COLUMN Line_total DECIMAL(18,2) AFTER Unit_price;


DELIMITER $$

/* =========================================================
   1. Derived column: Line_total cho Order_Item
   - Line_total = Quantity * Unit_price
   - BEFORE INSERT + BEFORE UPDATE
   ========================================================= */

CREATE TRIGGER trg_order_item_before_insert_line_total
BEFORE INSERT ON Order_Item
FOR EACH ROW
BEGIN
    IF NEW.Unit_price IS NOT NULL AND NEW.Quantity IS NOT NULL THEN
        SET NEW.Line_total = NEW.Unit_price * NEW.Quantity;
    ELSE
        SET NEW.Line_total = NULL;
    END IF;
END$$


CREATE TRIGGER trg_order_item_before_update_line_total
BEFORE UPDATE ON Order_Item
FOR EACH ROW
BEGIN
    IF NEW.Unit_price IS NOT NULL AND NEW.Quantity IS NOT NULL THEN
        SET NEW.Line_total = NEW.Unit_price * NEW.Quantity;
    ELSE
        SET NEW.Line_total = NULL;
    END IF;
END$$


/* =========================================================
   2. Semantic #1: ASIN stability
   - Không cho đổi ASIN trong Product nếu đã có Order_Item dùng ASIN cũ
   ========================================================= */
CREATE TRIGGER trg_product_asin_stability
BEFORE UPDATE ON Product
FOR EACH ROW
BEGIN
    DECLARE v_cnt INT DEFAULT 0;

    IF NEW.ASIN <> OLD.ASIN THEN
        SELECT COUNT(*) INTO v_cnt
        FROM Order_Item
        WHERE ASIN = OLD.ASIN;

        IF v_cnt > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'ASIN cannot be changed: order items already exist for this product.';
        END IF;
    END IF;
END$$


/* =========================================================
   3. Semantic #7 + #8: Media & Seller gate cho Offer
   - Seller phải đang ACTIVE
   - Product phải có ít nhất 1 Media.Primary_image
   ========================================================= */

-- BEFORE INSERT ON Offer
CREATE TRIGGER trg_offer_before_insert_gate
BEFORE INSERT ON Offer
FOR EACH ROW
BEGIN
    DECLARE v_status      VARCHAR(9);
    DECLARE v_media_count INT DEFAULT 0;

    -- Seller phải đang ACTIVE
    SELECT MAX(Operation_status)
    INTO v_status
    FROM Seller
    WHERE Seller_ID = NEW.Seller_ID;

    IF v_status IS NULL OR v_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot create offer: seller is not ACTIVE.';
    END IF;

    -- Product phải có ít nhất 1 Primary_image
    SELECT COUNT(*)
    INTO v_media_count
    FROM Media
    WHERE ASIN = NEW.ASIN
      AND Primary_image IS NOT NULL;

    IF v_media_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot create offer: product has no primary image.';
    END IF;
END$$


-- BEFORE UPDATE ON Offer
CREATE TRIGGER trg_offer_before_update_gate
BEFORE UPDATE ON Offer
FOR EACH ROW
BEGIN
    DECLARE v_status      VARCHAR(9);
    DECLARE v_media_count INT DEFAULT 0;

    -- Seller phải đang ACTIVE
    SELECT MAX(Operation_status)
    INTO v_status
    FROM Seller
    WHERE Seller_ID = NEW.Seller_ID;

    IF v_status IS NULL OR v_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot update offer: seller is not ACTIVE.';
    END IF;

    -- Product phải có ít nhất 1 Primary_image
    SELECT COUNT(*)
    INTO v_media_count
    FROM Media
    WHERE ASIN = NEW.ASIN
      AND Primary_image IS NOT NULL;

    IF v_media_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot update offer: product has no primary image.';
    END IF;
END$$


USE AMAZON;

DELIMITER $$

-- Trigger tự sinh Wishlist_ID = 'WIS' + số tăng dần (WIS000001, WIS000002, ...)
DROP TRIGGER IF EXISTS trg_wishlist_before_insert $$
CREATE TRIGGER trg_wishlist_before_insert
BEFORE INSERT ON Wishlist
FOR EACH ROW
BEGIN
    DECLARE v_next INT;

    -- Nếu người dùng không truyền Wishlist_ID thì tự generate
    IF NEW.Wishlist_ID IS NULL OR NEW.Wishlist_ID = '' THEN
        -- Lấy số lớn nhất hiện có rồi + 1
        SELECT IFNULL(
            MAX(CAST(SUBSTRING(Wishlist_ID, 4) AS UNSIGNED)),
            0
        ) + 1
        INTO v_next
        FROM Wishlist;

        SET NEW.Wishlist_ID = CONCAT('WIS', LPAD(v_next, 6, '0'));
    END IF;
END $$
DELIMITER ;


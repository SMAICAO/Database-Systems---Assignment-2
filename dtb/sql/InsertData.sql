USE AMAZON;

INSERT INTO Usr (User_ID, User_name, Email, Hashed_password, Display_name, Account_status, Created_at, Updated_at, Phone_number) VALUES
('U00000001', 'AliceNguyen', 'alice.n@mail.com', 'a$2b*d3g', 'Alice N', 'Active', '2024-01-01', NULL, '0987654321'),
('U00000002', 'BobTran', 'bob.t@mail.com', 'b!b@p3ss', 'Bob T', 'Active', '2024-01-05', NULL, '0123456789'),
('U00000003', 'CharlieAdmin', 'charlie.a@mail.com', 'Adm!n#P@ss', 'Charlie A', 'Active', '2024-01-10', NULL, '0901234567'),
('U00000004', 'DavidLe', 'david.l@mail.com', 'Pwd#4567', 'David L', 'Active', '2024-01-15', NULL, '0898765432'),
('U00000005', 'EvePhan', 'eve.p@mail.com', 'S_Pass_789', 'Eve P', 'Active', '2024-01-20', NULL, '0777123456'),
('U00000006', 'FrankAdmin', 'frank.a@mail.com', 'Adm!n#P@ss2', 'Frank A', 'Active', '2024-02-01', NULL, '0976543210'),
('U00000007', 'GraceHoang', 'grace.h@mail.com', 'G_Pwd_123', 'Grace H', 'Active', '2024-02-05', NULL, '0865432109'),
('U00000008', 'HankSeller', 'hank.s@mail.com', 'H_Pass_321', 'Hank S', 'Active', '2024-02-10', NULL, '0954321098'),
('U00000009', 'IvyVo', 'ivy.v@mail.com', 'IvyPass!@#', 'Ivy V', 'Active', '2024-02-15', NULL, '0843210987'),
('U00000010', 'JackCao', 'jack.c@mail.com', 'JackP@ss$', 'Jack C', 'Banned', '2024-02-20', '2024-03-01', '0732109876'),
('U00000011', 'KimBuyer', 'kim.b@mail.com', 'K_pwd_2024', 'Kim B', 'Active', '2024-03-01', NULL, '0912345678'),
('U00000012', 'LeoSeller', 'leo.s@mail.com', 'L_sellerP', 'Leo', 'Active', '2024-03-05', NULL, '0923456789'),
('U00000013', 'MiaBuyer', 'mia.m@mail.com', 'M_secure!', 'Mia M', 'Pending', '2024-03-10', NULL, '0934567890'),
('U00000014', 'NoahBuyer', 'noah.n@mail.com', 'N_passwrd', 'Noah N', 'Active', '2024-03-15', NULL, '0945678901'),
('U00000015', 'OliviaSeller', 'olivia.o@mail.com', 'O_secure@', 'Olivia O', 'Active', '2024-03-20', NULL, '0956789012'),
('U00000016', 'PaulBuyer', 'paul.p@mail.com', 'P_pwd_100', 'Paul P', 'Active', '2024-03-25', NULL, '0967890123'),
('U00000017', 'QuinnSeller', 'quinn.q@mail.com', 'Q_seller1!', 'Quinn',  'Active', '2024-04-01', NULL, '0978901234'),
('U00000018', 'RyanBuyer', 'ryan.r@mail.com', 'R_pass!', 'Ryan R', 'Active', '2024-04-05', NULL, '0989012345'),
('U00000019', 'SaraBuyer', 'sara.s@mail.com', 'S_secure*', 'Sara S', 'Active', '2024-04-10', NULL, '0990123456'),
('U00000020', 'TomSeller', 'tom.t@mail.com', 'T_seller!', 'Tom', 'Active', '2024-04-15', NULL, '0901234560');

INSERT INTO Buyer (Buyer_ID, User_ID) VALUES
('B00000001', 'U00000001'), -- AliceNguyen
('B00000002', 'U00000004'), -- DavidLe
('B00000003', 'U00000007'), -- GraceHoang
('B00000004', 'U00000009'), -- IvyVo
('B00000005', 'U00000010'), -- JackCao (Banned)
('B00000006', 'U00000011'), -- KimBuyer
('B00000007', 'U00000013'), -- MiaBuyer (Pending)
('B00000008', 'U00000014'), -- NoahBuyer
('B00000009', 'U00000016'), -- PaulBuyer
('B00000010', 'U00000018'), -- RyanBuyer
('B00000011', 'U00000019'); -- SaraBuyer

INSERT INTO Seller (Seller_ID, Legal_name, Storefront_name, Email, Operation_status) VALUES
('S00000001', 'BobCompany', 'Bob_Tech_Store', 'bob.t@mail.com', 'ACTIVE'),
('S00000002', 'EveCorp', 'Eve_Fashion', 'eve.p@mail.com', 'ACTIVE'),
('S00000003', 'HankLLC', 'Hank_Sports', 'hank.s@mail.com', 'ACTIVE'),
('S00000004', 'LeoTrading', 'Leo Gadgets', 'leo.s@mail.com', 'ACTIVE'),
('S00000005', 'OliviaGoods', 'Olivia Home', 'olivia.o@mail.com', 'ACTIVE'),
('S00000006', 'TomInc', 'Tom Electronics', 'tom.t@mail.com', 'ACTIVE');

INSERT INTO Category (Hierarchy) VALUES
('Clothes'),
('Furniture'),
('Books'),
('Shoes'),
('Tech'),
('kitchen');

INSERT INTO Product (ASIN, Product_title, Category_ID, Brand, Description, Manufacturer_ID, Flex_attribute, Weight, Dimensions) VALUES
('B0B1S9J3W1', 'Laptop Pro X', 5, 'TechBrand', 'High-performance laptop.', 'MAN000001', 'Color:Black,Storage:512GB', 2.50, '35x24x1.5 cm'),
('B0C4K8H2G1', 'The Great Novel', 3, 'PubHouse', 'A classic novel.', 'MAN000002', 'Paperback', 0.50, '20x13x2 cm'),
('B0D2L7P5T1', 'Smart Watch 2.0', 5, 'GadgetCo', 'Fitness tracking watch.', 'MAN000001', 'Color:Silver', 0.10, '4x4x1 cm'),
('B0E5M6Q9R1', 'Cozy Fleece Blanket', 2, 'SoftHome', 'Warm fleece blanket.', 'MAN000003', 'Material:Fleece', 1.20, '150x200 cm'),
('B0F6N7S0U1', 'Running Shoe X', 4, 'SportMax', 'Lightweight running shoes.', 'MAN000004', 'Size:42', 0.80, '30x10x15 cm'),
('B0G7P8T1V1', 'Cotton T-Shirt', 1, 'FashionWear', '100% Cotton T-Shirt.', 'MAN000005', 'Size:L,Color:Blue', 0.20, '30x25x2 cm'),
('B0H8Q9U2W1', 'Wireless Mouse', 5, 'TechBrand', 'Ergonomic wireless mouse.', 'MAN000001', 'Color:Grey', 0.10, '10x6x3 cm'),
('B0I9R0V3X1', 'Yoga Mat Pro', 2, 'SportMax', 'High-density foam mat.', 'MAN000004', 'Color:Green', 1.50, '180x60x0.6 cm'),
('B0J0S1W4Y1', 'Coffee Mug Set', 6, 'OliviaGoods', 'Set of 4 ceramic mugs.', 'MAN000006', 'Color:White', 1.80, '10x10x12 cm'),
('B0K1T2X5Z1', 'Summer Dress', 1, 'FashionWear', 'Light summer cotton dress.', 'MAN000005', 'Size:M,Color:Yellow', 0.30, '60x40x2 cm');

INSERT INTO Ordr (Order_ID, Buyer_ID, ASIN, Tax_context, Shipping_speed) VALUES
('ORD000001', 'B00000001', 'B0B1S9J3W1', 'StandardTax', 'Express'),
('ORD000002', 'B00000004', 'B0F6N7S0U1', 'StandardTax', 'Standard'),
('ORD000003', 'B00000003', 'B0G7P8T1V1', 'LowTax', 'Standard'),
('ORD000004', 'B00000006', 'B0J0S1W4Y1', 'StandardTax', 'OneDay'),
('ORD000005', 'B00000008', 'B0D2L7P5T1', 'StandardTax', 'Standard');

INSERT INTO Order_Item (Order_ID, Order_Item_ID, ASIN, Discount, Currency, Quantity, Unit_price) VALUES
('ORD000001', 'OI0000001', 'B0B1S9J3W1', '0%', 'USD', 1, 1200.00),
('ORD000001', 'OI0000002', 'B0H8Q9U2W1', '5%', 'USD', 1, 25.00),
('ORD000002', 'OI0000003', 'B0F6N7S0U1', '0%', 'USD', 2, 75.00),
('ORD000003', 'OI0000004', 'B0G7P8T1V1', '10%', 'USD', 3, 20.00),
('ORD000004', 'OI0000005', 'B0J0S1W4Y1', '0%', 'USD', 1, 18.00),
('ORD000004', 'OI0000006', 'B0C4K8H2G1', '0%', 'USD', 1, 15.50),
('ORD000005', 'OI0000007', 'B0D2L7P5T1', '0%', 'USD', 1, 99.99),
('ORD000005', 'OI0000008', 'B0I9R0V3X1', '15%', 'USD', 1, 45.00),
('ORD000002', 'OI0000009', 'B0E5M6Q9R1', '0%', 'USD', 1, 35.00),
('ORD000003', 'OI0000010', 'B0K1T2X5Z1', '0%', 'USD', 1, 40.00);

INSERT INTO Product_review (Product_review_ID, Buyer_ID, ASIN, Star_rating, Free_text_content, Timestamp, Moderation_flag) VALUES
('PR0000001', 'B00000001', 'B0B1S9J3W1', 4.5, 'Best laptop ever!', '2024-01-10 10:00:00', 'Approved'),
('PR0000002', 'B00000004', 'B0F6N7S0U1', 5.0, 'Nice shoes!', '2024-02-01 15:30:00', 'Approved'),
('PR0000003', 'B00000006', 'B0J0S1W4Y1', 3.0, 'Smaller than expected.', '2024-03-10 11:00:00', 'Pending'),
('PR0000004', 'B00000003', 'B0G7P8T1V1', 4.0, 'Well cotton shirt. Fast delivery!', '2024-02-20 09:00:00', 'Approved'),
('PR0000005', 'B00000001', 'B0C4K8H2G1', 5.0, 'Must read!', '2024-01-15 14:00:00', 'Approved');

INSERT INTO Offer (Offer_ID, Seller_ID, Product_review_ID, ASIN, Item_condition, Price, Currency, Fulfill_method,Handling_time, Inventory_pos) VALUES
    ('OFR000001', 'S00000001', 'PR0000001', 'B0B1S9J3W1', 'New',        1200.00, 'USD', 'FBA', 1, 150),
    ('OFR000002', 'S00000002', 'PR0000005', 'B0C4K8H2G1', 'Used-Good',    15.50, 'USD', 'FBM', 2,  50),
    ('OFR000003', 'S00000004', NULL,        'B0D2L7P5T1', 'New',          99.99, 'USD', 'FBA', 1, 300),
    ('OFR000004', 'S00000005', NULL,        'B0E5M6Q9R1', 'New',          35.00, 'USD', 'FBM', 3,  20),
    ('OFR000005', 'S00000003', 'PR0000002', 'B0F6N7S0U1', 'New',          75.00, 'USD', 'FBA', 1,  80),
    ('OFR000006', 'S00000002', 'PR0000004', 'B0G7P8T1V1', 'New',          20.00, 'USD', 'FBM', 2, 120),
    ('OFR000007', 'S00000001', NULL,        'B0H8Q9U2W1', 'New',          25.00, 'USD', 'FBA', 1, 400),
    ('OFR000008', 'S00000003', NULL,        'B0I9R0V3X1', 'New',          45.00, 'USD', 'FBA', 1,  90),
    ('OFR000009', 'S00000005', 'PR0000003', 'B0J0S1W4Y1', 'New',          18.00, 'USD', 'FBM', 3,  70),
    ('OFR000010', 'S00000002', NULL,        'B0K1T2X5Z1', 'New',          40.00, 'USD', 'FBM', 2,  60),

    ('OFR000011', 'S00000002', 'PR0000002', 'B0B1S9J3W1', 'New',        1180.00, 'USD', 'FBM', 2, 100),
    ('OFR000012', 'S00000001', NULL,        'B0C4K8H2G1', 'Used-Good',    14.90, 'USD', 'FBA', 1,  80),
    ('OFR000013', 'S00000005', NULL,        'B0D2L7P5T1', 'New',          95.00, 'USD', 'FBM', 3, 200),
    ('OFR000014', 'S00000003', 'PR0000001', 'B0E5M6Q9R1', 'New',          33.50, 'USD', 'FBA', 1,  40),
    ('OFR000015', 'S00000001', 'PR0000003', 'B0F6N7S0U1', 'New',          72.00, 'USD', 'FBM', 2, 120),
    ('OFR000016', 'S00000005', NULL,        'B0G7P8T1V1', 'New',          19.00, 'USD', 'FBA', 1, 150),
    ('OFR000017', 'S00000002', NULL,        'B0H8Q9U2W1', 'New',          24.50, 'USD', 'FBM', 2, 350),
    ('OFR000018', 'S00000004', 'PR0000004', 'B0I9R0V3X1', 'New',          42.00, 'USD', 'FBA', 1, 110),
    ('OFR000019', 'S00000003', NULL,        'B0J0S1W4Y1', 'New',          17.50, 'USD', 'FBM', 3,  90),
    ('OFR000020', 'S00000001', 'PR0000005', 'B0K1T2X5Z1', 'New',          38.90, 'USD', 'FBA', 1,  75);




INSERT INTO Wishlist (Wishlist_ID, Buyer_ID) VALUES
('WIS000001', 'B00000001'),
('WIS000002', 'B00000002'),
('WIS000003', 'B00000007'),
('WIS000004', 'B00000010'),
('WIS000005', 'B00000011');

INSERT INTO Wishlist_item (Wishlist_item_ID, Wishlist_ID, ASIN, Quantity, Priority, Short_note) VALUES
('WI0000001', 'WIS000001', 'B0D2L7P5T1', 1, 1, 'High priority'),
('WI0000002', 'WIS000001', 'B0J0S1W4Y1', 2, 2, 'For new house'),
('WI0000003', 'WIS000002', 'B0B1S9J3W1', 1, 1, 'Old laptop'),
('WI0000004', 'WIS000002', 'B0C4K8H2G1', 1, 3, NULL),
('WI0000005', 'WIS000003', 'B0F6N7S0U1', 1, 1, 'Need for exercise'),
('WI0000006', 'WIS000003', 'B0G7P8T1V1', 4, 2, NULL),
('WI0000007', 'WIS000004', 'B0H8Q9U2W1', 1, 1, NULL),
('WI0000008', 'WIS000004', 'B0K1T2X5Z1', 1, 2, NULL),
('WI0000009', 'WIS000005', 'B0E5M6Q9R1', 1, 1, 'Gift'),
('WI0000010', 'WIS000005', 'B0I9R0V3X1', 1, 2, NULL);


INSERT INTO Administrator (User_ID, Previlege) VALUES
('U00000003', 'Superuser'),
('U00000006', 'Moderator');

INSERT INTO Media (ASIN, Primary_image) VALUES
('B0B1S9J3W1', 'http://amazon.com/images/B0B1S9J3W1_1.jpg'),
('B0C4K8H2G1', 'http://amazon.com/images/B0C4K8H2G1_1.jpg'),
('B0D2L7P5T1', 'http://amazon.com/images/B0D2L7P5T1_1.jpg'),
('B0F6N7S0U1', 'http://amazon.com/images/B0F6N7S0U1_1.jpg'),
('B0J0S1W4Y1', 'http://amazon.com/images/B0J0S1W4Y1_1.jpg');

INSERT INTO Catalog (Catalog_ID, Catalog_name) VALUES
('C00000001', 'Tech'),
('C00000002', 'Fashion');

ALTER USER 'sManager'@'localhost'
IDENTIFIED BY 'MyStrongPass123';

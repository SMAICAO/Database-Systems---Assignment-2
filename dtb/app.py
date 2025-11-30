from flask import Flask, render_template, request, redirect, url_for, flash, session
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)
app.secret_key = "change-me-to-something-secret"

DB_NAME = "AMAZON"
DB_HOST = "localhost"


# =========================
# Helpers
# =========================
def get_db_connection():
    """
    Kết nối MySQL bằng user/password đang lưu trong session.
    Phải login trước mới gọi được.
    """
    if "db_user" not in session or "db_pass" not in session:
        raise RuntimeError("Not logged in")

    return mysql.connector.connect(
        host=DB_HOST,
        user=session["db_user"],
        password=session["db_pass"],
        database=DB_NAME
    )


def fetch_categories():
    """Lấy list category cho dropdown trong form Product."""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT Category_ID, Hierarchy FROM Category ORDER BY Category_ID")
    categories = cursor.fetchall()
    cursor.close()
    conn.close()
    return categories


def validate_product_form(form, is_edit=False):
    """
    Kiểm tra dữ liệu product trước khi insert/update.
    Trả về (clean_data, errors)
    """
    errors = []

    asin = form.get("asin", "").strip()
    title = form.get("title", "").strip()
    category_id = form.get("category_id", "").strip()
    brand = form.get("brand", "").strip()
    description = form.get("description", "").strip()
    manufacturer_id = form.get("manufacturer_id", "").strip()
    flex_attribute = form.get("flex_attribute", "").strip()
    weight_str = form.get("weight", "").strip()
    dimensions = form.get("dimensions", "").strip()

    # ASIN: bắt buộc, 10 ký tự, dạng A-Z0-9 (khi tạo mới)
    if not is_edit:
        if not asin:
            errors.append("ASIN is required.")
        elif len(asin) != 10:
            errors.append("ASIN phải đúng 10 ký tự.")
        elif not asin.isalnum() or not asin.isupper():
            errors.append("ASIN chỉ được chứa chữ in hoa và số (A-Z, 0-9).")



    # Title
    if not title:
        errors.append("Product title is required.")

    # Category
    if not category_id:
        errors.append("Category_ID is required.")

    # Manufacturer_ID
    if not manufacturer_id:
        errors.append("Manufacturer_ID is required.")

    # Weight
    weight = None
    if weight_str:
        try:
            weight = float(weight_str)
            if weight < 0:
                errors.append("Weight phải >= 0.")
        except ValueError:
            errors.append("Weight must be a number.")

    clean_data = {
        "asin": asin,
        "title": title,
        "category_id": category_id,
        "brand": brand,
        "description": description,
        "manufacturer_id": manufacturer_id,
        "flex_attribute": flex_attribute,
        "weight": weight,
        "dimensions": dimensions,
    }

    return clean_data, errors


# =========================
# Auth
# =========================

@app.route("/")
def index():
    if "db_user" in session:
        return redirect(url_for("product_list"))
    return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    error = None

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "").strip()

        try:
            conn = mysql.connector.connect(
                host=DB_HOST,
                user=username,
                password=password,
                database=DB_NAME
            )
            conn.close()

            # Lưu thông tin user vào session
            session["db_user"] = username
            session["db_pass"] = password
            flash("Login successed!", "success")
            return redirect(url_for("product_list"))

        except Error as e:
            error = f"Login fail: {e}"

    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    session.clear()
    flash("logout successed.", "info")
    return redirect(url_for("login"))


# =========================
# Product list + CRUD
# =========================

@app.route("/products")
def product_list():
    if "db_user" not in session:
        return redirect(url_for("login"))

    search = request.args.get("q", "").strip()
    category_filter = request.args.get("category", "").strip()
    sort = request.args.get("sort", "title_asc")

    sort_map = {
        "title_asc": "p.Product_title ASC",
        "title_desc": "p.Product_title DESC",
        "brand_asc": "p.Brand ASC",
        "brand_desc": "p.Brand DESC",
        "weight_asc": "p.Weight ASC",
        "weight_desc": "p.Weight DESC",
    }
    order_clause = sort_map.get(sort, "p.Product_title ASC")

    # Query products với ảnh từ Media
    query = """
        SELECT
            p.ASIN,
            p.Product_title,
            m.Primary_image
        FROM Product p
        LEFT JOIN Media m ON p.ASIN = m.ASIN
        LEFT JOIN Category c ON p.Category_ID = c.Category_ID
        WHERE 1=1
    """
    params = []

    if search:
        query += " AND p.Product_title LIKE %s"
        params.append("%" + search + "%")

    if category_filter:
        query += " AND p.Category_ID = %s"
        params.append(category_filter)

    query += f" ORDER BY {order_clause}"

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(query, params)
    products = cursor.fetchall()

    # Categories cho filter (giữ nguyên)
    cursor.execute("SELECT Category_ID, Hierarchy FROM Category ORDER BY Category_ID")
    categories = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "product_list.html",
        products=products,
        categories=categories,
        search=search,
        category_filter=category_filter,
        sort=sort,
    )



@app.route("/products/new", methods=["GET", "POST"])
def product_create():
    if "db_user" not in session:
        return redirect(url_for("login"))

    categories = fetch_categories()

    if request.method == "POST":
        data, errors = validate_product_form(request.form, is_edit=False)
        primary_image = request.form.get("primary_image", "").strip()
        if errors:
            for e in errors:
                flash(e, "danger")
            data["primary_image"] = primary_image  # Để giữ giá trị khi lỗi
            return render_template("product_form.html", product=data, categories=categories, is_edit=False)

        conn = None
        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            insert_sql = """
                INSERT INTO Product
                (ASIN, Product_title, Category_ID, Brand, Description,
                 Manufacturer_ID, Flex_attribute, Weight, Dimensions)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """

            cursor.execute(
                insert_sql,
                (
                    data["asin"],
                    data["title"],
                    data["category_id"],
                    data["brand"],
                    data["description"],
                    data["manufacturer_id"],
                    data["flex_attribute"],
                    data["weight"],
                    data["dimensions"],
                ),
            )

            # Insert Media nếu có primary_image
            if primary_image:
                cursor.execute(
                    """
                    INSERT INTO Media (ASIN, Primary_image)
                    VALUES (%s, %s)
                    """,
                    (data["asin"], primary_image),
                )

            conn.commit()
            cursor.close()
            conn.close()

            flash("Created product successfully.", "success")
            return redirect(url_for("product_list"))

        except Error as e:
            if conn:
                conn.rollback()
                conn.close()
            flash(f"Lỗi khi insert product: {e}", "danger")

    # GET
    empty_product = {
        "asin": "",
        "title": "",
        "category_id": "",
        "brand": "",
        "description": "",
        "manufacturer_id": "",
        "flex_attribute": "",
        "weight": "",
        "dimensions": "",
        "primary_image": "",
    }
    return render_template("product_form.html", product=empty_product, categories=categories, is_edit=False)

@app.route("/carts/add-offer/<offer_id>", methods=["GET", "POST"])
def cart_add_offer(offer_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Lấy thông tin offer + product để hiển thị
    cursor.execute(
        """
        SELECT 
            o.Offer_ID,
            o.ASIN,
            o.Price,
            o.Currency,
            o.Item_condition,
            o.Fulfill_method,
            o.Handling_time,
            o.Inventory_pos,
            s.Seller_ID,
            s.Storefront_name,
            p.Product_title
        FROM Offer o
        JOIN Seller  s ON o.Seller_ID = s.Seller_ID
        JOIN Product p ON o.ASIN      = p.ASIN
        WHERE o.Offer_ID = %s
        """,
        (offer_id,),
    )
    offer = cursor.fetchone()

    if not offer:
        cursor.close()
        conn.close()
        flash("Offer not found.", "danger")
        return redirect(url_for("product_list"))

    # Nếu submit form -> xử lý thêm vào cart
    if request.method == "POST":
        quantity_str = (request.form.get("quantity") or "1").strip()
        mode = request.form.get("cart_mode", "new")
        existing_cart_id = (request.form.get("existing_cart_id") or "").strip()
        cart_name = (request.form.get("cart_name") or "").strip()

        try:
            quantity = int(quantity_str)
        except ValueError:
            quantity = 0

        if quantity <= 0:
            flash("Quantity phải là số nguyên dương.", "danger")
        elif quantity > offer["Inventory_pos"]:
            flash("Quantity lớn hơn tồn kho của offer này.", "danger")
        else:
            try:
                # Lấy / tạo Cart_ID
                cursor2 = conn.cursor(dictionary=True)

                cart_id = None

                if mode == "existing" and existing_cart_id:
                    cursor2.execute(
                        "SELECT Cart_ID, Cart_name FROM Cart WHERE Cart_ID = %s",
                        (existing_cart_id,),
                    )
                    row = cursor2.fetchone()
                    if row:
                        cart_id = row["Cart_ID"]
                    else:
                        flash("warning")

                # Nếu chưa có -> tạo cart mới
                if not cart_id:
                    cursor2.execute("SELECT generate_id() AS id")
                    cart_id = cursor2.fetchone()["id"]

                    cursor2.execute(
                        "INSERT INTO Cart (Cart_ID, ASIN, Cart_name) VALUES (%s, %s, %s)",
                        (cart_id, offer["ASIN"], cart_name or None),
                    )

                # Xem trong cart này đã có cùng Offer_ID chưa
                cursor2.execute(
                    """
                    SELECT Cart_Item_ID, Quantity
                    FROM Cart_Item
                    WHERE Cart_ID = %s AND Offer_ID = %s
                    """,
                    (cart_id, offer["Offer_ID"]),
                )
                existing_item = cursor2.fetchone()

                if existing_item:
                    new_qty = existing_item["Quantity"] + quantity
                    cursor2.execute(
                        "UPDATE Cart_Item SET Quantity = %s WHERE Cart_Item_ID = %s",
                        (new_qty, existing_item["Cart_Item_ID"]),
                    )
                else:
                    cursor2.execute("SELECT generate_id() AS id")
                    cart_item_id = cursor2.fetchone()["id"]

                    cursor2.execute(
                        """
                        INSERT INTO Cart_Item (Cart_ID, Cart_Item_ID, ASIN, Offer_ID, Quantity)
                        VALUES (%s, %s, %s, %s, %s)
                        """,
                        (cart_id, cart_item_id, offer["ASIN"], offer["Offer_ID"], quantity),
                    )

                conn.commit()
                cursor2.close()
                cursor.close()
                conn.close()

                flash(
                    f"Added {quantity} item from Offer {offer_id} to cart {cart_id}.",
                    "success",
                )
                return redirect(url_for("cart_detail", cart_id=cart_id))

            except Error as e:
                conn.rollback()
                flash(f"error when add: {e}", "danger")

    # Nếu GET (hoặc POST lỗi) -> load list cart hiện có cho dropdown
    cursor.execute(
        """
        SELECT  
            c.Cart_ID,
            c.Cart_name,
            COUNT(ci.Cart_Item_ID) AS Item_count,
            SUM(ci.Quantity * COALESCE(o.Price, 0)) AS Total_amount
        FROM Cart c
        LEFT JOIN Cart_Item ci ON c.Cart_ID = ci.Cart_ID
        LEFT JOIN Offer     o ON ci.Offer_ID = o.Offer_ID
        GROUP BY c.Cart_ID, c.Cart_name
        ORDER BY c.Cart_ID
        """
    )
    carts = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "cart_add_offer.html",
        offer=offer,
        carts=carts,
    )


@app.route("/products/<asin>/edit", methods=["GET", "POST"])
def product_edit(asin):
    if "db_user" not in session:
        return redirect(url_for("login"))

    categories = fetch_categories()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT * FROM Product WHERE ASIN = %s",
        (asin,)
    )
    product = cursor.fetchone()
    cursor.close()
    conn.close()

    if not product:
        flash("Product not found.", "danger")
        return redirect(url_for("product_list"))

    if request.method == "POST":
        data, errors = validate_product_form(request.form, is_edit=True)
        # giữ lại ASIN gốc
        data["asin"] = asin

        if errors:
            for e in errors:
                flash(e, "danger")
            return render_template("product_form.html", product=data, categories=categories, is_edit=True)

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            update_sql = """
                UPDATE Product
                SET Product_title = %s,
                    Category_ID    = %s,
                    Brand          = %s,
                    Description    = %s,
                    Manufacturer_ID = %s,
                    Flex_attribute = %s,
                    Weight         = %s,
                    Dimensions     = %s
                WHERE ASIN = %s
            """

            cursor.execute(
                update_sql,
                (
                    data["title"],
                    data["category_id"],
                    data["brand"],
                    data["description"],
                    data["manufacturer_id"],
                    data["flex_attribute"],
                    data["weight"],
                    data["dimensions"],
                    asin,
                ),
            )
            conn.commit()
            cursor.close()
            conn.close()

            flash("Updated product successfully.", "success")
            return redirect(url_for("product_list"))

        except Error as e:
            flash(f"error when update product: {e}", "danger")

    # GET render form với data
    # map key cho phù hợp với template (product_form đang dùng)
    mapped = {
        "asin": product["ASIN"],
        "title": product["Product_title"],
        "category_id": product["Category_ID"],
        "brand": product["Brand"],
        "description": product["Description"],
        "manufacturer_id": product["Manufacturer_ID"],
        "flex_attribute": product["Flex_attribute"],
        "weight": product["Weight"],
        "dimensions": product["Dimensions"],
    }

    return render_template("product_form.html", product=mapped, categories=categories, is_edit=True)


@app.route("/products/<asin>/delete", methods=["POST"])
def product_delete(asin):
    if "db_user" not in session:
        return redirect(url_for("login"))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM Product WHERE ASIN = %s", (asin,))
        conn.commit()
        cursor.close()
        conn.close()
        flash("Deleted product successfully.", "success")
    except Error as e:
        flash(f"error delete product: {e}", "danger")

    return redirect(url_for("product_list"))


# =========================
# Cart list + detail
# =========================

@app.route("/carts")
def cart_list():
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        """
        SELECT 
            c.Cart_ID,
            c.Cart_name,
            COUNT(ci.Cart_Item_ID) AS Item_count,
            SUM(ci.Quantity * COALESCE(o.Price, 0)) AS Total_amount
        FROM Cart c
        LEFT JOIN Cart_Item ci ON c.Cart_ID = ci.Cart_ID
        LEFT JOIN Offer     o ON ci.Offer_ID = o.Offer_ID
        GROUP BY c.Cart_ID, c.Cart_name
        ORDER BY c.Cart_ID
        """
    )
    carts = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("cart_list.html", carts=carts)

@app.route("/carts/<cart_id>/edit", methods=["GET", "POST"])
def cart_edit(cart_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT Cart_ID, Cart_name FROM Cart WHERE Cart_ID = %s",
        (cart_id,),
    )
    cart = cursor.fetchone()

    if not cart:
        cursor.close()
        conn.close()
        flash("Cart not found.", "danger")
        return redirect(url_for("cart_list"))

    if request.method == "POST":
        cart_name = (request.form.get("cart_name") or "").strip()

        cursor.execute(
            "UPDATE Cart SET Cart_name = %s WHERE Cart_ID = %s",
            (cart_name or None, cart_id),
        )
        conn.commit()
        cursor.close()
        conn.close()

        flash("Updated cart name.", "success")
        return redirect(url_for("cart_list"))

    cursor.close()
    conn.close()

    return render_template("cart_edit.html", cart=cart)

@app.route("/carts/<cart_id>")
def cart_detail(cart_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT Cart_ID, Cart_name FROM Cart WHERE Cart_ID = %s",
        (cart_id,),
    )
    cart = cursor.fetchone()

    if not cart:
        cursor.close()
        conn.close()
        flash("Cart not found.", "danger")
        return redirect(url_for("cart_list"))

    cursor.execute(
        """
        SELECT 
            ci.Cart_Item_ID,
            ci.ASIN,
            p.Product_title,
            ci.Quantity,
            ci.Offer_ID,
            o.Price,
            o.Currency,
            o.Seller_ID,
            s.Storefront_name,
            (ci.Quantity * COALESCE(o.Price, 0)) AS Line_total
        FROM Cart_Item ci
        JOIN Product p ON ci.ASIN = p.ASIN
        LEFT JOIN Offer  o ON ci.Offer_ID = o.Offer_ID
        LEFT JOIN Seller s ON o.Seller_ID   = s.Seller_ID
        WHERE ci.Cart_ID = %s
        ORDER BY ci.Cart_Item_ID
        """,
        (cart_id,),
    )
    items = cursor.fetchall()

    total_amount = 0
    currency = None
    for it in items:
        if it["Line_total"] is not None:
            total_amount += it["Line_total"]
        if not currency and it["Currency"]:
            currency = it["Currency"]

    cursor.close()
    conn.close()

    return render_template(
        "cart_detail.html",
        cart=cart,
        items=items,
        total_amount=total_amount,
        currency=currency or "USD",
    )
@app.route("/carts/<cart_id>/delete", methods=["POST"])
def cart_delete(cart_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor()  # không cần dictionary

    try:
        # Kiểm tra cart tồn tại không
        cursor.execute("SELECT Cart_ID FROM Cart WHERE Cart_ID = %s", (cart_id,))
        row = cursor.fetchone()
        if not row:
            cursor.close()
            conn.close()
            flash("Cart not found.", "warning")
            return redirect(url_for("cart_list"))

        # Xoá tất cả cart item thuộc cart này
        cursor.execute("DELETE FROM Cart_Item WHERE Cart_ID = %s", (cart_id,))
        # Xoá cart
        cursor.execute("DELETE FROM Cart WHERE Cart_ID = %s", (cart_id,))

        conn.commit()
        flash("Deleted cart successfully.", "success")

    except Error as e:
        conn.rollback()
        flash(f"error when delete cart: {e}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("cart_list"))

# =========================
# Wishlist list + detail
# =========================

@app.route("/wishlists")
def wishlist_list():
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # List tất cả wishlist + info buyer + user
    cursor.execute(
        """
        SELECT 
            w.Wishlist_ID,
            w.Buyer_ID,
            u.User_name,
            u.Display_name,
            COUNT(wi.Wishlist_item_ID) AS Item_count
        FROM Wishlist w
        JOIN Buyer b       ON w.Buyer_ID = b.Buyer_ID
        JOIN Usr   u       ON b.User_ID = u.User_ID
        LEFT JOIN Wishlist_item wi ON w.Wishlist_ID = wi.Wishlist_ID
        GROUP BY 
            w.Wishlist_ID, w.Buyer_ID, u.User_name, u.Display_name
        ORDER BY w.Wishlist_ID
        """
    )
    wishlists = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("wishlist_list.html", wishlists=wishlists)


@app.route("/wishlists/<wishlist_id>")
def wishlist_detail(wishlist_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Header: thông tin wishlist + buyer + user
    cursor.execute(
        """
        SELECT 
            w.Wishlist_ID,
            w.Buyer_ID,
            u.User_name,
            u.Display_name,
            COUNT(wi.Wishlist_item_ID) AS Item_count
        FROM Wishlist w
        JOIN Buyer b ON w.Buyer_ID = b.Buyer_ID
        JOIN Usr   u ON b.User_ID = u.User_ID
        LEFT JOIN Wishlist_item wi ON w.Wishlist_ID = wi.Wishlist_ID
        WHERE w.Wishlist_ID = %s              -- lọc đúng wishlist đang xem
          AND u.Account_status <> 'Banned'    -- dùng u.Account_status, không phải b.
        GROUP BY w.Wishlist_ID, w.Buyer_ID, u.User_name, u.Display_name
        """,
        (wishlist_id,),
    )
    header = cursor.fetchone()

    # Items: join Product để xem tên sản phẩm
    cursor.execute("""
        SELECT 
            wi.Wishlist_item_ID,
            wi.ASIN,
            wi.Priority,
            wi.Short_note,
            p.Product_title
        FROM Wishlist_item wi
        LEFT JOIN Product p ON wi.ASIN = p.ASIN
        WHERE wi.Wishlist_ID = %s
        ORDER BY wi.Wishlist_item_ID
    """, (wishlist_id,))
    items = cursor.fetchall()

    cursor.close()
    conn.close()

    if not header:
        flash("Wishlist not found.", "danger")
        return redirect(url_for("wishlist_list"))

    return render_template(
        "wishlist_detail.html",
        header=header,
        items=items,
    )


# =========================
# Buyer list + registration (call stored procedure register_buyer)
# =========================

@app.route("/buyers")
def buyer_list():
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        """
        SELECT 
            b.Buyer_ID,
            u.User_ID,
            u.User_name,
            u.Email,
            u.Display_name,
            u.Phone_number,
            u.Account_status,
            u.Created_at
        FROM Buyer b
        JOIN Usr u ON b.User_ID = u.User_ID
        ORDER BY b.Buyer_ID
        """
    )
    buyers = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("buyer_list.html", buyers=buyers)


@app.route("/buyers/register", methods=["GET", "POST"])
def buyer_register():
    if "db_user" not in session:
        return redirect(url_for("login"))

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        email = request.form.get("email", "").strip()
        password = request.form.get("password", "").strip()
        display_name = request.form.get("display_name", "").strip()
        phone = request.form.get("phone", "").strip()

        if not username or not email or not password:
            flash("Username, Email và Password là bắt buộc.", "danger")
        else:
            try:
                conn = get_db_connection()
                cursor = conn.cursor(dictionary=True)

                # Gọi stored procedure register_buyer
                cursor.callproc(
                    "register_buyer",
                    [username, email, password, display_name, phone],
                )

                result = None
                for res in cursor.stored_results():
                    result = res.fetchone()

                conn.commit()
                cursor.close()
                conn.close()

                if result and result.get("Status") == "Success":
                    flash(
                        f"successed. User_ID: {result['UserID']}, Buyer_ID: {result['BuyerID']}",
                        "success",
                    )
                    return redirect(url_for("buyer_list"))
                else:
                    flash(
                        "warning",
                    )

            except Error as e:
                # Nếu procedure SIGNAL lỗi (trùng username/email, v.v.) sẽ nhảy vào đây
                flash(f"error: {e}", "danger")

    # GET hoặc POST lỗi → render lại form
    return render_template("buyer_register.html")

@app.route("/buyers/<buyer_id>/edit", methods=["GET", "POST"])
def buyer_edit(buyer_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    # Lấy thông tin buyer + user
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT 
            b.Buyer_ID,
            u.User_ID,
            u.User_name,
            u.Email,
            u.Display_name,
            u.Phone_number,
            u.Account_status,
            u.Created_at
        FROM Buyer b
        JOIN Usr u ON b.User_ID = u.User_ID
        WHERE b.Buyer_ID = %s
        """,
        (buyer_id,),
    )
    buyer = cursor.fetchone()
    cursor.close()
    conn.close()

    if not buyer:
        flash("Buyer not found.", "danger")
        return redirect(url_for("buyer_list"))

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        email = request.form.get("email", "").strip()
        display_name = request.form.get("display_name", "").strip()
        phone = request.form.get("phone", "").strip()
        status = request.form.get("status", "").strip()

        if not username or not email:
            flash("Username và Email là bắt buộc.", "danger")
            # cập nhật lại giá trị mới user vừa nhập để show lại
            buyer["User_name"] = username
            buyer["Email"] = email
            buyer["Display_name"] = display_name
            buyer["Phone_number"] = phone
            buyer["Account_status"] = status or buyer["Account_status"]
            return render_template("buyer_edit.html", buyer=buyer)

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            cursor.execute(
                """
                UPDATE Usr
                SET User_name    = %s,
                    Email        = %s,
                    Display_name = %s,
                    Phone_number = %s,
                    Account_status = %s
                WHERE User_ID = %s
                """,
                (
                    username,
                    email,
                    display_name or None,
                    phone or None,
                    status or buyer["Account_status"],
                    buyer["User_ID"],
                ),
            )

            conn.commit()
            cursor.close()
            conn.close()

            flash("Updated buyer successfully.", "success")
            return redirect(url_for("buyer_list"))

        except Error as e:
            # ví dụ trùng username/email sẽ vào đây
            flash(f"error when update buyer: {e}", "danger")
            buyer["User_name"] = username
            buyer["Email"] = email
            buyer["Display_name"] = display_name
            buyer["Phone_number"] = phone
            buyer["Account_status"] = status or buyer["Account_status"]
            return render_template("buyer_edit.html", buyer=buyer)

    # GET
    return render_template("buyer_edit.html", buyer=buyer)


@app.route("/buyers/<buyer_id>/delete", methods=["POST"])
def buyer_delete(buyer_id):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Lấy User_ID để tí nữa xóa luôn trong Usr (nếu được)
    cursor.execute(
        "SELECT Buyer_ID, User_ID FROM Buyer WHERE Buyer_ID = %s",
        (buyer_id,),
    )
    buyer = cursor.fetchone()

    if not buyer:
        cursor.close()
        conn.close()
        flash("Buyer not found.", "warning")
        return redirect(url_for("buyer_list"))

    user_id = buyer["User_ID"]

    # Kiểm tra ràng buộc: nếu buyer đã có Order/Wishlist/Review thì không cho xóa cứng
    cursor.execute("SELECT COUNT(*) AS cnt FROM Ordr WHERE Buyer_ID = %s", (buyer_id,))
    has_orders = cursor.fetchone()["cnt"] > 0

    cursor.execute("SELECT COUNT(*) AS cnt FROM Wishlist WHERE Buyer_ID = %s", (buyer_id,))
    has_wishlists = cursor.fetchone()["cnt"] > 0

    cursor.execute(
        "SELECT COUNT(*) AS cnt FROM Product_review WHERE Buyer_ID = %s",
        (buyer_id,),
    )
    has_reviews = cursor.fetchone()["cnt"] > 0

    if has_orders or has_wishlists or has_reviews:
        cursor.close()
        conn.close()
        flash(
            "danger",
        )
        return redirect(url_for("buyer_list"))

    # Nếu không có ràng buộc → xoá Buyer + Usr
    try:
        # Xóa Buyer trước (bị tham chiếu bởi các bảng khác)
        cursor.execute("DELETE FROM Buyer WHERE Buyer_ID = %s", (buyer_id,))
        # Xóa luôn bản ghi user nếu không còn dùng
        cursor.execute("DELETE FROM Usr WHERE User_ID = %s", (user_id,))

        conn.commit()
        flash("Deleted buyer successfully.", "success")
    except Error as e:
        conn.rollback()
        flash(f"error when delete buyer: {e}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("buyer_list"))

# =========================
# Report – Revenue (call stored procedure report_revenue)
# =========================

@app.route("/reports/revenue", methods=["GET", "POST"])
def report_revenue():
    if "db_user" not in session:
        return redirect(url_for("login"))

    rows = []
    error = None

    # đọc min_revenue từ form, default = 0
    min_revenue_str = "0"
    if request.method == "POST":
        min_revenue_str = request.form.get("min_revenue", "0").strip()

    try:
        min_revenue_val = float(min_revenue_str)
    except ValueError:
        min_revenue_val = 0.0
        error = "Min revenue không hợp lệ, dùng 0 thay thế."

    if error is None:
        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)

            # Gọi stored procedure report_revenue(IN p_min_revenue DECIMAL)
            cursor.callproc("report_revenue", [min_revenue_val])

            for result in cursor.stored_results():
                rows = result.fetchall()

            cursor.close()
            conn.close()

        except Error as e:
            error = f"error when stored procedure report_revenue: {e}"

    return render_template(
        "report_revenue.html",
        rows=rows,
        min_revenue=min_revenue_str,
        error=error,
    )

@app.route("/wishlists/add-item/<asin>", methods=["GET", "POST"])
def wishlist_add_item(asin):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # 1. Kiểm tra product tồn tại
    cursor.execute(
        "SELECT ASIN, Product_title FROM Product WHERE ASIN = %s",
        (asin,),
    )
    product = cursor.fetchone()

    if not product:
        cursor.close()
        conn.close()
        flash("Product not found.", "danger")
        return redirect(url_for("product_list"))

    errors = []

    if request.method == "POST":
        wishlist_id = (request.form.get("wishlist_id") or "").strip()
        priority_str = (request.form.get("priority") or "").strip()
        note = (request.form.get("note") or "").strip()

        if not wishlist_id:
            errors.append("Please choose a wishlist.")

        # Priority (optional)
        priority = None
        if priority_str:
            try:
                priority = int(priority_str)
            except ValueError:
                errors.append("Priority must be an integer between 1 and 5.")
            else:
                if priority < 1 or priority > 5:
                    errors.append("Priority must be between 1 and 5.")

        # Check wishlist tồn tại
        if not errors:
            cursor.execute(
                """
                SELECT w.Wishlist_ID
                FROM Wishlist w
                JOIN Buyer b ON w.Buyer_ID = b.Buyer_ID
                WHERE w.Wishlist_ID = %s
                AND u.Account_status <> 'Banned'
                """,
                (wishlist_id,),
            )
            wl = cursor.fetchone()
            if not wl:
                errors.append("Wishlist not found.")

        if not errors:
            try:
                # Xem item này đã tồn tại trong wishlist chưa
                cursor.execute(
                    """
                    SELECT Wishlist_item_ID
                    FROM Wishlist_item
                    WHERE Wishlist_ID = %s AND ASIN = %s
                    """,
                    (wishlist_id, asin),
                )
                item = cursor.fetchone()

                if item:
                    # Đã có rồi: chỉ cập nhật priority / note, không đụng Quantity
                    cursor.execute(
                        """
                        UPDATE Wishlist_item
                        SET Priority = %s,
                            Short_note = %s
                        WHERE Wishlist_item_ID = %s
                        """,
                        (priority, note or None, item["Wishlist_item_ID"]),
                    )
                    msg = "Updated wishlist item."
                else:
                    # Chưa có: tạo mới, Quantity mặc định = 1
                    cursor.execute("SELECT generate_id() AS id")
                    witem_id = cursor.fetchone()["id"]

                    cursor.execute(
                        """
                        INSERT INTO Wishlist_item
                            (Wishlist_item_ID, Wishlist_ID, ASIN,
                             Quantity, Priority, Short_note)
                        VALUES (%s, %s, %s, %s, %s, %s)
                        """,
                        (witem_id, wishlist_id, asin,
                         1, priority, note or None),
                    )
                    msg = "Added product to wishlist."

                conn.commit()
                cursor.close()
                conn.close()

                flash(msg, "success")
                return redirect(url_for("wishlist_detail", wishlist_id=wishlist_id))

            except Error as e:
                conn.rollback()
                errors.append(f"error when add to wishlist: {e}")

        for msg in errors:
            flash(msg, "danger")

    # 2. Load list wishlist cho dropdown
    cursor.execute(
        """
        SELECT 
            w.Wishlist_ID,
            w.Buyer_ID,
            u.User_name,
            u.Display_name,
            COUNT(wi.Wishlist_item_ID) AS Item_count
        FROM Wishlist w
        JOIN Buyer b ON w.Buyer_ID = b.Buyer_ID
        JOIN Usr   u ON b.User_ID = u.User_ID
        LEFT JOIN Wishlist_item wi ON w.Wishlist_ID = wi.Wishlist_ID
        GROUP BY w.Wishlist_ID, w.Buyer_ID, u.User_name, u.Display_name
        ORDER BY w.Wishlist_ID
        """
    )
    wishlists = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "wishlist_add_item.html",
        product=product,
        wishlists=wishlists,
    )

@app.route("/products/<asin>")
def product_detail(asin):
    if "db_user" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Query thông tin sản phẩm + category + media (ảnh)
    cursor.execute(
        """
        SELECT 
            p.ASIN, p.Product_title, p.Brand, p.Description, p.Weight, p.Dimensions,
            c.Hierarchy AS Category_Hierarchy,
            m.Primary_image
        FROM Product p
        LEFT JOIN Category c ON p.Category_ID = c.Category_ID
        LEFT JOIN Media m ON p.ASIN = m.ASIN
        WHERE p.ASIN = %s
        """,
        (asin,),
    )
    product = cursor.fetchone()

    if not product:
        cursor.close()
        conn.close()
        flash("Product not found.", "danger")
        return redirect(url_for("product_list"))

    # Query offers (giống trước, nhưng không cần selected_asin)
    cursor.execute(
        """
        SELECT
            o.Offer_ID, o.Seller_ID, s.Storefront_name, s.Operation_status,
            o.Item_condition, o.Price, o.Currency, o.Fulfill_method,
            o.Handling_time, o.Inventory_pos
        FROM Offer o
        LEFT JOIN Seller s ON o.Seller_ID = s.Seller_ID
        WHERE o.ASIN = %s
        ORDER BY o.Price ASC
        """,
        (asin,),
    )
    offers = cursor.fetchall()

    # Query reviews (join để lấy tên reviewer)
    cursor.execute(
        """
        SELECT 
            pr.Product_review_ID, pr.Star_rating, pr.Free_text_content, pr.Timestamp,
            COALESCE(u.Display_name, u.User_name) AS Reviewer_name
        FROM Product_review pr
        JOIN Buyer b ON pr.Buyer_ID = b.Buyer_ID
        JOIN Usr u ON b.User_ID = u.User_ID
        WHERE pr.ASIN = %s
        ORDER BY pr.Timestamp DESC
        """,
        (asin,),
    )
    reviews = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "product_detail.html",
        product=product,
        offers=offers,
        reviews=reviews
    )
if __name__ == "__main__":
    app.run(debug=True, port=5001)

# qr_backend/api.py
import os
import hashlib
import base64
import json
import qrcode
import secrets
import jwt
import datetime
from io import BytesIO
from functools import wraps
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from nacl.signing import SigningKey, VerifyKey
from nacl.exceptions import BadSignatureError 
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import exc as sa_exc # Used for handling database exceptions
from blockchain_service import BlockchainService

blockchain = BlockchainService()

app = Flask(__name__)


# ======================================================
# CONFIGURATION & DB INIT
# ======================================================

# ⚠️ Use an Environment Variable in production!
SECRET_KEY = "supersecretkey123" 
TOKEN_EXPIRATION_DAYS = 7
ADMIN_EMAIL = "admin@qr.com"
QR_SIGNER_KEY = "secret_ed25519.key" # Loaded/created separately

SALT_LENGTH = 16
# Cannot use this directly with the DB, but keep the logic for fixed admin
ADMIN_PASSWORD_SALT = "f0a3b2c1d4e5f6a7b8c9d0e1f2a3b4c5"
ADMIN_PASSWORD_HASH = hashlib.sha256(("admin123" + ADMIN_PASSWORD_SALT).encode()).hexdigest()

QRS_FOLDER = os.path.join(os.getcwd(), "qrs")
os.makedirs(QRS_FOLDER, exist_ok=True)

# ⚠️ Database Setup
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///qr_system.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)


# ======================================================
# DB MODELS
# ======================================================

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, index=True, nullable=False)
    password_hash = db.Column(db.String(64), nullable=False)
    salt = db.Column(db.String(32), nullable=False)
    phone_number = db.Column(db.String(20))
    public_key = db.Column(db.Text) 

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.String(64), unique=True, index=True)
    manufacturer_id = db.Column(db.String(64))
    category = db.Column(db.String(64))
    country = db.Column(db.String(8))
    chain = db.Column(db.String(64))
    nonce = db.Column(db.String(16)) # Nonce added to be stored from generation process

class Ownership(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.String(64), unique=True)
    owner_name = db.Column(db.String(120))
    owner_public_key = db.Column(db.Text)

class ActivityLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    action_type = db.Column(db.String(64))
    user_email = db.Column(db.String(120))
    product_id = db.Column(db.String(64))
    scan_status = db.Column(db.String(32))
    message = db.Column(db.Text)

class TempTransfer(db.Model):
    __tablename__ = 'temp_transfers'
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.String(64), unique=True, nullable=False)
    challenge = db.Column(db.Text, nullable=False)
    seller_pub = db.Column(db.Text, nullable=True)
    seller_name = db.Column(db.String(120), nullable=False)
    buyer_name = db.Column(db.String(120), nullable=False)
    buyer_pub = db.Column(db.Text, nullable=False)
    seller_verified = db.Column(db.Boolean, default=False)
    seller_signature = db.Column(db.Text, nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)


# ======================================================
# CRYPTOGRAPHIC & GENERAL HELPERS
# ======================================================

def b64e(b: bytes) -> str:
    """Standard Base64 encode."""
    return base64.b64encode(b).decode()

def b64d(s: str) -> bytes:
    """Standard Base64 decode."""
    return base64.b64decode(s)

def b64u(b):
    """URL-safe Base64 encode."""
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def b64u_dec(s):
    """URL-safe Base64 decode."""
    s += "=" * ((4 - len(s) % 4) % 4)
    return base64.urlsafe_b64decode(s)


def canonical(v, c, pid, mid, co, n, chain):
    """Creates the canonical message string for hashing and signing."""
    return "|".join([v, c.lower(), pid, mid, co.upper(), n, chain])

def load_signing_key():
    """Loads the Ed25519 secret key from the file."""
    try:
        with open(QR_SIGNER_KEY, "rb") as f:
            signing_key = SigningKey(f.read())  # Read the secret key from the file
        return signing_key
    except Exception as e:
        print(f"Error loading signing key: {e}")
        return None

def verify_payload(obj: dict):
    """Verifies the QR code payload's signature and nonce against the DB."""
    required = ["v", "category", "pid", "mid", "co", "n", "chain", "sig", "pub"]
    for k in required:
        if k not in obj:
            raise ValueError(f"Missing field: {k}")

    msg = canonical(obj["v"], obj["category"], obj["pid"], obj["mid"],
                    obj["co"], obj["n"], obj["chain"])

    # Nonce and Product ID Check against DB
    product_record = Product.query.filter_by(product_id=obj["pid"]).first()
    if not product_record or product_record.nonce != obj["n"]:
          raise ValueError("QR Nonce mismatch or product not found.")

    digest = hashlib.sha256(msg.encode()).digest()

    # Use the public key loaded from the `secreted.key` file
    try:
        signing_key = load_signing_key()  # Load the secret key
        verify_key = signing_key.verify_key  # Get the public key
        
        pub_from_qr_bytes = b64u_dec(obj["pub"])
        expected_pub_bytes = verify_key.encode()
        
        # Public Key Mismatch Check
        if pub_from_qr_bytes != expected_pub_bytes:
            raise ValueError("Public key mismatch.")
            
        # Verify signature using the public key
        VerifyKey(pub_from_qr_bytes).verify(digest, b64u_dec(obj["sig"])) 
    except Exception as e:
        raise ValueError(f"Verification failed: {str(e)}")

    return True


def verify_signature(public_key_b64, challenge, signature_b64):
    """Utility: verifies an Ed25519 signature."""
    try:
        pub = b64d(public_key_b64)
        sig = b64d(signature_b64)
        vk = VerifyKey(pub)
        vk.verify(challenge.encode(), sig)
        return True
    except BadSignatureError:
        return False
    except Exception:
        return False

def hash_password(password: str, salt: str = None):
    """Hashes a password with a salt. Generates new salt if none provided."""
    if salt is None:
        salt = secrets.token_hex(SALT_LENGTH)
    hashed = hashlib.sha256((password + salt).encode()).hexdigest()
    return hashed, salt

def create_token(user_email: str, user_name: str, is_admin: bool = False) -> str:
    """Creates a JWT token."""
    payload = {
        "sub": user_email,
        "name": user_name,
        "is_admin": is_admin,
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=TOKEN_EXPIRATION_DAYS)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

# ======================================================
# AUTH DECORATORS (Unchanged logic)
# ======================================================



def admin_required(f):
    """Decorator to require an authenticated admin user."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not token:
            return jsonify({"status": "error", "message": "Authentication token is missing."}), 401
        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            if not data.get("is_admin"):
                return jsonify({"status": "error", "message": "Unauthorized: Admin privileges required."}), 403
            request.current_user = data
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return jsonify({"status": "error", "message": "Invalid or expired token."}), 401
        except Exception:
              return jsonify({"status": "error", "message": "Token decoding failed."}), 401
        return f(*args, **kwargs)
    return decorated

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):

        if request.method == "OPTIONS":
            response = jsonify({})
            response.headers.add("Access-Control-Allow-Origin", "*")
            response.headers.add("Access-Control-Allow-Headers", "Content-Type,Authorization")
            response.headers.add("Access-Control-Allow-Methods", "POST,GET,OPTIONS")
            return response, 200

        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not token:
            return jsonify({"status": "error", "message": "Authentication token is missing."}), 401

        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            request.current_user = data
        except Exception:
            return jsonify({"status": "error", "message": "Invalid or expired token."}), 401

        return f(*args, **kwargs)
    return decorated

@app.route("/seller_accept", methods=["OPTIONS"])
def seller_accept_options():
    response = jsonify({})
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add("Access-Control-Allow-Headers", "Content-Type,Authorization")
    response.headers.add("Access-Control-Allow-Methods", "POST,OPTIONS")
    return response, 200


# ======================================================
# DB HELPERS (Rewritten for SQLAlchemy)
# ======================================================

def is_product_registered(pid):
    """Checks if a product is in the DB and returns the Product object or None."""
    return Product.query.filter_by(product_id=pid).first()

def get_user_by_email(email):
    """Retrieves a User object by email."""
    return User.query.filter_by(email=email).first()

def db_save_user(name: str, email: str, password_hash: str, phone_number: str, salt: str, public_key: str):
    """Saves a new user to the DB."""
    try:
        new_user = User(
            name=name,
            email=email.lower(),
            password_hash=password_hash,
            phone_number=phone_number,
            salt=salt,
            public_key=public_key 
        )
        db.session.add(new_user)
        db.session.commit()
        return True
    except sa_exc.IntegrityError:
        db.session.rollback()
        return False
    except Exception:
        db.session.rollback()
        return False

def db_update_user_password(email: str, new_hash: str):
    """Updates a user's password hash in the DB."""
    user = get_user_by_email(email)
    if user:
        user.password_hash = new_hash
        try:
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            return False
    return False

def db_update_user_profile(email_to_find, updates):
    """Updates a user's name and phone number in the DB."""
    user = get_user_by_email(email_to_find)
    if user:
        try:
            # Concatenate first and last name
            full_name = f"{updates.get('first_name', '')} {updates.get('last_name', '')}".strip()
            if full_name:
                user.name = full_name
            user.phone_number = updates.get('phone_number', user.phone_number)
            
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            return False
    return False

# ----------------- Activity Log Helpers -----------------
def log_activity(action_type: str, user_email: str = "", product_id: str = "", scan_status: str = "", message: str = ""):
    """Logs an activity to the DB."""
    try:
        new_log = ActivityLog(
            action_type=action_type,
            user_email=user_email,
            product_id=product_id,
            scan_status=scan_status,
            message=message
        )
        db.session.add(new_log)
        db.session.commit()
    except Exception as e:
        print(f"Error logging activity: {e}")
        db.session.rollback()

def load_activity_logs():
    """Loads all activity logs from the DB."""
    return ActivityLog.query.order_by(ActivityLog.timestamp.desc()).all()

def get_user_scan_counts(logs_list):
    """Calculates scan counts per user from a list of log objects."""
    scan_counts = {}
    for log in logs_list:
        if log.action_type == "QR_SCAN" and log.user_email:
            email = log.user_email
            scan_counts[email] = scan_counts.get(email, 0) + 1
    return scan_counts

# ----------------- Ownership Helpers -----------------

def get_ownership(pid):
    """Gets Ownership record by product_id."""
    return Ownership.query.filter_by(product_id=pid).first()

def update_ownership(pid, owner_name, owner_public_key):
    """Creates or updates an ownership record."""
    ownership = get_ownership(pid)
    if not ownership:
        ownership = Ownership(product_id=pid)
        db.session.add(ownership)
    
    ownership.owner_name = owner_name
    ownership.owner_public_key = owner_public_key
    
    try:
        db.session.commit()
        return True
    except Exception:
        db.session.rollback()
        return False

# ======================================================
# USER ENDPOINTS (Updated to use DB Helpers)
# ======================================================

@app.post("/user_signup")
def user_signup():
    """Registers a new user, generates keys, and returns keys to client."""
    try:
        data = request.json or {}
        name = data.get("name", "").strip()
        email = data.get("email", "").strip().lower()
        password = data.get("password", "").strip()
        phone_number = data.get("phone", "").strip()

        if not name or not email or not password or not phone_number:
            return jsonify({"status": "error", "message": "name, email, password, and phone_number are required"}), 400

        # Check for existing user in DB
        if get_user_by_email(email):
            return jsonify({"status": "error", "message": "Email already registered"}), 400

        pw_hash, salt = hash_password(password)
        
        # 🔑 FOR TESTING: Generate key pair
        keypair = SigningKey.generate()
        pub = b64e(keypair.verify_key.encode())
        full_prv_bytes = keypair.encode() # 64 bytes
        prv_seed_bytes = full_prv_bytes[:32] # Take the first 32 bytes (Seed)
        prv = b64e(prv_seed_bytes) # Base64 encode the 32-byte Seed only
        
        # Save user to DB
        if not db_save_user(name, email, pw_hash, phone_number, salt, pub):
              return jsonify({"status": "error", "message": "Failed to save user to database."}), 500

        log_activity(action_type="USER_SIGNUP", user_email=email, message=f"New user '{name}' signed up.")

        auth_token = create_token(email, name)
        
        return jsonify({
    "status": "success",
    "user": {
        "name": name,
        "email": email,
        "phone_number": phone_number,
        "public_key": pub
    },
    "auth_token": auth_token,
    "public_key": pub,
    "private_key": prv  # ✅ Send the private key (seed) for client storage
})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.post("/user_login")
def user_login():
    """Authenticates a user and returns their keys for client storage."""
    data = request.json or {}
    email = data.get("email", "").strip().lower()
    password = data.get("password", "").strip()

    if not email or not password:
            return jsonify({"status": "error", "message": "email and password are required"}), 400

    user_record = get_user_by_email(email)

    if user_record is None:
            log_activity(action_type="LOGIN_FAILED", user_email=email, message=f"Login attempt failed: user not found for '{email}'.")
            return jsonify({"status": "error", "message": "Invalid email or password"}), 401

    stored_salt = user_record.salt
    if not stored_salt:
          log_activity(action_type="LOGIN_FAILED", user_email=email, message=f"Login attempt failed: Missing salt for '{email}'.")
          return jsonify({"status": "error", "message": "Invalid email or password"}), 401

    checked_hash, _ = hash_password(password, stored_salt)
    if user_record.password_hash == checked_hash:
            log_activity(
        action_type="USER_LOGIN",
        user_email=email,
        message=f"User '{email}' logged in."
    )

            auth_token = create_token(
        user_record.email,
        user_record.name
    )

            return jsonify({
        "status": "success",
        "auth_token": auth_token,
        "user": {
            "name": user_record.name,
            "email": user_record.email,
            "phone_number": user_record.phone_number,
            "public_key": user_record.public_key
        }
    })
    return jsonify({
    "status": "error",
    "message": "Invalid email or password"
}), 401


@app.post("/user/update-profile")
@login_required 
def user_update_profile():
    """Updates a user's name and phone number (DB version)."""
    try:
        email_to_find = request.current_user["sub"]
        
        data = request.json or {}
        required_fields = ['first_name', 'last_name', 'phone_number']
        if not all(field in data for field in required_fields):
            return jsonify({"status": "error", "message": "Missing required fields (first_name/last_name/phone_number)."}), 400

        updates = {
            'first_name': data['first_name'],
            'last_name': data['last_name'],
            'phone_number': data['phone_number'],
        }
        
        if db_update_user_profile(email_to_find, updates):
            log_activity(action_type="USER_PROFILE_UPDATE", user_email=email_to_find, message=f"User '{email_to_find}' updated profile.")
            return jsonify({"status": "success", "message": "Profile updated successfully."}), 200
        else:
            return jsonify({"status": "error", "message": "User not found or update failed."}), 404

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.post("/change_password")
@login_required 
def change_password():
    """Allows a user to change their password (DB version)."""
    try:
        email = request.current_user["sub"]
        
        data = request.json or {}
        old_password = data.get("old_password", "").strip()
        new_password = data.get("new_password", "").strip()

        if not old_password or not new_password:
            return jsonify({"status": "error", "message": "Old password and new password are required."}), 400

        if len(new_password) < 8:
            return jsonify({"status": "error", "message": "New password must be at least 8 characters."}), 400

        user_record = get_user_by_email(email)

        if user_record is None:
            return jsonify({"status": "error", "message": "User not found."}), 404

        stored_salt = user_record.salt
        if not stored_salt:
            return jsonify({"status": "error", "message": "System error: Missing salt for user."}), 500

        old_hash_check, _ = hash_password(old_password, stored_salt)

        if user_record.password_hash != old_hash_check:
            log_activity(action_type="PASSWORD_CHANGE_FAILED", user_email=email, message=f"Password change failed for '{email}' due to incorrect old password.")
            return jsonify({"status": "error", "message": "Incorrect old password."}), 401

        new_hash, _ = hash_password(new_password, stored_salt)
        update_success = db_update_user_password(email, new_hash)

        if update_success:
            log_activity(action_type="PASSWORD_CHANGE", user_email=email, message=f"User '{email}' changed password.")
            return jsonify({"status": "success", "message": "Password updated successfully."})
        else:
            return jsonify({"status": "error", "message": "Failed to update password due to a server error."}), 500

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# ======================================================
# QR & VERIFICATION ENDPOINTS (Updated to use DB Helpers)
# ======================================================
@app.post("/generate_qr")
@admin_required
def generate_qr():
    """Generates a QR code using the secret key from the file."""
    try:
        data = request.json
        required = ["v", "category", "product_id", "manufacturer_id", "country", "chain"]
        if not all(f in data for f in required):
            return jsonify({"status": "error", "message": "Missing required QR fields for generation."}), 400

        pid = data["product_id"]
        mid = data["manufacturer_id"]

        if is_product_registered(pid):
            return jsonify({"status": "error", "message": f"Product ID {pid} already exists."}), 400

        signing_key = load_signing_key()
        if not signing_key:
            return jsonify({"status": "error", "message": "Failed to load signing key."}), 500

        pk = signing_key.verify_key
        qr_pub = b64u(pk.encode())

        nonce = secrets.token_hex(8)
        message = canonical(
            data["v"], data["category"], pid, mid,
            data["country"], nonce, data["chain"]
        )

        digest = hashlib.sha256(message.encode()).digest()
        sig = signing_key.sign(digest).signature

        payload = {
            "v": data["v"],
            "category": data["category"],
            "pid": pid,
            "mid": mid,
            "co": data["country"],
            "n": nonce,
            "chain": data["chain"],
            "sig": b64u(sig),
            "pub": qr_pub
        }

        # 🔗 Blockchain (immutable product hash)
        canonical_msg = canonical(
            payload["v"],
            payload["category"],
            pid,
            mid,
            payload["co"],
            payload["n"],
            payload["chain"]
        )

        manufacturer_address = blockchain.w3.eth.accounts[0]

        product_hash = hashlib.sha256(canonical_msg.encode()).hexdigest()
        blockchain.register_product(
            pid,
            product_hash,
            manufacturer_address
        )
        # QR image
        qr_data = json.dumps(payload, separators=(",", ":"))
        qr_img = qrcode.make(qr_data)
        file_name = f"{pid}.png"
        qr_img.save(os.path.join(QRS_FOLDER, file_name))

        new_product = Product(
            product_id=pid,
            manufacturer_id=mid,
            category=data["category"],
            country=data["country"],
            nonce=nonce,
            chain=data["chain"]
        )
        db.session.add(new_product)

        update_ownership(pid, mid, None)
        db.session.commit()

        buffer = BytesIO()
        qr_img.save(buffer, format="PNG")
        qr_base64 = base64.b64encode(buffer.getvalue()).decode()

        return jsonify({
            "status": "success",
            "payload": payload,
            "file": file_name,
            "qr_base64": qr_base64
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500

@app.post("/verify_product")
def verify_product():
    """Verifies a product's authenticity via QR + Blockchain."""
    try:
        qr = request.json or {}
        user_email = qr.get("user_email", "")

        if not all(k in qr for k in ["pid", "sig", "pub", "v", "category", "mid", "co", "n", "chain"]):
            return jsonify({"status": "error", "message": "Missing QR fields"}), 400

        pid = str(qr["pid"])

        try:
            verify_payload(qr)

            # 🔗 Blockchain verification
            on_chain_hash, _ = blockchain.get_product(pid)

            local_msg = canonical(
                qr["v"],
                qr["category"],
                qr["pid"],
                qr["mid"],
                qr["co"],
                qr["n"],
                qr["chain"]
            )

            local_hash = hashlib.sha256(local_msg.encode()).digest()

            if on_chain_hash != local_hash:
                return jsonify({
                    "status": "error",
                    "message": "Blockchain hash mismatch – product tampered"
                }), 400

        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400

        record = is_product_registered(pid)
        if not record:
            return jsonify({"status": "error", "message": "Product not registered"}), 404

        owner = get_ownership(pid)

        qr["product_id"] = record.product_id
        qr["manufacturer_id"] = record.manufacturer_id
        qr["category"] = record.category
        qr["country"] = record.country
        qr["chain"] = record.chain
        qr["nonce"] = record.nonce
        qr["owner_name"] = owner.owner_name if owner else "Unknown"

        return jsonify({
            "status": "success",
            "message": "Product verified",
            "payload": qr
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.get("/qr_records")
@admin_required # This function must be for administrators only
def qr_records():
    """Lists all registered QR records (DB version)."""
    try:
        records = Product.query.all()
        data = [{
            "product_id": r.product_id, 
            "manufacturer_id": r.manufacturer_id, 
            "category": r.category,
            "country": r.country,
            "chain": r.chain,
            "nonce": r.nonce
        } for r in records]
        
        return jsonify({"status": "success", "records": data})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/qrs/<path:filename>")
def serve_qr_image(filename):
    """Serves generated QR code images."""
    return send_from_directory(QRS_FOLDER, filename)


# ======================================================
# PURCHASE FLOW (Client-side signing - CORRECT MODEL)
# ======================================================


def create_challenge(product_id, buyer_name, seller_name):
    """Creates a unique challenge string for signature."""
    token = secrets.token_hex(8)
    ts = int(datetime.datetime.utcnow().timestamp())
    return f"challenge|product:{product_id}|buyer:{buyer_name}|seller:{seller_name}|ts:{ts}|rand:{token}"


@app.post("/purchase_start")
def purchase_start():
    """Starts the transfer process by creating a challenge."""
    data = request.json or {}
    pid = data.get("product_id")
    buyer_name = data.get("buyer_name")
    buyer_pub = data.get("buyer_public_key")

    ownership = get_ownership(pid)
    if ownership is None:
          return jsonify({
        "status": "error",
        "message": "Product has no ownership record"
          }), 400
    seller_name = ownership.owner_name
    seller_pub = ownership.owner_public_key

    challenge = create_challenge(pid, buyer_name, seller_name)

    # Delete any existing session for this product to prevent reuse
    TempTransfer.query.filter_by(product_id=pid).delete()
    db.session.commit()

    temp = TempTransfer(
        product_id=pid,
        challenge=challenge,
        seller_pub=seller_pub,
        seller_name=seller_name,
        buyer_name=buyer_name,
        buyer_pub=buyer_pub
    )

    # ✅ Special Case: If seller is manufacturer → automatic signature
    if seller_pub is None:
        temp.seller_verified = True
        temp.seller_signature = "NO_SIGNATURE_REQUIRED"


    db.session.add(temp)
    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Challenge sent to seller"
    })
@app.post("/purchase_complete")
def purchase_complete():
    data = request.json
    pid = data.get("product_id")

    session = TempTransfer.query.filter_by(product_id=pid).first()
    if not session or not session.seller_verified:
        return jsonify({"status": "error", "message": "Seller not verified"}), 400

    # 👇 المالك الحالي على البلوك تشين
    _, current_owner = blockchain.get_product(pid)

    # 👇 عنوان المشتري (للتجربة)
    buyer_blockchain_address = blockchain.w3.eth.accounts[1]

    # 🔗 نقل الملكية من المالك الحقيقي
    blockchain.transfer_ownership(
        pid,
        buyer_blockchain_address,
        current_owner
    )

    # 🔄 تحديث DB
    update_ownership(pid, session.buyer_name, session.buyer_pub)

    db.session.delete(session)
    db.session.commit()

    return jsonify({"status": "success"})


@app.post("/seller_accept")
@login_required
def seller_accept():

    """Endpoint for the seller to sign the challenge and verify the sale."""
    seller_email = request.current_user["sub"]
    data = request.json or {}
    pid = data.get("product_id")
    signature = data.get("signature")
    
    session = TempTransfer.query.filter_by(product_id=pid).first()
    if not session:
        return jsonify({"status": "error"}), 404
        
    user = get_user_by_email(seller_email)
    if not user:
        return jsonify({"status": "error", "message": "User not found"}), 404

    # Authorization Check: Current user must be the registered seller (unless manufacturer)
    if session.seller_pub is not None and user.public_key != session.seller_pub:
        return jsonify({
        "status": "error",
        "message": "You are not the seller of this product"
    }), 403


# 1️⃣ Prevent Reuse
    if session.challenge is None:
        return jsonify({
        "status": "error",
        "message": "Challenge already used"
    }), 400

# 2️⃣ Signature Verification
    if not verify_signature(
    session.seller_pub,
    session.challenge,
    signature
):
        return jsonify({"status": "error", "message": "Invalid signature"}), 400

# 3️⃣ Accept/Verify
    session.seller_verified = True
    session.seller_signature = signature
    # Invalidate challenge to prevent replay attacks
    
    db.session.commit()
    
    return jsonify({"status": "success"})

@app.get("/check_seller_status/<pid>")
def check_seller_status(pid):
    """Checks the verification status of the seller for a pending transfer."""
    session = TempTransfer.query.filter_by(product_id=pid).first()
    if not session:
        return jsonify({"status": "error"}), 404

    return jsonify({
        "status": "success",
        "seller_verified": session.seller_verified
    })
    
@app.get("/seller_challenge/<pid>")
@login_required
def get_seller_challenge(pid):
    """Retrieves the challenge string for the seller to sign."""
    session = TempTransfer.query.filter_by(product_id=pid).first()
    if not session:
        return jsonify({"status": "error"}), 404
    
    # Simple check that the user viewing the challenge is the seller (not strictly necessary but good practice)
    user_pub_key = get_user_by_email(request.current_user["sub"]).public_key
    if session.seller_pub != user_pub_key:
        return jsonify({"status": "error", "message": "Unauthorized challenge access"}), 403

    return jsonify({
        "status": "success",
        "challenge": session.challenge
    })

@app.get("/seller/pending")
@login_required
def seller_pending_sales():
    """Lists all pending transfer sessions where the current user is the seller."""
    seller_email = request.current_user["sub"]

    # Get the user
    user = get_user_by_email(seller_email)
    if not user:
        return jsonify({"status": "error"}), 404

    # Get all requests where the seller's public key matches and they haven't verified yet
    sessions = TempTransfer.query.filter_by(
        seller_pub=user.public_key,
        seller_verified=False
    ).all()

    data = [{
        "product_id": s.product_id,
        "buyer_name": s.buyer_name
    } for s in sessions]

    return jsonify({
        "status": "success",
        "sales": data
    })


# ======================================================
# ADMIN ENDPOINTS (Updated to use DB Helpers)
# ======================================================

@app.post("/admin_login")
def admin_login():
    """Authenticates the fixed admin user."""
    try:
        data = request.json or {}
        email = data.get("email", "").strip().lower()
        password = data.get("password", "").strip()

        if not email or not password:
            return jsonify({"status": "error", "message": "Email and password are required."}), 400

        checked_hash, _ = hash_password(password, ADMIN_PASSWORD_SALT)

        if email == ADMIN_EMAIL and checked_hash == ADMIN_PASSWORD_HASH:
            log_activity(action_type="ADMIN_LOGIN", user_email=email, message=f"Admin '{email}' logged in.")
            auth_token = create_token(ADMIN_EMAIL, "Admin", is_admin=True)
            return jsonify({
                "status": "success",
                "message": "Admin login successful.",
                "admin_auth_token": auth_token
            })
        else:
            log_activity(action_type="ADMIN_LOGIN_FAILED", user_email=email, message=f"Admin login failed for '{email}'.")
            return jsonify({"status": "error", "message": "Invalid admin credentials."}), 401
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.get("/admin/users")
@admin_required
def get_all_users():
    """Lists all user records with scan counts (Admin only) - DB version."""
    try:
        users_db = User.query.all()
        logs_db = load_activity_logs()
        scan_counts = get_user_scan_counts(logs_db)
        
        users_safe = []
        for u in users_db:
            user_data = {
                'id': u.id,
                'name': u.name,
                'email': u.email,
                'phone_number': u.phone_number,
                'public_key': u.public_key,
                'scan_count': scan_counts.get(u.email, 0)
            }
            users_safe.append(user_data)

        log_activity(action_type="ADMIN_VIEW_USERS", user_email=ADMIN_EMAIL, message="Admin viewed all user records.")
        return jsonify({"status": "success", "users": users_safe})
    except Exception as e:
        log_activity(action_type="ADMIN_VIEW_FAILED", user_email=ADMIN_EMAIL, message=f"Admin failed to view users: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.get("/admin/dashboard_stats")
@admin_required
def admin_dashboard_stats():
    """Provides key statistics for the admin dashboard (DB version)."""
    try:
        total_products = Product.query.count()
        total_users = User.query.count()
        logs = ActivityLog.query.all()
        total_admins = 1

        total_scans = len([log for log in logs if log.action_type == "QR_SCAN"])
        fake_detections = len([log for log in logs if log.scan_status == "COUNTERFEIT"])

        # Fetch latest 10 activity logs
        recent_activity_db = ActivityLog.query.order_by(ActivityLog.timestamp.desc()).limit(10).all()
        recent_activity_list = [{
            "timestamp": l.timestamp.isoformat(),
            "action_type": l.action_type,
            "user_email": l.user_email,
            "product_id": l.product_id,
            "scan_status": l.scan_status,
            "message": l.message,
        } for l in recent_activity_db]

        return jsonify({
            "status": "success",
            "stats": {
                "total_products": total_products,
                "fake_detections": fake_detections,
                "total_users": total_users,
                "total_admins": total_admins,
                "total_scans": total_scans,
            },
            "recent_activity": recent_activity_list
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# ======================================================
# SERVER RUN
# ======================================================
if __name__ == "__main__":
    with app.app_context():
        # Create tables when running the server
        db.create_all()

    # ⚠️ Load or create the signing key on startup
    # load_or_create_qr_signer_key() 

    app.run(host="0.0.0.0", port=5000, debug=True)
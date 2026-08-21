# Bashabondhu Home Rental Management System

A comprehensive, lightweight Flutter home rental and demand management mobile application backed by **Firebase Cloud Firestore**.

---

## 📍 Bangladesh Location Management System

This project features a real-time, hierarchical Bangladesh location dataset (**Division ➔ District ➔ Area / Upazila ➔ Sub-Area / Union**) with full bilingual localization support (English & বাংলা).

### 🚀 Architecture Highlights:
* **Cloud Storage**: All 8 Divisions, 64 Districts, 550 Areas, and 5,009 Sub-Areas are hosted directly in **Cloud Firestore** (`locations` collection).
* **Ultra-Fast Caching**: In-memory caching + Firestore native offline SQLite persistence for **0ms instant dropdown response**.
* **Zero APK Bloat**: Raw data is fetched on demand from Firestore, keeping the compiled mobile application lightweight.

---

## 🛠️ How to Add, Edit, or Update Location Data

You can manage location data using two straightforward methods:

### Method 1: Using the Master JSON File & Auto-Sync Script (Recommended for Batch Updates)

The master dataset is located at:
📁 `scripts/data/location.json`

#### Step-by-Step Example (Adding a New Sub-Area):
1. **Open the JSON File**:
   Navigate to `scripts/data/location.json`.

2. **Locate the Target Area**:
   Find the desired area under its district (for example, `gopalganj_sadar` under the `gopalganj` district).

3. **Add the New Sub-Area Entry**:
   Insert the new item inside the `sub_areas` array:
   ```json
   {
     "id": "notun_elaka",
     "name_en": "Notun Elaka",
     "name_bn": "নতুন এলাকা"
   }
   ```

4. **Save the File**:
   Press <kbd>Ctrl + S</kbd> (or <kbd>Cmd + S</kbd> on macOS).

5. **Upload & Sync to Cloud Firestore**:
   Run the sync script from your terminal:
   ```bash
   node scripts/upload_locations.mjs
   ```

   **Output:**
   ```text
   🚀 Starting upload to Firebase Cloud Firestore...
   📁 Reading location dataset from: scripts/data/location.json
   ✅ Loaded 8 divisions from JSON file.
   ✅ Successfully uploaded "dhaka" to Firestore!
   ...
   🎉 Finished uploading all divisions to Cloud Firestore!
   ```
   👉 Your changes are instantly synchronized with Firebase Firestore and live on all user devices without requiring a new app release on the Play Store.

---

### Method 2: Using the In-App Admin Management Panel (No Code Required)

1. **Log in as Administrator**:
   * **Email**: `admin@bashabondhu.com`
   * **Password**: `admin123`
2. **Navigate to Locations**:
   Select the **"Locations"** module from the Admin Sidebar.
3. **Select Division & District**:
   Choose the target division and district from the dropdowns.
4. **Add / Edit / Delete**:
   * Click **"Add Area"** or **"Add Sub-Area"**.
   * Enter the name in English and Bengali.
   * Click **Save** — changes are updated in Cloud Firestore in real-time.

---

## 📱 Getting Started with Flutter

To run this project locally:

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the application
flutter run
```

---

## 📄 License & Ownership
Copyright © 2026 Bashabondhu. All rights reserved.

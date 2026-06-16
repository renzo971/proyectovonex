# Development Guide

This guide provides step-by-step instructions for setting up the local development environment and running tests for the **VX Intranet** system.

---

## 🚀 Setup Instructions

### Prerequisites
Ensure you have the following installed:
- **PHP** (v8.3 or higher, v8.4 recommended)
- **Composer** (v2.x)
- **Node.js** (v18 or higher)
- **npm** (v10 or higher)
- **PostgreSQL** database engine

---

### 1. Local Environment Configuration

Copy the example configuration file to create your local `.env`:
```bash
cp .env.example .env
```

Open `.env` and configure your database parameters:
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=intranet_local
DB_USERNAME=postgres
DB_PASSWORD=your_password
```

---

### 2. Backend Setup (Laravel)

Install PHP dependencies, generate the app encryption key, and run database migrations:
```bash
# Install dependencies
composer install

# Generate application key
php artisan key:generate

# Run database migrations
php artisan migrate
```

---

### 3. Frontend Setup (React & Vite)

Install Javascript dependencies and set up the assets environment:
```bash
# Install node packages
npm install
```

---

### 4. Running the Application Locally

You need two processes running simultaneously to view changes in real-time:

1. **Vite Development Server** (compiles JS/CSS assets on the fly):
   ```bash
   npm run dev
   ```

2. **Laravel Server** (serves the PHP backend):
   ```bash
   php artisan serve
   ```

Now open your browser and navigate to `http://localhost:8000`.

---

### 5. Keeping Frontend Routes Typed (Laravel Wayfinder)

Whenever you add, modify, or delete a route or controller action on the backend, you must regenerate the frontend route definition helpers by running:
```bash
php artisan wayfinder:generate
```

---

## 🧪 Running Tests

### Backend Tests (Pest/PHPUnit)
To run backend automated test suites:
```bash
php artisan test
```

### Frontend Tests (Vitest)
To run unit and component tests on the frontend:
```bash
npm run test
```

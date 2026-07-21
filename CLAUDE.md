# Check Printer Pro — Claude Code Handoff

## Project Overview

Single-file HTML web application for printing text data onto pre-printed blank US check stock (3 checks per Letter page). The app does NOT print a check image — it positions user-entered text (date, payee, amount, etc.) onto blank check paper using precise inch-based calibration.

**Owner:** Miguel Guanche (`mguanche@sabercollege.edu`)  
**Organization:** Saber College

---

## Tech Stack

- **Frontend:** Single HTML file (~1850 lines, ~72KB), vanilla JS, vanilla CSS
- **Backend:** Supabase (auth + Postgres + RLS)
- **Fonts:** Google Fonts CDN — IBM Plex Mono (data fields) + DM Sans (UI)
- **No build tools, no frameworks, no npm**

---

## Supabase Configuration

```
Project URL:  https://afgntvrclqkbimrdsvlx.supabase.co
Anon Key:     eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFmZ250dnJjbHFrYmltcmRzdmx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NjY3NDUsImV4cCI6MjA5OTU0Mjc0NX0.PvlNw9eeHgk9_EEG0RULcZepcTVAfUTllC-rFO99Tpk
Project Ref:  afgntvrclqkbimrdsvlx
Region:       (check Supabase dashboard)
```

**Auth settings:**
- Email/password auth enabled
- Domain whitelist enforced in frontend: `sabercollege.edu`
- SMTP configured via Google App Password on `noreply@sabercollege.edu`
- Password reset uses `redirectTo: window.location.origin + window.location.pathname`

---

## Database Schema

### Table: `checks`
```sql
CREATE TABLE checks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  check_number SERIAL,
  date DATE,
  pay_to TEXT,
  amount NUMERIC(12,2),
  amount_words TEXT,
  address TEXT,
  memo TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','printed','voided')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS enabled. Policies enforce role-based access via get_my_role().
-- Auto-update trigger on updated_at.
```

### Table: `user_profiles`
```sql
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'viewer'
    CHECK (role IN ('super_admin', 'admin', 'printer', 'viewer')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);
-- RLS enabled. Only super_admin can manage profiles.
```

### Helper function: `get_my_role()`
Returns the caller's role from `user_profiles`. Used in all RLS policies. Defined as `SECURITY DEFINER STABLE`.

### Trigger: `handle_new_user()`
Auto-creates a `user_profiles` row on sign-up. First user becomes `super_admin`, all others get `viewer`.

---

## RBAC Roles & Permissions

| Permission          | super_admin | admin | printer | viewer |
|---------------------|:-----------:|:-----:|:-------:|:------:|
| Create checks       | ✅          | ✅    | ✅      | ❌     |
| Edit checks         | ✅          | ✅    | ✅      | ❌     |
| Delete checks       | ✅          | ✅    | ❌      | ❌     |
| Void checks         | ✅          | ✅    | ❌      | ❌     |
| View history        | ✅          | ✅    | ✅      | ✅     |
| View reports        | ✅          | ✅    | ❌      | ✅     |
| Export CSV           | ✅          | ✅    | ❌      | ✅     |
| Manage users        | ✅          | ❌    | ❌      | ❌     |
| Print checks        | ✅          | ✅    | ✅      | ❌     |

**Super Admin seed:** `mguanche@sabercollege.edu`

---

## Implemented Features

### ✅ Authentication
- Login / Register with email+password
- Domain whitelist (`@sabercollege.edu` only)
- Password reset via email (Supabase + custom SMTP)
- Password recovery URL hash token handling
- Session persistence

### ✅ Check Creation (Create View)
- 3-check tab switcher with dot indicators
- Fields: Date, Amount, Pay To, Amount Words (auto-generated), Address, Memo
- Auto number-to-words conversion (English, up to billions, XX/100 cents)
- Per-check calibration (X/Y in inches for each field)
- Font size slider (10pt–22pt)
- Calibration saved to localStorage (`cpCal3`, `cpFontSize`)
- Save to Supabase / Update existing check

### ✅ Print Preview & Print
- 8.5" × 11" Letter preview with 3 check zones
- Inch-based absolute positioning matching print output
- `@media print` rules: no UI, transparent background, exact dimensions
- Print settings banner (margins=none, scale=100%, no headers)

### ✅ History View
- Filterable table: status, date range, payee search
- Batch select with checkboxes
- Edit / Void / Delete actions (role-gated)
- Batch print selected checks (multi-page support)
- Auto-marks printed checks as "printed"

### ✅ Reports View
- Summary cards: total checks, total amount, pending/printed/voided counts
- Full check listing table
- Date range filter
- CSV export

### ✅ User Management (Super Admin only)
- Create new users with temporary password
- Random password generator
- Assign role on creation
- Change roles via dropdown
- Activate/deactivate users
- Users table with role badges

---

## File Inventory

| File | Purpose |
|------|---------|
| `index.html` | Production app (1850 lines) |
| `setup.sql` | Base schema — `checks` table + RLS |
| `setup_rbac.sql` | RBAC migration — `user_profiles` + role policies |
| `setup_auto_profile.sql` | Auto-profile trigger on sign-up |

**SQL execution order:** `setup.sql` → `setup_rbac.sql` → `setup_auto_profile.sql`  
**Run in:** Supabase Dashboard → SQL Editor

---

## Deployment

- **Planned:** GitHub Pages for stable HTTPS URL
- **Current:** Opened locally from file system
- Auth redirects use `window.location.origin + window.location.pathname` (dynamic)

---

## Architecture Notes

- Everything is in one `index.html` — CSS in `<style>`, JS in `<script>`
- Views are toggled via `.view.on` CSS class
- Supabase JS loaded from CDN: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2`
- No state management library — plain variables (`chks[]`, `cal[]`, `active`, etc.)
- `localStorage` used for calibration only; all check data lives in Supabase
- Create user flow: super admin calls `sb.auth.signUp()` then restores own session

---

## Default Calibration Positions (inches)

```js
const DPOS = {
  'date-x': 6.00, 'date-y': 0.50,
  'payto-x': 1.80, 'payto-y': 1.00,
  'amt-x': 6.20, 'amt-y': 1.00,
  'atxt-x': 0.35, 'atxt-y': 1.40,
  'addr-x': 0.55, 'addr-y': 1.75,
  'memo-x': 1.00, 'memo-y': 2.95
};
```

---

## Known Issues / Suggested Improvements

1. **Check Number management** — `check_number` uses `SERIAL` (auto-increment), but real check workflows often need custom starting numbers
2. **No audit trail** — who printed/voided/edited what and when
3. **Create User flow** — uses `signUp()` from client which can log out the admin; should use Supabase Admin API or Edge Function
4. **No pagination** — history and reports load all rows at once
5. **Single-file scale** — at 1850 lines, consider extracting into separate CSS/JS files
6. **Mobile UX** — nav hides on small screens, main nav replaced by mobile nav (partially implemented)
7. **No offline mode** — requires network for all operations
8. **XSS risk** — user input rendered via `innerHTML` without sanitization in preview/tables
9. **Duplicate entry prevention** — no dedup logic for batch saves
10. **Reports by user** — super admin can't filter reports by who created checks

# Check Printer Pro

Professional check printing application for Saber College.

## Features

- Print text data onto pre-printed US check stock
- Precise field positioning with calibration controls
- Supabase authentication with domain whitelist (@sabercollege.edu)
- Role-Based Access Control (Super Admin, Admin, Printer, Viewer)
- Check history & batch printing
- Reports & CSV export
- User management for Super Admins

## Setup

1. Create a Supabase project
2. Run `setup.sql` in the SQL Editor
3. Run `setup_rbac.sql` in the SQL Editor
4. Run `setup_auto_profile.sql` in the SQL Editor
5. Update the Supabase URL and anon key in `index.html`
6. Deploy to GitHub Pages or any static hosting

## Supabase Configuration

In your Supabase dashboard → Authentication → URL Configuration:
- **Site URL**: `https://mgdatanet.github.io/check-printer-pro/`
- **Redirect URLs**: `https://mgdatanet.github.io/check-printer-pro/`

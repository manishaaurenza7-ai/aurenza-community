# Aurenza Academy Community — First foundation release

A Next.js + Supabase starter for a private, admin-approved professional community.

## Included in this first release
- Aurenza-branded public landing page
- Email/password registration request
- Username and short bio collection (no phone number field)
- Sign-in flow
- Pending approval screen and approved-member dashboard shell
- Supabase database schema with RLS policies for profiles, rooms, posts, private conversations, messages and reports
- WhatsApp Channel link configuration placeholder

## Not yet implemented
The first release is a foundation, not a complete production community. Discussion posting UI, admin approval dashboard, private messaging UI, announcement management, reporting UI and WhatsApp Channel CTA wiring are next-stage work. Do not advertise those as live features yet.

## Setup

1. Create a Supabase project.
2. In Supabase SQL Editor, run `supabase/schema.sql`.
3. In Authentication > URL Configuration, set your local and production site URLs.
4. Configure email confirmation and a reliable SMTP sender.
5. Copy `.env.example` to `.env.local` and enter:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `NEXT_PUBLIC_WHATSAPP_CHANNEL_URL`
6. Install dependencies with `npm install`.
7. Run locally with `npm run dev`.
8. Deploy the repository to Vercel and add the same environment variables in Project Settings.

## First administrator
Register the intended company administrator through the website. Then run the commented bootstrap SQL at the bottom of `supabase/schema.sql`, replacing `YOUR_ADMIN_EMAIL` with that exact account email. Keep administrator access limited to trusted company personnel.

## Privacy design
- The app does not ask for or store a member phone number.
- Public profile records contain username, display name, bio and profession only.
- Auth email remains in Supabase Auth and is not selected into public profile views.
- RLS is required for data isolation. Never expose a Supabase service-role key in browser code.
- Members should be reminded not to publish phone numbers or personal contact details in posts or bios.

## Before production launch
Have a developer/security reviewer validate all RLS policies, add atomic server-side conversation creation and invitation, rate limiting, abuse controls, audit logs, data retention and privacy/legal notices. The SQL schema is a starter and should not be treated as a completed security audit.

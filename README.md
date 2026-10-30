# Farm Ledger: your own website with login

This folder is a complete website. It has three files you need:

- `index.html` is the app (login page, sheets, Hindi/English).
- `config.js` holds your Supabase address and key (you fill this in).
- `schema.sql` creates the database tables and the rules about who can do what.

You need two free accounts: **Supabase** (database and login) and a **host** for the files (Netlify is the easiest).

## Step 1. Create the database (about 5 minutes)

1. Go to supabase.com, sign up, and click **New project**. Choose a name, a database password (save it somewhere), and the region closest to you (for India, choose Mumbai if offered).
2. Wait about two minutes for the project to start.
3. In the left menu open **SQL Editor**, click **New query**, paste everything from `schema.sql`, and click **Run**. It should say "Success".
4. In the left menu open **Authentication**, then **Sign In / Providers**, then **Email**. If you want staff to log in right after signing up without confirming by email, turn **Confirm email** off. (If you leave it on, each person must click a link in an email first.)
5. Open **Project Settings**, then **API**. Copy:
   - **Project URL**
   - the **anon / publishable** key (never the `service_role` key)

## Step 2. Connect the website to your database

Open `config.js` in Notepad and replace the two placeholder values with what you copied. Save the file.

## Step 3. Put the website online

**Netlify (easiest):**
1. Go to app.netlify.com/drop (sign up for free).
2. Drag this whole folder onto the page.
3. Netlify gives you an address like `something.netlify.app`. You can rename it under Site settings, or connect your own domain such as `www.yourfarm.com`.

Other hosts (Vercel, Cloudflare Pages, GitHub Pages, your own server) also work. Just upload the three files as they are.

## Step 4. First login

1. Open your website and tap **I need an account**. Create your account with your email and a password.
2. **The first account ever created becomes the owner.** Do this yourself before telling anyone else the address.
3. Your staff create their own accounts the same way. They see "Waiting for approval" until you open **Setup**, find them under **People who can log in**, and tap **Approve**.

## Who can do what

| | Owner | Staff |
|---|---|---|
| See all sheets and the Home page | Yes | Yes |
| Add and edit entries | Yes | Yes |
| Delete entries | Yes | No |
| Setup (rename, add columns, new sheets, approve people) | Yes | No |
| Example entries | Yes | No |

These rules are enforced by the database itself, not only by the screen, so staff cannot get around them.

## Moving your existing data

The Claude-hosted version of this page keeps its data in your Claude account. This website starts empty. To bring data across, download each sheet with **Download CSV** from the old page, and ask Claude to help you load those files into this one.

## Good to know

- Passwords are handled by Supabase. They are never stored in these files.
- The anon key in `config.js` is meant to be public. The rules in `schema.sql` are what protect your data.
- Supabase's free plan pauses a project after a week with no use. If that happens, open the Supabase dashboard and tap **Restore**. Your data is kept.
- Back up regularly: use **Download CSV** on each sheet, or Supabase's backup options on a paid plan.
- If the owner forgets their password, reset it from Supabase under **Authentication, Users**.

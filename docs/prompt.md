You are an expert Ruby on Rails 8 AI assistant working directly in a freshly scaffolded Rails app that already includes a local Rails 8 reference in `/docs/railway8-docs`. Use only those local docs—no external lookups—and follow Rails philosophy: build complete functionality first, test it thoroughly, then add Tailwind styles and UI components.

1. **Set up your AI workflow**

   - In the **project root**, create `CLAUDE.md` that:
     - Explains your role and audience (Rails beginner).
     - Defines a versioned journal under `docs/journal/` (journal-v1.md, journal-v2.md, …), each capped at 500 lines.
     - Defines a task list in `docs/todo.md`.
     - Outlines your workflow:
       1. Read `docs/todo.md` and the latest journal to get context.
       2. Execute the next task.
       3. Mark it done and add new tasks in `docs/todo.md`.
       4. Append details to the current journal (or start a new one if needed).
       5. Prompt: “I have completed `<task>`. Should I push to GitHub with a descriptive commit?”

2. **Document your docs folder**

   - Under `docs/`, create:
     - `todo.md` listing initial tasks:
       1. Initialize docs workflow
       2. Build public home page
       3. Build public blog section
       4. Build admin panel
       5. Generate tutorial documentation
     - A folder `journal/` with `journal-v1.md` (today’s date, goals, and approach).
     - `README.md` explaining:
       - Why `docs/` exists
       - How to use `/docs/railway8-docs` as your Rails 8 guide
       - How to work through `todo.md` and the journals
       - Where to find `CLAUDE.md` and follow its workflow

3. **Create phase documentation**

   - Under `docs/`, create:
     - `phase-1.md` (setup & docs workflow)
     - `phase-2.md` (public interface)
     - `phase-3.md` (admin authentication)
     - `phase-4.md` (admin CRUD)
     - `phase-5.md` (documentation & deployment)
   - Follow each `phase-*.md` systematically—use it as your roadmap, referring back to `/docs/railway8-docs` and your procedures in `CLAUDE.md`.

4. **Build the tutorial blog functionality**

   - Create a **home page** with a welcome message and a link to the blog index.
   - Create a **public blog section** that shows only published posts (titles, excerpts, dates) and a detail view for each post’s full content.
   - Create an **admin panel** where only a seeded admin user can sign in (no signup), and can create and update blog posts.
   - Use your local Rails 8 docs to determine the correct commands, file structure, and naming conventions.
   - **Test every feature end-to-end** before moving on—don’t add styling yet.

5. **Prepare tutorial documentation**
   - Update the **root** `README.md` to describe the tutorial app and link to `docs/README.md`.
   - Under `docs/`, create a `tutorial-blog/` folder with:
     - `README.md` (overview & how to follow the steps)
     - `01-setup.md`
     - `02-public-interface.md`
     - `03-admin-auth.md`
     - `04-admin-crud.md`
     - `05-deployment.md` (Kamal + Railway instructions, referencing `/docs/railway8-docs`)

For each step, update `docs/todo.md`, append to the current journal, and then prompt:  
“I have completed `<task>`. Should I push to GitHub with a descriptive commit message?”

You are an expert Ruby on Rails 8 AI assistant.

## 🔍 **PROJECT STATE DETECTION - READ THIS FIRST:**

**STEP 1: Check if this is a new or existing project**

1. **IF `CLAUDE.md` EXISTS in project root:**

   - Read `CLAUDE.md` for all project rules and workflow
   - Read latest `docs/todos/todo-vX.md` and `docs/journals/journal-vX.md`
   - Continue development following existing workflow
   - Skip to "Continue Development" section below

2. **IF `CLAUDE.md` DOES NOT EXIST:**
   - This is a **NEW PROJECT** - follow full setup below
   - Create all documentation structure from scratch
   - Follow "New Project Setup" section below

---

## 🚨 CRITICAL RULES FOR ALL PROJECTS - NEW OR EXISTING:

### Rule 1: MINIMAL STYLING ONLY UNTIL 100% FUNCTIONALITY COMPLETE

- **NO CSS beyond basic HTML structure** until ALL functionality works end-to-end
- Use ONLY basic HTML tags: `<h1>`, `<p>`, `<div>`, `<form>`, `<input>`, `<button>`, `<ul>`, `<li>`
- NO custom CSS, NO styling classes, NO complex layouts until functionality phase complete
- User wants creative control over UI design - your job is FUNCTIONALITY ONLY

### Rule 2: MANDATORY LOCAL DOCS USAGE

- Use ONLY `/docs/railway8-docs` - no external lookups
- Every Rails decision must reference specific local doc sections
- Document which local docs you consulted for each implementation
- If local docs don't cover something, ask user for guidance

### Rule 3: SMALL, TESTABLE PHASES

- Break work into 1-2 hour phases maximum
- Each phase must have clear acceptance criteria
- Test every feature completely before moving to next phase
- No phase dependencies that could break earlier work

---

## 📋 **CONTINUE DEVELOPMENT (Existing Project)**

If `CLAUDE.md` exists, follow this workflow:

1. **Read Project State:**

   - Read `CLAUDE.md` for all rules and workflow details
   - Check latest `docs/todos/todo-vX.md` for current tasks
   - Review latest `docs/journals/journal-vX.md` for recent progress
   - Check `docs/architecture.md` for current app structure

2. **Continue Development:**

   - Follow exact workflow defined in `CLAUDE.md`
   - Use ONLY `/docs/railway8-docs` for Rails guidance
   - Maintain minimal styling (basic HTML only)
   - Update todos, journals, and architecture as you work
   - Create new versioned files when 500 line limit reached

3. **Quality Control:**
   - Test all changes end-to-end
   - Document local docs usage
   - Update architecture.md with structural changes
   - Follow all rules from `CLAUDE.md`

**Do not proceed with "New Project Setup" if CLAUDE.md exists!**

---

## 🆕 **NEW PROJECT SETUP**

Only follow this section if `CLAUDE.md` does NOT exist:

## 1. **Set up your AI workflow**

In the **project root**, create `CLAUDE.md` that contains ALL critical rules:

**CLAUDE.md MUST INCLUDE:**

1.  **Project Role & Audience:**

    - Rails 8 AI assistant for Rails beginners
    - Educational focus with detailed explanations

2.  **🚨 MANDATORY STYLING RULES:**

    - **NO CSS beyond basic HTML** until ALL functionality complete
    - Use ONLY: `<h1>`, `<p>`, `<div>`, `<form>`, `<input>`, `<button>`, `<ul>`, `<li>`
    - NO styling classes, NO complex layouts until Phase 7
    - User maintains creative control over UI design

3.  **🚨 MANDATORY LOCAL DOCS USAGE:**

    - Use ONLY `/docs/railway8-docs` - no external lookups
    - Document which local doc sections used for each feature
    - Reference specific local doc sections in implementation

4.  **🚨 VERSIONED DOCUMENTATION SYSTEM:**

    - `docs/journals/` (journal-v1.md, v2.md, …) - 500 line limit each
    - `docs/todos/` (todo-v1.md, v2.md, …) - 500 line limit each
    - `docs/specs/` (feature specifications for each functionality)
    - `docs/implementation/` (phase-1a.md, phase-1b.md, …) - small testable phases
    - `docs/architecture.md` - keep updated with app structure

5.  **🚨 SMALL TESTABLE PHASES:**

    - Break work into 1-2 hour phases maximum
    - Each phase has clear acceptance criteria
    - Test completely before next phase

6.  **🚨 DETAILED WORKFLOW:** (Must copy exact workflow from section 7 below)

7.  **🚨 SUCCESS CRITERIA:** (Must copy from section 8 below)

**The CLAUDE.md file becomes the SINGLE SOURCE OF TRUTH for the project.**

## 2. **Create granular phase documentation**

Under `docs/implementation/`, create detailed phase files with small, testable goals:

**Phase Structure (1-2 hours each):**

- `phase-1a.md` - Documentation setup (CLAUDE.md, todos/, journals/, architecture.md)
- `phase-1b.md` - Local docs review and Rails app analysis
- `phase-2a.md` - Basic home page (minimal HTML only)
- `phase-2b.md` - Home page routing and controller (test end-to-end)
- `phase-3a.md` - Blog index page (basic HTML list)
- `phase-3b.md` - Blog show page (basic HTML content)
- `phase-4a.md` - User model and authentication (no UI)
- `phase-4b.md` - Admin login form (basic HTML form only)
- `phase-4c.md` - Admin session management (test auth flow)
- `phase-5a.md` - Post model and database setup
- `phase-5b.md` - Admin post creation (basic HTML forms)
- `phase-5c.md` - Admin post editing (basic HTML forms)
- `phase-5d.md` - Admin post management (basic HTML lists)
- `phase-6a.md` - Integration testing (all features work)
- `phase-6b.md` - Tutorial documentation
- `phase-7.md` - STYLING PHASE (user creative control begins here)

**Each phase file must include:**

- Acceptance criteria (specific, testable)
- Local docs sections to reference
- Minimal HTML examples (no styling)
- Testing checklist
- Next phase dependencies

## 3. **Document your docs folder structure**

Under `docs/`, create:

- `todos/` folder with `todo-v1.md` (granular phase-based tasks, 500 line limit)
- `journals/` folder with `journal-v1.md` (date, goals, approach, 500 line limit)
- `specs/` folder with feature specifications that can be referred to for each feature
- `implementation/` folder with all phase documentation files
- `architecture.md` (current app structure, models, controllers, routes)
- `README.md` explaining:
  - How to use `/docs/railway8-docs` as your ONLY Rails guide
  - Minimal styling approach until functionality complete
  - Phase-by-phase development approach
  - How to follow versioned todos and journals
  - Link to `CLAUDE.md` workflow

## 4. **Build tutorial blog functionality (MINIMAL STYLING ONLY)**

**Acceptance Criteria for Core Features:**

**Home Page:**

- [ ] Basic HTML page with `<h1>` welcome message
- [ ] Simple `<a>` link to blog index
- [ ] Route works: `GET /`
- [ ] Controller renders correct view
- [ ] NO styling beyond basic HTML structure

**Public Blog Section:**

- [ ] Index page: basic `<ul>` list of published posts
- [ ] Each post: `<li>` with title, excerpt, date (plain text)
- [ ] Show page: basic HTML with title, content, date
- [ ] Only published posts visible (security check)
- [ ] Routes work: `GET /blog`, `GET /blog/:id`
- [ ] NO styling beyond basic HTML structure

**Admin Panel:**

- [ ] Basic HTML login form (email, password inputs)
- [ ] Session management (login/logout)
- [ ] Seeded admin user in database
- [ ] Post CRUD: basic HTML forms and lists
- [ ] Publish/unpublish functionality
- [ ] Admin-only access (authorization check)
- [ ] Routes work: `GET /admin/login`, `GET /admin/posts`, etc.
- [ ] NO styling beyond basic HTML structure

**Local Docs Usage:**

- Reference `/docs/railway8-docs` for every Rails concept
- Document which sections used for each feature
- No external Rails documentation allowed

## 5. **Prepare tutorial documentation**

- Update root `README.md`: describe app, link to `docs/README.md`
- Create `docs/tutorial-blog/` folder:
  - `README.md` (overview and step-by-step approach)
  - `01-setup.md` (Rails app initialization)
  - `02-basic-pages.md` (home page, basic routing)
  - `03-blog-functionality.md` (public blog pages)
  - `04-admin-auth.md` (authentication system)
  - `05-admin-crud.md` (post management)
  - `06-testing.md` (end-to-end verification)
  - `07-styling.md` (user's creative styling phase)
  - `08-deployment.md` (Kamal + Railway, reference local docs)

## 6. **Quality Control Checkpoints**

Before each phase completion, verify:

- [ ] Feature works end-to-end with manual testing
- [ ] Only minimal HTML used (no custom CSS/styling)
- [ ] Local docs referenced and documented
- [ ] Acceptance criteria met completely
- [ ] Next phase dependencies ready
- [ ] Journal updated with implementation details

## 7. **Workflow for each task**

1.  Read latest `docs/todos/todo-vX.md` and `docs/journals/journal-vX.md`
2.  Consult specific `/docs/railway8-docs` sections
3.  Implement with MINIMAL HTML only
4.  Test functionality completely
5.  Update current todo file (mark done, add new tasks)
6.  Document local docs used
7.  Update current journal with details
8.  Update `docs/architecture.md` with structural changes
9.  Create new versioned files if 500 line limit reached
10. Prompt: "I have completed `<task>`. Should I push to GitHub with descriptive commit?"

## 8. **Success Criteria**

Project complete when:

- [ ] All functionality works end-to-end
- [ ] User can create, edit, publish blog posts via admin
- [ ] Public can view published posts only
- [ ] Authentication system secure and functional
- [ ] Complete tutorial documentation exists
- [ ] NO custom styling (basic HTML only)
- [ ] User has full creative control for styling phase
- [ ] All local docs usage documented

---

## 🔄 **REUSABILITY NOTE**

This `prompt.md` file is designed to be reusable:

- **New Projects**: Follow full setup process, create CLAUDE.md with all rules
- **Existing Projects**: Read CLAUDE.md and continue development
- **Project Handoffs**: New AI agents should read prompt.md, detect project state, and follow appropriate path

The key is that **CLAUDE.md becomes the project's single source of truth** containing all critical rules, while this prompt.md serves as the initial setup and detection system.

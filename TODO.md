# Todo

## Repository Setup
- [x] **T001 · Chore · P0: initialize git repository**
    - **Context:** Detailed Build Steps - Phase 1: 1. Repository Setup
    - **Action:**
        1. Run `git init` in the project's root directory.
    - **Done‑when:**
        1. A `.git` directory exists.
        2. Project is recognized as a Git repository.
    - **Verification:**
        1. Run `git status` in the project root; it should report the status of a git repository.
    - **Depends‑on:** none
- [x] **T002 · Chore · P0: create initial directory and core files structure**
    - **Context:** Detailed Build Steps - Phase 1: 1. Repository Setup
    - **Action:**
        1. Create directories: `data/`, `assets/`, `scripts/`, `templates/`.
        2. Create empty files: `README.md`, `CV.md`, `.gitignore`.
    - **Done‑when:**
        1. All specified directories and empty files exist at the root of the repository.
    - **Verification:**
        1. List files and directories in the project root; confirm all items are present.
    - **Depends‑on:** [T001]
- [x] **T003 · Chore · P1: add DEVELOPMENT_PHILOSOPHY.md to repository**
    - **Context:** Detailed Build Steps - Phase 1: 1. Repository Setup
    - **Action:**
        1. Copy or symlink the `DEVELOPMENT_PHILOSOPHY.md` document into the root of the repository.
    - **Done‑when:**
        1. `DEVELOPMENT_PHILOSOPHY.md` is present in the project root.
    - **Verification:**
        1. Check for the existence of `DEVELOPMENT_PHILOSOPHY.md` in the project root and verify its content.
    - **Depends‑on:** [T001]

## CV.md Structure & Initial Content
- [x] **T004 · Feature · P1: outline major sections in CV.md using H2 headings**
    - **Context:** Detailed Build Steps - Phase 1: 2. Define `CV.md` Core Structure
    - **Action:**
        1. Add H2 headings to `CV.md` for: Professional Experience, Technical Skills, GitHub Projects, Hidden Experience, Learning Journey, Domain Knowledge, Specialized Sections.
    - **Done‑when:**
        1. `CV.md` contains all specified H2 headings.
    - **Verification:**
        1. Open `CV.md` and verify the presence and correctness of H2 headings.
    - **Depends‑on:** [T002]
- [x] **T005 · Feature · P1: define consistent formatting rules for CV.md content**
    - **Context:** Detailed Build Steps - Phase 1: 2. Define `CV.md` Core Structure
    - **Action:**
        1. Define rules for H3-H5 sub-sections, list items, and key-value pair patterns (e.g., `Tech:`, `Impact:`).
    - **Done‑when:**
        1. Formatting rules are clearly defined.
    - **Depends‑on:** none
- [x] **T006 · Documentation · P1: document CV.md structure and formatting guidelines**
    - **Context:** Detailed Build Steps - Phase 1: 2. Define `CV.md` Core Structure; Documentation - `README.md` (Root)
    - **Action:**
        1. Add a section to `README.md` (or `CONTRIBUTING.md`) detailing the `CV.md` heading hierarchy (H1-H5) and content formatting rules.
    - **Done‑when:**
        1. `README.md` contains clear guidelines for `CV.md` structure and formatting.
    - **Verification:**
        1. Review the documented guidelines for clarity and completeness.
    - **Depends‑on:** [T004, T005]
- [x] **T007 · Feature · P2: populate CV.md Professional Experience section structure**
    - **Context:** Detailed Build Steps - Phase 1: 3. Populate Professional Experience (Manual)
    - **Action:**
        1. For each professional role, add an H3 heading for Role/Company.
        2. Under each role, add H4 sub-sections for major projects or responsibilities.
    - **Done‑when:**
        1. `CV.md` Professional Experience section has the H3/H4 structure for all roles.
    - **Verification:**
        1. Review `CV.md` to ensure all roles have the defined heading structure.
    - **Depends‑on:** [T004]
- [x] **T008 · Feature · P2: detail Professional Experience in CV.md**
    - **Context:** Detailed Build Steps - Phase 1: 3. Populate Professional Experience (Manual)
    - **Action:**
        1. For each role/project in `CV.md`, populate details: Technical Stack, Team Structure, Methodology, Problem-Solution Framing, Cross-Functional Collaboration.
    - **Done‑when:**
        1. All entries in the Professional Experience section are populated with the required details.
    - **Verification:**
        1. Manually review populated details for completeness and adherence to format.
    - **Depends‑on:** [T007, T005]
- [ ] **T009 · Feature · P1: create data/skill_matrix.yml file and define base structure**
    - **Context:** Detailed Build Steps - Phase 1: 4. Populate Technical Skills
    - **Action:**
        1. Create the `data/skill_matrix.yml` file.
        2. Define the YAML structure with keys: `name`, `category`, `proficiency`, `acquired_on`, `versions`, `used_in_projects_ids`, `education_refs`.
    - **Done‑when:**
        1. `data/skill_matrix.yml` exists with the specified base structure.
    - **Verification:**
        1. Check the file content for correct YAML structure and keys.
    - **Depends‑on:** [T002, C001]
- [ ] **T010 · Feature · P2: define proficiency scale in data/skill_matrix.yml comments or README.md**
    - **Context:** Detailed Build Steps - Phase 1: 4. Populate Technical Skills
    - **Action:**
        1. Document the definitions for the chosen proficiency scale (e.g., 1-5) as comments within `skill_matrix.yml` or in `README.md`.
    - **Done‑when:**
        1. Proficiency scale definitions are documented.
    - **Depends‑on:** [T009]
- [ ] **T011 · Feature · P2: populate data/skill_matrix.yml with initial skills data**
    - **Context:** Detailed Build Steps - Phase 1: 4. Populate Technical Skills
    - **Action:**
        1. Add known skills to `skill_matrix.yml`, including categories, proficiency, versions, and acquisition dates.
    - **Done‑when:**
        1. `skill_matrix.yml` is populated with a comprehensive list of initial skills.
    - **Verification:**
        1. Review `skill_matrix.yml` for data accuracy and completeness.
    - **Depends‑on:** [T009]
- [ ] **T012 · Feature · P2: populate CV.md Technical Skills Taxonomy section**
    - **Context:** Detailed Build Steps - Phase 1: 4. Populate Technical Skills
    - **Action:**
        1. In `CV.md` under the "Technical Skills" H2 heading, create an H3 "Technical Skills Taxonomy" sub-section.
        2. Summarize skills by category, referencing `skill_matrix.yml` where appropriate.
    - **Done‑when:**
        1. The "Technical Skills Taxonomy" section in `CV.md` is populated and references `skill_matrix.yml`.
    - **Verification:**
        1. Review the section in `CV.md` for clarity and correct referencing.
    - **Depends‑on:** [T004, T011]
- [x] **T013 · Feature · P1: create data/project_index.yml file and define base structure**
    - **Context:** Detailed Build Steps - Phase 1: 5. Populate GitHub Projects
    - **Action:**
        1. Create the `data/project_index.yml` file.
        2. Define the YAML structure with keys: `id`, `name`, `type`, `repo_url`, `description`, `tech_stack_ids`, `metrics`, `impact_summary`.
    - **Done‑when:**
        1. `data/project_index.yml` exists with the specified base structure.
    - **Verification:**
        1. Check the file content for correct YAML structure and keys.
    - **Depends‑on:** [T002]
- [ ] **T014 · Feature · P2: populate data/project_index.yml with 10-15 showcase projects**
    - **Context:** Detailed Build Steps - Phase 1: 5. Populate GitHub Projects
    - **Action:**
        1. Manually add entries for 10-15 showcase projects into `project_index.yml`.
    - **Done‑when:**
        1. `project_index.yml` contains data for at least 10-15 projects.
    - **Verification:**
        1. Review `project_index.yml` for data accuracy and completeness.
    - **Depends‑on:** [T013]
- [ ] **T015 · Feature · P2: develop basic scripts/github_analyzer.py**
    - **Context:** Detailed Build Steps - Phase 1: 5. Populate GitHub Projects
    - **Action:**
        1. Create `scripts/github_analyzer.py`.
        2. Implement functionality to list public repositories for a given GitHub username (e.g., `phrazzld`).
        3. Output basic repository information (e.g., name, URL, description) to `data/github_analysis.json` or a Markdown snippet.
    - **Done‑when:**
        1. Script successfully fetches and outputs basic repo info.
        2. Script accepts username and output file as CLI arguments.
    - **Verification:**
        1. Run the script: `python scripts/github_analyzer.py --username <user> --output data/github_analysis.json`.
        2. Verify the content and format of the output file.
    - **Depends‑on:** [T002, C004]
- [ ] **T016 · Feature · P2: populate CV.md GitHub Project Integration section**
    - **Context:** Detailed Build Steps - Phase 1: 5. Populate GitHub Projects
    - **Action:**
        1. In `CV.md` under the "GitHub Projects" H2 heading, create an H3 "GitHub Project Integration" sub-section.
        2. For showcase projects, detail: Problem, Contribution, Challenges, Technologies, Metrics, Learnings.
        3. Reference `project_index.yml` IDs for each project.
    - **Done‑when:**
        1. The "GitHub Project Integration" section in `CV.md` is populated for showcase projects.
    - **Verification:**
        1. Review the section for detail, accuracy, and correct referencing of `project_index.yml` IDs.
    - **Depends‑on:** [T004, T014, T005]
- [ ] **T017 · Feature · P2: document Open Source Contributions in CV.md**
    - **Context:** Detailed Build Steps - Phase 1: 5. Populate GitHub Projects
    - **Action:**
        1. Add entries for Open Source Contributions (e.g., BlueWallet, BTCPay Server) within the "GitHub Projects" section or a dedicated sub-section in `CV.md`.
    - **Done‑when:**
        1. Open Source Contributions are documented in `CV.md`.
    - **Verification:**
        1. Review the entries for completeness and accuracy.
    - **Depends‑on:** [T004]
- [ ] **T018 · Feature · P2: populate CV.md Hidden Experience section**
    - **Context:** Detailed Build Steps - Phase 1: 6. Populate Hidden Experience (Manual)
    - **Action:**
        1. Add content to the "Hidden Experience" section in `CV.md` for Internal Tools, Anonymized Client Projects, and Mentorship & Leadership.
    - **Done‑when:**
        1. The "Hidden Experience" section is populated with relevant details.
    - **Verification:**
        1. Review the section for content and adherence to anonymization (once defined).
    - **Depends‑on:** [T004, C005]
- [ ] **T019 · Feature · P2: populate CV.md Learning Journey section**
    - **Context:** Detailed Build Steps - Phase 1: 7. Populate Learning Journey (Manual)
    - **Action:**
        1. Add content to the "Learning Journey" section in `CV.md` for Formal Education and Self-Directed Learning.
    - **Done‑when:**
        1. The "Learning Journey" section is populated.
    - **Verification:**
        1. Review the section for completeness and accuracy.
    - **Depends‑on:** [T004]
- [ ] **T020 · Feature · P2: populate CV.md Domain Knowledge & Specialized Sections**
    - **Context:** Detailed Build Steps - Phase 1: 8. Populate Domain Knowledge & Specialized Sections (Manual)
    - **Action:**
        1. Add content to the "Domain Knowledge" and "Specialized Sections" in `CV.md`.
    - **Done‑when:**
        1. These sections are populated with relevant information.
    - **Verification:**
        1. Review the sections for appropriate content.
    - **Depends‑on:** [T004]
- [ ] **T021 · Feature · P1: create Markdown entry templates in templates/**
    - **Context:** Detailed Build Steps - Phase 1: 9. Create Entry Templates
    - **Action:**
        1. Develop Markdown snippet templates in the `templates/` directory for new roles, projects, and skills.
    - **Done‑when:**
        1. `templates/` directory contains at least one template for roles, projects, and skills.
        2. Templates reflect the defined `CV.md` formatting.
    - **Verification:**
        1. Review templates for usability and consistency with `CV.md` structure.
    - **Depends‑on:** [T002, T005]

## Enrichment & Script Development (Phase 2)
- [ ] **T022 · Refactor · P2: add quantifiable impact and deepen technical descriptions in CV.md**
    - **Context:** Detailed Build Steps - Phase 2: 10. Metrics Gathering & Technical Detail Deepening
    - **Action:**
        1. Revisit all populated entries in `CV.md` (Professional Experience, Projects, etc.).
        2. Add quantifiable impact metrics and deepen technical descriptions where appropriate.
    - **Done‑when:**
        1. Key entries in `CV.md` are enriched with metrics and detailed technical information.
    - **Depends‑on:** [T008, T016, C003]
- [ ] **T023 · Feature · P2: implement Markdown link-based cross-referencing in CV.md**
    - **Context:** Detailed Build Steps - Phase 2: 11. Cross-Referencing Strategy
    - **Action:**
        1. Update `CV.md` to use Markdown links (e.g., `[Project X](#project-x-details)`) for internal cross-referencing between sections, projects, and skills where appropriate.
    - **Done‑when:**
        1. `CV.md` uses Markdown links for robust internal linking.
    - **Verification:**
        1. Manually check a few links in a Markdown preview to ensure they navigate correctly.
    - **Depends‑on:** [T004, T012, T016]
- [ ] **T024 · Feature · P2: update data/skill_matrix.yml with used_in_projects_ids**
    - **Context:** Detailed Build Steps - Phase 2: 11. Cross-Referencing Strategy
    - **Action:**
        1. For each skill in `skill_matrix.yml`, populate the `used_in_projects_ids` field with corresponding project IDs from `project_index.yml`.
    - **Done‑when:**
        1. `skill_matrix.yml` is updated with project cross-references.
    - **Verification:**
        1. Review `skill_matrix.yml` to confirm `used_in_projects_ids` are populated.
    - **Depends‑on:** [T011, T014]
- [ ] **T025 · Feature · P2: update data/project_index.yml with tech_stack_ids**
    - **Context:** Detailed Build Steps - Phase 2: 11. Cross-Referencing Strategy
    - **Action:**
        1. For each project in `project_index.yml`, populate the `tech_stack_ids` field with corresponding skill names/IDs from `skill_matrix.yml`.
    - **Done‑when:**
        1. `project_index.yml` is updated with skill cross-references.
    - **Verification:**
        1. Review `project_index.yml` to confirm `tech_stack_ids` are populated.
    - **Depends‑on:** [T014, T011]
- [ ] **T026 · Feature · P2: enhance scripts/github_analyzer.py to fetch detailed repo info**
    - **Context:** Detailed Build Steps - Phase 2: 12. Enhance `github_analyzer.py`
    - **Action:**
        1. Modify `github_analyzer.py` to fetch contribution details (if available via public API), stars, forks, and last commit dates for repositories.
    - **Done‑when:**
        1. Script can fetch the specified detailed repository information.
    - **Verification:**
        1. Run the script and verify the output includes the new detailed fields.
    -

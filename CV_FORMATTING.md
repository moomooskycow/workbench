# CV Formatting Guidelines

This document defines the consistent formatting rules for CV.md content, ensuring a standardized approach to documenting professional experience, skills, and knowledge.

## Heading Hierarchy

The CV.md document uses a consistent hierarchy of headings to organize content:

- **H1 (`#`)**: Document title - used only once at the top of the document
- **H2 (`##`)**: Main sections - used for the primary content divisions
- **H3 (`###`)**: Sub-sections - used for roles, major skill categories, significant projects, etc.
- **H4 (`####`)**: Components - used for projects within roles, sub-categories within skills, etc.
- **H5 (`#####`)**: Details - used for specific aspects of a component when needed

## Section Structures

### Professional Experience

```markdown
## Professional Experience

### Role Title, Company Name
*Location (Remote if applicable) | Date Range (Month YYYY - Month YYYY)*

Brief 1-3 sentence role overview highlighting key responsibilities and impact.

#### Major Project or Responsibility Area

**Context:** Brief description of the project's business context and objectives
**Tech:** List of key technologies used, separated by commas
**Team:** Team size and structure (e.g., "Led team of 5 engineers")
**Methodology:** Development methodology used (e.g., "Agile/Scrum, 2-week sprints")

- Key achievement or contribution with measurable impact
- Another significant accomplishment with context
- Process improvement or technical innovation introduced

#### Another Project

...follow same pattern
```

### Technical Skills

```markdown
## Technical Skills

### Skill Category (e.g., Languages, Frameworks, Tools)

#### Skill Name
**Proficiency:** Advanced (5/5)
**Acquisition:** Initially learned YYYY, professional usage since YYYY 
**Versions:** List of specific versions used professionally
**Key Projects:** [Project Name](#link-to-project), [Another Project](#link-to-project)
**Education:** Any formal training, certifications, or notable self-learning resources

Brief 1-2 sentence description of how the skill has been applied professionally.

#### Another Skill
...follow same pattern
```

### GitHub Projects

```markdown
## GitHub Projects

### Project Name
**Type:** Personal Project, Open Source Contribution, etc.
**Status:** Active, Completed, Archived
**Duration:** Date Range or Time Period
**Repo:** [link-to-repository](URL)

**Problem:** Brief description of the problem the project solves
**Solution:** Overview of the implemented solution approach
**Tech Stack:** List of key technologies used, separated by commas
**Metrics:** User count, stars, downloads, or other relevant statistics
**Impact:** Business or community impact, if applicable

#### Key Challenges
- Technical challenge faced and how it was solved
- Another significant challenge and resolution

#### Learning Outcomes
- Important skill or knowledge gained
- Insight or best practice discovered
```

### Hidden Experience

```markdown
## Hidden Experience

### Internal Tool/System Name or Project Identifier
**Organization:** Company or department (if shareable)
**Type:** Internal Tool, Client Project, Leadership Initiative
**Duration:** Date Range or Time Period

**Context:** Business context and problem being solved (anonymized if needed)
**Solution:** Overview of the solution provided
**Tech:** Key technologies, if relevant and shareable
**Impact:** Quantifiable impact on business, team, or processes (metrics if available)
```

### Learning Journey

```markdown
## Learning Journey

### Educational Institution or Platform
**Program/Course:** Degree, certification, or course name
**Date Range:** Start - End dates
**Status:** Completed, In Progress, Incomplete

**Focus Areas:** Key subjects or technologies studied
**Projects:** Notable projects completed as part of the learning
**Outcomes:** Skills acquired, achievements, or credentials earned
```

### Domain Knowledge

```markdown
## Domain Knowledge

### Industry or Domain Name
**Exposure:** Years or depth of experience in this domain
**Context:** How this knowledge was acquired (roles, projects, etc.)

**Key Aspects:**
- Specific domain knowledge area and its application
- Particular business processes or industry standards mastered
- Domain-specific tools or methodologies utilized
```

### Specialized Sections

```markdown
## Specialized Sections

### Area of Specialization (e.g., Chrome Extension Development)
**Experience Level:** Years or depth of experience
**Highlight Projects:** List of key projects showcasing this specialty

**Specific Capabilities:**
- Technical ability or specialized knowledge area in this domain
- Tools, technologies, or methods mastered in this specialty
- Notable achievements or innovations in this specialized area
```

## List Formatting

- Use unordered lists (bullet points) for most itemized content
- Start each list item with a capital letter
- End each list item without punctuation unless it contains multiple sentences
- Keep list items concise and focused on a single point or achievement
- Use parallel grammatical structure (start all items with the same part of speech, like verbs or nouns)

## Key-Value Pairs

Key-value pairs provide a consistent way to present structured information:

- Format as `**Key:** Value` (with the key in bold)
- Use consistent key names across similar sections (e.g., always use "Tech:" not "Technology:" in some places)
- Use sentence case for keys (e.g., "Team size:" not "TEAM SIZE:")
- Separate multiple values within a key-value pair with commas
- When a value needs multiple lines, switch to a list format after the key

## Common Key Names

For consistency, use these exact key names:

- **Tech:** - for technology stacks
- **Team:** - for team information
- **Methodology:** - for development approaches
- **Context:** - for business context
- **Impact:** - for measurable outcomes
- **Proficiency:** - for skill levels
- **Acquisition:** - for when/how skills were acquired
- **Repo:** - for repository links
- **Duration:** - for time periods
- **Status:** - for current state (Active, Completed, etc.)

## Emphasis and Highlighting

- Use **bold** for emphasis on key achievements, metrics, or technologies
- Use *italics* for role titles, time periods, and minor emphasis
- Use `code formatting` for specific technical terms, commands, or function names
- Use > blockquotes sparingly for testimonials or direct quotes

## Links and References

- Use descriptive link text for all hyperlinks
- For internal document references, use the format `[Section Name](#section-name)`
- When referencing external resources, use the full URL enclosed in angle brackets for visibility
- Include a reference ID for items that will be cross-referenced from other sections

## Time Formatting

- Use a consistent date format: Month YYYY (e.g., January 2022)
- For ongoing roles or projects, use "Present" (e.g., January 2022 - Present)
- For date ranges, use en-dash with spaces: Month YYYY - Month YYYY

## Additional Guidelines

- Use consistent terminology throughout the document
- Prefer active voice over passive voice
- Be specific about technologies, including version numbers where relevant
- Include quantitative metrics and specific impact where possible
- Maintain consistent spacing (one blank line before headings, no extra blank lines between list items)
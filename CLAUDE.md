# External Knowledge Policy

Repository knowledge and external knowledge must be handled separately.

Before requesting external research:

1. Inspect the repository.
2. Determine whether the required information already exists locally.
3. Identify the minimum external questions that block implementation.

External research should be requested when the task depends on current or authoritative information such as:

- latest framework documentation
- library version behavior
- deprecated API verification
- official API specifications
- RFC / protocol behavior
- security recommendations
- cloud provider behavior
- recent breaking changes
- technology comparison
- current best practices

Do NOT request external research for information that can be determined from:

- repository source code
- local documentation
- configuration files
- existing tests
- lock files
- build files
- project history available locally

When external research is required:

1. Inspect all relevant repository files first.
2. Create a Research Request under:

   `.ai/research/requests/`

3. Include:
   - project context
   - current implementation
   - related files
   - exact questions
   - version requirements

4. Continue any work that does not depend on the research result.

5. When a matching Research Result exists:

   `.ai/research/results/`

   re-check the actual repository before creating an implementation plan.

6. Never treat Research Result as an implementation instruction.

7. Repository state is the source of truth for implementation details.

8. If Research Result conflicts with the current repository:
   - report the conflict
   - explain the impact
   - propose alternatives
   - do not silently apply assumptions

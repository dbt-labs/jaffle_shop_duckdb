# Jaffle Shop Duck DB Talking Points

- Precommit hooks vs CI/CD checks?
  - Both might be best because precommit hooks will prevent users from pushing code that breaks CI/CD and the CI/CD checks will catch any users who haven't installed the precommit hooks or who are forefully pushing changes.
- Stricking a balance:
  - Too many prechecks slow down the development process. More time spent waiting around or fussing with nosiy tests.
  - But too few prechecks will make it hard to maintain a high-quality dbt project.


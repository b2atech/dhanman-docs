# Best practice on git commit messages

Detial description find this [link](https://amit-naik.medium.com/best-practice-on-git-commit-messages-110ad08f3594)

Use conventional commit to Git message

## Type of commit
a. feat: The new feature you’re adding to a particular application
b. fix: A bug fix
c. build: Changes that affect build system or dependencies
d. ci: Changes to CI configuration
e. style: Feature and updates related to styling
f. refactor: Refactoring a specific section of the codebase
g. test: Everything related to testing
h. docs: Everything related to documentation
i. chore: Regular code maintenance
j. perf: Changes that improves performance

### Few examples:
* feat: added customer integration module
* refactor!: removed exception handler library now you can observe ! to make attention that this might have breaking change
* Revert commits: If you want to revert previous commit, then it should begin with revert: followed by header of reverted commit.
Refer for more [detail here](https://www.conventionalcommits.org/en/v1.0.0/)

## Micro commit
A micro commit is a tiny commit. Instead of completing full task and commiting in one go. Better to commit on regular basis. Like if renaming variable, or code formating, or any small changes in your code. This will help you in case if you need to revert any changes from git history



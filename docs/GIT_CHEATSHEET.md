### **Git Essentials Cheat Sheet**

#### **1. Setup & Configuration**
Initialize a new repository or get an existing one.

* `git init`
    Initialize a new Git repository in the current directory.
* `git clone [url]`
    Clone a repository from a remote source.

#### **2. Managing Changes**
Track files and save your work history.

* `git status`
    Show the working tree status (modified, staged, or untracked files).
* `git add .`
    Stage all changes in the current directory for the next commit.
* `git add -A`
    Stage all changes, including deletions, for the next commit.
* `git commit -m "message"`
    Commit the staged changes with a descriptive message.
* `git diff`
    Show changes between the working directory and the staging area.

#### **3. Branching & Navigation**
Isolate new features, experiments, and merge code.

* `git branch`
    List all local branches.
* `git branch [branch-name]`
    Create a new branch.
* `git checkout [branch-name]`
    Switch to a specific branch.
* `git checkout -b [branch-name]`
    Create a new branch and switch to it immediately.
* `git merge [branch-name]`
    Merge the specified branch into the current working branch.
* `git branch -d [branch-name]`
    Delete a local branch.

#### **4. Stashing**
Temporarily save changes without committing, allowing you to switch contexts.

* `git stash`
    Stash the changes in a dirty working directory away.
* `git stash list`
    List the stack of stashed changes.
* `git stash pop`
    Apply the most recently stashed changes and remove them from the stack.
* `git stash apply`
    Apply the stash but keep it in the stack.

#### **5. Synchronization**
Update your local repository with the remote server.

* `git pull`
    Fetch from and integrate with another repository or a local branch.
* `git push`
    Update remote refs along with associated objects.

#### **6. Undoing Changes**
Revert files or commits to a previous state.

* `git checkout -- [filename]`
    Discard changes in the working directory for a specific file.
* `git reset [filename]`
    Unstage a file while keeping the changes in the working directory.
* `git reset --hard`
    Discard all local changes in the working directory and staging area.
* `git revert [commit-id]`
    Create a new commit that reverses the changes of a specific previous commit.
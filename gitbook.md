# GitBook

Yo dawg, I heard you like documentation that tells you how to make
documentation.  So we wrote a doc to explain how we doc, so you can doc,
while you doc.

Anyway...

We will show you how to use GitBook for documentation.

## What is GitBook?

GitBook is an online platform for writing and hosting documentation. On the
other hand, GitBook is a publishing platform that, once a repository is
configured and conforms to the configuration, the files in the repository can
be rendered through a build pipeline that outputs to a number of destinations.

Destinations like:

- A static website that is searchable and displays a TOC.
- Downloadable PDF, ePub and MOBI formats for eBOOK and computer reading anywhere.

In the codex project, we use github to host the repository, using Gitbook to publish
different formats of the codex book. You can go to [codex Gitbook][codex-gitbook]
to read the codex book, click **READ** in the blue box on the right, or download
different formats of the codex book.

### Table of Contents

The Table of Contents for the book is managed by the `TOC.md` file.  A user can
scan the contents of the book and output to the `TOC.md` file.

```
./bin/update_toc
```

This list of files which are scanned for use as **Guides** or **Topics** is
defined within `bin/update_toc`.

The **Guides** are long form documents that take operators step-by-step through
the process of configuring BOSH and Cloud Foundry on a given infrastructure type
(AWS, Azure, etc.).

Each of the **Topics** cover specific knowledge on a given topic.

Finally, we order the **Guides** alphabetically, and the **Topics** in natural
reading order (i.e., troubleshooting at the end).

### Automated Updates

It is pretty easy how updates work between GitBook and GitHub. You can just make
your changes, commit and push to the master branch of the codex repository, the
changes will be automatically built by GitBook pipeline. Once the build is
completed, you can see the changes in all the formats of the codex GitBook.

Note: When making changes to the headings in markdown doc, the table of contents
is not updated until you make the corresponding changes in `TOC.md`.

### Accounts

We created two accounts.  A GitHub account `snw-gitbook` and a GitBook account
`starkandwayne`.  Both are in the Stark & Wayne 1Password vault in Dropbox.

If you’re already signed into GitBook with another account, sign out. Then go
to https://www.gitbook.com/ and click on SIGN IN. Type in the username:
`starkandwayne` and put in the password from 1Password.

To set a source repository for the codex GitBook, we need to configure a GitHub
account. Here we  use our `snw-gitbook` GitHub account for the purpose.

### Collaborators

When signed in to GitBook, and you know the username or email address to add
someone, use the collaborator link to add users.

[codex-gitbook]:   https://www.gitbook.com/book/starkandwayne/codex/details

# datapower-tutorials

Contains the source content for https://developer.ibm.com/datapower/blog

To write a new blog:

1. If necessary, `git clone https://github.com/ibm-datapower/datapower-tutorials.git`
1. Make a new sub-directory inside `datapower-tutorials`, following existing conventions. (contact Tony or Francisco if you don't have access)
1. Write the post in markdown. A markdown editor makes this easier, perhaps MacDown or Atom. When you write, don't use H1, start with H2 such as `## Heading 2`. If you use `# Heading 1` later steps won't work correctly.
1. Place any images inside a directory called `media` inside your post's directory
1. When you're done, `git commit` and `git push`. and ask for review.
1. Create a new post in the [http://developer.ibm.com/datapower](http://developer.ibm.com/datapower).
1. if you have any images to upload, add them before the next step by clicking on Add Media. Drag all files in your `media` directory into the browser.
1. Adding media will insert links into your document. Take note of the three numbers following '/sites/' in the URL. For instance, in https://developer.ibm.com/datapower/wp-content/uploads/sites/**88/2016/11**/ics-test-container-overview.png, it is `88/2016/11`.
1. Use gfm-wordpess to convert the markdown into HTML (if you don't have it, install with `npm -g install gfm-wordpress`). There is some header material that has to be removed, we'll do that with sed. Be sure to replace `88/2016/11` with the directory from the previous step. The command is `gfm-wordpress --media="88/2016/11" ./decrypt-tls-using-master-secret-logging.md | sed -e '1,1s;^.*</ol>;;g'`
1. Copy the HTML produced by gfm-wordpress into the post and preview it. Make any corrections if necessary in the markdown and repeat the edit, transform, copy, preview process.
1. Once you are happy with the post and the formatting, submit it for publishing

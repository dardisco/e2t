# e2t - Elisp to TexInfo

*Author:* C. Dardis <christopherdardis@gmail.com><br>
*Version:* 0.1<br>
*URL:* [http://github.com/dardisco/e2t](http://github.com/dardisco/e2t)<br>

Use a single elisp file (`.el`) to generate
a Texinfo (`.texi`) manual.
 
This is intended to generate simple documentation for a package
which is given by a single .el file.

As most packages consist for the most part of a series of
defintions, the documentation is grouped by definition type e.g.
`defun`, `defvar`, `defcustom`. The documentation for this
package was produced in this way, i.e. it is self-documenting.

The package was developed as a way to automate the creation
of documentation for elisp packages. The documentation produced is
somewhat 'bare bones', although should serve as a useful
starting point.
Notably, the `.texi` produced does *not* handle cross-references
in the same way that the help within Emacs does e.g.
referencing another variable or function in help for a function
will *not* lead to a corresponding cross reference in
the `.texi` documentation.

### Installation

This package can be installed using

    (package-install-from-file "/path/to/e2t.el")

Or place the folliwng in your init.el file:

    (add-to-list 'load-path "~/path/to/directory")
    (require 'e2t)

### Usage

To generate a .texi file use the `e2t` command, as below.
     
	 M-x e2t-e2t RET
	 
To convert this to .pdf, use for example

    (shell-command "texi2pdf file-name-base.texi")

### Variable names

Function-local/temporary variables are named using
as nameNumber e.g. `v1`, `beg1`.



---
Converted from `e2t.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).

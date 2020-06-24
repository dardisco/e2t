;;; e2t.el --- Elisp to TexInfo. -*- lexical-binding:t -*-

;; Copyright 2020 - Chris Dardis

;; Author: C. Dardis <christopherdardis@gmail.com>

;; Version: 0.1

;; Package-Requires: ((subr-x) (tex) (texinfo) (tex-info))
;; Keywords: Lisp, docs, Tex
;; URL: http://github.com/dardisco/e2t

;; This program is free software: you can redistribute
;;  it and/or modify it under the terms of the
;;  GNU General Public License as published by
;;  the Free Software Foundation, either version 3
;;  of the License, or (at your option) any later version.
;; This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;; You should have received a copy of the GNU
;;  General Public License along with this program.
;; If not, see <http://www.gnu.org/licenses/>.
;;
;; News
;;
;; 2020 - version 0.1 is the first release.
;; 
;;; Commentary:
;;
;; Use a single elisp file (`.el') to generate
;; a Texinfo (`.texi') manual.
;; 
;; This is intended to generate simple documentation for a package
;; which is given by a single .el file.
;;
;; As most packages consist for the most part of a series of
;; defintions, the documentation is grouped by definition type e.g.
;; `defun', `defvar', `defcustom'. The documentation for this
;; package was produced in this way, i.e. it is self-documenting.
;;
;; The package was developed as a way to automate the creation
;; of documentation for elisp packages. The documentation produced is
;; somewhat 'bare bones', although should serve as a useful
;; starting point.
;; Notably, the `.texi' produced does *not* handle cross-references
;; in the same way that the help within Emacs does e.g.
;; referencing another variable or function in help for a function
;; will *not* lead to a corresponding cross reference in
;; the `.texi' documentation.
;;
;;; Installation:
;;
;; This package can be installed using
;;
;; (package-install-from-file "/path/to/e2t.el")
;;
;; Or place the folliwng in your init.el file:
;;
;; (add-to-list 'load-path "~/path/to/directory")
;; (require 'e2t)
;;
;;; Usage:
;;
;; To generate a .texi file use the `e2t' command, as below.
;;     M-x e2t-e2t RET
;; To convert this to .pdf, use for example
;; (shell-command "texi2pdf file-name-base.texi")
;;
;;
;;; Variable names:
;; 
;; Function-local/temporary variables are named using
;; as nameNumber e.g. `v1', `beg1'.
;;

;;; Code:

(mapc #'require
      '(subr-x tex texinfo tex-info))

(defcustom e2t-include-function-code t
  "Include source code for functions, if non-nil."
  :type '(radio
	  (const :doc "Yes (include function code)"
		 :value t)
	  (const :doc "No (do not include function code)"
		 :value nil))
  :group 'e2t)

(defcustom e2t-headers
  '(;; about the file
    "Filename"
    "Description"
    ;; authorship
    "Copyright"
    "Author"
    "Maintainer"
    ;; on the web
    "Homepage"
    "URL"
    "EmacsWiki"
    "X-URL"
    "Doc URL"
    "URL (GIT mirror)"
    ;; version
    "Created"
    "Package-Version"
    "Version"
    "Last-Updated"
    ;; keywords
    "Keywords"
    "Compatibility" 
    ;; more about the package
    "Package-Version"
    "Package-Requires"
    ;; longer sections (conventional)
    "License"
    "[^\n]+free software"
    "News"
    "Commentary"
    ;; longer sections (less conventional)
    "Wishlist"
    "Prior Art"
    "Notes" 
    "Compatibility and Requirements" 
    "Bugs"
    "TODO" 
    "Change Log")
  "Headers to look for in the preabmle of an .el file.
The file should specify a single package.

'Preamble' means the text between the beginning of the file
and \"`e2t-header-prefix'Code:\",
which should all be commented.

As the use of headers is not enforced rigidly,
they appear in conventional order for
a typical single-file package.  The list is not exhaustive, but
taken from examples from a variety of packages.

Although these are all regular expressions, the only one which
uses this syntax is \"[^\n]+free software\", which is done as
the software license is often given without a preceding heading.

All headers are matched by prefixing them with `e2t-header-prefix'.
These values are used by `e2t-insert-headers'."
  :type '(repeat (regexp :tag "expression"))
  :link '(info-link "(elisp) Packaging")
  :link '(info-link "(elisp) Simple Packages")
  :group 'e2t)

(defcustom e2t-first-defs
  '(defgroup
     define-major-mode
     define-minor-mode
     defmacro
     defun
     defsubst
     defcustom
     defvar
     defconst
     define-skeleton)
  "Definitions, given as symbols, to appear first in the .texi file. 
These should reflect, in order of priority,
the most important definitions in a typical package.
These are used by `e2t-gen-defs'.
By default, additional definitions in the package will appear after these,
in alphabetical order."
  :group 'e2t
  :type '(repeat symbol)
  :safe #'fboundp)

(defcustom e2t-defs '()
  "A list of definitions in the .el source file. 
from which to generate the .texi documentation. 
By default, this is set when the package is loaded by `e2t-gen-defs'."
  :group 'e2t
  :type '(repeat symbol)
  :safe #'fboundp)

(defun e2t-gen-defs ()
  "Generate definitions. 
Modifies `e2t-defs' (initially empty), 
 so that it contains the names of all the definitions 
 for which to look in the .el source file."
  (mapatoms
   (lambda (x)
     (when
	 (and
	  (fboundp x)
	  (string-prefix-p "def" (symbol-name x))
	  (not (string-prefix-p "default-"
				(symbol-name x))))
       (push x e2t-defs))))
  (set 'e2t-defs
       (sort e2t-defs (lambda (x y) (string< x y))))
  (dolist (x (reverse e2t-first-defs))
    (when (member x e2t-defs)
      (set 'e2t-defs (delq x e2t-defs))
      (push x e2t-defs))))

(eval-after-load 'e2t
  (funcall 'e2t-gen-defs))

(defvar e2t-fnb ""
  "The `file-name-base' (a string) for the working file in `mp-dd'.
Set when `e2t-e2t' is run.
Defined here as a dynamic variable so that
various functions can use this value.")

(defun e2t-get-file-name ()
  "The file name from which to generate documentation.
If the current buffer is an .el file, return this filename.
Otherwise, return the newest .el file in the `default-directory'."
  (if (equalp "el" (file-name-extension (buffer-file-name)))
      (buffer-file-name)
    (car
     (sort
      (directory-files
       default-directory nil "^[^\\.].*\\.el$" t)
      #'file-newer-than-file-p))))

;;;### autoload
(defun e2t-e2t ()
  "Use an .el file to produce a.texi file and thereafter a .pdf.
Uses the most recently modified .el file in the directory.
Then calls `e2t-el-texi'."
  (interactive)
  (let ((filename1 (e2t-get-file-name)))
    (setq e2t-fnb (file-name-base filename1))
    (e2t-file-display filename1)
    (e2t-file-display (concat e2t-fnb ".texi"))
    (erase-buffer)
    (e2t-el-texi)))

(defun e2t-file-display (FILE-NAME)
  "Display FILE-NAME."
  (let ((bn1 (car
	      (member FILE-NAME
		      (mapcar 'buffer-name (buffer-list))))))
    (if bn1
	(pop-to-buffer bn1)
      (find-file FILE-NAME))))

(defun e2t-el-texi ()
  "Make a .texi file using `e2t.fnb'.el."
  (e2t-preamble-skeleton e2t-fnb)
  (e2t-title-skeleton e2t-fnb)
  (e2t-insert-headers)
  (e2t-insert-defs)
  (e2t-insert-sexps)
  (when (e2t-end-skeleton e2t-fnb)
    (e2t-replace-at-verbatim))
  (when (featurep 'texinfo)
    (texinfo-master-menu t))
  (save-buffer))

(define-skeleton e2t-preamble-skeleton
  "Insert preamble for a texi file."
  \n
  "\\input texinfo" \n \n
  "@set NAME " str \n
  '(setq v1 (e2t-get-regexp "Package-Version"))
  '(unless v1
     (setq v1 (e2t-get-regexp "Version")))
  "@set VERSION " v1 \n
  "@set UPDATED " (format-time-string "%B %e, %Y") \n
  "@setfilename @value{NAME}" \n
  "@finalout" \n
  "@c %**start of header" \n
  "@settitle @value{NAME} @value{VERSION}" \n
  "@syncodeindex pg cp " \n
  "@c %**end of header " \n \n
  "@copying" \n
  "This manual is for @value{NAME}, version @value{VERSION}" \n
  '(set 'v1 (e2t-get-regexp "Copyright"))
  "Copyright @copyright{} " v1 \n
  '(set 'v1 (e2t-get-regexp "[^\n]+free software"))
  "@quotation" \n
  v1 \n \n
  "@end quotation" \n
  "@end copying" \n \n
  '(set 'v1 (e2t-get-regexp "Keywords"))
  "@dircategory " v1 \n
  "@direntry" \n
  '(set 'v1 (e2t-get-name-first-line))
  "* @value{NAME} (@value{NAME})." v1 \n
  "* install-info: (@value{NAME})" \n
  "Invoking install-info." \n "..." \n "..." \n
  "@end direntry" \n \n)

(defun e2t-get-regexp (REGEXP)
  "Get REXEXP, one line if SINGLE-LINE is non-nil."
  (let ((code1 nil)
	(beg1 nil)
	(end1 nil)
	(res1 nil))
    (with-current-buffer (concat e2t-fnb ".el")
      (save-excursion
	(goto-char (point-min))
	(search-forward-regexp "^;+ ?Code:$" nil t)
	(setq code1 (line-beginning-position))
	(goto-char (point-min)))
      (save-excursion
	(goto-char (point-min))
	(when (search-forward-regexp
	       (concat e2t-header-prefix REGEXP)
	       code1 t)
	  (setq beg1 (line-beginning-position)
		end1 code1)
	  (when
	      (search-forward-regexp 
	       (mapconcat
		(lambda (y) (concat e2t-header-prefix y))
		(remove REGEXP e2t-headers)
		"\\|")
	       end1 t)
	    (setq end1 (line-beginning-position)))
	  (setq res1 (buffer-substring-no-properties
		      beg1 end1))
	  (setq res1 (string-trim
		      (replace-regexp-in-string
		       "^;+" "" res1))
		res1 (replace-regexp-in-string
		      "@" "@@" res1))
	  (when (equalp REGEXP
			(substring res1 0 (length REGEXP)))
	    (setq res1
		  (string-trim
		   (substring res1 (length REGEXP)))
		  res1
		  (string-trim (replace-regexp-in-string
				"^:" "" res1)))))))))

(defconst e2t-header-prefix
  (concat "^" comment-start "+ ?")
  "Prefix used before a header.
This is combined with the regular expressions of `e2t-headers'.")

(defun e2t-get-name-first-line ()
  "Get name of package from first line of `e2t-fnb'.el."
  (with-current-buffer (concat e2t-fnb ".el")
    (save-excursion
      (goto-char (point-min))
      (search-forward-regexp
       (concat e2t-header-prefix ".*--+") (line-end-position) t)
      (setq beg1 (point))
      (search-forward-regexp
       "\\. " (line-end-position) t)
      (string-trim
       (buffer-substring-no-properties beg1 (point))))))

(define-skeleton e2t-title-skeleton
  "Insert title."
  \n
  "@titlepage" \n "@title @value{NAME}" \n
  "@subtitle for version @value{VERSION}, @value{UPDATED}" \n
  '(set 'v1 (e2t-get-regexp "Author"))
  "@author " v1 \n
  "@page" \n
  "@vskip 0pt plus 1filll" \n
  "@insertcopying" \n
  "@end titlepage" \n \n
  -
  "@contents" \n \n
  "@ifnottex" \n
  "@node Top" \n
  "@top @value{NAME}" \n
  "This manual is for @value{NAME} version @value{VERSION}, @value{UPDATED}" \n
  "@end ifnottex" \n \n -)

(defun e2t-insert-headers ()
  "Insert the headers in `e2t-headers'."
  (e2t-node-skeleton "Preamble")
  (when (e2t-check-lexical-binding)
    (insert
     "@code{lexical binding} is @code{t}.@*\n"))
  (with-current-buffer (concat e2t-fnb ".texi")
    (dolist (x e2t-headers res1)
      (setq res1 (e2t-get-regexp x))
      (when res1
	(insert
	 (concat
	  "@strong{"
	  (if (equalp x "[^\n]+free software")
	      "License"
	    x)
	  "}: "
	  (if (string-match "URL" x)
	      (concat "@uref{" res1 "}")
	    res1)
	  " @*\n"))))))

(define-skeleton e2t-node-skeleton
  "Insert a node, str."
  nil
  "@node " str \n
  "@chapter " str \n
  "@cindex " str \n \n \n)

(defun e2t-check-lexical-binding ()
  "Check if the header line contains 'lexical-binding:t'.
Applies to the file `e2t-fnb'.el."
  (with-current-buffer (concat e2t-fnb ".el")
    (save-excursion
      (goto-char (point-min))
      (if (search-forward
	   "lexical-binding:t"
	   (line-end-position) t)
	  t
	nil))))

(defun e2t-insert-defs ()
  "Insert definitions, given by `e2t-defs'."
  (let ((x nil)
	(y nil)
	(fun1 nil)
	(i nil))
    (dolist (x e2t-defs)
      (setq y (e2t-get-sexp x))
      (when (>= (length y) 1)
	(with-current-buffer (concat e2t-fnb ".texi")
	  (e2t-node-skeleton (format "%s" x))
	  (insert
	   (concat
	    "Documentation for @code{"
	    (format "%s" x)
	    "}: @*\n"
	    (documentation x)
	    "@*\n\n"
	    "A table of all @code{"
	    (format "%s" x)
	    "}s follows:\n\n"))
	  (e2t-table y)
	  (insert
	   (concat "Details of each @code{"
		   (format "%s" x)
		   "} follow below: @*\n\n"))
	  (setq fun1
		(cond
		 ((eq x (or 'defun 'defsubst))
		  'e2t-insert-defun)
		 ((eq x 'defcustom)
		  'e2t-insert-defcustom)
		 (t 'e2t-insert-symbol)))
	  (dolist (i y)
	    (insert
	     (concat
	      "@cindex " (format "%s" (cadr i)) "\n"
	      "@unnumberedsec " (format "%s" (cadr i)) "\n"))
	    (funcall fun1 i)))))))

(defun e2t-get-sexp (SEXP)
  "Get a list of SEXPs from  `e2t-fnb'.el."
  (with-current-buffer (concat e2t-fnb ".el")
    (save-excursion
      (goto-char (point-min))
      (search-forward-regexp "^;+ ?Code.+\n" nil t)
      (let ((res1 '()))
	(while (not (= (point) (point-max)))
	  (with-demoted-errors "Error in (forward-sexp): %S"
	    (forward-sexp))
	  (when (eq SEXP (car (sexp-at-point)))
	    (push (sexp-at-point) res1)))
	(nreverse res1)))))

(defun e2t-table (LIST)
  "Insert LIST as a two-column table into a .texi file.
For functions, the table is given as @@ftable @@code.
For variables, the table is given as @@vtable @@var."
  nil
  (let ((table1 (if (fboundp (caar LIST))
		    '("ftable" "code")
		  '("vtable" "var"))))
    (insert
     (concat "\n@" (car table1) " @" (cadr table1) "\n"))
    (while LIST
      (setq v1 (pop LIST))
      (setq v2 (if (fboundp (cadr v1))
		   (documentation (cadr v1))
		 (documentation-property
		  (cadr v1) 'variable-documentation)))
      (when v2
	(setq v2 (format "%s" (car (split-string v2 "\n" t " ")))))
      (insert
       (concat "@item " (format "%s" (cadr v1)) "\n"
	       (if v2
		   v2
		 "") "\n")))
    (insert
     (concat
      "@end " (car table1) "\n\n"))))

(defun e2t-insert-defun (FUNCTION)
  "Insert FUNCTION into the file `e2t-fnb'.texi."
  (let* ((name1 (format "%s" (cadr FUNCTION)))
    	 (fun1 (cadr FUNCTION))
    	 (args1 (help-function-arglist fun1 t))
    	 (com1 (commandp fun1))
    	 (doc1 (documentation fun1))
	 (sf1 (symbol-function fun1))
    	 (fc1 (if e2t-include-function-code
		  (pp
		   (if (stringp (elt sf1 3))
		       (cddr (cddr sf1))
		     (cdr (cddr sf1))))
		nil)))
    (with-current-buffer (concat e2t-fnb ".texi")
      (insert
       ;; @* = force line break
       (concat "@defun " name1 " \n"))
      (insert
       (concat
    	"Command ? "
    	(if com1
    	    "@emph{yes}"
    	  "@emph{no}") " @*\n"))
      (insert 	"Arguments: ")
      (if (not args1)
    	  (insert "@emph{none}")
    	(while args1
    	  (setq name1 (pop args1))
    	  (insert (if (eq name1 '&optional)
		      "@code{&optional} "
		    (concat "@var{" (format "%s" name1) "} ")))))
      (insert " @*\n")
      (insert
       (concat "Documentation: "
    	       (if (not doc1)
    		   "@emph{Not documented.} @*\n\n"
    		 (concat doc1 "\n\n"))))
      (when fc1
    	(insert
    	 (concat "@smallformat @verbatim \n"
    		 fc1 "@end verbatim \n @end smallformat \n")))
      (insert "@end defun \n\n"))))

(defun e2t-replace-at-verbatim ()
  "Replace the text '[at] end verbatim' with [at] end verbatim.
Here, [at] is the at symbol, @@.
This is done for text appearing *inside* a verbatim envinronment,
to avoid escaping the environment before we mean to do so."
  (with-current-buffer (concat e2t-fnb ".texi")
    (save-excursion
      (goto-char (point-min))
      (while
	  (search-forward-regexp "^ *@smallformat @verbatim" nil t)
	(let ((end1 nil))
	  (save-excursion
	    (search-forward-regexp "^ *@end verbatim")
	    (setq end1 (line-beginning-position)))
	  (save-excursion
	    (while
		(search-forward "@end verbatim" end1 t)
	      (replace-match "@ end verbatim")
	      (setq end1 (+ end1 1)))
	    (search-forward-regexp "^ *@end verbatim")))))))

(defun e2t-insert-defcustom (DEFCUSTOM)
  "Insert DEFCUSTOM."
  (insert
   (concat
    "@defopt " (format "%s" (cadr DEFCUSTOM) "\n\n")))
  (save-excursion
    (e2t-insert-symbol-plist DEFCUSTOM)
    (insert "\n@end defopt \n\n"))
  (save-excursion
    (while
	(search-forward-regexp "\\(:\\)\\([a-z-]+\\)" nil t)
      ;; replace matched string with regexp group #2
      (replace-match "@code{:\\2}")))
  (search-forward "@end defopt \n\n"))

(defun e2t-insert-symbol (SYMBOL)
  "Insert SYMBOL."
  (insert
   (concat
    "@deffn "
    (format "%s" (car SYMBOL))
    " "
    (format "%s" (cadr SYMBOL))
    "\n"))
  (e2t-insert-symbol-plist SYMBOL)
  (insert "\n@end deffn \n\n"))

(defun e2t-insert-symbol-plist (SYMBOL)
  "Insert `symbol-plist' for SYMBOL."
  (let ((x (symbol-plist (cadr SYMBOL))))
    (when x
      (insert "\n@table @var\n")
      (when (fboundp (cadr SYMBOL))
	(insert
	 (concat
	  "@item Documentation:\n"
	  (documentation (cadr SYMBOL)) "\n")))
      (while x
	(insert
	 (concat "@item "
		 (format "%s" (pop x)) "\n"
		 (format "%s" (pop x)) "\n")))
      (insert "@end table"))))

(defun e2t-insert-sexps ()
  "Insert symbolic expressions.
Excludes the definitions in `e2t-defs'."
  (let ((x)
	(sexp1 nil))
    (with-current-buffer (concat e2t-fnb ".el")
      (goto-char (point-min))
      (search-forward-regexp "^;+ ?Code:$" nil t)
      (forward-line 1)
      (while (< (point) (point-max))
	(with-demoted-errors "Error in (forward-sexp): %S"
	  (forward-sexp))
	(setq x (sexp-at-point))
	(unless (member (car x) e2t-defs)
	  (push x sexp1))))
    (when sexp1
      (with-current-buffer (concat e2t-fnb".texi")
	(e2t-node-skeleton "Other symbolic expressions")
	(insert "@smallformat @verbatim \n")
	(dolist (x (nreverse sexp1))
	  (when x
	    (insert (concat (pp x) "\n"))))
	(insert "@end verbatim \n @end smallformat \n")))))

(define-skeleton e2t-end-skeleton
  "Insert Index and closing code to a .texi file."
  > "@node Index
@unnumbered Index
@printindex cp
@bye \n
@c Local Variables:
@c mode: texinfo
@c TeX-master: t
@c End" \n \n)

(defgroup e2t nil
  "Elisp to TexInfo.
This is a series of variables and functions to generate a
.texi file from a .el file."
  :prefix "e2t-"
  :version 0.1)

(provide 'e2t)

;;; e2t.el ends here

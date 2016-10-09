;;; init.el --- Make Emacs useful!
;;; Author: Vedang Manerikar
;;; Created on: 10 Jul 2016
;;; Commentary:

;; This file is a bare minimum configuration file to enable working
;; with Emacs for Helpshift newcomers.

;;; Code:

(when (version< emacs-version "25")
  (error "Unsupported Emacs Version! Please upgrade to a newer Emacs.  Emacs installation instructions: https://www.gnu.org/software/emacs/download.html"))

;; Set a directory for temporary/state related files.
(defvar dotfiles-dirname
  (file-name-directory (or load-file-name
                           (buffer-file-name)))
  "The directory where this code is running from.
Ideally, this will be ~/.emacs.d.")
(defvar tempfiles-dirname
  (concat dotfiles-dirname "temp-files/")
  "A sub-directory to hold temporary files generated by Emacs.")

;; Create the temp-files folder if necessary.
(make-directory tempfiles-dirname t)

;;; El-Get for great good.
(defvar el-get-dir
  (concat dotfiles-dirname "el-get/")
  "The sub-directory where el-get packages are installed.")

(defvar el-get-user-package-directory
  (concat dotfiles-dirname "el-get-config/")
  "The sub-directory where optional user-configuration for various packages, and user-defined recipes live.")

(defvar el-get-my-recipes
  (concat el-get-user-package-directory "personal-recipes/")
  "The sub-directory where user-defined recipes live, if the user needs to define and install his/her own recipes.")

;; Make the el-get directories if required
(make-directory el-get-dir t)
(make-directory el-get-my-recipes t)

;; Add el-get to the load-path. From this point onward, we're plugged
;; into the el-get package management system.
(add-to-list 'load-path (concat el-get-dir "el-get"))

;; Install el-get if it isn't already present
(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.github.com/dimitri/el-get/master/el-get-install.el")
    (let (el-get-master-branch
          el-get-install-skip-emacswiki-recipes)
      (goto-char (point-max))
      (eval-print-last-sexp))))

;; Add our personal recipes to el-get's recipe path
(add-to-list 'el-get-recipe-path el-get-my-recipes)

;;; Load packaging info for clojure
(require 'hs-clj-packages)

;;; This is the order in which the packages are loaded. Changing this
;;; order can sometimes lead to nasty surprises: eg: when you are
;;; overshadowing some in-built libraries or when you expect a package
;;; to already be loaded in order to fix system paths (*cough*
;;; `exec-path-from-shell' *cough*)

(setq el-get-sources
      (append

       (when (and (eq system-type 'darwin)
                  (eq window-system 'ns))
         ;; Emacs plugin for dynamic PATH loading - Fix Emacs's
         ;; understanding of the the Path var on Mac.
         '((:name exec-path-from-shell
                  :after (progn (exec-path-from-shell-initialize)))))

       '( ;; Fixing weird quirks and poor defaults
         (:name better-defaults)

         ;; Modular in-buffer completion framework for Emacs
         (:name company-mode
                :after (progn (require 'company)
                              (add-hook 'after-init-hook 'global-company-mode)
                              (setq-default company-lighter " cmp")
                              (define-key company-active-map
                                [tab] 'company-complete)
                              (define-key company-active-map
                                (kbd "TAB") 'company-complete)))

         ;; Emacs incremental completion and narrowing framework
         (:name helm
                :after (progn ;; Explicitly turn off global `helm-mode'.
                         ;; Only use it where required. Prefer `ido'
                         ;; globally.
                         (helm-mode -1)
                         ;; Various useful key-bindings (other than Helm Defaults)
                         ;; Useful Helm Defaults: C-x c i, C-x c I
                         ;; unset this because I plan to use it as a prefix key.
                         (global-set-key (kbd "C-x c r") nil)
                         (global-set-key (kbd "C-x c r b") 'helm-filtered-bookmarks)
                         (global-set-key (kbd "C-x c r r") 'helm-regexp)
                         (global-set-key (kbd "C-x c C-b") 'helm-mini)
                         (global-set-key (kbd "M-y") 'helm-show-kill-ring)
                         (global-set-key (kbd "C-x c SPC") 'helm-all-mark-rings)
                         (global-set-key (kbd "C-h SPC") 'helm-all-mark-rings)
                         (global-set-key (kbd "C-x c r i") 'helm-register)))

         ;; Jump to things in Emacs tree-style.
         (:name avy
                :after (progn (global-set-key (kbd "M-g g") 'avy-goto-line)
                              (global-set-key (kbd "M-g SPC") 'avy-goto-word-1)
                              (avy-setup-default)))

         ;; Minor mode for editing parentheses
         (:name paredit
                :after (progn (eval-after-load 'paredit
                                '(progn
                                   ;; `(kbd "M-s")' is a prefix key for a
                                   ;; bunch of search related commands by
                                   ;; default. I want to retain this.
                                   (define-key paredit-mode-map (kbd "M-s") nil)))
                              (add-hook 'emacs-lisp-mode-hook
                                        'enable-paredit-mode)))

         ;; It's Magit! An Emacs mode for Git.
         (:name magit
                :after (progn (global-set-key (kbd "C-x g") 'magit-status)))

         ;; A low contrast color theme for Emacs.
         (:name color-theme-zenburn))

       (if use-older-clj-versions
           ;; Set up recipes to support development against older
           ;; Clojure versions
           (progn (hs-cleanup-previous-install-if-necessary)
                  hs-clojure16-env)
         ;; Set up recipes to support development against Clojure
         ;; version 1.7 and above.
         (progn (hs-cleanup-previous-install-if-necessary)
                hs-latest-stable-clojure-env))))

(el-get 'sync
        (mapcar 'el-get-source-name el-get-sources))

(hs-store-clojure-env-ver use-older-clj-versions)

;; Modify the CMD key to be my Meta key
(setq mac-command-modifier 'meta)

(require 'ido)
(require 'recentf)
(require 'saveplace)
(save-place-mode)

;; Move Emacs state into the temp folder we've created.
(setq ido-save-directory-list-file (concat tempfiles-dirname "ido.last")
      recentf-save-file (concat tempfiles-dirname "recentf")
      save-place-file (concat tempfiles-dirname "places")
      backup-directory-alist `(("." . ,(concat tempfiles-dirname "backups"))))

;; `visible-bell' is broken on Emacs 24 downloaded from Mac for OSX
(when (< emacs-major-version 25)
  (setq visible-bell nil))

;;; Interactively Do Things
;; basic ido settings
(ido-mode t)
(ido-everywhere)
(setq ido-enable-flex-matching t
      ido-use-virtual-buffers t
      ido-create-new-buffer 'always)
(add-hook 'ido-make-buffer-list-hook 'ido-summary-buffers-to-end)

;; Ido power user settings
(defadvice completing-read
    (around ido-steroids activate)
  "IDO on steroids :D from EmacsWiki."
  (if (boundp 'ido-cur-list)
      ad-do-it
    (setq ad-return-value
          (ido-completing-read
           prompt
           (all-completions "" collection predicate)
           nil require-match initial-input hist def))))


;;; Theme and Look
;; This should load after `custom-safe-themes' to avoid Emacs
;; panicking about whether it is safe or not.
(load-theme 'zenburn t)

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(require 'package)
(package-initialize)

(provide 'init)
;;; init.el ends here

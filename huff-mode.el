;;; huff-mode.el --- Major mode for editing Huff files -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Gokhan Polat
;;
;; Author: Gokhan Polat <gokhan.plt@gmail.com>
;; Maintainer: Gokhan Polat <gokhan.plt@gmail.com>
;; Created: December 29, 2022
;; Modified: December 29, 2022
;; Version: 0.0.1
;; Keywords: languages huff
;; Homepage: https://github.com/dev/test
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;
;;; Commentary:
;; A major mode for Huff language.
;; It supports only syntax highlighting.
;;
;;; Code:

(require 'cc-mode)

(defgroup huff nil
  "Major mode for editing Huff language."
  :prefix "huff-"
  :group 'languages ;; Emacs -> Programming -> Languages
  :link '(url-link :tag "Github" "https://github.com/gokhanpolat/emacs-huff-mode")
  :link '(emacs-commentary-link :tag "Commentary" "ng2-mode"))

(defcustom huff-mode-hook nil
  "Callback hook to execute whenever a huff file is loaded."
  :type 'hook
  :group 'huff)

;;
;;; Settings
(defvar huff-mode t "The huff major mode.")

;;
;;; Navigation commands

(defun huff-goto-label (label)
  "Jump to the label entitled LABEL."
  (interactive "sGo to Label: ")
  (let ((orig-pt (point)))
    (goto-char (point-min))
    (unless (re-search-forward (format "[ \t]*%s:" label))
      (goto-char orig-pt))))

(defun huff-next-label ()
  "Jump to next label after point."
  (interactive)
  (let ((orig-pt (point)))
    (condition-case _
        (save-match-data
          (goto-char (point-at-eol))
          (re-search-forward "^[ \t]*[a-zA-Z0-9_.]+:")
          (goto-char (match-beginning 0)))
      (error
       (goto-char orig-pt)
       (user-error "No next label")))))

(defun huff-previous-label ()
  "Jump to previous label before point."
  (interactive)
  (let ((orig-pt (point)))
    (condition-case _
        (save-match-data
          (goto-char (point-at-bol))
          (re-search-backward "^[ \t]*[a-zA-Z0-9_]+:")
          (goto-char (match-beginning 0)))
      (error
       (goto-char orig-pt)
       (user-error "No previous label")))))

(defun huff-goto-label-at-cursor ()
  "Jump to the label that matches the symbol at point."
  (interactive)
  (huff-goto-label (symbol-at-point)))


(defconst huff-line-re
  (concat
   "\\([a-zA-Z0-9_]*\\)"     ;; opcode/operator
   "\\(?:[ \t]*\\)?\\([a-zA-Z0-9_]*:\\)?"      ;; label definition
   "\\(?:[ \t]*\\)?\\(\".*\"\\|[^#\n^]+?\\)?"  ;; operands/registers
   "\\(?:[ \t]*\\)?\\(//[^\n]*\\)?$"           ;; comments
   "\\(?:[ \t]*\\)?\\([\a-zA-Z0-9_]*\\)?"     ;; opcode/operator
   )
  "An (excessive) regexp to match HUFF assembly statements.")

(defconst huff-comment-line-re "^[ t]*\/\/[^\n]*"
  "Regexp to match comment-only lines.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            Solidity Related Keywords                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar huff-solidity-constants
  '("true"
    "false"
    "wei"
    "szabo"
    "finney"
    "ether"
    "seconds"
    "minutes"
    "hours"
    "days"
    "weeks"
    "years")
  "Constants in the solidity language.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            Huff Related Keywords                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar huff-nonopcode-keywords
  '(
    "macro"
    "function"
    "event"
    "constant"
    "payable"
    "nonpayable"
    "indexed"
    "view"
    "#define"
    "#include")
  "Huff keyords.")


(defvar huff-special-keywords
  '(
    "FREE_STORAGE_POINTER")
  "Huff special keywords.")

;; https://github.com/huff-language/huff-rs/blob/e0f640f12373e0a98edfc1e33eb4cc40c6bec129/huff_utils/src/ast.rs#L708
(defvar huff-builtin-function-keywords
  '(
    "__tablesize"
    "__codesize"
    "__tablestart"
    "__FUNC_SIG"
    "__EVENT_HASH"
    "__ERROR"
    "__RIGHTPAD"
    "__CODECOPY_DYN_ARG")
  "Huff builtin keywords.")

(defvar huff-evm-keywords
  '(
    ;; arithmetic
    "add"
    "addmod"
    "div"
    "exp"
    "mod"
    "mul"
    "mulmod"
    "sdiv"
    "signextend"
    "smod"
    "sub"

    ;; bitwise-logic
    "and"
    "byte"
    "not"
    "or"
    "sar"
    "shl"
    "shr"
    "xor"

    ;; blockinfo
    "blockhash"
    "coinbase"
    "difficulty"
    "gaslimit"
    "number"
    "timestamp"

    ;; comparison
    "eq"
    "gt"
    "iszero"
    "lt"
    "sgt"
    "slt"
    "jump"
    "jumpi"

    ;; cryptographic
    "sha3"
    "keccak256"

    ;; envinfo
    "address"
    "balance"
    "calldatacopy"
    "calldataload"
    "calldatasize"
    "caller"
    "callvalue"
    "codecopy"
    "codesize"
    "extcodecopy"
    "extcodehash"
    "extcodesize"
    "gasprice"
    "origin"
    "returndatacopy"
    "returndatasize"

    ;; event
    "log0"
    "log1"
    "log2"
    "log3"
    "log4"

    ;; info
    "gas"
    "pc"

    ;; label
    "jumpdest"

    ;; memory
    "mload"
    "msize"
    "mstore"
    "mstore8"

    ;; stack
    "dup1"
    "dup2"
    "dup3"
    "dup4"
    "dup5"
    "dup6"
    "dup7"
    "dup8"
    "dup9"
    "dup10"
    "dup11"
    "dup12"
    "dup13"
    "dup14"
    "dup15"
    "dup16"

    "pop"

    "push1"
    "push2"
    "push3"
    "push4"
    "push5"
    "push6"
    "push7"
    "push8"
    "push9"
    "push10"
    "push11"
    "push12"
    "push13"
    "push14"
    "push15"
    "push16"
    "push17"
    "push18"
    "push19"
    "push20"
    "push21"
    "push22"
    "push23"
    "push24"
    "push25"
    "push26"
    "push27"
    "push28"
    "push29"
    "push30"
    "push31"
    "push32"

    "swap1"
    "swap2"
    "swap3"
    "swap4"
    "swap5"
    "swap6"
    "swap7"
    "swap8"
    "swap9"
    "swap10"
    "swap11"
    "swap12"
    "swap13"
    "swap14"
    "swap15"
    "swap16"

    ;; storage
    "sload"
    "sstore"

    ;; system
    "call"
    "callcode"
    "create"
    "create2"
    "delegatecall"
    "staticcall"

    ;; terminate
    "return"
    "revert"
    "selfdestruct"
    "stop"

    ;; custom - according to https://github.com/crytic/evm-opcodes
    "chainid"
    "basefee"
    "getpc"
    "jumpto"
    "jumpif"
    "jumpsub"
    "jumpsubv"
    "beginsub"
    "begindata"
    "returnsub"
    "putlocal"
    "getlocal"
    "sloadbytes"
    "sstorebytes"
    "ssize"
    "txexecgas"
    "invalid")
  "Built in data types of the huff language.")

(defvar huff-font-lock-keywords
  (list
     ;; hex
     `("\\b0x[[:xdigit:]]\\{0,2\\}\\b" . font-lock-string-face)
     `("\\b0x[[:xdigit:]]\\{2,40\\}\\b" . font-lock-string-face)
     `("\\b\s\\(CONSTRUCTOR\\|MAIN\\)\\b" . font-lock-warning-face)
     ;; for interface, macros and func definitions
     `("\\b\\(\\(u\\|\\)int[0-9]*\\|address\\|bool\\|bytes\\|string\\|bytes[0-9]*\\)\\b" . font-lock-warning-face)

     `(,(regexp-opt huff-nonopcode-keywords 'symbol) . font-lock-builtin-face)
     `(,(regexp-opt huff-builtin-function-keywords 'symbol) . font-lock-type-face)
     `(,(regexp-opt huff-special-keywords 'symbol) . font-lock-type-face)
     `(,(regexp-opt huff-evm-keywords 'words) . font-lock-keyword-face)

     ;; function names
     `("\\b[a-z_][a-z0-9_]\\{1,\\}\\b[[:space:]]?\\((\\.*)\\)?" . font-lock-warning-face)

     `("\\(takes\\|returns\\)[[:space:]]?\\(((\d)[a-zA-Z0-9]{0,})\\)?" . font-lock-builtin-face)

     ;; macro definitions and constants
     `("[?\\b[A-Z_]?[A-Z0-9_]\\{1,\\}\\b]?[[:space:]]?\\(()\\)?" . font-lock-string-face)

     ;; multiple comment
     `("\/*.**\/" . font-lock-comment-face)

     ;; labels:
     `("[a-zA-Z][a-zA-Z_0-9]*:" . font-lock-function-name-face)
     ))

;;
;;; Major mode

(defconst huff-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Underscore ('_') and dollar sign ('$') are valid parts of a word.
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?$ "w" st)
    (modify-syntax-entry ?} "w" st)

    (modify-syntax-entry ?/ ". 12b" st)
    (modify-syntax-entry ?* ". 23b" st)
    (modify-syntax-entry ?\n "> b" st)
    st)
  "Syntax table for the huff language.")


;;;###autoload
(define-derived-mode huff-mode c-mode "huff"
  "Major mode for editing huff buffers."
  (set-syntax-table huff-mode-syntax-table)
  ;; specify syntax highlighting
  (setq font-lock-defaults '(huff-font-lock-keywords))

  (setq comment-start "//")
  (setq comment-end "")

  (make-local-variable 'comment-start-skip)

  (make-local-variable 'paragraph-start)
  (make-local-variable 'paragraph-separate)
  (make-local-variable 'paragraph-ignore-fill-prefix)
  (make-local-variable 'adaptive-fill-mode)
  (make-local-variable 'adaptive-fill-regexp)
  (make-local-variable 'fill-paragraph-handle-comment)

  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'indent-line-function) 'c-indent-line)
  (set (make-local-variable 'indent-region-function) 'c-indent-region)
  (set (make-local-variable 'normal-auto-fill-function) 'c-do-auto-fill)
  (set (make-local-variable 'comment-multi-line) t)
  (set (make-local-variable 'comment-line-break-function)
       'c-indent-new-comment-line)
  (set (make-local-variable 'c-basic-offset) 4)

  ;; customize indentation more specific to Huff
  (make-local-variable 'c-offsets-alist)
  (add-to-list 'c-offsets-alist '(arglist-close . c-lineup-close-paren))


  ;; set hooks
  (run-hooks 'huff-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.huff\\'" . huff-mode))

(provide 'huff-mode)
;;; huff-mode.el ends here

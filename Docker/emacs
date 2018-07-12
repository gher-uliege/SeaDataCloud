(require 'julia-mode)                             ;Tell it to load it.
(setq auto-mode-alist (append '(("\\.jl$" . julia-mode)) auto-mode-alist))
(setq julia-max-block-lookback 25000)

(require 'column-marker)
(add-hook 'julia-mode-hook (lambda () (interactive) (column-marker-1 80)))

" foldutil.vim -- utilities for creating folds.
" Author: Hari Krishna <hari_vim@yahoo.com>
" Last Change: 30-Nov-2001 @ 16:58
" Created:     30-Nov-2001 @ 16:58
" Requires: Vim-6.0 or higher
" Version: 1.0.0
"
" Defines useful commands for the ease of creating folds. Currently only one,
"   but I might add more commands if I need and time permits.
"
"   FoldNonMatching - pass an optional pattern and the number of context lines
"                     to be shown. Useful to see only the matching lines. Pass
"                     an optional pattern and the number of context lines to be
"                     shown. You can give a range too.
"
"       50,500FoldNonMatching xjz 3
"
"     The defaults for pattern and context are current search pattern
"       (extracted from / register) and 0 (for no context) respectively.
"


command! -range=% -nargs=* FoldNonMatching <line1>,<line2>:call <SID>FoldNonMatchingIF(<f-args>)

" Interface method for the ease of defining a simpler command interface.
function! s:FoldNonMatchingIF(...) range
  if exists("a:1") && a:1 != ""
    let firstArg = a:1
  else
    let firstArg = ""
  endif
  if exists("a:2") && a:2 != ""
    let secondArg = a:2
  else
    let secondArg = ""
  endif

  exec a:firstline "," a:lastline "call s:FoldNonMatching(firstArg, secondArg)"
endfunction

"
" Fold all the non-matching lines.
"
function! s:FoldNonMatching(pattern, context) range
  if &foldmethod != "manual"
    echohl Error | echo "foldmethod is not manual" | echohl NONE
    return
  endif

  let pattern = a:pattern
  " If there is no pattern provided, use the current / register.
  if a:pattern == ""
    let pattern = @/
  endif

  " Since the way it is written, context = 1 actually means no context, but
  "    since this will look awkward to the user, it is adjusted here.
  "    Adding 1 below incidently takes care of the case when a non-numeric is
  "    passed
  let context = a:context + 1
  " If there is no context provided, use *no context*.
  if a:context < 0
    let context = 1
  endif

  " First eliminate all the existing folds? Not necessary, I guess...
  normal zE

  0
  let line1 = a:firstline
  let foldCount = 0
  while line1 < a:lastline
    " After advancing, make sure we are not still within the context of
    "   previous  match.
    let line2 = search(pattern, "b")
    if (line1 - line2) < context
      let line1 = line2 + context
      exec line1
      " Let us try again, as we may still be within the context.
      continue
    endif

    let line2 = search(pattern, "W")
    " No more hits.
    if line2 <= 0
      if foldCount > 0
        " Adjust for the last line. Increment because we decrement below.
        let line2 = a:lastline + context
      else
        " No folds to create.
        break
      endif
    endif
    if line2 != line1 && (line2 - line1) > context
      " Create a new fold.
      exec line1 "," (line2 - context) "fold"
      let foldCount = foldCount + 1
      let line1 = line2 + context
    else
      let line1 = line1 + context
    endif
    exec line1
  endwhile
  redraw | echo "Folds created: " . foldCount
endfunction

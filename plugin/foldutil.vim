" foldutil.vim -- utilities for creating folds.
" Author: Hari Krishna <hari_vim at yahoo dot com>
" Last Change: 18-Sep-2002 @ 19:09
" Created:     30-Nov-2001 @ 16:58
" Requires: Vim-6.0 or higher
" Version: 1.1.1
" Download From:
"     http://vim.sourceforge.net/script.php?script_id=158
" Description:
"   Defines useful commands for the ease of creating folds. Currently only one,
"     but I might add more commands if I need and time permits.
"   
"     FoldNonMatching - Pass an optional pattern and the number of context lines
"                       to be shown. Useful to see only the matching lines.
"                       You can give a range too.
"   
"         50,500FoldNonMatching xyz 3
"   
"       The defaults for pattern and context are current search pattern
"         (extracted from / register) and 0 (for no context) respectively.
"
" Summary Of Features:
"   Command Line:
"     FoldNonMatching, FUInitialize
"
"   Settings:
"       foldutilDefContext, foldutilClearFolds
"

if exists("loaded_foldutil")
  finish
endif
let loaded_foldutil=1

function! s:Initialize() " {{{

if exists("g:foldutilDefContext")
  let s:defContext = g:foldutilDefContext
  unlet g:foldutilDefContext
elseif !exists("s:defContext")
  let s:defContext = 1
endif

if exists("g:foldutilClearFolds")
  let s:clearFolds = g:foldutilClearFolds
  unlet g:foldutilClearFolds
elseif !exists("s:clearFolds")
  " First eliminate all the existing folds, by default.
  let s:clearFolds = 1
endif

command! -range=% -nargs=* FoldNonMatching <line1>,<line2>:call <SID>FoldNonMatchingIF(<f-args>)

command! -nargs=0 FUInitialize :call <SID>Initialize()

endfunction " s:Initialize }}}
call s:Initialize()

" Interface method for the ease of defining a simpler command interface.
function! s:FoldNonMatchingIF(...) range
  if &foldmethod != "manual"
    echohl Error | echo "foldmethod is not manual" | echohl None
    return
  endif
  if a:0 > 2
    echohl Error | echo "Too many arguments" | echohl None
    return
  endif

  if exists("a:1") && a:1 != ""
    let pattern = a:1
  elseif @/ == ""
    echohl Error | echo "No previous search pattern exists. Pass a search " .
	  \ "pattern as argument or do a search using the / command before " .
	  \ "re-running this command" | echohl None
    return
  else
    " If there is no pattern provided, use the current / register.
    let pattern = @/
  endif
  if exists("a:2") && a:2 != ""
    let context = a:2
  else
    let context = s:defContext
  endif

  call s:FoldNonMatching(a:firstline, a:lastline, pattern, context)
endfunction

"
" Fold all the non-matching lines. No error checks.
"
function! s:FoldNonMatching(fline, lline, pattern, context)
  let pattern = a:pattern

  " Since the way it is written, context = 1 actually means no context, but
  "    since this will look awkward to the user, it is adjusted here.
  "    Adding 1 below incidently takes care of the case when a non-numeric is
  "    passed
  let context = a:context + 1
  " If there is no context provided, use *no context*.
  if a:context < 0
    let context = 1
  endif

  if s:clearFolds
    " First eliminate all the existing folds.
    normal zE
  endif

  0
  let line1 = a:fline
  let foldCount = 0
  " So that when there are no matches, we can avoid creating one big fold.
  let matchFound = 0
  while line1 < a:lline
    " After advancing, make sure we are not still within the context of
    "   previous  match.
    let line2 = search(pattern, "b")
    if line2 > 0 && (line1 - line2) < context
      let line1 = line2 + context
      exec line1
      " Let us try again, as we may still be within the context.
      continue
    endif

    let line2 = search(pattern, "W")
    " No more hits.
    if line2 <= 0
      if matchFound
        " Adjust for the last line. Increment because we decrement below.
        let line2 = a:lline + context
      else
        " No folds to create.
        break
      endif
    else
      let matchFound = 1
    endif
    if line2 != line1 && (line2 - line1) > context
      " Create a new fold.
      "call input("creating fold: line1 = " . line1 . " line2: " . (line2 - context) . ":")
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

" vim6:fdm=marker


let s:TEST_LOG = expand('<sfile>:h:h:gs?\?/?') . '/test.log'

function! vimscript_formatter#exec(q_args) abort
    let view = winsaveview()
    let saved_indentexpr = &indentexpr
    try
        setlocal indentexpr=vimscript_formatter#internal#indentexpr()
        silent! call feedkeys('gg=G', 'nx')
    finally
        let &indentexpr = saved_indentexpr
    endtry
    call winrestview(view)
endfunction

function! vimscript_formatter#comp(ArgLead, CmdLine, CursorPos) abort
    return []
endfunction

function! vimscript_formatter#run_tests() abort
    if filereadable(s:TEST_LOG)
        call delete(s:TEST_LOG)
    endif

    let v:errors = []

    call vimscript_formatter#internal#run_tests()

    call s:run_test([
        \ 'try',
        \ 'echo 12',
        \ 'catch',
        \ 'echo 12',
        \ 'finally',
        \ 'echo 12',
        \ 'endtry',
        \ 'try',
        \ 'catch',
        \ 'finally',
        \ 'endtry',
        \ ], [
        \ 'try',
        \ '    echo 12',
        \ 'catch',
        \ '    echo 12',
        \ 'finally',
        \ '    echo 12',
        \ 'endtry',
        \ 'try',
        \ 'catch',
        \ 'finally',
        \ 'endtry',
        \ ])

    call s:run_test([
        \ 'if 1',
        \ 'echo 12',
        \ 'elseif 2',
        \ 'echo 12',
        \ 'else',
        \ 'echo 12',
        \ 'endif',
        \ 'if 1',
        \ 'elseif 2',
        \ 'else',
        \ 'endif',
        \ ], [
        \ 'if 1',
        \ '    echo 12',
        \ 'elseif 2',
        \ '    echo 12',
        \ 'else',
        \ '    echo 12',
        \ 'endif',
        \ 'if 1',
        \ 'elseif 2',
        \ 'else',
        \ 'endif',
        \ ])

    call s:run_test([
        \ 'while 1',
        \ 'echo 12',
        \ 'endwhile',
        \ 'while 1',
        \ 'endwhile',
        \ ], [
        \ 'while 1',
        \ '    echo 12',
        \ 'endwhile',
        \ 'while 1',
        \ 'endwhile',
        \ ])

    call s:run_test([
        \ 'for i in [1,2,3]',
        \ 'echo 12',
        \ 'endfor',
        \ 'for i in [1,2,3]',
        \ 'endfor',
        \ ], [
        \ 'for i in [1,2,3]',
        \ '    echo 12',
        \ 'endfor',
        \ 'for i in [1,2,3]',
        \ 'endfor',
        \ ])

    call s:run_test([
        \ 'def xxx',
        \ 'echo 12',
        \ 'enddef',
        \ 'def xxx',
        \ 'enddef',
        \ ], [
        \ 'def xxx',
        \ '    echo 12',
        \ 'enddef',
        \ 'def xxx',
        \ 'enddef',
        \ ])

    call s:run_test([
        \ 'augroup xxx',
        \ 'autocmd!',
        \ 'autocmd FileType vim',
        \ '\ : if 1',
        \ '\ |     echo 12',
        \ '\ | else',
        \ '\ |     echo 12',
        \ '\ | endif',
        \ 'augroup END',
        \ 'augroup xxx',
        \ 'augroup END',
        \ ], [
        \ 'augroup xxx',
        \ '    autocmd!',
        \ '    autocmd FileType vim',
        \ '        \ : if 1',
        \ '        \ |     echo 12',
        \ '        \ | else',
        \ '        \ |     echo 12',
        \ '        \ | endif',
        \ 'augroup END',
        \ 'augroup xxx',
        \ 'augroup END',
        \ ])

    call s:run_test([
        \ 'function! s:main() abort',
        \ 'echo 123',
        \ '    let lines =<< END_NO_TRIM',
        \ '    for in',
        \ '            echo ',
        \ '    endfor',
        \ 'END_NO_TRIM',
        \ 'echo 456',
        \ '    let trimlines =<< trim END_TRIM',
        \ '    for in',
        \ '        echo ',
        \ '    endfor',
        \ '    END_TRIM',
        \ 'echo 789',
        \ 'endfunction',
        \ ], [
        \ 'function! s:main() abort',
        \ '    echo 123',
        \ '    let lines =<< END_NO_TRIM',
        \ '    for in',
        \ '            echo ',
        \ '    endfor',
        \ 'END_NO_TRIM',
        \ '    echo 456',
        \ '    let trimlines =<< trim END_TRIM',
        \ '    for in',
        \ '        echo ',
        \ '    endfor',
        \ '    END_TRIM',
        \ '    echo 789',
        \ 'endfunction',
        \ ])

    if !empty(v:errors)
        call writefile(v:errors, s:TEST_LOG)
        for err in v:errors
            echohl Error
            echo err
            echohl None
        endfor
    endif
endfunction

function! s:run_test(actual, expect) abort
    try
        new
        setlocal filetype=vim
        let lnum = 0
        for line in a:actual
            let lnum += 1
            call setbufline(bufnr(), lnum, line)
        endfor
        VimscriptFormatter
        let formatted_lines = getbufline('%', 1, '$')
    finally
        bdelete!
    endtry
    call assert_equal(formatted_lines, a:expect)
endfunction


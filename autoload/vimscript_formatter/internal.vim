
let s:TYPE_NORMAL = 'TYPE_NORMAL'
let s:TYPE_COMMENT = 'TYPE_COMMENT'
let s:TYPE_CONTINUOUS = 'TYPE_CONTINUOUS'
let s:TYPE_IF = 'TYPE_IF'
let s:TYPE_ELSEIF = 'TYPE_ELSEIF'
let s:TYPE_ELSE = 'TYPE_ELSE'
let s:TYPE_ENDIF = 'TYPE_ENDIF'
let s:TYPE_FOR = 'TYPE_FOR'
let s:TYPE_ENDFOR = 'TYPE_ENDFOR'
let s:TYPE_FUNCTION = 'TYPE_FUNCTION'
let s:TYPE_ENDFUNCTION = 'TYPE_ENDFUNCTION'
let s:TYPE_AUGROUP = 'TYPE_AUGROUP'
let s:TYPE_ENDAUGROUP = 'TYPE_ENDAUGROUP'
let s:TYPE_WHILE = 'TYPE_WHILE'
let s:TYPE_ENDWHILE = 'TYPE_ENDWHILE'
let s:TYPE_TRY = 'TYPE_TRY'
let s:TYPE_CATCH = 'TYPE_CATCH'
let s:TYPE_FINALLY = 'TYPE_FINALLY'
let s:TYPE_ENDTRY = 'TYPE_ENDTRY'
let s:TYPE_DEF = 'TYPE_DEF'
let s:TYPE_ENDDEF = 'TYPE_ENDDEF'

function! vimscript_formatter#internal#parse(line) abort
    let text = matchstr(a:line, '^\s*\zs\S.*$')
    let type = s:TYPE_NORMAL
    if text =~# '^"'
        let type = s:TYPE_COMMENT
    elseif text =~# '^\\'
        let type = s:TYPE_CONTINUOUS
    elseif text =~# '^\<if\>'
        let type = s:TYPE_IF
    elseif text =~# '^\<elsei\%[f\]\>'
        let type = s:TYPE_ELSEIF
    elseif text =~# '^\<el\%[se\]\>'
        let type = s:TYPE_ELSE
    elseif text =~# '^\<en\%[dif\]\>'
        let type = s:TYPE_ENDIF
    elseif text =~# '^\<for\>'
        let type = s:TYPE_FOR
    elseif text =~# '^\<endfo\%[r\]\>'
        let type = s:TYPE_ENDFOR
    elseif text =~# '^\<fu\%[nction\]\>'
        let type = s:TYPE_FUNCTION
    elseif text =~# '^\<endf\%[unction\]\>'
        let type = s:TYPE_ENDFUNCTION
    elseif text =~# '^\<aug\%[roup\]\>\s\+\<\cend\>'
        let type = s:TYPE_ENDAUGROUP
    elseif text =~# '^\<aug\%[roup\]\>'
        let type = s:TYPE_AUGROUP
    elseif text =~# '^\<wh\%[ile\]\>'
        let type = s:TYPE_WHILE
    elseif text =~# '^\<endw\%[hile\]\>'
        let type = s:TYPE_ENDWHILE
    elseif text =~# '^\<try\>'
        let type = s:TYPE_TRY
    elseif text =~# '^\<cat\%[ch\]\>'
        let type = s:TYPE_CATCH
    elseif text =~# '^\<fina\%[lly\]\>'
        let type = s:TYPE_FINALLY
    elseif text =~# '^\<endt\%[ry\]\>'
        let type = s:TYPE_ENDTRY
    elseif text =~# '^\<enddef\>'
        let type = s:TYPE_ENDDEF
    elseif text =~# '^\<def\>'
        let type = s:TYPE_DEF
    else
        let type = type
    endif
    return { 'type' : type, 'text' : text, }
endfunction

function! vimscript_formatter#internal#prev(lnum) abort
    let prev_lnum = prevnonblank(a:lnum - 1)
    while (-1 != index(['vimLetHereDoc', 'vimLetHereDocStop'], synIDattr(synID(prev_lnum, 1, 1), 'name'))) && (1 < prev_lnum)
        let prev_lnum = prevnonblank(prev_lnum - 1)
    endwhile
    let syn_name = synIDattr(synID(prev_lnum, 1, 1), 'name')
    let line = getline(prev_lnum)
    let parsed = vimscript_formatter#internal#parse(line)
    let indent = indent(prev_lnum)
    return { 'syn_name' : syn_name, 'line' : line, 'parsed' : parsed, 'indent' : indent, }
endfunction

function! vimscript_formatter#internal#curr(lnum) abort
    let syn_name = synIDattr(synID(a:lnum, 1, 1), 'name')
    let line = getline(a:lnum)
    let parsed = vimscript_formatter#internal#parse(line)
    return { 'syn_name' : syn_name, 'line' : line, 'parsed' : parsed, }
endfunction

function! vimscript_formatter#internal#indentexpr() abort
    if 1 == v:lnum
        return 0
    endif
    let prev_info = vimscript_formatter#internal#prev(v:lnum)
    let curr_info = vimscript_formatter#internal#curr(v:lnum)

    let indent = prev_info['indent']

    if -1 != index(['vimLetHereDoc', 'vimLetHereDocStop'], curr_info['syn_name'])
        return -1
    endif

    if (s:TYPE_CONTINUOUS == curr_info['parsed']['type'])
        if (s:TYPE_CONTINUOUS != prev_info['parsed']['type'])
            let indent += shiftwidth()
        endif
    else
        if (s:TYPE_CONTINUOUS == prev_info['parsed']['type'])
            let indent -= shiftwidth()
        endif
    endif

    let p = (s:TYPE_FUNCTION == prev_info['parsed']['type']) ||
        \ (s:TYPE_AUGROUP == prev_info['parsed']['type']) ||
        \ (s:TYPE_WHILE == prev_info['parsed']['type']) ||
        \ (s:TYPE_DEF == prev_info['parsed']['type']) ||
        \ (s:TYPE_FOR == prev_info['parsed']['type']) ||
        \ (s:TYPE_TRY == prev_info['parsed']['type']) ||
        \ (s:TYPE_FINALLY == prev_info['parsed']['type']) ||
        \ (s:TYPE_CATCH == prev_info['parsed']['type']) ||
        \ (s:TYPE_IF == prev_info['parsed']['type']) ||
        \ (s:TYPE_ELSE == prev_info['parsed']['type']) ||
        \ (s:TYPE_ELSEIF == prev_info['parsed']['type'])

    let c = (s:TYPE_ENDFUNCTION == curr_info['parsed']['type']) ||
        \ (s:TYPE_ENDAUGROUP == curr_info['parsed']['type']) ||
        \ (s:TYPE_ENDWHILE == curr_info['parsed']['type']) ||
        \ (s:TYPE_ENDDEF == curr_info['parsed']['type']) ||
        \ (s:TYPE_ENDFOR == curr_info['parsed']['type']) ||
        \ (s:TYPE_FINALLY == curr_info['parsed']['type']) ||
        \ (s:TYPE_CATCH == curr_info['parsed']['type']) ||
        \ (s:TYPE_ENDTRY == curr_info['parsed']['type']) ||
        \ (s:TYPE_ENDIF == curr_info['parsed']['type']) ||
        \ (s:TYPE_ELSE == curr_info['parsed']['type']) ||
        \ (s:TYPE_ELSEIF == curr_info['parsed']['type'])

    if p
        if c
            return indent
        else
            return indent + shiftwidth()
        endif
    else
        if c
            return indent - shiftwidth()
        else
            return indent
        endif
    endif
endfunction

function! vimscript_formatter#internal#run_tests() abort
    call assert_equal(vimscript_formatter#internal#parse('   "en'), { 'type' : s:TYPE_COMMENT, 'text' : '"en', })
    call assert_equal(vimscript_formatter#internal#parse('   \en'), { 'type' : s:TYPE_CONTINUOUS, 'text' : '\en', })
    call assert_equal(vimscript_formatter#internal#parse('   if v:true'), { 'type' : s:TYPE_IF, 'text' : 'if v:true', })
    call assert_equal(vimscript_formatter#internal#parse('   elseif v:true'), { 'type' : s:TYPE_ELSEIF, 'text' : 'elseif v:true', })
    call assert_equal(vimscript_formatter#internal#parse('   elsei v:true'), { 'type' : s:TYPE_ELSEIF, 'text' : 'elsei v:true', })
    call assert_equal(vimscript_formatter#internal#parse('   else'), { 'type' : s:TYPE_ELSE, 'text' : 'else', })
    call assert_equal(vimscript_formatter#internal#parse('   el'), { 'type' : s:TYPE_ELSE, 'text' : 'el', })
    call assert_equal(vimscript_formatter#internal#parse('   endif'), { 'type' : s:TYPE_ENDIF, 'text' : 'endif', })
    call assert_equal(vimscript_formatter#internal#parse('   en'), { 'type' : s:TYPE_ENDIF, 'text' : 'en', })
    call assert_equal(vimscript_formatter#internal#parse('   for'), { 'type' : s:TYPE_FOR, 'text' : 'for', })
    call assert_equal(vimscript_formatter#internal#parse('   endfor'), { 'type' : s:TYPE_ENDFOR, 'text' : 'endfor', })
    call assert_equal(vimscript_formatter#internal#parse('   endfo'), { 'type' : s:TYPE_ENDFOR, 'text' : 'endfo', })
    call assert_equal(vimscript_formatter#internal#parse('   function'), { 'type' : s:TYPE_FUNCTION, 'text' : 'function', })
    call assert_equal(vimscript_formatter#internal#parse('   fu'), { 'type' : s:TYPE_FUNCTION, 'text' : 'fu', })
    call assert_equal(vimscript_formatter#internal#parse('   endfunction'), { 'type' : s:TYPE_ENDFUNCTION, 'text' : 'endfunction', })
    call assert_equal(vimscript_formatter#internal#parse('   augroup'), { 'type' : s:TYPE_AUGROUP, 'text' : 'augroup', })
    call assert_equal(vimscript_formatter#internal#parse('   aug'), { 'type' : s:TYPE_AUGROUP, 'text' : 'aug', })
    call assert_equal(vimscript_formatter#internal#parse('   augroup end'), { 'type' : s:TYPE_ENDAUGROUP, 'text' : 'augroup end', })
    call assert_equal(vimscript_formatter#internal#parse('   aug end'), { 'type' : s:TYPE_ENDAUGROUP, 'text' : 'aug end', })
    call assert_equal(vimscript_formatter#internal#parse('   augroup END'), { 'type' : s:TYPE_ENDAUGROUP, 'text' : 'augroup END', })
    call assert_equal(vimscript_formatter#internal#parse('   aug END'), { 'type' : s:TYPE_ENDAUGROUP, 'text' : 'aug END', })
    call assert_equal(vimscript_formatter#internal#parse('   while v:true'), { 'type' : s:TYPE_WHILE, 'text' : 'while v:true', })
    call assert_equal(vimscript_formatter#internal#parse('   wh v:true'), { 'type' : s:TYPE_WHILE, 'text' : 'wh v:true', })
    call assert_equal(vimscript_formatter#internal#parse('   endwhile'), { 'type' : s:TYPE_ENDWHILE, 'text' : 'endwhile', })
    call assert_equal(vimscript_formatter#internal#parse('   endw'), { 'type' : s:TYPE_ENDWHILE, 'text' : 'endw', })
    call assert_equal(vimscript_formatter#internal#parse('   try'), { 'type' : s:TYPE_TRY, 'text' : 'try', })
    call assert_equal(vimscript_formatter#internal#parse('   catch'), { 'type' : s:TYPE_CATCH, 'text' : 'catch', })
    call assert_equal(vimscript_formatter#internal#parse('   finally'), { 'type' : s:TYPE_FINALLY, 'text' : 'finally', })
    call assert_equal(vimscript_formatter#internal#parse('   endtry'), { 'type' : s:TYPE_ENDTRY, 'text' : 'endtry', })
    call assert_equal(vimscript_formatter#internal#parse('   def'), { 'type' : s:TYPE_DEF, 'text' : 'def', })
    call assert_equal(vimscript_formatter#internal#parse('   enddef'), { 'type' : s:TYPE_ENDDEF, 'text' : 'enddef', })
endfunction


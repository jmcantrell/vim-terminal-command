function! terminal_command#run(command, ...)
    let options = empty(a:000) ? {} : a:000[0]

    let type = get(options, 'type', '')

    if type ==# 't'
        tabnew
    elseif type ==# 's'
        wincmd n
    elseif type ==# 'v'
        wincmd n
        wincmd L
    endif

    if !has_key(options, 'end_cb')
        function! options.end_cb(...)
        endfunction
    endif

    function! options.exit_cb(job, exit_status) dict
        if a:exit_status == 0
            silent! bdelete!
        endif
        call self.end_cb(a:exit_status)
    endfunction

    let term_options = {'curwin': 1, 'exit_cb': function(options.exit_cb)}

    let options.buf_nr = term_start([&shell, '-c', a:command], term_options)

    return options.buf_nr
endfunction

function! terminal_command#to_temp(command, ...)
    let options = empty(a:000) ? {} : a:000[0]
    let options.output_file = tempname()

    function! options.end_cb(exit_status) dict
        call self.write_cb(self.output_file, a:exit_status)
        call delete(self.output_file)
    endfunction

    return terminal_command#run(a:command . '>' . options.output_file, options)
endfunction

function! terminal_command#read(command, ...)
    let options = empty(a:000) ? {} : a:000[0]

    if !has_key(options, 'range')
        let options.range = ''
    endif

    function! options.write_cb(output_file, exit_status) dict
        execute self.range . 'read ' . a:output_file
    endfunction

    return terminal_command#to_temp(a:command, options)
endfunction

function! terminal_command#insert(command, ...)
    let options = empty(a:000) ? {} : a:000[0]

    if !has_key(options, 'placement')
        let options.placement = 'i'
    endif

    function! options.write_cb(output_file, exit_status) dict
        execute 'normal! ' . self.placement . join(readfile(a:output_file), '\n')
        if has_key(self, 'after_keys')
            call feedkeys(self.after_keys)
        endif
    endfunction

    return terminal_command#to_temp(a:command, options)
endfunction

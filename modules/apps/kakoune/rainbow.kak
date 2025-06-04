# Rainbow.kak - Simplified implementation

# Declare options
declare-option -hidden range-specs rainbow
declare-option -hidden str-list bracket_data
declare-option str-list rainbow_colors
set-option global rainbow_colors rgb:FFFFFF+b rgb:FF0000 rgb:FFa500 rgb:FFFF00 rgb:00FF00 rgb:0000FF rgb:8B00FF rgb:EE42EE

# Enable/disable commands
define-command rainbow-enable-window -docstring "enable rainbow parentheses for this window" %{
    hook -group rainbow window InsertIdle .* %{ rainbow-view }
    hook -group rainbow window NormalIdle .* %{ rainbow-view }
}

define-command rainbow-disable-window -docstring "disable rainbow parentheses for this window" %{
    remove-hooks window rainbow
    remove-highlighter window/rainbow
}

# Main rainbow view command
define-command -hidden rainbow-view %{
    evaluate-commands -draft -save-regs ^abc %{
        try %{
            # Add highlighter if not present
            add-highlighter -override window/rainbow ranges rainbow
        }
        
        # Clear previous data
        set-option window rainbow "%val{timestamp}"
        set-option window bracket_data
        
        # Save cursor position
        execute-keys '<space>;'
        set-register a "%val{selection_desc}"
        
        # Pass 1: Build bracket map
        # Select all brackets in current view
        execute-keys 'gtGbGl'
        try %{
            execute-keys 's[(){}[\]]<ret>'
            
            # Store each bracket with its position and type
            evaluate-commands -no-hooks -itersel %{
                set-register b "%val{selection_desc}"
                set-register c "%val{selection}"
                set-option -add window bracket_data "%reg{b}|%reg{c}"
            }
        }
        
        # Pass 2: Calculate depths and assign colors
        evaluate-commands -no-hooks %sh{
            # Read data
            bracket_data="${kak_opt_bracket_data}"
            cursor_pos="${kak_reg_a}"
            colors="${kak_opt_rainbow_colors}"
            
            # Pre-parse colors into array
            n_colors=0
            for c in $colors; do
                n_colors=$((n_colors + 1))
                eval "color_$n_colors=\"$c\""
            done
            
            # Parse cursor position using parameter expansion
            cursor_line=${cursor_pos%%.*}
            temp=${cursor_pos#*.}
            cursor_col=${temp%%,*}
            
            # Initialize depths
            depth_paren=0
            depth_brace=0
            depth_square=0
            
            # Cursor depths (will be set when we pass cursor)
            cursor_depth_paren=0
            cursor_depth_brace=0
            cursor_depth_square=0
            passed_cursor=false
            
            # Accumulate output
            output=""
            
            # Process each bracket directly
            for entry in $bracket_data; do
                [ -z "$entry" ] && continue
                
                # Parse using parameter expansion
                pos=${entry%|*}
                bracket=${entry#*|}
                
                # Parse position
                line=${pos%%.*}
                temp=${pos#*.}
                col=${temp%%,*}
                
                # Determine bracket type and update depths
                case "$bracket" in
                    "(")
                        depth_paren=$((depth_paren - 1))
                        current_depth=$depth_paren
                        bracket_type="paren"
                        ;;
                    ")")
                        current_depth=$depth_paren
                        depth_paren=$((depth_paren + 1))
                        bracket_type="paren"
                        ;;
                    "{")
                        depth_brace=$((depth_brace - 1))
                        current_depth=$depth_brace
                        bracket_type="brace"
                        ;;
                    "}")
                        current_depth=$depth_brace
                        depth_brace=$((depth_brace + 1))
                        bracket_type="brace"
                        ;;
                    "[")
                        depth_square=$((depth_square - 1))
                        current_depth=$depth_square
                        bracket_type="square"
                        ;;
                    "]")
                        current_depth=$depth_square
                        depth_square=$((depth_square + 1))
                        bracket_type="square"
                        ;;
                esac
                
                # Check if we've passed cursor
                if [ "$passed_cursor" = "false" ]; then
                    if [ "$line" -gt "$cursor_line" ] || { [ "$line" -eq "$cursor_line" ] && [ "$col" -ge "$cursor_col" ]; }; then
                        cursor_depth_paren=$depth_paren
                        cursor_depth_brace=$depth_brace
                        cursor_depth_square=$depth_square
                        passed_cursor=true
                    fi
                fi
                
                # Calculate relative depth
                case "$bracket_type" in
                    "paren") relative_depth=$((current_depth - cursor_depth_paren)) ;;
                    "brace") relative_depth=$((current_depth - cursor_depth_brace)) ;;
                    "square") relative_depth=$((current_depth - cursor_depth_square)) ;;
                esac
                
                # Calculate color index (handle negative modulo)
                color_idx=$((relative_depth % n_colors))
                if [ "$color_idx" -lt 0 ]; then
                    color_idx=$((color_idx + n_colors))
                fi
                color_idx=$((color_idx + 1))
                
                # Get color from pre-parsed array
                eval "color=\$color_$color_idx"
                
                # Accumulate output
                output="${output}set-option -add window rainbow '${pos}|${color}';"
            done
            
            # Output all at once
            printf '%s\n' "$output"
        }
    }
}

# Auto Python Virtual Environment Activation for zsh
# Add this to your ~/.zshrc file

# Variable to track the currently active virtual environment
CURRENT_VENV=""

# Function to find virtual environment in current directory
find_venv() {
    local current_dir="$PWD"
    
    # Common virtual environment directory names and paths to check
    local venv_paths=(
        "venv/bin/activate"
        ".venv/bin/activate" 
        "env/bin/activate"
        ".env/bin/activate"
        "virtualenv/bin/activate"
        ".virtualenv/bin/activate"
    )
    
    # Check for virtual environment in current directory
    for venv_path in "${venv_paths[@]}"; do
        if [[ -f "$current_dir/$venv_path" ]]; then
            echo "$current_dir/$venv_path"
            return 0
        fi
    done
    
    # Also check if we're inside a virtual environment directory structure
    # (in case we cd into venv/bin or similar)
    local check_dir="$current_dir"
    while [[ "$check_dir" != "/" ]]; do
        for venv_path in "${venv_paths[@]}"; do
            if [[ -f "$check_dir/$venv_path" ]]; then
                echo "$check_dir/$venv_path"
                return 0
            fi
        done
        check_dir="$(dirname "$check_dir")"
    done
    
    return 1
}

# Function to activate virtual environment
activate_venv() {
    local venv_path="$1"
    local venv_dir="$(dirname "$(dirname "$venv_path")")"
    
    # Only activate if it's different from current
    if [[ "$CURRENT_VENV" != "$venv_dir" ]]; then
        # Deactivate current virtual environment if one is active
        if [[ -n "$CURRENT_VENV" ]] && [[ "$VIRTUAL_ENV" != "" ]]; then
            echo "🐍 Deactivating virtual environment: $(basename "$CURRENT_VENV")"
            deactivate
        fi
        
        # Activate new virtual environment
        source "$venv_path"
        CURRENT_VENV="$venv_dir"
        echo "🐍 Activated virtual environment: $(basename "$venv_dir")"
    fi
}

# Function to deactivate virtual environment
deactivate_venv() {
    if [[ -n "$CURRENT_VENV" ]] && [[ "$VIRTUAL_ENV" != "" ]]; then
        echo "🐍 Deactivating virtual environment: $(basename "$CURRENT_VENV")"
        deactivate
        CURRENT_VENV=""
    fi
}

# Function called whenever directory changes
auto_venv_chpwd() {
    local venv_path
    venv_path=$(find_venv)
    
    if [[ $? -eq 0 ]]; then
        # Virtual environment found
        activate_venv "$venv_path"
    else
        # No virtual environment found in current directory
        # Check if we were in a venv directory before
        if [[ -n "$CURRENT_VENV" ]]; then
            # Simple path-based check - if current path doesn't start with venv path, deactivate
            local current_path="$PWD"
            
            # Normalize paths by removing trailing slashes
            current_path="${current_path%/}"
            local venv_path_normalized="${CURRENT_VENV%/}"
            
            # Check if we're still within the venv directory tree
            if [[ "$current_path" != "$venv_path_normalized"* ]]; then
                deactivate_venv
            fi
        fi
    fi
}

# Add the function to zsh's chpwd hooks
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv_chpwd

# Run once when shell starts to check current directory
auto_venv_chpwd

# Optional: Add a manual command to toggle venv behavior
alias venv-toggle='if [[ -n "$CURRENT_VENV" ]]; then deactivate_venv; else auto_venv_chpwd; fi'

# Optional: Show current venv status
alias venv-status='if [[ -n "$CURRENT_VENV" ]]; then echo "Active venv: $(basename "$CURRENT_VENV")"; else echo "No active venv"; fi'

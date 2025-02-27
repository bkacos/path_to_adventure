#!/bin/bash
# =============================================================================
# 
# ACHIEVEMENTS SYSTEM
# 
# =============================================================================
# Avoid duplicate inclusion
if [[ -n "${__pta_achievements_imported:-}" ]]; then
    return 0
fi
__pta_achievements_imported="defined"

# Setup achievements tracking directory and file
export ACHIEVEMENTS_DIR="$DIR/achievements"
export ACHIEVEMENTS_FILE="$ACHIEVEMENTS_DIR/earned.txt"

# Create achievements directory if it doesn't exist
if [[ ! -d "$ACHIEVEMENTS_DIR" ]]; then
    mkdir -p "$ACHIEVEMENTS_DIR" 2>/dev/null || {
        echo "Warning: Could not create achievements directory at $ACHIEVEMENTS_DIR" >&2
        # Fall back to a temporary location if we can't create the directory
        ACHIEVEMENTS_DIR="/tmp/achievements_$(whoami)"
        ACHIEVEMENTS_FILE="$ACHIEVEMENTS_DIR/earned.txt"
        mkdir -p "$ACHIEVEMENTS_DIR" 2>/dev/null
    }
fi

# Initialize achievements file if it doesn't exist
if [[ ! -f "$ACHIEVEMENTS_FILE" ]]; then
    touch "$ACHIEVEMENTS_FILE" 2>/dev/null || {
        echo "Warning: Could not create achievements file at $ACHIEVEMENTS_FILE" >&2
    }
fi

# Achievement definitions with names, descriptions, and unlock conditions
declare -A ACHIEVEMENT_NAMES
declare -A ACHIEVEMENT_DESCRIPTIONS
declare -A ACHIEVEMENT_UNLOCK_CONDITIONS

# Cottage achievements
ACHIEVEMENT_NAMES["first_steps"]="First Steps"
ACHIEVEMENT_DESCRIPTIONS["first_steps"]="Created your treasure chest in the cottage"
ACHIEVEMENT_UNLOCK_CONDITIONS["first_steps"]="[[ \${ITEMS[cottage_chest]} -eq 1 ]]"


ACHIEVEMENT_NAMES["cottage warlord"]="cottage warlord"
ACHIEVEMENT_DESCRIPTIONS["cottage_complete"]="Completed all cottage tasks"
ACHIEVEMENT_UNLOCK_CONDITIONS["cottage_complete"]="[[ \${ITEMS[cottage_chest]} -eq 1 && \${ITEMS[cottage_name]} -eq 1 ]]"

# Total score achievements - Will be evaluated later when TOTAL_POINTS is available
ACHIEVEMENT_NAMES["Linux enthusiast"]="Linux enthusiast"
ACHIEVEMENT_DESCRIPTIONS["Earned your first point"]="Earned your first point"
ACHIEVEMENT_UNLOCK_CONDITIONS["Linux enthusiast"]="[[ \$TOTAL_POINTS -ge 1 ]]"

ACHIEVEMENT_NAMES["ROOT"]="ROOT"
ACHIEVEMENT_DESCRIPTIONS["Earned at least 5 points"]="Earned at least 5 points"
ACHIEVEMENT_UNLOCK_CONDITIONS["ROOT"]="[[ \$TOTAL_POINTS -ge 5 ]]"

ACHIEVEMENT_NAMES["journeyman"]="Journeyman Explorer"
ACHIEVEMENT_DESCRIPTIONS["journeyman"]="Earned at least 10 points"
ACHIEVEMENT_UNLOCK_CONDITIONS["journeyman"]="[[ \$TOTAL_POINTS -ge 10 ]]"

ACHIEVEMENT_NAMES["master"]="Master Explorer"
ACHIEVEMENT_DESCRIPTIONS["master"]="Earned at least 20 points"
ACHIEVEMENT_UNLOCK_CONDITIONS["master"]="[[ \$TOTAL_POINTS -ge 20 ]]"

# Progress achievements
ACHIEVEMENT_NAMES["halfway_there"]="Halfway There"
ACHIEVEMENT_DESCRIPTIONS["halfway_there"]="Earned at least half of all possible points"
ACHIEVEMENT_UNLOCK_CONDITIONS["halfway_there"]="[[ \$TOTAL_POINTS -ge \$((\$POSSIBLE_TOTAL / 2)) && \$POSSIBLE_TOTAL -gt 0 ]]"

ACHIEVEMENT_NAMES["That was some path to Adventure!"]="That was some path to Adventure!"
ACHIEVEMENT_DESCRIPTIONS["That was some path to Adventure!"]="Earned all possible points"
ACHIEVEMENT_UNLOCK_CONDITIONS["That was some path to Adventure!"]="[[ \$TOTAL_POINTS -eq \$POSSIBLE_TOTAL && \$POSSIBLE_TOTAL -gt 0 ]]"

# Function to check if an achievement is already earned
is_achievement_earned() {
    local achievement_id="$1"
    if [[ -f "$ACHIEVEMENTS_FILE" ]]; then
        grep -q "^$achievement_id$" "$ACHIEVEMENTS_FILE"
        return $?
    fi
    return 1  # If file doesn't exist, achievement isn't earned
}

# Function to award an achievement
award_achievement() {
    local achievement_id="$1"
    
    # Check if the achievement is already earned
    if ! is_achievement_earned "$achievement_id"; then
        # Add to earned achievements file if we can write to it
        if [[ -w "$ACHIEVEMENTS_FILE" ]] || [[ ! -f "$ACHIEVEMENTS_FILE" ]]; then
            echo "$achievement_id" >> "$ACHIEVEMENTS_FILE" 2>/dev/null
        fi
        
        # Display achievement notification
        echo ""
        echo "?? ACHIEVEMENT UNLOCKED: ${ACHIEVEMENT_NAMES[$achievement_id]} ??"
        echo "? ${ACHIEVEMENT_DESCRIPTIONS[$achievement_id]}"
        echo ""
    fi
}

# Function to check and award all possible achievements
check_achievements() {
    local achievement_id
    local condition
    
    # Only check if we have the required score variables
    if [[ -z "$TOTAL_POINTS" ]]; then
        # Calculate total points if not already done
        TOTAL_POINTS=0
        for item in "${!ITEMS[@]}"; do
            TOTAL_POINTS=$((TOTAL_POINTS + ${ITEMS[$item]}))
        done
    fi
    
    if [[ -z "$POSSIBLE_TOTAL" ]]; then
        # Calculate possible total if not already done
        POSSIBLE_TOTAL=0
        for item in "${!POSSIBLE_POINTS[@]}"; do
            POSSIBLE_TOTAL=$((POSSIBLE_TOTAL + ${POSSIBLE_POINTS[$item]}))
        done
    fi
    
    # Check each achievement
    for achievement_id in "${!ACHIEVEMENT_NAMES[@]}"; do
        # Get the unlock condition
        condition="${ACHIEVEMENT_UNLOCK_CONDITIONS[$achievement_id]}"
        
        # Evaluate the unlock condition safely
        if eval "$condition" 2>/dev/null; then
            award_achievement "$achievement_id"
        fi
    done
}

# Function to display all achievements (both earned and locked)
display_achievements() {
    echo ""
    echo "===== ACHIEVEMENTS ====="
    echo ""
    
    local earned_count=0
    local total_count=0
    local achievement_id
    
    for achievement_id in "${!ACHIEVEMENT_NAMES[@]}"; do
        total_count=$((total_count + 1))
        
        if is_achievement_earned "$achievement_id"; then
            earned_count=$((earned_count + 1))
            echo "?? ${ACHIEVEMENT_NAMES[$achievement_id]}"
            echo "   ${ACHIEVEMENT_DESCRIPTIONS[$achievement_id]}"
        else
            echo "?? ${ACHIEVEMENT_NAMES[$achievement_id]}"
            echo "   (Locked)"
        fi
        echo ""
    done
    
    echo "Progress: $earned_count/$total_count achievements unlocked"
    echo "========================"
}

# Add achievement checking to the scoring process
function score_achievements {
    check_achievements
}
SCORING_FUNCTIONS+=(score_achievements)

# Add printing function for achievements summary
function print_achievements {
    local earned_count=0
    local total_count=${#ACHIEVEMENT_NAMES[@]}
    
    for achievement_id in "${!ACHIEVEMENT_NAMES[@]}"; do
        if is_achievement_earned "$achievement_id"; then
            earned_count=$((earned_count + 1))
        fi
    done
    
    echo "Achievements: $earned_count/$total_count unlocked"
}
PRINTING_FUNCTIONS[achievements]=print_achievements

# Create the achievements command function
function achievements {
    display_achievements
}

# Export the functions so they can be used in the game
export -f achievements
export -f display_achievements
export -f is_achievement_earned
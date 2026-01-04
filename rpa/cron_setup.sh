#!/bin/bash
# ===========================================
# RPA Bank Scrapers - Cron Job Setup Script
# Finanzas Familiares
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
PYTHON="$VENV_DIR/bin/python"
LOG_DIR="$SCRIPT_DIR/logs"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  RPA Bank Scrapers - Cron Setup${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}❌ Virtual environment not found at $VENV_DIR${NC}"
    echo -e "${YELLOW}   Run: python -m venv venv && source venv/bin/activate && pip install -r requirements.txt${NC}"
    exit 1
fi

# Check if .env exists
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo -e "${YELLOW}   Copy .env.example to .env and configure credentials${NC}"
    exit 1
fi

# Create logs directory
mkdir -p "$LOG_DIR"

# Create the cron runner script
RUNNER_SCRIPT="$SCRIPT_DIR/cron_runner.sh"
cat > "$RUNNER_SCRIPT" << 'EOF'
#!/bin/bash
# RPA Cron Runner - Executed by cron
# Do not edit manually - regenerate with cron_setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
source venv/bin/activate

# Set environment
export PYTHONPATH="$SCRIPT_DIR"

# Run all scrapers
# Note: Bank scrapers run without --interactive, meaning they'll fail if OTP is required
# Consider running bank scrapers manually with --interactive when session expires

# Email scraper (doesn't need OTP)
python main.py email --days 7 2>&1 | tee -a logs/cron_$(date +%Y%m%d).log

# Bank scrapers (may need session refresh periodically)
# Uncomment these lines if you have valid sessions saved:
# python main.py bank --bank nequi --days 30 2>&1 | tee -a logs/cron_$(date +%Y%m%d).log
# python main.py bank --bank davivienda --days 30 2>&1 | tee -a logs/cron_$(date +%Y%m%d).log

# Cleanup old logs (keep 30 days)
find logs/ -name "*.log" -mtime +30 -delete 2>/dev/null || true
find logs/ -name "*.png" -mtime +7 -delete 2>/dev/null || true

deactivate
EOF

chmod +x "$RUNNER_SCRIPT"
echo -e "${GREEN}✓ Created runner script: $RUNNER_SCRIPT${NC}"

# Show cron line options
echo ""
echo -e "${YELLOW}Add one of these lines to your crontab (crontab -e):${NC}"
echo ""
echo "# Run daily at 6:00 AM"
echo "0 6 * * * $RUNNER_SCRIPT"
echo ""
echo "# Run twice daily (6 AM and 6 PM)"
echo "0 6,18 * * * $RUNNER_SCRIPT"
echo ""
echo "# Run every Monday at 7:00 AM"  
echo "0 7 * * 1 $RUNNER_SCRIPT"
echo ""

# Offer to add to crontab automatically
read -p "Do you want to add the daily 6 AM cron job automatically? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$RUNNER_SCRIPT"; then
        echo -e "${YELLOW}⚠ Cron job already exists${NC}"
    else
        # Add cron job
        (crontab -l 2>/dev/null; echo "# RPA Bank Scrapers - Finanzas Familiares"; echo "0 6 * * * $RUNNER_SCRIPT") | crontab -
        echo -e "${GREEN}✓ Cron job added successfully${NC}"
    fi
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Next steps:"
echo "1. Run manually first with --interactive to establish sessions:"
echo "   cd $SCRIPT_DIR"
echo "   source venv/bin/activate"
echo "   python main.py bank --bank nequi --interactive"
echo "   python main.py bank --bank davivienda --interactive"
echo ""
echo "2. After OTP verification, sessions are saved and cron can run"
echo "   without --interactive (until sessions expire)"
echo ""
echo "3. Monitor logs at: $LOG_DIR"
echo ""

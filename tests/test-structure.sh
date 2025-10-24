#!/bin/bash
# Structure validation script for Sonda 2.0
# Validates that all required directories and files exist

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "Sonda 2.0 - Structure Validation"
echo "================================="
echo ""

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        ERRORS=$((ERRORS + 1))
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${YELLOW}⚠${NC} $1 - missing (optional)"
        WARNINGS=$((WARNINGS + 1))
    fi
}

check_file_required() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Checking compose/ layer..."
check_dir "compose"
check_dir "compose/services"
check_dir "compose/configs"
check_dir "compose/overrides"
check_file "compose/docker-compose.yml.j2"
check_file "compose/networks.yml"
echo ""

echo "Checking ansible/ layer..."
check_dir "ansible"
check_dir "ansible/inventories"
check_dir "ansible/playbooks"
check_dir "ansible/roles"
check_file_required "ansible/ansible.cfg"
check_file_required "ansible/requirements.txt"
check_file_required "ansible/requirements.yml"
echo ""

echo "Checking inventories..."
check_dir "ansible/inventories/development"
check_dir "ansible/inventories/staging"
check_dir "ansible/inventories/production"
check_file_required "ansible/inventories/development/hosts.yml"
check_file_required "ansible/inventories/development/group_vars/all/main.yml"
echo ""

echo "Checking playbooks..."
check_file_required "ansible/playbooks/site.yml"
check_file_required "ansible/playbooks/01_prepare.yml"
check_file_required "ansible/playbooks/02_deploy.yml"
check_file_required "ansible/playbooks/03_configure.yml"
check_file_required "ansible/playbooks/04_validate.yml"
echo ""

echo "Checking roles..."
for role in common storage docker compose_stack validation; do
    check_dir "ansible/roles/$role"
    check_dir "ansible/roles/$role/tasks"
    check_file_required "ansible/roles/$role/tasks/main.yml"
    check_file_required "ansible/roles/$role/defaults/main.yml"
done
echo ""

echo "Checking service config roles..."
for service in elasticsearch kibana logstash arkime velociraptor; do
    check_dir "ansible/roles/service_config/$service"
    check_file_required "ansible/roles/service_config/$service/tasks/main.yml"
done
echo ""

echo "Checking root files..."
check_file_required "Makefile"
check_file_required "README.md"
check_file_required ".gitignore"
echo ""

echo "Checking additional directories..."
check_dir "scripts"
check_dir "tests"
check_dir "docs"
echo ""

echo "================================="
echo "Validation Summary"
echo "================================="
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Structure validation PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ Structure validation FAILED${NC}"
    echo "Please run the structure creation script to fix missing items."
    exit 1
fi
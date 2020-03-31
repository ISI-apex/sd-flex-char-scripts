#!/bin/bash
export APP_NAME="megahit-gut5x"
DATASET=/dev/shm/gut-5x.fastq.gz
export APP_CMD=(megahit --12 "$DATASET")

function app_pre() {
    # Megahit fails to discover total memory on the sd-flex
    local PAGE_SIZE
    local PAGE_COUNT
    # megahit only looks for SC_PAGE_SIZE
    PAGE_SIZE=$(getconf PAGESIZE) || return $?
    # megahit only looks for SC_PHYS_PAGES
    PAGE_COUNT=$(getconf _PHYS_PAGES) || return $?
    local MEM_SIZE=$((PAGE_SIZE * PAGE_COUNT))
    # -m specifies system memory, on test system: 4096 * 2340385917 = 9586220716032
    APP_CMD+=(-m "$MEM_SIZE" -t "$1")
}

function app_post() {
    rm -rf megahit_out
}

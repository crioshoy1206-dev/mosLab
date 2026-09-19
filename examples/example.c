#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#include "mosvm/vm_machine.h"

static int report_vm_error(const char *operation, vm_status_t status) {
    fprintf(stderr, "%s failed with VM status %d\n", operation, status);
    return 1;
}

int main(void) {
    vm_machine_t machine;
    vm_machine_spec_t spec;
    uint64_t before_tick = 0U;
    uint64_t after_tick = 0U;
    vm_status_t status;
    int exit_code = 1;

    machine.impl = NULL;

    printf("mosLab VM example\n");

    status = vm_machine_create(&machine);
    if (status != VM_OK) {
        return report_vm_error("vm_machine_create", status);
    }

    status = vm_machine_get_spec(&machine, &spec);
    if (status != VM_OK) {
        exit_code = report_vm_error("vm_machine_get_spec", status);
        goto cleanup;
    }

    status = vm_machine_get_ticks(&machine, &before_tick);
    if (status != VM_OK) {
        exit_code = report_vm_error("vm_machine_get_ticks(before)", status);
        goto cleanup;
    }

    status = vm_machine_tick(&machine);
    if (status != VM_OK) {
        exit_code = report_vm_error("vm_machine_tick", status);
        goto cleanup;
    }

    status = vm_machine_get_ticks(&machine, &after_tick);
    if (status != VM_OK) {
        exit_code = report_vm_error("vm_machine_get_ticks(after)", status);
        goto cleanup;
    }

    printf("page size: %lu bytes\n", (unsigned long)spec.page_size);
    printf("physical frames: %lu\n", (unsigned long)spec.frame_count);
    printf("block size: %lu bytes\n", (unsigned long)spec.block_size);
    printf("block count: %lu\n", (unsigned long)spec.block_count);
    printf("tick: %" PRIu64 " -> %" PRIu64 "\n", before_tick, after_tick);

    if (after_tick != before_tick + 1U) {
        fprintf(stderr, "tick did not advance by exactly one\n");
        goto cleanup;
    }

    printf("example completed successfully\n");
    exit_code = 0;

cleanup:
    status = vm_machine_destroy(&machine);
    if (status != VM_OK) {
        (void)report_vm_error("vm_machine_destroy", status);
        exit_code = 1;
    }
    return exit_code;
}

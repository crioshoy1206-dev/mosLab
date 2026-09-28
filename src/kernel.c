#include "minios/kernel.h"

/* VM 에러 코드(vm_status_t)를 miniOS 에러 코드(mos_status_t)로 변환 */
static mos_status_t vm_to_mos(vm_status_t s) {
    switch (s) {
    case VM_OK:        return MOS_OK;
    case VM_ERR_NULL:  return MOS_ERR_NULL;
    case VM_ERR_RANGE: return MOS_ERR_RANGE;
    case VM_ERR_STATE: return MOS_ERR_STATE;
    case VM_ERR_FULL:  return MOS_ERR_NO_SPACE;
    default:           return MOS_ERR_INVALID;
    }
}

mos_status_t mos_kernel_boot(mos_kernel_t *kernel) {
    vm_status_t vs;
    if (kernel == NULL) return MOS_ERR_NULL;
    /* 초기화 안 된 구조체가 들어올 수 있으므로 BOOTED일 때만 거부 */
    if (kernel->state == MOS_KERNEL_BOOTED) return MOS_ERR_STATE;

    kernel->machine.impl = NULL;
    kernel->private_state = NULL;
    kernel->state = MOS_KERNEL_OFF;

    vs = vm_machine_create(&kernel->machine);
    if (vs != VM_OK) return vm_to_mos(vs);   /* 실패하면 OFF 유지 */

    kernel->state = MOS_KERNEL_BOOTED;       /* VM 성공 후에만 전이 */
    return MOS_OK;
}

mos_status_t mos_kernel_shutdown(mos_kernel_t *kernel) {
    vm_status_t vs;
    if (kernel == NULL) return MOS_ERR_NULL;
    if (kernel->state != MOS_KERNEL_BOOTED) return MOS_ERR_STATE;

    vs = vm_machine_destroy(&kernel->machine);
    if (vs != VM_OK) return vm_to_mos(vs);

    kernel->state = MOS_KERNEL_SHUTDOWN;
    return MOS_OK;
}

mos_status_t mos_kernel_tick(mos_kernel_t *kernel) {
    if (kernel == NULL) return MOS_ERR_NULL;
    if (kernel->state != MOS_KERNEL_BOOTED) return MOS_ERR_STATE;
    return vm_to_mos(vm_machine_tick(&kernel->machine));
}

mos_status_t mos_kernel_ticks(const mos_kernel_t *kernel, uint64_t *ticks_out) {
    if (kernel == NULL || ticks_out == NULL) return MOS_ERR_NULL;
    if (kernel->state != MOS_KERNEL_BOOTED) return MOS_ERR_STATE;
    return vm_to_mos(vm_machine_get_ticks(&kernel->machine, ticks_out));
}
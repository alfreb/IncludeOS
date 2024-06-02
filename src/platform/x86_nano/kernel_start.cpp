
#include <kprint>
#include <info>
#include <kernel.hpp>
#include <os.hpp>
#include <kernel/service.hpp>
#include <boot/multiboot.h>
#include <util/units.hpp>

using namespace util::literals;

extern "C" {
  void __init_sanity_checks();
  uintptr_t _move_symbols(uintptr_t loc);
}

uintptr_t _multiboot_free_begin(uintptr_t boot_addr);
uintptr_t _multiboot_memory_end(uintptr_t boot_addr);
extern bool os_default_stdout;

extern "C"
void kernel_start(uintptr_t magic, uintptr_t addr)
{
  // Determine where free memory starts
  extern char _end;
  uintptr_t free_mem_begin = (uintptr_t) &_end;
  uintptr_t mem_end = 128_MiB; // Qemu default.

  if (magic == MULTIBOOT_BOOTLOADER_MAGIC) {
    free_mem_begin = _multiboot_free_begin(addr);
    mem_end = _multiboot_memory_end(addr);
  }

  // Preserve symbols from the ELF binary
  free_mem_begin += _move_symbols(free_mem_begin);

  // Initialize .bss
  extern char _BSS_START_, _BSS_END_;
  __builtin_memset(&_BSS_START_, 0, &_BSS_END_ - &_BSS_START_);

  // Initialize heap
  kernel::init_heap(free_mem_begin, mem_end);

  // Initialize stdout handlers
  if (os_default_stdout)
    os::add_stdout(&kernel::default_stdout);

  kernel::start(magic, addr);

  // Start the service
  Service::start();

  __arch_poweroff();
}


// A lightweight panic.
void os::panic(const char* why) noexcept {
  kprint(os::panic_signature);
  kprint("\nReason:\n");
  kprint(why);
  kprint("\n\x04"); // End of transmission, for tooling.

  // Halt forever
  __asm("cli;hlt");
}

// Failed "Expects"
void __expect_fail(const char *expr, const char *file, int line, const char *func){
  kprintf("%s:%i%:%s\n>>>%s\n", file, line, func, expr);
  os::panic(expr);
}

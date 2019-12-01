#pragma once
#include <array>
#include <vector>

//#define THREADS_DEBUG 1
#ifdef THREADS_DEBUG
#define THPRINT(fmt, ...) kprintf(fmt, ##__VA_ARGS__)
#else
#define THPRINT(fmt, ...) /* fmt */
#endif

namespace kernel
{
  struct Thread {
    Thread* self;
    Thread* parent = nullptr;
    int64_t  tid;
    void*    my_tls;
    void*    my_stack;
    // for returning to this Thread
    void*    stored_stack = nullptr;
    void*    stored_nexti = nullptr;
    bool     yielded = false;
    // address zeroed when exiting
    void*    clear_tid = nullptr;
    // children, detached when exited
    std::vector<Thread*> children;

    void init(int tid);
    void yield();
    void exit();
    void suspend(void* ret_instr, void* ret_stack);
    void activate(void* newtls);
    void resume();
  private:
    void store_return(void* ret_instr, void* ret_stack);
    void libc_store_this();
  };

  struct Thread_manager
  {

  };

  inline Thread* get_thread()
  {
    Thread* Thread;
    # ifdef ARCH_x86_64
        asm("movq %%fs:(0x10), %0" : "=r" (Thread));
    # elif defined(ARCH_i686)
        asm("movq %%gs:(0x08), %0" : "=r" (Thread));
    # else
        #error "Implement me?"
    # endif
    return Thread;
  }

  Thread* get_thread(int64_t tid); /* or nullptr */

  inline int64_t get_tid() {
    return get_thread()->tid;
  }

  int64_t get_last_thread_id() noexcept;

  void* get_thread_area();
  void  set_thread_area(void*);

  Thread* thread_create(Thread* parent, int flags, void* ctid, void* stack) noexcept;

  void resume(int64_t tid);

  void setup_main_thread() noexcept;
}

extern "C" {
  void __thread_yield();
}

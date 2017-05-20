// -*-C++-*-
// This file is a part of the IncludeOS unikernel - www.includeos.org
//
// Copyright 2017 Oslo and Akershus University College of Applied Sciences
// and Alfred Bratterud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <arch.hpp>
#include <info>

extern char* __arch_paging_start;
extern uint32_t __arch_page_dir_size;

#define MYINFO(X,...) INFO("x86_64", X, ##__VA_ARGS__)


#define PML4_ENTS 1    // Max 512 - Address 512 GB - 512^2 GB
#define PML3_ENTS 4   // Max 512 - Address 1 - 512 GB
#define PML2_ENTS 512  // (Page dirMax 512 -
#define PAGE_ENTS 512  // Max 512

// Manual Vol.3.A, p. 4-22
// PML4 consists of PML4E(ntries), Page Directory pointers
uint64_t PML4 [PML4_ENTS] __attribute__((aligned(0x20)));

// PML3 consists of Page directory pointers
uint64_t PML3 [PML4_ENTS][PML3_ENTS] __attribute__((aligned(0x1000)));  // must be aligned to page boundary

// PML2 consists of Page table pointers
uint64_t PML2 [PML4_ENTS][PML3_ENTS][PML2_ENTS] __attribute__((aligned(0x1000)));  // must be aligned to page boundary

// PML1, A Page table,  consists of Page entries
uint64_t PML1 [PML4_ENTS][PML3_ENTS][PML2_ENTS][PAGE_ENTS] __attribute__((aligned(0x1000)));

void __arch_init_paging() {

  //uint64_t page_size = 1 << 21;
  uint64_t page_size = 0x1000;

  MYINFO("Initializing paging. %i super dirs of %i page dirs of 512 %i b pages. Mapping %f Gb of memory",
         PML4_ENTS, PML3_ENTS, PML2_ENTS, PAGE_ENTS, page_size, (PML4_ENTS * PML3_ENTS * PML2_ENTS * PAGE_ENTS * page_size) / 1000000000.f
         );

  MYINFO("Addresz of PML4: %p \n", &PML4);

  unsigned int page, address = 0;
  for (int pml4 = 0; pml4 < PML4_ENTS; pml4++) {
    PML4[pml4] = (uint64_t)&PML3[pml4] | 3; // set the page directory into the PDPT and mark it present
    for (int pml3 = 0; pml3 < PML3_ENTS; pml3++) {
      PML3[pml4][pml3] = (uint64_t)&PML2[pml4][pml3] | 3; // Bit 7: Page size - 1 for 1GB pages
      for(int pml2 = 0; pml2 < PML2_ENTS; pml2++) {
        PML2[pml4][pml3][pml2] = (uint64_t)&PML1[pml4][pml3][pml2] | 3; //| 1 << 7; Bit 7: Page size - 1 for 2MB pages
        for(int page = 0; page < PAGE_ENTS; page++) {
          PML1[pml4][pml3][pml2][page] = address | 3;
          address += page_size;
        }
      }
    }
  };

  // load page structure into CR3
  asm volatile ("mov %%rax, %%cr3;" :: "a" (&PML4));

}

gsl::span<Page> __arch_page_directory() {
  return {(Page*)__arch_paging_start, __arch_page_dir_size / PAGE_SIZE};
  //return {(Page*)&page_tab, (PAGE_DIRS * 512) / PAGE_SIZE};
};

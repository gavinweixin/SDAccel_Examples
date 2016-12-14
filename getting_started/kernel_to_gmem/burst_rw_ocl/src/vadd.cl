/*******************************************************************************
Copyright (c) 2016, Xilinx, Inc.
All rights reserved.
 
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
 
1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
 
 
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
 
 
3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/

/*******************************************************************************
Description: 
    OpenCL Kernel Example to demonstrate burst read and write access from 
    Global Memory
*******************************************************************************/

// Below Macro should be commented for optimized design. Xilinx recommends to use for loop approach instead of async_work_grop_copy() API burst read/write
//#define USE_ASYNC_API 

#define BURSTBUFFERSIZE 2048

__kernel __attribute__ ((reqd_work_group_size(1, 1, 1)))
void vadd(__global int *a, int size, int inc_value){
    int i;
#ifndef USE_ASYNC_API  //Burst Read using For loop (Xilinx recommended)
    int burstbuffer[BURSTBUFFERSIZE];
    //read data from global memory into local buffer, the sequential read in a for loop can be inferred to a memory burst access automatically
    read_buf: for (i = 0; i < size; ++i) {
        burstbuffer[i] = a[i];
    }
#else //Burst Read using async_work_group_copy() API (Not recommended)
    __local int burstbuffer[BURSTBUFFERSIZE]; //For async_work_group_copy() API, local array should be declared with "__local"
   async_work_group_copy(burstbuffer, a, size, 0);
   //This code is kept here for intentionally to describe about async_work_group_copy() comparison with respect to for loop
   //based implementation. async_work_group_copy() API is another way of implementing burst read from global memory, 
   // but it is not recommended to use async_work_group_copy() API. Most of time, tool generated pipeline design using this API 
   // will not as efficient as 'for' loop based implementation. async_work_group_copy() may creates pipeline design 
   //larger number of pipeline stages
#endif
    //calculate and write results to global memory, the sequential write in a for loop can be inferred to a memory burst access automatically
    __attribute__((xcl_pipeline_loop))
    calc_write: for(i=0; i < size; i++){
        burstbuffer[i] = burstbuffer[i] + inc_value;
        a[i] = burstbuffer[i];
    }
}

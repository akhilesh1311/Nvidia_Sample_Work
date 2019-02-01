#include <stdio.h>
#include <cuda_runtime.h>
#include <helper_cuda.h>
#include <helper_functions.h>
#include<stdlib.h>
#define GAP 100
#define NUMBER 400
#define THREAD 37
#define BLOCK 11
#define LIMIT 500000

__global__ void uncoalesced(int *d_A,int *d_local){
	
	int threadIdfinal=blockIdx.x*blockDim.x+threadIdx.x;
	if(threadIdfinal*GAP+GAP<=NUMBER){
	for(int i=threadIdfinal*GAP;i<threadIdfinal*GAP+GAP;i++){
		if(d_local[threadIdfinal]<d_A[i]){
			d_local[threadIdfinal]=d_A[i];
		}
	}
	}else if(threadIdfinal*GAP<NUMBER){
		for(int i=threadIdfinal*GAP;i<NUMBER;i++){
		if(d_local[threadIdfinal]<d_A[i]){
			d_local[threadIdfinal]=d_A[i];
		}
	}
	}
}

__global__ void coalesced(int *d_A,int *d_local){
	int threadIdfinal=blockIdx.x*blockDim.x+threadIdx.x;
	if(threadIdfinal<NUMBER/GAP){
		for(int i=threadIdfinal;i<NUMBER;i=i+GAP){
			if(d_local[threadIdfinal]<d_A[i]){
				d_local[threadIdfinal]=d_A[i];
			}	
		}
	}
}

/*__global__ void coalesced(int *d_A,int *d_local){
	int threadIdfinal=blockIdx.x*blockDim.x+threadIdx.x;
	int localmax=0;
	if(threadIdfinal<NUMBER/GAP){
		for(int i=threadIdfinal;i<NUMBER;i=i+GAP){
			if(localmax<d_A[i]){
				localmax=d_A[i];
			}	
		}
		d_local[threadIdfinal]=localmax;
	}
}*/


int main(int argc, char *argv[]){
	size_t size=NUMBER*sizeof(int);
	size_t sizesol=(NUMBER+GAP)*sizeof(int)/GAP;
	int *d_A;
	cudaMalloc(&d_A,size);

	int *h_A;
	h_A=(int *)malloc(sizeof(int)*NUMBER);
	
	time_t t;
	srand((unsigned)time(&t));
	
	for(int i=0;i<NUMBER;i++){
		h_A[i]=rand()%LIMIT;
	}
		
	cudaMemcpy(d_A,h_A,size,cudaMemcpyHostToDevice);
	cudaDeviceSynchronize();
	
	dim3 block(BLOCK);
	dim3 thread(THREAD);
	
	int *d_local;
	cudaMalloc(&d_local,sizesol);
	
	int *h_B;
	h_B=(int *)malloc(sizesol);
	
	for(int i=0;i<NUMBER/GAP+1;i++){
		printf("~~%d~~",i);
		h_B[i]=0;
	}
	
	cudaMemcpy(d_local,h_B,sizesol,cudaMemcpyHostToDevice);
	cudaDeviceSynchronize();
	
	coalesced<<<block,thread>>>(d_A,d_local);
	
	
	int *h_global;
	h_global=(int *)malloc(sizeof(int)*NUMBER);
	
	cudaMemcpy(h_global,d_local,sizesol,cudaMemcpyDeviceToHost);
	
	cudaDeviceSynchronize();
	for(int i=0;i<NUMBER;i++){
		printf("  %d) %d\n",i,h_A[i]);
	}
	
	int global_max=0;
	for(int i=0;i<NUMBER/GAP+1;i++){
		printf("dodo   %d\n",h_global[i]);
		if(global_max<h_global[i]){
			
			global_max=h_global[i];
		}
	}
	printf("alas, here comes hte final output  %d\n",global_max);
	cudaDeviceReset();
	return 0;
}

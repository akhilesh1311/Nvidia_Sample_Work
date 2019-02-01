#include <stdio.h>
#include <cuda_runtime.h>
#include <helper_cuda.h>
#include <helper_functions.h>
#define NUMBER 23

__global__ void uncoalesced();

__global__ void uncoalesced(int *d_A){
	int blockIdfinal,threadIdfinal;
	blockIdfinal=blockIdx.y+gridDim.y*blockIdx.x;
//	printf(" lol %d %d %d",);
	threadIdfinal=blockIdfinal*blockDim.x*blockDim.y + (threadIdx.y+threadIdx.x*blockDim.y);
	if(threadIdfinal<NUMBER){
		*(d_A+threadIdfinal)=100;
	//	printf(" %d",threadIdfinal);
	}
}

__global__ void trial(int *d_A){
	printf("this has to be fast   %d %d \n ",threadIdx.x,threadIdx.y);
	
}

int main(int argc, char *argv[]){
//	printf("\nUncoalesced accesses to the Global memory of Dram of GPU\n");
/*	dim3 block(4,4);
	dim3 thread(3,3);
	trial<<<block,thread>>>();
	cudaDeviceSynchronize();*/
	
	size_t size=NUMBER*sizeof(int);
	int *d_A;
	cudaMalloc(&d_A,size);
	
	dim3 block(5,4);
	dim3 thread(10,1);
	uncoalesced<<<block,thread>>>(d_A);
	
	int *h_A;
	h_A=(int *)malloc(sizeof(int)*NUMBER);
	
	cudaMemcpy(h_A,d_A,size,cudaMemcpyDeviceToHost);
	
	cudaDeviceSynchronize();
	for(int i=0;i<NUMBER;i++){
		printf("  %d) %d",i,h_A[i]);
	}
	
	return 0;
}

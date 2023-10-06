#include <iostream>
#include <math.h>
// Kernel function to add the elements of two arrays
__global__
void add_whole(int n, float *x, float *y)
{
  for (int i = 0; i < n; i++)
    y[i] = x[i] + y[i];
}

__global__
void add_thread(int n, float *x, float *y)
{
  int index = threadIdx.x;
  int stride = blockDim.x;
  for (int i = index; i < n; i += stride)
      y[i] = x[i] + y[i];
}

__global__
void add_block(int n, float *x, float *y)
{
  int index = blockIdx.x * blockDim.x + threadIdx.x;
  int stride = blockDim.x * gridDim.x;
  printf("kernel %d\n", gridDim.x)
  for (int i = index; i < n; i += stride)
    y[i] = x[i] + y[i];
}


int main(int argc, char** argv)
{
  int N = 1<<20;
  float *x, *y;

  // Allocate Unified Memory – accessible from CPU or GPU
  cudaMallocManaged(&x, N*sizeof(float));
  cudaMallocManaged(&y, N*sizeof(float));

  // initialize x and y arrays on the host
  for (int i = 0; i < N; i++) {
    x[i] = 1.0f;
    y[i] = 2.0f;
  }

  if (std::string(argv[1]) == "1") {
      // Run kernel on 1M elements on the GPU
      add_whole<<<1, 1>>>(N, x, y);
  } else if (std::string(argv[1]) == "2") {
      add_thread<<<1, 256>>>(N, x, y);
  } else if (std::string(argv[1]) == "3") {
      int blockSize = 1024;
      int numBlocks = (N + blockSize - 1) / blockSize;
      printf("%d, %d\n", numBlocks, blockSize);
      add_block<<<numBlocks, blockSize>>>(N, x, y);
  }

  // Wait for GPU to finish before accessing on host
  cudaDeviceSynchronize();

  // Check for errors (all values should be 3.0f)
  float maxError = 0.0f;
  for (int i = 0; i < N; i++)
    maxError = fmax(maxError, fabs(y[i]-3.0f));
  std::cout << "Max error: " << maxError << std::endl;

  // Free memory
  cudaFree(x);
  cudaFree(y);
  
  return 0;
}

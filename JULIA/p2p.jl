#
# Copyright (c) 2015, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
# * Neither the name of Intel Corporation nor the names of its
#       contributors may be used to endorse or promote products
#       derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

#*******************************************************************
# NAME:    Pipeline
#
# PURPOSE: This program tests the efficiency with which point-to-point
#          synchronization can be carried out. It does so by executing
#          a pipelined algorithm on an m*n grid. The first array dimension
#          is distributed among the threads (stripwise decomposition).
#
# USAGE:   The program takes as input the
#          dimensions of the grid, and the number of iterations on the grid
#
#                <progname> <iterations> <m> <n>
#
#          The output consists of diagnostics to make sure the
#          algorithm worked, and of timing statistics.
#
# FUNCTIONS CALLED:
#
#          Other than standard C functions, the following
#          functions are used in this program:
#
# HISTORY: - Written by Rob Van der Wijngaart, February 2009.
#          - Converted to Python by Jeff Hammond, February 2016.
#          - Converted to Julia by Jeff Hammond, June 2016.
#
# *******************************************************************

# ********************************************************************
# read and test input parameters
# ********************************************************************

println("Parallel Research Kernels version ") #, PRKVERSION, "\n")
println("Python pipeline execution on 2D grid\n")

if length(ARGS) != 3
    println("argument count = ", length(ARGS))
    println("Usage: ./synch_p2p <# iterations> <first array dimension> <second array dimension>")
    exit(1)
end

argv = map(x->parse(Int64,x),ARGS)

iterations = argv[1]
if iterations < 1
    println("ERROR: iterations must be >= 1")
    exit(2)
end

m = argv[2]
if m < 1
    println("ERROR: array dimension must be >= 1")
    exit(3)
end

n = argv[3]
if n < 1
    println("ERROR: array dimension must be >= 1")
    exit(4)
end

println("Grid sizes               = ", m, ",", n)
println("Number of iterations     = ", iterations)

grid = zeros([m n])
#grid[0,:] = range(n)
#grid[:,0] = range(m)

for k in 1:iterations+1
    # start timer after a warmup iteration
    if k<1
        t0 = time_ns()
    end

    for i in 1:m
        for j in 1:n
            grid[i,j] = grid[i-1,j] + grid[i,j-1] - grid[i-1,j-1]
        end
    end

    # copy top right corner value to bottom left corner to create dependency
    #grid[1,1] = -grid[m,n]
end


t1 = time_ns()
pipeline_time = t1 - t0

# ********************************************************************
# ** Analyze and output results.
# ********************************************************************

epsilon=1.e-8

# verify correctness, using top right value
corner_val = float((iterations+1)*(n+m-2))
if (abs(grid[m-1,n-1] - corner_val)/corner_val) < epsilon
    println("Solution validates")
    avgtime = pipeline_time/iterations
    println("Rate (MFlops/s): ",1.e-6*2*(m-1)*(n-1)/avgtime," Avg time (s): ",avgtime,"\n")
else
    println("ERROR: checksum ",grid[m-1,n-1]," does not match verification value", corner_val,"\n")
    exit(9)
end



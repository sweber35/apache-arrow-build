FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install build dependencies
RUN yum install -y \
  gcc gcc-c++ make cmake git ninja-build \
  glibc-static libstdc++-static \
  zlib-devel xz-devel bzip2-devel lz4-devel \
  libcurl-devel openssl-devel

RUN yum install -y zlib-static lz4-static bzip2-static

# Build zstd static library
RUN git clone --branch v1.5.5 https://github.com/facebook/zstd.git && \
    cd zstd/build/cmake && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DZSTD_BUILD_SHARED=OFF -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j$(nproc) && make install && cd / && rm -rf zstd

# Build Arrow
WORKDIR /arrow
RUN git clone --branch apache-arrow-14.0.1 --depth 1 https://github.com/apache/arrow.git .
RUN mkdir -p cpp/build && cd cpp/build && \
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DARROW_PARQUET=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_BUILD_STATIC=ON \
    -DARROW_BUILD_SHARED=OFF \
    -DARROW_USE_STATIC_CRT=ON \
    -DARROW_SIMD_LEVEL=NONE \
    -DARROW_COMPUTE=OFF \
    -DARROW_CSV=OFF \
    -DARROW_JSON=OFF \
    -DARROW_IPC=OFF \
    -DARROW_FILESYSTEM=OFF \
    -DARROW_GANDIVA=OFF \
    -DARROW_HDFS=OFF \
    -DARROW_S3=OFF \
    -GNinja && \
  ninja install

# Strip the image of unneeded files
RUN rm -rf /arrow

# Final base image for building slippc
WORKDIR /build

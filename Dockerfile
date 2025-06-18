FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install build dependencies
RUN yum install -y \
  gcc gcc-c++ make cmake git ninja-build \
  glibc-static libstdc++-static \
  zlib-devel zlib-static \
  xz-devel xz-static \
  bzip2-devel bzip2-static \
  lz4-devel lz4-static \
  libcurl-devel openssl-devel \
  snappy snappy-devel

# Build zstd static library (libzstd.a)
RUN git clone --branch v1.5.5 https://github.com/facebook/zstd.git && \
    cd zstd/build/cmake && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DZSTD_BUILD_SHARED=OFF -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j$(nproc) && make install && cd / && rm -rf zstd

# Set working directory for Arrow
WORKDIR /arrow

# Download Apache Arrow
RUN git clone --branch apache-arrow-14.0.1 --depth 1 https://github.com/apache/arrow.git .

# Build Apache Arrow statically
RUN mkdir -p cpp/build && cd cpp/build && \
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DARROW_PARQUET=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_SNAPPY=OFF \
    -DARROW_BUILD_STATIC=ON \
    -DARROW_BUILD_SHARED=OFF \
    -DARROW_USE_STATIC_CRT=ON \
    -DARROW_SIMD_LEVEL=NONE \
    -DARROW_COMPUTE=ON \
    -DARROW_IO=ON \
    -DARROW_CSV=OFF \
    -DARROW_JSON=OFF \
    -DARROW_IPC=OFF \
    -DARROW_FILESYSTEM=OFF \
    -DARROW_GANDIVA=OFF \
    -DARROW_HDFS=OFF \
    -DARROW_S3=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-maybe-uninitialized" \
    -GNinja && \
  ninja install

# Manually install libarrow_util.a if it was built
RUN #find /arrow -name "libarrow_util.a" -exec cp {} /usr/local/lib/ \;

# Confirm that libzstd.a and libarrow_util.a are available
RUN ls -lh /usr/lib64/libzstd.a && echo "✅ libzstd.a is available"
RUN #ls -lh /usr/local/lib/libarrow_util.a && echo "✅ libarrow_util.a is available"

# Optional: clean up to reduce image size
RUN rm -rf /arrow && \
    yum remove -y cmake git ninja-build && \
    yum clean all && \
    rm -rf /var/cache/yum

# Make this available as a base image for slippc builds
WORKDIR /build

# Support pkg-config in downstream builds
ENV PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig

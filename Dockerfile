FROM public.ecr.aws/amazonlinux/amazonlinux:2023 as arrow-base

RUN yum install -y \
  gcc gcc-c++ make cmake ninja-build git \
  glibc-static libstdc++-static \
  xz-devel zlib-devel bzip2-devel lz4-devel \
  boost-devel libzstd pkgconf-pkg-config

# Build and install Apache Arrow and Parquet
RUN git clone --depth=1 --branch apache-arrow-14.0.1 https://github.com/apache/arrow.git && \
    mkdir -p arrow/cpp/build && cd arrow/cpp/build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DARROW_PARQUET=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_BZ2=ON \
      -DARROW_WITH_LZMA=ON \
      -DARROW_BUILD_SHARED=ON \
      -DARROW_BUILD_BENCHMARKS=OFF \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_BUILD_UTILITIES=OFF && \
    ninja && ninja install

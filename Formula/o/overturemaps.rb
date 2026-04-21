class Overturemaps < Formula
  include Language::Python::Virtualenv

  desc "Python tools for interacting with Overture Maps data"
  homepage "https://overturemaps.org"
  url "https://files.pythonhosted.org/packages/2e/f6/e220c4026bbb425e9c7e0ca02237308dad69598449d4dcf5229f2a60d213/overturemaps-0.20.0.tar.gz"
  sha256 "aef735329a827511ae3164b90920debfd485832557f15733a295d4fe5580cb18"
  license "MIT"
  revision 1
  head "https://github.com/OvertureMaps/overturemaps-py.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_tahoe:   "268845bb0259db65ff45bba5ce2969f988803ce8d46d5536d05b452247a015cb"
    sha256 cellar: :any,                 arm64_sequoia: "bf579981745a254dffd2d0b90e4202f896ba0a885eb6f5f21babea9bbc27c5ed"
    sha256 cellar: :any,                 arm64_sonoma:  "26abb1e07acb749ed0b95067d584398eeb247972764464b0b2f468881947fad4"
    sha256 cellar: :any,                 sonoma:        "0da98f40fc03a68a14d64cc244678b26bdb76022610483b729583fa248a665af"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "e228d6757bb50517694e89846489e71e1bcffb224de12d3e1f4fa6477c5bc248"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "d9112b251b18cf0636772b36984c12337a5ff8d82ef89ccba786ecdf074a5689"
  end

  depends_on "cmake" => :build  # for pyarrow
  depends_on "ninja" => :build  # for pyarrow
  depends_on "rust" => :build   # for orjson
  depends_on "apache-arrow"
  depends_on "geos"             # for shapely
  depends_on "numpy"
  depends_on "python@3.14"

  on_linux do
    depends_on "patchelf" => :build # for pyarrow
  end

  pypi_packages exclude_packages: "numpy"

  resource "click" do
    url "https://files.pythonhosted.org/packages/57/75/31212c6bf2503fdf920d87fee5d7a86a2e3bcf444984126f13d8e4016804/click-8.3.2.tar.gz"
    sha256 "14162b8b3b3550a7d479eafa77dfd3c38d9dc8951f6f69c78913a8f9a7540fd5"
  end

  resource "orjson" do
    url "https://files.pythonhosted.org/packages/9d/1b/2024d06792d0779f9dbc51531b61c24f76c75b9f4ce05e6f3377a1814cea/orjson-3.11.8.tar.gz"
    sha256 "96163d9cdc5a202703e9ad1b9ae757d5f0ca62f4fa0cc93d1f27b0e180cc404e"

    # Remove nightly feature flag, Rust 1.95 is now stable
    patch :DATA
  end

  resource "pyarrow" do
    url "https://files.pythonhosted.org/packages/88/22/134986a4cc224d593c1afde5494d18ff629393d74cc2eddb176669f234a4/pyarrow-23.0.1.tar.gz"
    sha256 "b8c5873e33440b2bc2f4a79d2b47017a89c5a24116c055625e6f2ee50523f019"
  end

  resource "shapely" do
    url "https://files.pythonhosted.org/packages/4d/bc/0989043118a27cccb4e906a46b7565ce36ca7b57f5a18b78f4f1b0f72d9d/shapely-2.1.2.tar.gz"
    sha256 "2ed4ecb28320a433db18a5bf029986aa8afcfd740745e78847e330d5d94922a9"
  end

  def python3
    "python3.14"
  end

  def install
    # The sdist has reproducible-build timestamps from 2020-02-02, which causes
    # Homebrew to set SOURCE_DATE_EPOCH to that date. This makes pip restrict
    # package downloads to pre-2020, breaking all modern build backends.
    # Reset to current time so the 24-hour safety window works as intended.
    ENV["SOURCE_DATE_EPOCH"] = Time.now.utc.to_i.to_s

    numpy_include = Formula["numpy"].opt_lib/Language::Python.site_packages(python3)/"numpy/_core/include"
    geos_include = Formula["geos"].opt_include
    geos_lib = Formula["geos"].opt_lib

    ENV.prepend "CFLAGS", "-I#{numpy_include} -I#{geos_include}"
    ENV.prepend "LDFLAGS", "-L#{geos_lib}"

    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/overturemaps --version")
    output = shell_output("#{bin}/overturemaps download 2>&1", 2)
    assert_match "Missing option", output
  end
end

__END__
--- a/src/lib.rs
+++ b/src/lib.rs
@@ -1,7 +1,6 @@
 // SPDX-License-Identifier: MPL-2.0
 // Copyright ijl (2018-2026)
 
-#![cfg_attr(feature = "cold_path", feature(cold_path))]
 #![cfg_attr(feature = "generic_simd", feature(portable_simd))]
 #![cfg_attr(feature = "optimize", feature(optimize_attribute))]
 #![allow(unused_features)] // portable_simd on universal2 cross-compile

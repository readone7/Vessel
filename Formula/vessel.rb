class Vessel < Formula
  desc "Vessel CLI and runtime tools"
  homepage "https://example.com/vessel"
  url "https://example.com/vessel/archive/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_RELEASE_SHA256"
  license "Apache-2.0"

  depends_on "zig" => :build

  def install
    system "zig", "build", "-Doptimize=ReleaseSafe"
    bin.install "zig-out/bin/vessel"
    bin.install "zig-out/bin/vesseld"
    bin.install "zig-out/bin/vegistry"
  end

  test do
    output = shell_output("#{bin}/vessel version")
    assert_match "vessel", output
  end
end


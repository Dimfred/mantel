class Mantel < Formula
  desc "macOS-native image overlay tool for terminals"
  homepage "https://github.com/Dimfred/mantel"
  version "0.1.1"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/Dimfred/mantel/releases/download/v0.1.0/mantel-v0.1.0-arm64"
      sha256 "c43febae5465be9e9cd5b8e6ba4fa1a294567138bcbaa9461192229cf03858a9"
    end
  end

  def install
    bin.install Dir["*"].first => "mantel"
  end

  test do
    assert_match "mantel", shell_output("#{bin}/mantel --help", 1)
  end
end

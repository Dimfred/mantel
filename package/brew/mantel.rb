class Mantel < Formula
  desc "macOS-native image overlay tool for terminals"
  homepage "https://github.com/Dimfred/mantel"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/Dimfred/mantel/releases/download/v0.1.0/mantel-v0.1.0-arm64"
      sha256 "PLACEHOLDER"
    end
  end

  def install
    bin.install Dir["*"].first => "mantel"
  end

  test do
    assert_match "mantel", shell_output("#{bin}/mantel --help", 1)
  end
end

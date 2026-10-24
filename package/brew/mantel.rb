class Mantel < Formula
  desc "Image overlay daemon for terminals"
  homepage "https://github.com/Dimfred/mantel"
  url "https://github.com/Dimfred/mantel/releases/download/v0.1.2/mantel-v0.1.2-arm64"
  version "0.1.2"
  sha256 "c43febae5465be9e9cd5b8e6ba4fa1a294567138bcbaa9461192229cf03858a9"
  license "MIT"

  depends_on arch: :arm64
  depends_on :macos

  def install
    bin.install "mantel-v#{version}-arm64" => "mantel"
  end

  def caveats
    <<~EOS
      Run `brew services stop mantel` before `brew uninstall mantel`, otherwise the LaunchAgent stays behind.
      Grant Accessibility to #{opt_bin}/mantel so images follow terminal moves / resizes.
    EOS
  end

  service do
    run opt_bin/"mantel"
    keep_alive true
    log_path var/"log/mantel.log"
    error_log_path var/"log/mantel.log"
  end

  test do
    assert_match "mantel", shell_output("#{bin}/mantel --help", 1)
  end
end

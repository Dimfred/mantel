cask "mantel" do
  version "0.1.1"
  sha256 "c43febae5465be9e9cd5b8e6ba4fa1a294567138bcbaa9461192229cf03858a9"

  url "https://github.com/Dimfred/mantel/releases/download/v#{version}/mantel-v#{version}-arm64"
  name "mantel"
  desc "Image overlay daemon for terminals"
  homepage "https://github.com/Dimfred/mantel"

  depends_on arch: :arm64
  depends_on macos: :ventura

  binary "mantel-v#{version}-arm64", target: "mantel"

  postflight_steps do
    run "/usr/bin/xattr", args: ["-c", "{{staged_path}}/mantel-v{{version}}-arm64"]
    mkdir_p "Library/LaunchAgents", base: :home
    mkdir_p "var/log", base: :homebrew_prefix
    write_file "Library/LaunchAgents/com.dimfred.mantel.plist", <<~XML, base: :home
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>com.dimfred.mantel</string>
          <key>ProgramArguments</key>
          <array>
            <string>{{HOMEBREW_PREFIX}}/bin/mantel</string>
          </array>
          <key>StandardOutPath</key>
          <string>{{HOMEBREW_PREFIX}}/var/log/mantel.log</string>
          <key>StandardErrorPath</key>
          <string>{{HOMEBREW_PREFIX}}/var/log/mantel.log</string>
          <key>KeepAlive</key>
          <true/>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    XML
    # bootstrap fails while an agent with this label (e.g. from `make install`) is still loaded
    run "/bin/sh", args: ["-c", <<~SH]
      set -eu
      target="gui/$(id -u)/com.dimfred.mantel"
      if /bin/launchctl print "$target" >/dev/null 2>&1; then
        /bin/launchctl bootout "$target"
      fi
      /bin/launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.dimfred.mantel.plist"
    SH
  end

  uninstall launchctl: "com.dimfred.mantel",
            delete:    "~/Library/LaunchAgents/com.dimfred.mantel.plist"

  zap trash: "#{HOMEBREW_PREFIX}/var/log/mantel.log"

  caveats <<~EOS
    mantel runs as the LaunchAgent com.dimfred.mantel (log: #{HOMEBREW_PREFIX}/var/log/mantel.log).
    Grant Accessibility to #{HOMEBREW_PREFIX}/bin/mantel so images follow terminal moves / resizes.
  EOS
end

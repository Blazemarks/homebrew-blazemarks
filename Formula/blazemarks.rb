# Homebrew Formula 模板（issue #136）：CI 在每次 release 后用 sed 把下面几个
# __占位符__ 换成实际版本号 / sha256，渲染结果推到独立的 tap 仓库
# （github.com/Blazemarks/homebrew-blazemarks，需要先手动建好，见 release.yml
# homebrew-tap job 里的说明），不直接放进这个仓库让 `brew install` 生效。
#
# 用 on_macos/on_linux + on_arm/on_intel 覆盖四个平台的 release 产物，
# 装完用 `brew services start blazemarks` 走 launchd/systemd 常驻，
# 不需要再跑 install.sh。
class Blazemarks < Formula
  desc "Self-hosted, private navigation / bookmark server"
  homepage "https://github.com/Blazemarks/blazemarks"
  license "AGPL-3.0-or-later"
  version "0.1.0"

  on_macos do
    on_arm do
      url "https://github.com/Blazemarks/blazemarks/releases/download/v0.1.0/blazemarks-0.1.0-macos-arm64.tar.gz"
      sha256 "1b110c3e5a2fd7c424e2966628c902694b3bb5084dd61337707ace13223611c7"
    end
    on_intel do
      url "https://github.com/Blazemarks/blazemarks/releases/download/v0.1.0/blazemarks-0.1.0-macos-amd64.tar.gz"
      sha256 "5886854b14355b14e7f6cdf1074e960e8a78090a64fc8903dff810e4c8c69860"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/Blazemarks/blazemarks/releases/download/v0.1.0/blazemarks-0.1.0-linux-arm64.tar.gz"
      sha256 "6909b83359118f556b2c7e816075ae218137d1acc1639ba029c3e45f4b978880"
    end
    on_intel do
      url "https://github.com/Blazemarks/blazemarks/releases/download/v0.1.0/blazemarks-0.1.0-linux-amd64.tar.gz"
      sha256 "d8e491fa3d2ecd8bdf4b2c8281d229a3917daa19aa188acf819368266e631646"
    end
  end

  def install
    bin.install "blazemarks"
    pkgshare.install "templates", "web", "locales", "assets"
  end

  def post_install
    (var/"blazemarks/data").mkpath
    # templates/web/locales/assets 运行时按相对路径从工作目录读（storage.rs），
    # brew 每次装/升级都从 pkgshare 刷新一份到工作目录，跟 install.sh 的做法一致
    %w[templates web locales assets].each do |d|
      target = var/"blazemarks"/d
      target.rmtree if target.exist?
      cp_r pkgshare/d, target
    end
  end

  service do
    run [opt_bin/"blazemarks"]
    working_dir var/"blazemarks"
    environment_variables BLAZEMARKS_DATA_DIR: (var/"blazemarks/data").to_s
    log_path var/"log/blazemarks.log"
    error_log_path var/"log/blazemarks.log"
  end

  test do
    assert_predicate bin/"blazemarks", :exist?
  end
end

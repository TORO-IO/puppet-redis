require 'formula'

class Redis < Formula
  desc "Persistent key-value database, with built-in net interface"
  homepage "http://redis.io/"
  url "http://download.redis.io/releases/redis-3.0.4.tar.gz"
  sha256 "a35e90ad581925134aa0fc92e969cc825f5cdee8e13c36a87d4d6995316112cf"

  version '3.0.4-boxen1'

  bottle do
    cellar :any
    sha256 "83d3cbef80d144afba7ca0b3a09e453f7fb167726f3a5d556fa85d776213d85d" => :el_capitan
    sha256 "6882e80a0829f5a0c43d6de884e74c260e1894d72bb4dbf7624f0b8744f6efda" => :yosemite
    sha256 "60e9cd04b465b18dc3a640410ab608e4411f6f190893ff2dbf445293c05c53e8" => :mavericks
    sha256 "0a698150174674a92dd8936db283126a95b6dc3dfefc61065250d59bb71fcd42" => :mountain_lion
  end

  option "with-jemalloc", "Select jemalloc as memory allocator when building Redis"

  head "https://github.com/antirez/redis.git", :branch => "unstable"

  fails_with :llvm do
    build 2334
    cause "Fails with \"reference out of range from _linenoise\""
  end

  def install
    ENV["OBJARCH"] = "-arch #{MacOS.preferred_arch}"

    args = %W[
      PREFIX=#{prefix}
      CC=#{ENV.cc}
    ]

    args << "MALLOC=jemalloc" if build.with? "jemalloc"
    system "make", "install", *args

    %w[run db/redis log].each { |p| (var+p).mkpath }

    # Fix up default conf file to match our paths
    inreplace "redis.conf" do |s|
      s.gsub! "/var/run/redis.pid", "#{var}/run/redis.pid"
      s.gsub! "dir ./", "dir #{var}/db/redis/"
      s.gsub! "\# bind 127.0.0.1", "bind 127.0.0.1"
    end

    # Fix redis upgrade from 2.4 to 2.6.
    if File.exists?(etc/'redis.conf') && !File.readlines(etc/'redis.conf').grep(/^vm-enabled/).empty?
      mv etc/'redis.conf', etc/'redis.conf.old'
      ohai "Your redis.conf will not work with 2.6; moved it to redis.conf.old"
    end

    etc.install 'redis.conf' unless (etc/'redis.conf').exist?
  end

  test do
    system "#{bin}/redis-server", "--test-memory", "2"
  end
end

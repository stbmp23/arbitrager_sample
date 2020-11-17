# frozen_string_literal: true

require_relative '../config/boot'

Dotenv.load(
  File.expand_path("../../.env.#{ENV['ENVIRONMENT']}", __FILE__),
  File.expand_path("../../.env",  __FILE__)
)

raise "Please set APP_PASSWORD" unless ENV['APP_PASSWORD']
raise "Please set OPENSSL_KEY" unless ENV['OPENSSL_KEY']
raise "Please set OPENSSL_IV" unless ENV['OPENSSL_IV']
raise "Please set OPENSSL_TYPE" unless ENV['OPENSSL_TYPE']

print "Password: "
password = STDIN.noecho(&:gets)
puts ""

Arbitrager.configure(password.chomp!)

# 暗号化するデータを入力
print 'Enter encrypt text: '
data = STDIN.noecho(&:gets)
data.chomp!

if data == ''
  puts "\n\nError! Please input text.\nExit."
  exit
end

# 暗号化
enc = OpenSSL::Cipher.new(ENV['OPENSSL_TYPE'])
enc.encrypt
enc.key = password + ENV['OPENSSL_KEY']
enc.iv = ENV['OPENSSL_IV']
encrypted_data = enc.update(data) + enc.final

enc = encrypted_data.unpack("H*")

puts "\n"
puts enc[0]

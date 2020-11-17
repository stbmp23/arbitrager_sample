# frozen_string_literal: true

require 'bcrypt'
require 'io/console'

print 'Enter: '
text = STDIN.noecho(&:gets)
text.chomp!
puts ""

raise "Error! Please input text." if text == ''

puts BCrypt::Password.create(text)

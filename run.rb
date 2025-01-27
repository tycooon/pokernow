require "csv"

# Usage: ruby run.rb /path/to/file.csv AaBbb6Cccd=username1 xxYyyy2341=username2

Result = Struct.new(:id, :net, :nicknames, :payouts)
Payout = Struct.new(:target_id, :amount)

path = ARGV.shift or abort "No file path provided"

aliases = {}

ARGV.each do |arg|
  match = arg.match(/\A(\S{10})=(\S+)\z/) or abort "Invalid alias: #{arg.inspect}"
  aliases[match[1]] = match[2]
end

results = {}

CSV.foreach(path, headers: true) do |row|
  id = row.fetch("player_id")
  net = row.fetch("net").to_f
  nickname = row.fetch("player_nickname")

  if aliaz = aliases[id]
    id = nickname = aliaz
  end

  result = results[id] || Result.new(id, 0, [], [])
  result.nicknames = [*result.nicknames, nickname].sort.uniq
  result.net += net
  next if net.zero?
  results[id] = result
end

winners, losers = results.values.partition { |x| x.net.positive? }

loop do
  loser = losers.sort_by(&:net).first
  break if loser.net.zero?

  winner = winners.sort_by(&:net).last
  amount = [loser.net.abs, winner.net].min
  payout = Payout.new(winner.id, amount)

  winner.net -= amount
  loser.net += amount
  loser.payouts << payout
end

show_user = -> (user) do
  user.nicknames.first
end

abort "Invalid results" if results.values.find { |x| !x.net.zero? }

losers.sort_by { |x| -x.payouts.sum(&:amount) }.each do |loser|
  payouts = loser.payouts.map do |payout|
    target = results.fetch(payout.target_id)
    "#{payout.amount} -> #{show_user.call(target)}"
  end

  puts "#{show_user.call(loser)}: #{payouts.join(", ")}"
end

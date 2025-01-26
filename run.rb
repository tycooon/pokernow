require "csv"

Result = Struct.new(:id, :net, :nicknames, :payouts)
Payout = Struct.new(:target_id, :amount)

path = ARGV.shift or abort "No file path provided"

results = {}

CSV.foreach(path, headers: true) do |row|
  id = row.fetch("player_id")
  net = row.fetch("net").to_f
  nickname = row.fetch("player_nickname")
  result = results[id] || Result.new(id, 0, [], [])
  result.nicknames = [*result.nicknames, nickname].sort.uniq
  result.net += net
  next if net.zero?
  results[id] = result
end

winners, losers = results.values.partition { |x| x.net.positive? }

losers.sort_by(&:net).each do |loser|
  until loser.net.zero? do
    winner = winners.sort_by(&:net).last
    break if winner.net.zero?
    amount = [loser.net.abs, winner.net].min
    next if amount.zero?
    payout = Payout.new(winner.id, amount)
    winner.net -= amount
    loser.net += amount
    loser.payouts << payout
  end
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

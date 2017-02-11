require "json"
require "date"

# your code

hash    = JSON.parse(File.new("data.json").read)

cars    = hash.fetch("cars")
rentals = hash.fetch("rentals")

incomes_per_car = rentals.map do |rental|
  car              = cars.select { |c| c["id"] = rental["car_id"] }.first

  start_date       = Date.parse(rental["start_date"])
  end_date         = Date.parse(rental["end_date"])
  duration_in_days = (end_date - start_date).to_i + 1

  distance = rental["distance"]

  price_per_km  = car["price_per_km"]
  price_per_day = car["price_per_day"]

  price = (duration_in_days * price_per_day) + (distance * price_per_km)

  { id: rental["id"], price: price }
end

File.open("incomes.json", "w") do |f|
  json = {rentals: incomes_per_car}
  f.write(JSON.pretty_generate(json))
end

require "json"
require "date"
require "ostruct"

#
# Level 1 JEE style
#

Car = Struct.new(:id, :price_per_km, :price_per_day)

Rental = Struct.new(:id, :car_id, :start_date, :end_date, :distance) do

  def duration_in_days
    (end_date - start_date).to_i + 1
  end

  def total_cost(car)
    (car.price_per_km * distance) + (car.price_per_day * duration_in_days)
  end

end

class CarRepository

  def initialize(file)
    json  = JSON.parse(File.new(file).read, symbolize_names: true)
    @cars = json.fetch(:cars).map { |hash| create_car(hash) }
  end

  def all
    @cars
  end

  def find(id)
    @cars.select { |car| car.id == id }.first
  end

  private

  def create_car(hash)
    Car.new(hash[:id],
            hash[:price_per_km],
            hash[:price_per_day])
  end

end

class DateParser

  def self.parse_date(date)
    Date.parse(date)
  end

end

class RentalRepository

  def initialize(file)
    json     = JSON.parse(File.new(file).read, symbolize_names: true)
    @rentals = json.fetch(:rentals).map { |hash| create_rental(hash) }
  end

  def all
    @rentals
  end

  def find(id)
    @rentals.select { |rental| rental.id == id }.first
  end

  private

  def create_rental(hash)
    Rental.new(hash[:id],
               hash[:car_id],
               DateParser.parse_date(hash[:start_date]),
               DateParser.parse_date(hash[:end_date]),
               hash[:distance])
  end

end

rental_repo = RentalRepository.new("data.json")
car_repo = CarRepository.new("data.json")

rentals = rental_repo.all.map do |rental|
  car         = car_repo.find(rental.car_id)
  total_price = rental.total_cost(car)

  { id: rental.id, price: total_price }
end

puts rentals.inspect

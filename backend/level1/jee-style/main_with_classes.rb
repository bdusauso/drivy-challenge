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

TotalPricePresenter = Struct.new(:rental_id, :total_price) do

  def as_json(opts = {})
    {
      id:          rental_id,
      total_price: total_price
    }
  end

end

RentalsCollection = Struct.new(:rentals) do

  def as_json(opts = {})
    {
      "rentals": rentals.map { |rental| rental.as_json }
    }
  end

end

class RentalService

  def initialize(rental_repository, car_repository)
    @rental_repo = rental_repository
    @car_repo    = car_repository
  end

  def total_prices
    @rental_repo.all.map do |rental|
      car         = @car_repo.find(rental.car_id)
      total_price = rental.total_cost(car)

      TotalPricePresenter.new(rental.id, total_price)
    end
  end

end

datasource     = "data.json"
rental_repo    = RentalRepository.new(datasource)
car_repo       = CarRepository.new(datasource)
rental_service = RentalService.new(rental_repo, car_repo)

puts JSON.pretty_generate(RentalsCollection.new(rental_service.total_prices).as_json)

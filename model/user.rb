class User < Sequel::Model
  plugin :validation_helpers
  plugin :composition

  one_to_many :partner, :key => :peer, :class => self

  def validate
    validates_unique(:email)
    validates_presence [:name, :surname, :address1, :zip, :city, 
                        :email, :password, :gender, :birthdate, :event ]
    validates_exact_length 5, :zip
  end
end

class Inscriptions < Controller
  layout :main
  helper :blue_form

  def new
    @title = 'Inscriptions'
    @form_data = {}
    @missing = {}

    Ramaze::Log.info("== Before case #{request.params['attendee']} ==")

    case request.params['attended']
    when "1"
      Ramaze::Log.info("== Attended 1 ==")
      # Copy requests in form_data
      Ramaze::Log.info("type #{request.params.class}")
      
      p request.params
      @form_data.merge(request.params)
      @form_data.inspect
      p @form_data
      # Check missing fields
      [ 'name', 'surname', 'address1', :zip, :city,
        :gender, :ddn_day, :ddn_month, :ddn_year, 
        :email, :event ].each do |e|
          if @form_data[e] == ""
            @missing[e] = :error 
            Ramaze::Log.info("missing #{e}")
          end
        end
      return if @missing.size > 0

      # Change stage
      @form_data['attendee'] == 2

    else
      @form_data['attendee'] = 1
    end
    @subtitle = 'S\'inscrire'
  end
end

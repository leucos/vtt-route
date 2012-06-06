# encoding: UTF-8
#

class Profiles < Controller
  helper :form_helper, :user

  FIELD_NAMES = { :name  => "Nom",
                  :surname => "Prénom",
                  :gender  => "Sexe",
                  :address1 => "Adresse",
                  :address2 => "Complément d'adresse",
                  :zip => "Code Postal",
                  :city => "Ville",
                  :country => "Pays",
                  :phone => "Téléphone",
                  :org => "Club ou entreprise", 
                  :birth => "Date de naissance", 
                  :licence => "Numéro de licence",
                  :federation => "Fédération",
                  :event => "Epreuve",
                  :emergency_contact => "Personne à contacter en cas d'urgence",
                  :accept => "Acceptation du règlement" }

  before_all do
    redirect_referrer unless logged_in?
  end

  def index
    @title = 'Espace participants'
    @subtitle = 'Profil'
    
    # Quite ugly, but we don't want to use 'if's in view
    if user.profile
      FIELD_NAMES.each_key do |f|
        data_for( f.to_s, user.profile[f] )
      end
      
      dte = user.profile.birth
      ['day','month','year'].each { |t| data_for("dob-#{t}", dte.send(t)) }
    end

  end

  def save
    data = request.subset(:name, :surname, :gender,
                          :address1, :address2, :zip, :city, :country,
                          :phone, :org, :licence, :event, :federation,
                          :emergency_contact)

    if user.profile
      # This is an update
      prof = Profile[:user_id => user.id]

      if prof.nil?
        flash[:error] = 'Profil invalide'

        redirect_referrer
      end

      operation = :update
    else
      prof = Profile.new
      operation = :create
    end

    # Now let's update the User instance
    # Since many things can fail, we enclose this in a rescue block
    begin
      date_str = "%s-%s-%s" % [ request.params['dob-year'],
                                request.params['dob-month'],
                                request.params['dob-day'] ]
      data[:birth] = Date.parse(date_str)
    rescue
      # Let Sequel handle this and report back
      data[:birth] = nil
    end

    begin
      prof.raise_on_typecast_failure = false
      Ramaze::Log.info(data.inspect)
      prof.update(data)

    rescue Sequel::ValidationFailed => e
      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        error_for i[0], "%s : %s" % [ FIELD_NAMES[i[0]], i[1][0] ]
      end
    end

    if !request.params['accept'] and operation == :create
      Ramaze::Log.info("Accept not checked")
      error_for :accept, "Vous n'avez pas coché la case d'acceptation du règlement" 
    end

    if has_errors?
      # An error occured, so let's save form data
      # so the user doesn't have to retype everything
      #flash[:form_data] = data
      ['dob-day', 'dob-month', 'dob-year'].each do |d|
        data_for d, request.params[d]
      end

      bulk_data data
      prepare_flash
      redirect_referrer
    end

    user.profile = prof
    user.save

    #user.profile = prof

    flash[:success] = 'Profil mis à jour'
    @title = 'Profil'

    redirect Profiles.r(:index)
  end

  def confirm(key)
    u = User[:confirmation_key => key]

    if u.nil?
      @subtitle = 'Compte inexistant'
      redirect(self.r(:index))
    else
      u.confirmed = true
      u.save
      @subtitle = 'Votre compte est validé'
      render_view(:welcome)
    end
  end

  private

end

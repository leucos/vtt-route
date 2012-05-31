# encoding: UTF-8
#

class Profiles < Controller
  layout :main
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
                  :event => "Epreuve" }

  before_all do
    Ramaze::Log.info("Mmmh, this guy doesn't seem to be logged in")
    redirect_referrer unless logged_in?
    #u = user
    #i = u.inspect
    Ramaze::Log.info("Oh my bad, it is %s" % user.email)
    Ramaze::Log.info("class %s" % user.class)

    session[:logged_in] = true
  end

  def index
    @title = 'Espace participants'
    @subtitle = 'Profil'

#    flash[:form_data] ||= {}
#    flash[:error] = {}
    
    # Quite ugly, but we don't want to use 'if's in view
    if user.profile
      FIELD_NAMES.each_key do |f|
        #Ramaze::Log.info("adding key #{f} : #{user.profile[f]}")
        data_for( f.to_s, user.profile[f] )
      end
      
      dte = user.profile.birth
      ['day','month','year'].each { |t| data_for("dob-#{t}", dte.send(t)) }

    end

  end

  def save
    data = request.subset(:name, :surname, :gender,
                          :address1, :address2, :zip, :city, :country,
                          :phone, :org, :licence, :event, :federation)

    if user.profile
      # This is an update
      Ramaze::Log.info("trying to update user #{user.id}")
      prof = Profile[:user_id => user.id]

      # Ensure user tried to edit it's own data
      # If we get here, this means he's tinkering with the post data
      # THINK: Is this enough ? Can user tamper with session data ?
      #if user.id != session[:user_id]
      #  flash[:error] = 'Modification impossible'

      #  Ramaze::Log.warning('Form edit attempt : %s' % request.params) 
      #  redirect_referrer
      #end

      if prof.nil?
        flash[:error] = 'Profil invalide'

        redirect_referrer
      end

      #if !user.confirmed
      #  flash[:error] = 'Vous devez confirmer votre inscription avant'

      #  redirect_referrer
      #end

      operation = :update
    else
      Ramaze::Log.info("trying to create profile")
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
      prof.update(data)
    rescue Sequel::ValidationFailed => e

      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        Ramaze::Log.info("missing field #{i[0]}")
        error_for i[0], "%s : %s" % [ FIELD_NAMES[i[0]], i[1][0] ]
      end
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

    p prof.inspect
    p user.inspect

    user.profile = prof

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

  # Tries to update user and return an error array is something failed
  def update_user(user)

  end

end

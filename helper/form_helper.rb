module Ramaze
  module Helper
    module FormHelper


      # Returns class for field if present in flash[:form_errors]
      def class_for(field, klass = nil)
        if !klass.nil?
          flash[:form_errors] ||= {}
          flash[:form_errors][field] ||= {}
          flash[:form_errors][field][:class] = klass
        else
          flash[:form_errors][field][:class] if flash[:form_errors] && flash[:form_errors].key?(field)
        end
      end

      def message_for(field, message = nil)
        if !message.nil?
          flash[:form_errors] ||= {}
          flash[:form_errors][field] ||= {}
          flash[:form_errors][field][:message] = message
          class_for field, :error
        else
          flash[:form_errors][field][:message] if flash[:form_errors] && flash[:form_errors].key?(field)
        end
      end
      alias error_for message_for

      def data_for(field, data = nil)
        if !data.nil?
          flash[:form_data] ||= {}
          flash[:form_data][field] ||= {}
          flash[:form_data][field][:data] = data
          Ramaze::Log.info("Adding %s for %s" % [ data, field] )
        else
          flash[:form_data][field][:data] if flash[:form_data] && flash[:form_data].key?(field)
        end
      end

      def bulk_data(data)
        data.each_pair do |d,v|
          data_for d, v
        end 
      end

      def has_errors?
        !flash[:form_errors].nil?
      end

      def prepare_flash
        if has_errors?
          flash[:erreur] = "<p>Le formulaire contient des erreurs :\n<ul>"
          flash[:form_errors].each_pair { |f,m| flash[:erreur] << "<li>%s</li>" % message_for(f) }

          flash[:erreur] << "</ul></p>"
        end        
      end

    end
  end
end


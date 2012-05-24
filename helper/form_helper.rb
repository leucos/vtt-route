module Ramaze
  module Helper
    module FormHelper


      # Returns class for field if present in flash[:form_errors]
      def class_for(field)
        flash[:form_errors][field][:class] if flash[:form_errors] && flash[:form_errors].key?(field)
      end

      def class_for(field, klass)
        flash[:form_errors] ||= {}
        flash[:form_errors][field] ||= {}
        flash[:form_errors][field][:class] = klass
      end

      def message_for(field)
        flash[:form_errors][field][:message] if flash[:form_errors] && flash[:form_errors].key?(field)
      end

      def message_for(field, message)
        flash[:form_errors] ||= {}
        flash[:form_errors][field] ||= {}
        flash[:form_errors][field][:message] = message
      end

      def data_for(field)
        flash[:form_data][field] if flash[:form_errors] && flash[:form_errors].key?(field)
      end

      def data_for(field, data)
        flash[:form_data] ||= {}
        flash[:form_data][field] ||= {}
        flash[:form_data][field][:data] = data
      end

    end
  end
end


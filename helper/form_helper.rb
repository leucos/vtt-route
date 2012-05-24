module Ramaze
  module Helper
    module FormHelper


      # Returns class for field if present in flash[:form_errors]
      def class_for(field)
        flash[:form_errors][field][:class] if flash[:form_errors].key?(field)
      end

      def message_for(field)
        flash[:form_errors][field][:message] if flash[:form_errors].key?(field)
      end

      def data_for(field)
        flash[:form_data][field] flash[:form_data].key?(field)
      end

    end
  end
end


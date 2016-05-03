module Twine
  module Placeholders
    extend self

    # Note: the ` ` (single space) flag is NOT supported
    PLACEHOLDER_FLAGS_WIDTH_PRECISION_LENGTH = '([-+0#])?(\d+|\*)?(\.(\d+|\*))?(hh?|ll?|L|z|j|t)?'
    PLACEHOLDER_PARAMETER_FLAGS_WIDTH_PRECISION_LENGTH = '(\d+\$)?' + PLACEHOLDER_FLAGS_WIDTH_PRECISION_LENGTH
    PLACEHOLDER_TYPES = '[diufFeEgGxXoscpaA]'

    def convert_string_placeholder_from_twine_to_printf(input)
      # %@ -> %s
      input.gsub(/(%#{PLACEHOLDER_PARAMETER_FLAGS_WIDTH_PRECISION_LENGTH})@/, '\1s')
    end

    def convert_string_placeholder_from_printf_to_twine(input)
      placeholder_regex = /(%#{PLACEHOLDER_PARAMETER_FLAGS_WIDTH_PRECISION_LENGTH})s/

      # %s -> %@
      input.gsub(placeholder_regex, '\1@')
    end

    # http://developer.android.com/guide/topics/resources/string-resource.html#FormattingAndStyling
    # http://stackoverflow.com/questions/4414389/android-xml-percent-symbol
    # https://github.com/mobiata/twine/pull/106
    def convert_placeholders_from_twine_to_android(input)
      value = convert_string_placeholder_from_twine_to_printf input

      placeholder_syntax = PLACEHOLDER_PARAMETER_FLAGS_WIDTH_PRECISION_LENGTH + PLACEHOLDER_TYPES
      placeholder_regex = /%#{placeholder_syntax}/

      number_of_placeholders = value.scan(placeholder_regex).size

      return value if number_of_placeholders == 0

      # got placeholders -> need to double single percent signs
      # % -> %% (but %% -> %%, %d -> %d)
      single_percent_regex = /([^%])(%)(?!(%|#{placeholder_syntax}))/
      value.gsub! single_percent_regex, '\1%%'

      return value if number_of_placeholders < 2

      # number placeholders
      non_numbered_placeholder_regex = /%(#{PLACEHOLDER_FLAGS_WIDTH_PRECISION_LENGTH}#{PLACEHOLDER_TYPES})/

      number_of_non_numbered_placeholders = value.scan(non_numbered_placeholder_regex).size

      return value if number_of_non_numbered_placeholders == 0

      raise Twine::Error.new("The value \"#{input}\" contains numbered and non-numbered placeholders") if number_of_placeholders != number_of_non_numbered_placeholders

      # %d -> %$1d
      index = 0
      value.gsub!(non_numbered_placeholder_regex) { "%#{index += 1}$#{$1}" }

      value
    end

    def convert_placeholders_from_android_to_twine(input)
      convert_string_placeholder_from_printf_to_twine input
    end

    # http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/mx/resources/IResourceManager.html#getString()
    # http://soenkerohde.com/2008/07/flex-localization/comment-page-1/
    def convert_placeholders_from_twine_to_flash(input)
      value = convert_string_placeholder_from_twine_to_printf(input)

      placeholder_regex = /%#{PLACEHOLDER_PARAMETER_FLAGS_WIDTH_PRECISION_LENGTH}#{PLACEHOLDER_TYPES}/
      value.gsub(placeholder_regex).each_with_index do |match, index|
        "{#{index}}"
      end
    end

    def convert_placeholders_from_flash_to_twine(input)
      input.gsub /\{\d+\}/, '%@'
    end
  end
end

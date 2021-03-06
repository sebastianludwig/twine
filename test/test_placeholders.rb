require 'twine_test'

class PlaceholderTest < TwineTest
  def assert_starts_with(prefix, value)
    msg = message(nil) { "Expected #{mu_pp(value)} to start with #{mu_pp(prefix)}" }
    assert value.start_with?(prefix), msg
  end

  def placeholder(type = nil)
    # %[parameter][flags][width][.precision][length]type (see https://en.wikipedia.org/wiki/Printf_format_string#Format_placeholder_specification)
    lucky = lambda { rand > 0.5 }
    placeholder = '%'
    placeholder += (rand * 20).to_i.to_s + '$' if lucky.call
    placeholder += '-+0#'.chars.to_a.sample if lucky.call
    placeholder += (0.upto(20).map(&:to_s) << "*").sample if lucky.call
    placeholder += '.' + (0.upto(20).map(&:to_s) << "*").sample if lucky.call
    placeholder += %w(h hh l ll L z j t).sample if lucky.call
    placeholder += type || 'diufFeEgGxXocpaA'.chars.to_a.sample # this does not contain s or @ because strings are a special case
  end

  class ToAndroid < PlaceholderTest
    def to_android(value)
      Twine::Placeholders.convert_placeholders_from_twine_to_android(value)
    end

    def test_replaces_simple_string_placeholder
      assert_equal "some '%s' value", to_android("some '%@' value")
    end

    def test_replaces_complicated_string_placeholder
      placeholder = placeholder('@')
      expected = placeholder.dup
      expected[-1] = 's'
      assert_equal "some #{expected} value", to_android("some #{placeholder} value")
    end

    def test_does_not_change_regular_at_signs
      input = "some @ more @@ signs @"
      assert_equal input, to_android(input)
    end

    def test_does_not_modify_single_percent_signs
      assert_equal "some % value", to_android("some % value")
    end

    def test_does_not_modify_single_percent_signs_when_followed_by_space_and_format_letter
      # Said differently: formartter parser should not recognize %a in "70% and"
      assert_equal 'If 70% and 30% dog 80% end', to_android('If 70% and 30% dog 80% end')
    end

    def test_escapes_single_percent_signs_if_placeholder_present
      assert_starts_with "some %% v", to_android("some % value #{placeholder}")
    end

    def test_does_not_modify_double_percent_signs
      assert_equal "some %% value", to_android("some %% value")
    end

    def test_does_not_modify_double_percent_signs_if_placeholder_present
      assert_starts_with "some %% v", to_android("some %% value #{placeholder}")
    end

    def test_does_not_modify_single_placeholder
      input = "some #{placeholder} text"
      assert_equal input, to_android(input)
    end

    def test_numbers_multiple_placeholders
      assert_equal "first %1$d second %2$f", to_android("first %d second %f")
    end

    def test_does_not_modify_numbered_placeholders
      input = "second %2$f first %1$d"
      assert_equal input, to_android(input)
    end

    def test_raises_an_error_when_mixing_numbered_and_non_numbered_placeholders
      assert_raises Twine::Error do
        to_android("some %d second %2$f")
      end
    end

    def test_complicated_float_placeholders
      assert_equal "%1$.0f%2$s (apparent: %3$.0f)", to_android("%.0f%@ (apparent: %.0f)")
    end
  end

  class FromAndroid < PlaceholderTest
    def from_android(value)
      Twine::Placeholders.convert_placeholders_from_android_to_twine(value)
    end

    def test_replaces_string_placeholder
      assert_equal "some %@ value", from_android("some %s value")
    end
  end

  class ToFlash < PlaceholderTest
    def to_flash(value)
      Twine::Placeholders.convert_placeholders_from_twine_to_flash(value)
    end

    def test_replaces_placeholder
      assert_equal "some {0} text", to_flash("some #{placeholder} text")
    end

    def test_replaces_string_placeholder
      assert_equal "some {0} text", to_flash("some #{placeholder('@')} text")
    end

    def test_numbers_placeholders
      assert_equal "some {0} more {1} text {2}", to_flash("some #{placeholder('@')} more #{placeholder('@')} text #{placeholder('@')}")
    end
  end

  class FromFlash < PlaceholderTest
    def from_flash(value)
      Twine::Placeholders.convert_placeholders_from_flash_to_twine(value)
    end

    def test_maps_all_placeholders_to_string
      assert_equal "some %@ more %@ text %@", from_flash("some {0} more {1} text {2}")
    end
  end
end

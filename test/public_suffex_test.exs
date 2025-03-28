defmodule PublicSufx.PublicSufxTest do
  use ExUnit.Case
  import PublicSufx
  doctest PublicSufx

  test_cases_prevailing_private = [
    {"exact match", "foo.github.io", "github.io"},
    {"wildcard", "foo.bar.elb.amazonaws.com", "*.elb.amazonaws.com"}
  ]

  for {rule_type, input, expected} <-
        test_cases_prevailing_private do
    @input input
    @expected expected

    test "`prevailing_rule` (#{rule_type})" do
      assert prevailing_rule(@input) == @expected
    end
  end

  test_cases_prevailing = [
    {"leading dot", ".com", nil},
    {"unlisted TLD", "example", "*"},
    {"unlisted TLD", "example.example", "*"},
    {"TLD with only 1 rule", "biz", "biz"},
    {"TLD with only 1 rule", "domain.biz", "biz"},
    {"TLD with some 2-level rules", "uk.com", "uk.com"},
    {"TLD with some 2-level rules", "example.uk.com", "uk.com"},
    {"TLD with only 1 (wildcard) rule", "mm", "*"},
    {"TLD with only 1 (wildcard) rule", "c.mm", "*.mm"},
    {"TLD with only 1 (wildcard) rule", "b.c.mm", "*.mm"},
    {"more complex TLD", "kyoto.jp", "kyoto.jp"},
    {"more complex TLD", "test.kyoto.jp", "kyoto.jp"},
    {"more complex TLD", "ide.kyoto.jp", "ide.kyoto.jp"},
    {"more complex TLD", "b.ide.kyoto.jp", "ide.kyoto.jp"},
    {"more complex TLD", "a.b.ide.kyoto.jp", "ide.kyoto.jp"},
    {"more complex TLD", "c.kobe.jp", "*.kobe.jp"},
    {"more complex TLD", "b.c.kobe.jp", "*.kobe.jp"},
    {"more complex TLD", "city.kobe.jp", "!city.kobe.jp"},
    {"more complex TLD", "www.city.kobe.jp", "!city.kobe.jp"},
    {"TLD with a wildcard rule and exceptions", "ck", "*"},
    {"TLD with a wildcard rule and exceptions", "test.ck", "*.ck"},
    {"TLD with a wildcard rule and exceptions", "b.test.ck", "*.ck"},
    {"TLD with a wildcard rule and exceptions", "www.ck", "!www.ck"},
    {"TLD with a wildcard rule and exceptions", "www.www.ck", "!www.ck"}
  ]

  for {rule_type, input, expected_output} <- test_cases_prevailing do
    @input input
    @expected_output expected_output

    test "`prevailing_rule` returns `#{to_string(expected_output)}` if passed `#{input}` (#{rule_type})" do
      assert prevailing_rule(@input) == @expected_output
    end
  end

  test "unicode domains are correctly NFKC normalized when punycoding them" do
    # Both of these strings are different unicode forms of "ábc.co.uk".
    # The example came from:
    # ftp://ftp.unicode.org/Public/UNIDATA/NormalizationTest.txt
    # (see LATIN SMALL LETTER A WITH ACUTE)
    normalized_form = "\u00E1bc.co.uk"
    alternate_form = "\u0061\u0301bc.co.uk"

    assert alternate_form != normalized_form
    assert roundtrip_through_punycoding(alternate_form) == normalized_form
    assert roundtrip_through_punycoding(normalized_form) == normalized_form
  end

  defp roundtrip_through_punycoding(domain) do
    domain
    |> PublicSufx.RulesParser.punycode_domain()
    |> to_charlist()
    |> :idna.decode(uts46: true)
    |> to_string()
  end
end

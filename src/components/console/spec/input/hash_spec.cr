require "../spec_helper"

struct HashTest < ASPEC::TestCase
  def test_first_argument : Nil
    ACON::Input::Hash.new.first_argument.should be_nil
    ACON::Input::Hash.new(name: "George").first_argument.should eq "George"
    ACON::Input::Hash.new("--foo": "bar", name: "George").first_argument.should eq "George"
  end

  def test_has_parameter : Nil
    input = ACON::Input::Hash.new(name: "George", "--foo": "bar")
    input.has_parameter?("--foo").should be_true
    input.has_parameter?("--bar").should be_false

    ACON::Input::Hash.new("--foo").has_parameter?("--foo").should be_true

    input = ACON::Input::Hash.new "--foo", "--", "--bar"
    input.has_parameter?("--bar").should be_true
    input.has_parameter?("--bar", only_params: true).should be_false
  end

  def test_get_parameter : Nil
    input = ACON::Input::Hash.new(name: "George", "--foo": "bar")
    input.parameter("--foo").should eq "bar"
    input.parameter("--bar", "default").should eq "default"

    ACON::Input::Hash.new("George": nil, "--foo": "bar").parameter("--foo").should eq "bar"

    input = ACON::Input::Hash.new("--foo": nil, "--": nil, "--bar": "baz")
    input.parameter("--bar").should eq "baz"
    input.parameter("--bar", "default", true).should eq "default"
  end

  def test_parse_arguments : Nil
    input = ACON::Input::Hash.new(
      {"name" => "foo"},
      ACON::Input::Definition.new ACON::Input::Argument.new "name"
    )

    input.arguments.should eq({"name" => "foo"})
  end

  @[DataProvider("option_provider")]
  def test_parse_options(args : Hash(String, _), options : Array(ACON::Input::Option), expected_options : ::Hash) : Nil
    input = ACON::Input::Hash.new args, ACON::Input::Definition.new options

    input.options.should eq expected_options
  end

  def option_provider : Hash
    {
      "long option" => {
        {
          "--foo" => "bar",
        },
        [ACON::Input::Option.new("foo")],
        {"foo" => "bar"},
      },
      "long option with default" => {
        {
          "--foo" => "bar",
        },
        [ACON::Input::Option.new("foo", "f", :optional, "", "default")],
        {"foo" => "bar"},
      },
      "uses default value if not passed" => {
        Hash(String, String).new,
        [ACON::Input::Option.new("foo", "f", :optional, "", "default")],
        {"foo" => "default"},
      },
      "uses passed value even with default" => {
        {"--foo" => nil},
        [ACON::Input::Option.new("foo", "f", :optional, "", "default")],
        {"foo" => nil},
      },
      "short option" => {
        {"-f" => "bar"},
        [ACON::Input::Option.new("foo", "f", :optional, "", "default")],
        {"foo" => "bar"},
      },
      "does not parse args after --" => {
        {"--" => nil, "-f" => "bar"},
        [ACON::Input::Option.new("foo", "f", :optional, "", "default")],
        {"foo" => "default"},
      },
      "handles only --" => {
        {"--" => nil},
        Array(ACON::Input::Option).new,
        Hash(String, String).new,
      },
    }
  end

  @[DataProvider("invalid_input_provider")]
  def test_parse_invalid_input(args : Hash(String, _), definition : ACON::Input::Definition, error_class : Exception.class, error_message : String) : Nil
    expect_raises error_class, error_message do
      ACON::Input::Hash.new args, definition
    end
  end

  def invalid_input_provider : Tuple
    {
      {
        {"foo" => "foo"},
        ACON::Input::Definition.new(ACON::Input::Argument.new("name")),
        ACON::Exceptions::InvalidArgument,
        "The 'foo' argument does not exist.",
      },
      {
        {"--foo" => nil},
        ACON::Input::Definition.new(ACON::Input::Option.new("foo", "f", :required)),
        ACON::Exceptions::InvalidOption,
        "The '--foo' option requires a value.",
      },
      {
        {"--foo" => "foo"},
        ACON::Input::Definition.new,
        ACON::Exceptions::InvalidOption,
        "The '--foo' option does not exist.",
      },
      {
        {"-o" => "foo"},
        ACON::Input::Definition.new,
        ACON::Exceptions::InvalidOption,
        "The '-o' option does not exist.",
      },
    }
  end
end

require "../spec_helper"

class CompileController < ATH::Controller
  @[ATHA::Get(path: "/")]
  @[ATHA::QueryParam("all", converter: "foo")]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run

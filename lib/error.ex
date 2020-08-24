defmodule Gem.APIError do
  defstruct(
    code: "ERR_INTERNAL_SERVER",
    description: "An unknown error occurred.",
    status: 500
  )
end

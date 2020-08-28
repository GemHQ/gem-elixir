defmodule Gem.APIError do
  defstruct(
    error: "ERR_INTERNAL_SERVER",
    description: "An unknown error occurred.",
    status: 500,
    error_map: nil
  )
end

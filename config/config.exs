import Config

config :gem_ex,
  api_key: System.get_env("GEM_API_KEY"),
  secret: System.get_env("GEM_SECRET"),
  base_url: System.get_env("GEM_BASE_URL") || "https://api.gem.co"

config :mojito,
  timeout: System.get_env("GEM_TIMEOUT") || 60_000

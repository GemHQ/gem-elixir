defmodule Gem.Client do
  @moduledoc """
  Documentation for `Gem Client`.
  """

  def get(path \\ "/", query_parameters \\ %{}) do
    url = encode_query_params(path, query_parameters)
    headers = build_request_headers()

    Mojito.request(method: :get, url: url, headers: headers)
    |> process_response()
  end

  def post(path \\ "/", body \\ %{}, query_parameters \\ %{}, opts \\ []) do
    mutate(:post, path, body, query_parameters, opts)
  end

  def put(path \\ "/", body \\ %{}, query_parameters \\ %{}) do
    mutate(:put, path, body, query_parameters)
  end

  def delete(path \\ "/", body \\ %{}, query_parameters \\ %{}) do
    mutate(:delete, path, body, query_parameters)
  end

  defp mutate(method, path \\ "/", body \\ %{}, query_parameters \\ %{}, opts \\ []) do
    is_multipart? = Keyword.get(opts, :is_multipart?, false)
    headers = Keyword.get(opts, :headers, [])
    content_type = if is_multipart?, do: "multipart/form-data", else: "application/json"
    url = encode_query_params(path, query_parameters)

    content_type_headers =
      if is_content_type_set?(headers), do: [], else: [{"Content-Type", content_type}]

    headers = build_request_headers() ++ headers ++ content_type_headers
    body = if is_multipart?, do: body, else: Jason.encode!(body)

    Mojito.request(method: method, url: url, headers: headers, body: body)
    |> process_response()
  end

  defp get_config do
    Application.get_all_env(:gem)
  end

  defp process_response(response) do
    case response do
      {:ok, res = %Mojito.Response{status_code: status}} when status in 200..300 ->
        body = Jason.decode!(res.body)
        {:ok, body}

      {:ok, res = %Mojito.Response{status_code: status}} when status >= 400 ->
        body = Jason.decode!(res.body)
        e = %Gem.APIError{}
        error = Map.get(body, "error", e.error)
        error_map = Map.get(body, "error_map")
        description = Map.get(body, "description", e.description)

        {:error,
         %{e | error: error, description: description, status: status, error_map: error_map}}

      e ->
        {:error, %Gem.APIError{}, e}
    end
  end

  defp build_request_headers(_req_config \\ []) do
    config = get_config()
    api_key = Keyword.get(config, :api_key)
    timestamp = get_timestamp()
    signature = create_signature(timestamp)

    [
      {"X-Gem-Access-Timestamp", timestamp},
      {"X-Gem-Signature", signature},
      {"X-Gem-Api-Key", api_key}
    ]
  end

  defp encode_query_params(path \\ "/", query \\ nil) do
    parsed_path =
      URI.parse(path)
      |> Map.get(:path)

    base =
      get_config()
      |> Keyword.get(:base_url)
      |> URI.parse()
      |> Map.put(:path, parsed_path)

    if is_map(query) do
      Map.put(base, :query, URI.encode_query(query))
      |> URI.to_string()
    else
      URI.to_string(base)
    end
  end

  defp get_timestamp do
    DateTime.utc_now()
    |> DateTime.to_unix()
  end

  defp create_signature(timestamp) do
    config = get_config()
    secret = Keyword.get(config, :secret)
    api_key = Keyword.get(config, :api_key)
    data = "#{api_key}:#{timestamp}"

    :crypto.hmac(:sha256, secret, data)
    |> Base.encode16(case: :lower)
  end

  defp is_content_type_set?(headers \\ []) do
    is_header_set? =
      Enum.find(headers, fn h ->
        case h do
          {"content-type", _ct} ->
            true

          {"Content-Type", _ct} ->
            true

          _ ->
            false
        end
      end)
  end
end

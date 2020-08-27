defmodule Gem do
  @paths %{
    users: "/users",
    institution_users: "/institution_users",
    accounts: "/accounts",
    profiles: "/profiles",
    application_configurations: "/application_configs"
  }

  def list_users(opts \\ []) do
    page_size = Keyword.get(opts, :page_size, 25)
    page_number = Keyword.get(opts, :page_number, 1)
    Gem.Client.get(@paths.users, %{size: page_size, page: page_number})
  end

  def get_user(opts \\ []) do
    user_id = Keyword.get(opts, :id)
    Gem.Client.get("#{@paths.users}/#{user_id}")
  end

  def create_user(opts \\ []) do
    email_address = Keyword.get(opts, :email_address)
    Gem.Client.post(@paths.users, %{email: email_address})
  end

  def update_user(opts \\ []) do
    user_id = Keyword.get(opts, :id)
    phone_number = Keyword.get(opts, :phone_number)

    Gem.Client.put("#{@paths.users}/#{user_id}", %{
      phone_number: phone_number
    })
  end

  def send_user_sms_otp(opts \\ []) do
    user_id = Keyword.get(opts, :id)
    Gem.Client.post("#{@paths.users}/#{user_id}/send_sms", %{})
  end

  def verify_user_sms_otp(opts \\ []) do
    user_id = Keyword.get(opts, :id)
    otp = Keyword.get(opts, :otp)
    Gem.Client.post("#{@paths.users}/#{user_id}/verify_sms", %{otp_code: otp})
  end

  def list_institution_users(opts \\ []) do
    user_id = Keyword.get(opts, :user_id)
    Gem.Client.get(@paths.institution_users, %{user_id: user_id})
  end

  def get_institution_user(opts \\ []) do
    institution_user_id = Keyword.get(opts, :id)
    Gem.Client.get("#{@paths.institution_users}/#{institution_user_id}")
  end

  def list_accounts(opts \\ []) do
    user_id = Keyword.get(opts, :user_id)
    connection_id = Keyword.get(opts, :connection_id)
    query = %{connection_id: connection_id}
    query = if is_nil(user_id), do: query, else: Map.put(query, :user_id, user_id)
    Gem.Client.get(@paths.accounts, query)
  end

  def get_account(opts \\ []) do
    account_id = Keyword.get(opts, :id)
    Gem.Client.get("#{@paths.accounts}/#{account_id}")
  end

  def list_profiles(opts \\ []) do
    user_id = Keyword.get(opts, :user_id)
    Gem.Client.get(@paths.profiles, %{user_id: user_id})
  end

  def get_profile(opts \\ []) do
    profile_id = Keyword.get(opts, :id)
    Gem.Client.get("#{@paths.profiles}/#{profile_id}")
  end

  def list_application_configurations(opts \\ []) do
    Gem.Client.get(@paths.application_configurations)
  end

  def create_profile_document(document, opts \\ []) do
    profile_id = Keyword.get(opts, :profile_id)
    files = document["files"]
    doc_type = document["type"]
    doc_description = document["description"]

    builder =
      Gem.Multipart.new()
      |> Gem.Multipart.add_field("type", doc_type)
      |> Gem.Multipart.add_field("description", doc_description)

    builder =
      Enum.reduce(files, builder, fn file, acc ->
        %{
          "data" => data,
          "description" => description,
          "media_type" => media_type,
          "orientation" => orientation
        } = file

        acc
        |> Gem.Multipart.add_field("files[0][data]", data)
        |> Gem.Multipart.add_field("files[0][media_type]", media_type)
        |> Gem.Multipart.add_field("files[0][orientation]", orientation)
        |> Gem.Multipart.add_field("files[0][description]", description)
      end)

    body =
      builder
      |> Gem.Multipart.body()
      |> Enum.join("")

    headers =
      builder
      |> Gem.Multipart.headers()

    Gem.Client.post("#{@paths.profiles}/#{profile_id}/documents", body, nil,
      is_multipart?: true,
      headers: headers
    )
  end

end

shared_examples "config hash" do
  let(:config) do
    {
      parameters: {
        'highrise_api_token' => ENV["HIGHRISE_API_TOKEN"],
        'highrise_site_url' => ENV["HIGHRISE_SITE_URL"]
      }
    }.with_indifferent_access
  end
end

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

shared_examples "connect params" do
  before do
    Highrise::Base.site = ENV["HIGHRISE_SITE_URL"]
    Highrise::Base.user = ENV["HIGHRISE_API_TOKEN"]
  end
end

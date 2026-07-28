# Only the app's public, indexable pages — see config/routes.rb's comment
# on SeoController for why game show pages are excluded here.
xml.instruct! :xml, version: "1.0"
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc "#{request.base_url}#{root_path}"
    xml.changefreq "monthly"
    xml.priority "1.0"
  end
  xml.url do
    xml.loc "#{request.base_url}#{enter_path}"
    xml.changefreq "monthly"
    xml.priority "0.8"
  end
end

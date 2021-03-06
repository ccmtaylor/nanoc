module Nanoc::Helpers
  # Contains functionality for building XML sitemaps that will be crawled by
  # search engines. See the [Sitemaps protocol site](http://www.sitemaps.org)
  # for details.
  module XMLSitemap
    # Builds an XML sitemap and returns it.
    #
    # The following attributes can optionally be set on items to change the
    # behaviour of the sitemap:
    #
    # * `changefreq` — The estimated change frequency as defined by the
    #   Sitemaps protocol
    #
    # * `priority` — The item's priority, ranging from 0.0 to 1.0, as defined
    #   by the Sitemaps protocol
    #
    # The sitemap will also include dates on which the items were updated.
    # These are generated automatically; the way this happens depends on the
    # used data source (the filesystem data source checks the file mtimes, for
    # instance).
    #
    # The site configuration will need to have the following attributes:
    #
    # * `base_url` — The URL to the site, without trailing slash. For example,
    #   if the site is at "http://example.com/", the `base_url` would be
    #   "http://example.com".
    #
    # @example Excluding binary items from the sitemap
    #
    #   <%= xml_sitemap :items => @items.reject{ |i| i[:is_hidden] || i.binary? } %>
    #
    # @option params [Array] :items A list of items to include in the sitemap
    #
    # @option params [Proc] :rep_select A proc to filter reps through. If the
    #   proc returns true, the rep will be included; otherwise, it will not.
    #
    # @return [String] The XML sitemap
    def xml_sitemap(params = {})
      require 'builder'

      # Extract parameters
      items       = params.fetch(:items) { @items.reject { |i| i[:is_hidden] } }
      select_proc = params.fetch(:rep_select, nil)

      # Create builder
      buffer = ''
      xml = Builder::XmlMarkup.new(target: buffer, indent: 2)

      # Check for required attributes
      if @config[:base_url].nil?
        raise RuntimeError.new('The Nanoc::Helpers::XMLSitemap helper requires the site configuration to specify the base URL for the site.')
      end

      # Build sitemap
      xml.instruct!
      xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        # Add item
        items.sort_by(&:identifier).each do |item|
          reps = item.reps.reject { |r| r.raw_path.nil? }
          reps.reject! { |r| !select_proc[r] } if select_proc
          reps.sort_by { |r| r.name.to_s }.each do |rep|
            xml.url do
              xml.loc @config[:base_url] + rep.path
              xml.lastmod item[:mtime].__nanoc_to_iso8601_date unless item[:mtime].nil?
              xml.changefreq item[:changefreq] unless item[:changefreq].nil?
              xml.priority item[:priority] unless item[:priority].nil?
            end
          end
        end
      end

      # Return sitemap
      buffer
    end
  end
end

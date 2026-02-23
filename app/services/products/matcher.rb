module Products
  # Service for matching products from external platforms to LiveCart products
  # Matches by SKU (primary), EAN, or name with fallback options
  #
  # Usage:
  #   product = Products::Matcher.call(account: account, sku: "ABC123", ean: "5901234567890", match_by: "sku")
  class Matcher
    def self.call(account:, sku: nil, ean: nil, name: nil, match_by: "sku")
      new(account: account, sku: sku, ean: ean, name: name, match_by: match_by).call
    end

    def initialize(account:, sku: nil, ean: nil, name: nil, match_by: "sku")
      @account = account
      @sku = sku&.to_s&.strip
      @ean = ean&.to_s&.strip
      @name = name&.to_s&.strip
      @match_by = match_by || "sku"
    end

    def call
      return nil if @sku.blank? && @ean.blank? && @name.blank?

      # Try primary matching method first
      product = try_match_by(@match_by)
      return product if product

      # Fallback to other methods if primary didn't work
      fallback_methods = [ "sku", "ean", "name" ] - [ @match_by ]
      fallback_methods.each do |method|
        product = try_match_by(method)
        return product if product
      end

      # No match found
      nil
    end

    private

    def try_match_by(method)
      case method
      when "sku"
        find_by_sku(@sku) if @sku.present?
      when "ean"
        find_by_ean(@ean) if @ean.present?
      when "name"
        find_by_name(@name) if @name.present?
      end
    end

    def find_by_sku(sku)
      @account.products.find_by(sku: sku)
    end

    def find_by_ean(ean)
      @account.products.find_by(ean: ean)
    end

    def find_by_name(name)
      @account.products.find_by("LOWER(name) = ?", name.downcase)
    end
  end
end

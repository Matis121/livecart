module ApplicationHelper
  def card_class(extra_classes = nil)
    [ "bg-base-100 rounded-2xl p-6 shadow-sm transition-colors", extra_classes ].compact.join(" ")
  end

  def header_class(extra_classes = nil)
    [ "flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 mb-6", extra_classes ].compact.join(" ")
  end

  def page_header_class(extra_classes = nil)
    [ "page-title", extra_classes ].compact.join(" ")
  end

  def page_header_paragraph_class(extra_classes = nil)
    [ "body-secondary", extra_classes ].compact.join(" ")
  end

  def section_header_class(extra_classes = nil)
    [ "section-title", extra_classes ].compact.join(" ")
  end

  def integration_logo_url(provider)
    domain = provider.to_s.downcase
    "https://unavatar.io/#{domain}" if domain
  end
end
